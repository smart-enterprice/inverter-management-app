import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/signup/screens/user/sign_up_screen.dart';
import 'package:inverter_management_app/feature/signup/screens/user/user_view_screen.dart';
import '../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';
import '../../repository/signUp_repository.dart';

// ── Zoho Books design tokens (mirrored from DealersScreen) ────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

const _avatarSets = [
  (_kPBg,      _kPBd,      _kP),
  (_kGreenBg,  _kGreenBd,  _kGreen),
  (_kPurpleBg, _kPurpleBd, _kPurple),
  (_kAmberBg,  _kAmberBd,  _kAmber),
  (_kRedBg,    _kRedBd,    _kRed),
];

(Color, Color, Color) _avatarColors(int i) => _avatarSets[i % _avatarSets.length];

String _initials(String name) => name.trim().split(' ').take(2)
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

String _formatRole(String role) {
  final clean = role.startsWith('ROLE_')
      ? role.replaceFirst('ROLE_', '')
      : role;
  return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
}

// ── Pagination notifier (unchanged logic) ─────────────────────────────────────
final paginatedUserProvider =
StateNotifierProvider<PaginatedUserNotifier, AsyncValue<List<UserModel>>>(
      (ref) => PaginatedUserNotifier(ref.read(signupRepositoryProvider)),
);

class PaginatedUserNotifier
    extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SignupRepository _repo;
  int _page       = 1;
  final int _limit      = 20;
  final int _totalPages = 1;
  bool _isLoadingMore   = false;

  PaginatedUserNotifier(this._repo) : super(const AsyncLoading()) {
    fetchUsers(reset: true);
  }

  Future<void> fetchUsers({bool reset = false}) async {
    if (reset) { _page = 1; state = const AsyncLoading(); }
    try {
      final newUsers =
      await _repo.getEmployees(page: _page, limit: _limit);
      state = reset
          ? AsyncData(newUsers)
          : AsyncData([...state.value ?? [], ...newUsers]);
    } catch (e, st) { state = AsyncError(e, st); }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    _isLoadingMore = true; _page++;
    await fetchUsers(); _isLoadingMore = false;
  }
}

// ── Role filter provider ──────────────────────────────────────────────────────
final selectedRoleProvider = StateProvider<String?>((ref) => null);

