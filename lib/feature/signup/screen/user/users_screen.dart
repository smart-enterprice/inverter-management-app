import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/signup/screen/user/sign_up_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/user/user_view_screen.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../model/user_model.dart';
import '../../controller/signUp_controller.dart';
import '../../repository/signUp_repository.dart';


final paginatedUserProvider =
StateNotifierProvider<PaginatedUserNotifier, AsyncValue<List<UserModel>>>(
        (ref) {
      final repo = ref.read(signupRepositoryProvider);
      return PaginatedUserNotifier(repo);
    });

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
    if (reset) {
      _page = 1;
      state = const AsyncLoading();
    }
    try {
      final response = await _repo.getEmployees(page: _page, limit: _limit);

      // Get total pages from backend response if available
      // Example: response.data['pages'] (you can return it from repo if needed)

      final newUsers = response;

      if (reset) {
        state = AsyncData(newUsers);
      } else {
        final current = state.value ?? [];
        state = AsyncData([...current, ...newUsers]);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (_page >= _totalPages) return;

    _isLoadingMore = true;
    _page++;
    await fetchUsers();
    _isLoadingMore = false;
  }
}


final selectedRoleProvider = StateProvider<String?>((ref) => null);

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        ref.read(paginatedUserProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(userListProvider);
    final selectedRole = ref.watch(selectedRoleProvider);

    return employeesAsync.when(
      loading: () => GlobalLoader(),
      error: (e, st) => _buildErrorScaffold(context),
      data: (users) => _buildDataScaffold(context, users, selectedRole),
    );
  }


  // Error Scaffold
  Scaffold _buildErrorScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        leading: IconButton(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          icon: SvgPicture.asset(
            AppIcons.back_Arrow,
            width: screenWidth * 0.07,
            colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Users', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 50, color: Colors.grey),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: screenHeight * 0.01),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userListProvider); // retry
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // Data Scaffold
  Scaffold _buildDataScaffold(BuildContext context, List<UserModel> users, String? selectedRole) {
    String formatRole(String role) {
      if (role.startsWith('ROLE_')) {
        final cleaned = role.replaceFirst('ROLE_', '');
        return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
      }
      return role;
    }

    final allRoles = [
      'All',
      ...{
        for (var user in users)
          if (user.role != 'ROLE_SUPER_ADMIN')
            formatRole(user.role)
      }
    ];

    final filteredUsers = users.where((user) {
      final formatted = formatRole(user.role);
      if (user.role == 'ROLE_DEALER' || user.role == 'ROLE_SUPER_ADMIN') return false;
      if (selectedRole == null || selectedRole == 'All') return true;
      return formatted == selectedRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        leading: IconButton(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          icon: SvgPicture.asset(
            AppIcons.back_Arrow,
            width: screenWidth * 0.07,
            colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Users', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen())
              );
            },
            icon: SvgPicture.asset(
              AppIcons.add,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: RefreshIndicator(
          backgroundColor: Colors.white,
          color: Theme.of(context).primaryColor,
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 2));
            ref.invalidate(userListProvider);
          },
          child: Column(
            children: [
              SizedBox(
                height: screenWidth * 0.1,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allRoles.length,
                  itemBuilder: (context, index) {
                    final role = allRoles[index];
                    final isSelected = role == selectedRole || (role == 'All' && selectedRole == null);
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      child: ChoiceChip(
                        showCheckmark: false,
                        backgroundColor: Colors.white,
                        selectedColor: Theme.of(context).primaryColor,
                        label: Text(role,  style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(selectedRoleProvider.notifier).state = role == 'All' ? null : role;
                        },
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UserViewScreen(userId: user.employeeId!)
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.06),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(screenWidth * 0.04),
                          leading: CircleAvatar(
                            radius: screenWidth * 0.07,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: user.photo != null && user.photo!.isNotEmpty
                                ? CachedNetworkImageProvider(user.photo!)
                                : null,
                            child: (user.photo == null || user.photo!.isEmpty)
                                ? Icon(Icons.person, size: screenWidth * 0.07, color: Colors.grey)
                                : null,
                          ),
                          title: Text(
                            user.employeeName,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenWidth * 0.01),
                              Text(
                                'Role: ${formatRole(user.role)}',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                              SizedBox(height: screenWidth * 0.01),
                              _buildInfoRow(Icons.phone_outlined, user.employeePhone, context),
                              SizedBox(height: screenWidth * 0.01),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.05, color: Theme.of(context).primaryColor),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }
}