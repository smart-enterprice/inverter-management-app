import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/signup/screen/user/sign_up_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/user/user_view_screen.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';
import '../../repository/signUp_repository.dart';

const _kBlue       = Color(0xFF1B4FD8);
const _kBlueBg     = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg         = Color(0xFFF2F4F8);
const _kBorder     = Color(0xFFE5E7EB);
const _kDark       = Color(0xFF111827);
const _kMid        = Color(0xFF374151);
const _kMuted      = Color(0xFF9CA3AF);

const _avatarSets = [
  (Color(0xFFEEF2FF), Color(0xFFC7D4FF), Color(0xFF1B4FD8)),
  (Color(0xFFEDFAF4), Color(0xFF9FE0C5), Color(0xFF0A8A5C)),
  (Color(0xFFF3EEFF), Color(0xFFC4A8FF), Color(0xFF7C3AED)),
  (Color(0xFFFFF5EA), Color(0xFFFFCF96), Color(0xFFB05800)),
  (Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626)),
];

(Color, Color, Color) _avatarColors(int i) => _avatarSets[i % _avatarSets.length];

String _initials(String name) => name.trim().split(' ').take(2)
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

String _formatRole(String role) {
  if (role.startsWith('ROLE_')) {
    final c = role.replaceFirst('ROLE_', '');
    return c[0].toUpperCase() + c.substring(1).toLowerCase();
  }
  return role;
}

final paginatedUserProvider =
StateNotifierProvider<PaginatedUserNotifier, AsyncValue<List<UserModel>>>(
      (ref) => PaginatedUserNotifier(ref.read(signupRepositoryProvider)),
);

class PaginatedUserNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SignupRepository _repo;
  int _page = 1;
  final int _limit = 20;
  final int _totalPages = 1;
  bool _isLoadingMore = false;

  PaginatedUserNotifier(this._repo) : super(const AsyncLoading()) {
    fetchUsers(reset: true);
  }

  Future<void> fetchUsers({bool reset = false}) async {
    if (reset) { _page = 1; state = const AsyncLoading(); }
    try {
      final newUsers = await _repo.getEmployees(page: _page, limit: _limit);
      if (reset) {
        state = AsyncData(newUsers);
      } else {
        state = AsyncData([...state.value ?? [], ...newUsers]);
      }
    } catch (e, st) { state = AsyncError(e, st); }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    _isLoadingMore = true; _page++;
    await fetchUsers(); _isLoadingMore = false;
  }
}