// ═════════════════════════════════════════════════════════════════════════════
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});
  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _query     = '';
  bool   _searching = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(paginatedUserProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) { _searchCtrl.clear(); _query = ''; }
  });

  List<UserModel> _filter(List<UserModel> users, String? selectedRole) {
    return users.where((u) {
      // Always exclude dealers and super admins from user list
      if (u.role == 'ROLE_DEALER' || u.role == 'ROLE_SUPER_ADMIN') {
        return false;
      }
      // Role filter
      if (selectedRole != null && selectedRole != 'All') {
        if (_formatRole(u.role) != selectedRole) return false;
      }
      // Search filter
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.employeeName.toLowerCase().contains(q) ||
          u.employeePhone.toLowerCase().contains(q) ||
          _formatRole(u.role).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw           = MediaQuery.sizeOf(context).width;
    final sh           = MediaQuery.sizeOf(context).height;
    final employeesAsync = ref.watch(userListProvider);
    final selectedRole = ref.watch(selectedRoleProvider);

    // Show the loading/error screens only when we have no cached data yet.
    // On refetch with previous data, keep the list visible.
    final cached = employeesAsync.value;
    if (cached == null) {
      if (employeesAsync.hasError) return _errorView(context, sw, sh);
      return const Scaffold(
          backgroundColor: _kBg,
          body: Center(
              child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)));
    }

    return _buildScaffold(context, sw, sh, cached, selectedRole);
  }

  Widget _buildScaffold(BuildContext context, double sw, double sh,
      List<UserModel> users, String? selectedRole) {
    final allRoles = [
      'All',
      ...{
        for (final u in users)
          if (u.role != 'ROLE_SUPER_ADMIN' && u.role != 'ROLE_DEALER')
            _formatRole(u.role)
      }
    ];
    final filtered = _filter(users, selectedRole);

    return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(child: Column(children: [

            // ── App Bar ────────────────────────────────────────────────
            Container(
              color:   _kWhite,
              padding: EdgeInsets.fromLTRB(
                  sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context)),
                const Spacer(),
                Text('Users',
                    style: TextStyle(
                        fontSize:   (sw * 0.042).clamp(14.0, 20.0),
                        fontWeight: FontWeight.w700,
                        color:      _kT1,
                        letterSpacing: -0.2)),
                const Spacer(),
                CircularIconButton(
                    icon:  _searching
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    onTap: _toggleSearch),
                SizedBox(width: sw * 0.025),
                RoleGuard(
                  feature: AppFeature.handleUser,
                  child: CircularIconButton(
                    icon:  Icons.add,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AddUserScreen())),
                  ),
                ),
              ]),
            ),

            // ── Search bar ─────────────────────────────────────────────
            if (_searching)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.04, 0, sw * 0.04, sh * 0.012),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus:  true,
                  onChanged:  (v) => setState(() => _query = v),
                  style: TextStyle(
                      fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                      color:      _kT1),
                  decoration: _searchDeco(sw),
                ),
              ),

            // ── Role chips ─────────────────────────────────────────────
            _RoleChips(
              sw:           sw,
              sh:           sh,
              roles:        allRoles,
              selectedRole: selectedRole,
              onSelect: (role) => ref
                  .read(selectedRoleProvider.notifier)
                  .state = role == 'All' ? null : role,
            ),

            // ── Count pill ─────────────────────────────────────────────
            if (!(_searching && _query.isEmpty))
              Padding(
                padding: EdgeInsets.only(
                    left:   sw * 0.04,
                    right:  sw * 0.04,
                    top:    sw * 0.01,
                    bottom: sw * 0.02),
                child: Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.03).clamp(10.0, 14.0),
                        vertical:   (sw * 0.01).clamp(3.0, 6.0)),
                    decoration: BoxDecoration(
                        color:        _kPBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kPBd, width: 0.5)),
                    child: Text(
                        _searching
                            ? '${filtered.length} result${filtered.length != 1 ? 's' : ''}'
                            : '${filtered.length} user${filtered.length != 1 ? 's' : ''}',
                        style: TextStyle(
                            fontSize:   (sw * 0.029).clamp(9.5, 12.5),
                            fontWeight: FontWeight.w700,
                            color:      _kP)),
                  ),
                ]),
              ),

            // ── List ───────────────────────────────────────────────────
            Expanded(child: _buildList(context, sw, sh, filtered)),
          ])),
        );
  }

  // ── List ────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext ctx, double sw, double sh,
      List<UserModel> filtered) {
    if (_searching && filtered.isEmpty) {
      return _emptySearch(sw, sh);
    }
    if (filtered.isEmpty) {
      return _emptyAll(sw, sh);
    }
    return RefreshIndicator(
      color:           _kP,
      backgroundColor: _kWhite,
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        ref.invalidate(userListProvider);
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        physics:    const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
        itemCount:   filtered.length,
        itemBuilder: (_, i) {
          final user = filtered[i];
          final c    = _avatarColors(i);
          return _UserCard(
            user:       user,
            avatarBg:   c.$1,
            avatarBd:   c.$2,
            avatarFg:   c.$3,
            onTap: () => Navigator.push(ctx,
                MaterialPageRoute(
                    builder: (_) =>
                        UserViewScreen(userId: user.employeeId!))),
          );
        },
      ),
    );
  }

  // ── Empty states ────────────────────────────────────────────────────────
  Widget _emptySearch(double sw, double sh) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width:  (sw * 0.18).clamp(60.0, 90.0),
        height: (sw * 0.18).clamp(60.0, 90.0),
        decoration: BoxDecoration(
            color:  _kWhite,
            shape:  BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.search_off_rounded,
            size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
      ),
      SizedBox(height: sh * 0.02),
      Text(
          _query.isEmpty
              ? 'Start typing to search'
              : 'No results for "$_query"',
          style: TextStyle(
              fontSize:   (sw * 0.036).clamp(12.0, 16.0),
              fontWeight: FontWeight.w600,
              color:      _kT2),
          textAlign: TextAlign.center),
      SizedBox(height: sh * 0.006),
      Text('Try a different name, phone or role',
          style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
    ]),
  );

  Widget _emptyAll(double sw, double sh) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width:  (sw * 0.18).clamp(60.0, 90.0),
        height: (sw * 0.18).clamp(60.0, 90.0),
        decoration: BoxDecoration(
            color:  _kWhite,
            shape:  BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.people_outline_rounded,
            size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
      ),
      SizedBox(height: sh * 0.02),
      Text('No users found',
          style: TextStyle(
              fontSize:   (sw * 0.036).clamp(12.0, 16.0),
              fontWeight: FontWeight.w600,
              color:      _kT2)),
    ]),
  );

  // ── Error scaffold ──────────────────────────────────────────────────────
  Widget _errorView(BuildContext ctx, double sw, double sh) => Scaffold(
    backgroundColor: _kBg,
    body: SafeArea(child: Column(children: [
      Container(
        color:   _kWhite,
        padding: EdgeInsets.fromLTRB(
            sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
        child: Row(children: [
          CircularIconButton(
              icon: Icons.arrow_back_ios_rounded,
              onTap: () => Navigator.pop(ctx)),
          const Spacer(),
          Text('Users',
              style: TextStyle(
                  fontSize:   (sw * 0.042).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w700,
                  color:      _kT1,
                  letterSpacing: -0.2)),
          const Spacer(),
          SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
        ]),
      ),
      Expanded(
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width:  (sw * 0.18).clamp(60.0, 90.0),
              height: (sw * 0.18).clamp(60.0, 90.0),
              decoration: BoxDecoration(
                  color:  _kWhite,
                  shape:  BoxShape.circle,
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(Icons.wifi_off_rounded,
                  size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
            ),
            SizedBox(height: sh * 0.02),
            Text('No Connection',
                style: TextStyle(
                    fontSize:   (sw * 0.04).clamp(13.0, 18.0),
                    fontWeight: FontWeight.w600,
                    color:      _kT2)),
            SizedBox(height: sh * 0.02),
            ElevatedButton(
                onPressed: () => ref.invalidate(userListProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kP,
                    foregroundColor: _kWhite,
                    shape:   const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    elevation: 0),
                child: const Icon(Icons.refresh_rounded)),
          ]),
        ),
      ),
    ])),
  );

  // ── Search decoration ───────────────────────────────────────────────────
  InputDecoration _searchDeco(double sw) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return InputDecoration(
      hintText:  'Search by name, phone or role',
      hintStyle: TextStyle(
          fontSize:   (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
      prefixIcon: Icon(Icons.search_rounded,
          color: _kP, size: (sw * 0.05).clamp(16.0, 22.0)),
      suffixIcon: _query.isNotEmpty
          ? IconButton(
          icon: Icon(Icons.clear_rounded,
              size:  (sw * 0.045).clamp(15.0, 20.0), color: _kT4),
          onPressed: () =>
              setState(() { _searchCtrl.clear(); _query = ''; }))
          : null,
      filled:     true,
      fillColor:  _kWhite,
      contentPadding: EdgeInsets.symmetric(
          vertical: sw * 0.035, horizontal: sw * 0.04),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide:   const BorderSide(color: _kBd, width: 0.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide:   const BorderSide(color: _kBd, width: 0.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kP, width: 1.5)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _RoleChips — horizontal scrollable role filter, matching dealers' chip style
// ═════════════════════════════════════════════════════════════════════════════
class _RoleChips extends StatelessWidget {
  const _RoleChips({
    required this.sw,
    required this.sh,
    required this.roles,
    required this.selectedRole,
    required this.onSelect,
  });

  final double       sw, sh;
  final List<String> roles;
  final String?      selectedRole;
  final void Function(String) onSelect;

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'all':      return _kT3;
      case 'admin':    return _kP;
      case 'manager':  return _kGreen;
      case 'staff':    return _kAmber;
      case 'technician': return _kPurple;
      default:         return _kP;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kWhite,
      child: Column(children: [
        SizedBox(
          height: sh * 0.048,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics:         const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, 0, sw * 0.04, sh * 0.006),
            itemCount:   roles.length,
            itemBuilder: (_, i) {
              final role = roles[i];
              final isSelected = role == selectedRole ||
                  (role == 'All' && selectedRole == null);
              final dot = _roleColor(role);
              return GestureDetector(
                onTap: () => onSelect(role),
                child: Container(
                  margin:  EdgeInsets.only(right: sw * 0.02),
                  padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.032).clamp(10.0, 16.0),
                      vertical:   (sw * 0.014).clamp(5.0, 8.0)),
                  decoration: BoxDecoration(
                      color:        isSelected ? _kWhite : _kBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? dot : _kBd,
                          width: isSelected ? 1.0 : 0.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width:  (sw * 0.016).clamp(5.0, 8.0),
                        height: (sw * 0.016).clamp(5.0, 8.0),
                        decoration: BoxDecoration(
                            color: dot, shape: BoxShape.circle)),
                    SizedBox(width: sw * 0.015),
                    Text(role,
                        style: TextStyle(
                            fontSize:   (sw * 0.03).clamp(10.0, 13.0),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? _kT1 : _kT4)),
                  ]),
                ),
              );
            },
          ),
        ),
        Divider(height: 1, color: _kBd),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _UserCard — mirrored from _DealerCard structure exactly
// ═════════════════════════════════════════════════════════════════════════════
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.avatarBg,
    required this.avatarBd,
    required this.avatarFg,
    required this.onTap,
  });

  final UserModel user;
  final Color     avatarBg, avatarBd, avatarFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sw       = MediaQuery.sizeOf(context).width;
    final hasPhoto = user.photo != null && user.photo!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sw * 0.025),
        decoration: BoxDecoration(
            color:        _kWhite,
            borderRadius: BorderRadius.circular(
                (sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        padding: EdgeInsets.all(sw * 0.038),
        child: Row(children: [

          // ── Avatar ─────────────────────────────────────────────────
          Container(
            width:  (sw * 0.12).clamp(42.0, 56.0),
            height: (sw * 0.12).clamp(42.0, 56.0),
            decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  avatarBg,
                border: Border.all(color: avatarBd, width: 1.0)),
            child: ClipOval(
              child: hasPhoto
                  ? CachedNetworkImage(
                  imageUrl:    user.photo!,
                  fit:         BoxFit.cover,
                  placeholder: (_, __) => _initView(sw),
                  errorWidget: (_, __, ___) => _initView(sw))
                  : _initView(sw),
            ),
          ),
          SizedBox(width: sw * 0.035),

          // ── Info ────────────────────────────────────────────────────
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Name
              Text(
                user.employeeName.replaceAll('_', ' '),
                style: TextStyle(
                    fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color:      _kT1,
                    letterSpacing: -0.2),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: sw * 0.012),

              // Phone
              _MetaRow(
                  icon:  Icons.phone_outlined,
                  value: user.employeePhone,
                  sw:    sw),
              SizedBox(height: sw * 0.006),

              // Role pill — same pattern as dealer card's location row
              // but rendered as a coloured badge matching the avatar set
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.022).clamp(7.0, 11.0),
                    vertical:   (sw * 0.006).clamp(2.0, 4.5)),
                decoration: BoxDecoration(
                    color:        avatarBg,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: avatarBd, width: 0.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.badge_outlined,
                      size:  (sw * 0.028).clamp(9.5, 12.5),
                      color: avatarFg),
                  SizedBox(width: sw * 0.01),
                  Text(_formatRole(user.role),
                      style: TextStyle(
                          fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                          fontWeight: FontWeight.w700,
                          color:      avatarFg)),
                ]),
              ),
            ]),
          ),
          SizedBox(width: sw * 0.02),

          // ── Chevron ─────────────────────────────────────────────────
          Container(
            width:  (sw * 0.07).clamp(26.0, 34.0),
            height: (sw * 0.07).clamp(26.0, 34.0),
            decoration: BoxDecoration(
                color:  _kBg,
                shape:  BoxShape.circle,
                border: Border.all(color: _kBd, width: 0.5)),
            child: Icon(Icons.chevron_right_rounded,
                size:  (sw * 0.04).clamp(14.0, 18.0), color: _kT4),
          ),
        ]),
      ),
    );
  }

  Widget _initView(double sw) => Container(
    color: avatarBg,
    child: Center(
      child: Text(_initials(user.employeeName),
          style: TextStyle(
              fontSize:   (sw * 0.036).clamp(12.0, 18.0),
              fontWeight: FontWeight.w800,
              color:      avatarFg)),
    ),
  );
}

// ── _MetaRow ─────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.value,
    required this.sw,
  });
  final IconData icon;
  final String   value;
  final double   sw;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon,
        size:  (sw * 0.035).clamp(12.0, 16.0), color: _kP),
    SizedBox(width: sw * 0.015),
    Expanded(
      child: Text(value,
          style: TextStyle(
              fontSize:   (sw * 0.032).clamp(11.0, 14.0),
              color:      _kT2,
              fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  ]);
}