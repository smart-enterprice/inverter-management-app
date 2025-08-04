import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/signup/screen/user/sign_up_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/user/user_view_screen.dart';
import '../../../../core/media_query/media_query.dart';
import '../../controller/signUp_controller.dart';


final selectedRoleProvider = StateProvider<String?>((ref) => null);

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(userListProvider);
    final selectedRole = ref.watch(selectedRoleProvider);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (users) {
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
                  if (user.role != 'ROLE_DEALER' && user.role != 'ROLE_SUPER_ADMIN')
                    formatRole(user.role)
              }
            ];


            final filteredUsers = users.where((user) {
              final formatted = formatRole(user.role);
              if (user.role == 'ROLE_DEALER' || user.role == 'ROLE_SUPER_ADMIN') return false;
              if (selectedRole == null || selectedRole == 'All') return true;
              return formatted == selectedRole;
            }).toList();



            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Role filter buttons
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
                          backgroundColor:Theme.of(context).cardColor,
                          selectedColor: Theme.of(context).primaryColor,
                          label: Text(role),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(selectedRoleProvider.notifier).state = role == 'All' ? null : role;
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),

                // ✅ User list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 2));
                      ref.invalidate(userListProvider);
                    },
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserViewScreen(user: user)),
                            );
                          },
                          child: Card(
                            margin:
                            EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(screenWidth * 0.08),
                            ),
                            child: ListTile(
                              contentPadding:
                              EdgeInsets.all(screenWidth * 0.04),
                              leading: CircleAvatar(
                                radius: screenWidth * 0.07,
                                backgroundImage:
                                NetworkImage(user.photo),
                                backgroundColor: Colors.grey[200],
                              ),
                              title: Text(
                                user.employeeName,
                                style:
                                Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: screenWidth * 0.01),
                                  _buildInfoRow(Icons.email, user.employeeEmail, context),
                                  SizedBox(height: screenWidth * 0.01),
                                  _buildInfoRow(Icons.phone_outlined, user.employeePhone, context),
                                  SizedBox(height: screenWidth * 0.01),
                                  Text(
                                    'Role: ${formatRole(user.role)}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  AppBar _buildAppBar(BuildContext context){
    return AppBar(
      title: Text('Users', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: SvgPicture.asset(AppIcons.back_Arrow, width: screenWidth * 0.06,colorFilter:ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn) ,),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddUserScreen()));
          },
          icon: SvgPicture.asset(width: screenWidth*0.06,AppIcons.add,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),),
        )
      ],
    );
  }

}


Widget _buildInfoRow(IconData icon, String value, BuildContext context) {
  return Row(
    children: [
      Icon(icon, size: screenWidth * 0.05, color: Theme.of(context).primaryColor),
      SizedBox(width: screenWidth * 0.02),
      Expanded(
        child: Text(
          value,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ],
  );
}