final selectedRoleProvider = StateProvider<String?>((ref) => null);

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});
  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(paginatedUserProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) { _searchController.clear(); _searchQuery = ''; }
    });
  }

  List<UserModel> _filter(List<UserModel> users, String? selectedRole) {
    return users.where((u) {
      if (u.role == 'ROLE_DEALER' || u.role == 'ROLE_SUPER_ADMIN') return false;
      if (selectedRole != null && selectedRole != 'All') {
        if (_formatRole(u.role) != selectedRole) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return u.employeeName.toLowerCase().contains(q) ||
            u.employeePhone.toLowerCase().contains(q) ||
            _formatRole(u.role).toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final employeesAsync = ref.watch(userListProvider);
    final selectedRole = ref.watch(selectedRoleProvider);

    return employeesAsync.when(
      loading: () => const GlobalLoader(),
      error: (_, __) => _buildError(context, sw, sh),
      data: (users) {
        final allRoles = ['All', ...{
          for (final u in users)
            if (u.role != 'ROLE_SUPER_ADMIN' && u.role != 'ROLE_DEALER')
              _formatRole(u.role)
        }];
        final filtered = _filter(users, selectedRole);

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopNav(context, sw),
                if (_isSearching) _buildSearchBar(context, sw, sh),
                _buildRoleChips(context, sw, allRoles, selectedRole),
                _buildCountRow(sw, filtered.length),
                Expanded(child: _buildList(context, sw, sh, filtered, users)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopNav(BuildContext context, double sw) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
      child: Row(
        children: [
          CircularIconButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text('Users', style: TextStyle(
              fontSize: sw * 0.042, fontWeight: FontWeight.w700,
              color: _kDark, letterSpacing: -0.2)),
          const Spacer(),
          CircularIconButton(
            icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
            onTap: _toggleSearch,
          ),
          SizedBox(width: sw * 0.025),
          RoleGuard(
            feature: AppFeature.handleUser,
            child: CircularIconButton(
              icon: Icons.add,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, double sw, double sh) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sw * 0.04, 0, sw * 0.04, sw * 0.03),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: sw * 0.036, color: _kDark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search by name, phone or role',
          hintStyle: TextStyle(fontSize: sw * 0.034, color: _kMuted, fontWeight: FontWeight.w400),
          prefixIcon: Icon(Icons.search_rounded, color: _kBlue, size: sw * 0.05),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
              icon: Icon(Icons.clear_rounded, size: sw * 0.045, color: _kMuted),
              onPressed: () => setState(() {
                _searchController.clear(); _searchQuery = '';
              }))
              : null,
          filled: true, fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: sw * 0.035, horizontal: sw * 0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.03), borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.03), borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.03), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildRoleChips(BuildContext context, double sw, List<String> roles, String? selectedRole) {
    return SizedBox(
      height: sw * 0.09,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: sw * 0.04),
        itemCount: roles.length,
        itemBuilder: (_, i) {
          final role = roles[i];
          final isSelected = role == selectedRole || (role == 'All' && selectedRole == null);
          return Padding(
            padding: EdgeInsets.only(right: sw * 0.02),
            child: GestureDetector(
              onTap: () => ref.read(selectedRoleProvider.notifier).state = role == 'All' ? null : role,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.015),
                decoration: BoxDecoration(
                  color: isSelected ? _kBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _kBlue : _kBorder, width: 1.5),
                ),
                child: Text(role, style: TextStyle(
                    fontSize: sw * 0.03, fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _kMid)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountRow(double sw, int count) {
    return Padding(
      padding: EdgeInsets.only(left: sw * 0.04, right: sw * 0.04, top: sw * 0.025, bottom: sw * 0.015),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.01),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBlueBorder),
            ),
            child: Text(
              _isSearching && _searchQuery.isNotEmpty
                  ? '$count result${count != 1 ? 's' : ''} found'
                  : '$count user${count != 1 ? 's' : ''}',
              style: TextStyle(fontSize: sw * 0.029, fontWeight: FontWeight.w700, color: _kBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, double sw, double sh,
      List<UserModel> filtered, List<UserModel> all) {
    if (_isSearching && filtered.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: sw * 0.18, height: sw * 0.18,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _kBorder)),
            child: Icon(Icons.search_off_rounded, size: sw * 0.09, color: _kMuted)),
        SizedBox(height: sh * 0.02),
        Text(_searchQuery.isEmpty ? 'Start typing to search' : 'No results for "$_searchQuery"',
            style: TextStyle(fontSize: sw * 0.038, fontWeight: FontWeight.w600, color: _kMid), textAlign: TextAlign.center),
        SizedBox(height: sh * 0.008),
        Text('Try a different name, phone or role', style: TextStyle(fontSize: sw * 0.032, color: _kMuted)),
      ]));
    }

    if (filtered.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: sw * 0.18, height: sw * 0.18,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _kBorder)),
            child: Icon(Icons.people_outline_rounded, size: sw * 0.09, color: _kMuted)),
        SizedBox(height: sh * 0.02),
        Text('No users found', style: TextStyle(fontSize: sw * 0.038, fontWeight: FontWeight.w600, color: _kMid)),
      ]));
    }

    return RefreshIndicator(
      color: _kBlue,
      backgroundColor: Colors.white,
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        ref.invalidate(userListProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final user = filtered[i];
          final c = _avatarColors(i);
          return _UserCard(
            user: user, index: i,
            avatarBg: c.$1, avatarBorder: c.$2, avatarFg: c.$3,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => UserViewScreen(userId: user.employeeId!))),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _buildTopNav(context, sw),
        Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: sw * 0.18, height: sw * 0.18,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _kBorder)),
              child: Icon(Icons.wifi_off_rounded, size: sw * 0.09, color: _kMuted)),
          SizedBox(height: sh * 0.02),
          Text('No Internet Connection', style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w600, color: _kMid)),
          SizedBox(height: sh * 0.025),
          ElevatedButton(
              onPressed: () => ref.invalidate(userListProvider),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue, foregroundColor: Colors.white,
                  shape: const CircleBorder(), padding: const EdgeInsets.all(16), elevation: 0),
              child: const Icon(Icons.refresh_rounded)),
        ]))),
      ])),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final int index;
  final Color avatarBg, avatarBorder, avatarFg;
  final VoidCallback onTap;

  const _UserCard({
    required this.user, required this.index,
    required this.avatarBg, required this.avatarBorder, required this.avatarFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final hasPhoto = user.photo != null && user.photo!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sw * 0.028),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.038),
          child: Row(
            children: [
              // Avatar
              Container(
                width: sw * 0.13, height: sw * 0.13,
                decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBg, border: Border.all(color: avatarBorder, width: 1.5)),
                child: ClipOval(
                  child: hasPhoto
                      ? CachedNetworkImage(
                      imageUrl: user.photo!, fit: BoxFit.cover,
                      placeholder: (_, __) => _fallback(sw),
                      errorWidget: (_, __, ___) => _fallback(sw))
                      : _fallback(sw),
                ),
              ),
              SizedBox(width: sw * 0.035),

              // Info
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    user.employeeName.replaceAll('_', ' '),
                    style: TextStyle(fontSize: sw * 0.038, fontWeight: FontWeight.w700, color: _kDark, letterSpacing: -0.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: sw * 0.015),
                  Row(children: [
                    Icon(Icons.phone_outlined, size: sw * 0.038, color: _kBlue),
                    SizedBox(width: sw * 0.015),
                    Expanded(child: Text(user.employeePhone,
                        style: TextStyle(fontSize: sw * 0.032, color: _kMid, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  SizedBox(height: sw * 0.015),
                  // role badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sw * 0.008),
                    decoration: BoxDecoration(
                      color: avatarBg, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: avatarBorder),
                    ),
                    child: Text(_formatRole(user.role),
                        style: TextStyle(fontSize: sw * 0.028, fontWeight: FontWeight.w700, color: avatarFg)),
                  ),
                ]),
              ),
              SizedBox(width: sw * 0.02),

              // Chevron
              Container(
                width: sw * 0.075, height: sw * 0.075,
                decoration: BoxDecoration(color: _kBg, shape: BoxShape.circle, border: Border.all(color: _kBorder)),
                child: Icon(Icons.chevron_right_rounded, size: sw * 0.045, color: _kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(double sw) => Container(
    color: avatarBg,
    child: Center(child: Text(_initials(user.employeeName),
        style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w800, color: avatarFg))),
  );
}