import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/signup/screen/user/edit_user_screen.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../core/theme/theme.dart';
import '../../../../model/user_model.dart';
import '../../../../core/const/roll_converter.dart';
import '../../controller/signUp_controller.dart';

String formatRole(String role) {
  if (role.startsWith('ROLE_')) {
    final cleaned = role.replaceFirst('ROLE_', '');
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }
  return role;
}

class UserViewScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserViewScreen({super.key, required this.userId});

  @override
  ConsumerState<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends ConsumerState<UserViewScreen> {
  late Future<UserModel?> userFuture;

  @override
  void initState() {
    super.initState();
    // User info API call once
    userFuture = ref.read(signupControllerProvider.notifier)
        .getEmployeeById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final sw = screenWidth;
    final sh = screenHeight;

    return FutureBuilder<UserModel?>(
      future: userFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (asyncSnapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, null, sw),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: sw * 0.15, color: Theme.of(context).colorScheme.error),
                  SizedBox(height: sh * 0.02),
                  Text('Error loading user details',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: sh * 0.01),
                  Text('${asyncSnapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        } else if (asyncSnapshot.hasData) {
          final user = asyncSnapshot.data!;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, user, sw),
            body: RefreshIndicator(
              backgroundColor: Colors.white,
              color: Theme.of(context).primaryColor,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 2));
                // Reload user details
                final newUser = await ref
                    .read(signupControllerProvider.notifier)
                    .getEmployeeById(widget.userId);
                setState(() {
                  userFuture = Future.value(newUser);
                });
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(sw * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, user, sw, sh),
                    SizedBox(height: sh * 0.03),
                    _buildSectionCard(
                      context,
                      'Personal Information',
                      Icons.person,
                      sw,
                      [
                        _buildInfoRow(context, 'Employee ID', user.employeeId ?? 'N/A', sw),
                        _buildInfoRow(context, 'Name', user.employeeName, sw),
                        _buildInfoRow(context, 'Email', user.employeeEmail, sw),
                        _buildInfoRow(context, 'Phone', user.employeePhone, sw),
                        _buildInfoRow(context, 'Role', formatRole(user.role), sw),
                      ],
                    ),
                    SizedBox(height: sh * 0.02),
                    _buildSectionCard(
                      context,
                      'Address Information',
                      Icons.location_on,
                      sw,
                      [
                        _buildInfoRow(context, 'Address', user.address, sw),
                      ],
                    ),
                    SizedBox(height: sh * 0.03),
                    _buildActionButtons(context, user, sw, sh),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, null, sw),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off,
                      size: sw * 0.15, color: Theme.of(context).disabledColor),
                  SizedBox(height: sh * 0.02),
                  Text('No user found',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel? user, double sw) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        padding: EdgeInsets.only(left: screenWidth * 0.04),
        icon: SvgPicture.asset(
          AppIcons.back_Arrow,
          width: screenWidth * 0.07,
          colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'User Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: sw * 0.05,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        if (user != null) ...[
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.04),
            icon: SvgPicture.asset(
              AppIcons.delete,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
            ),
            onPressed: () => _showDeleteDialog(context, user.employeeName, user.employeeId!),
          ),
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.04, right: screenWidth * 0.04),
            icon: SvgPicture.asset(
              AppIcons.edit,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => EditUserScreen(user: user))
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user, double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(sw * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: sw * 0.03,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: sw * 0.25,
            height: sw * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: sw * 0.01),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: sw * 0.02,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: user.photo != null && user.photo!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: user.photo!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(Icons.person,
                    size: sw * 0.1, color: Colors.grey[600]),
              )
                  : Icon(Icons.person, size: sw * 0.1, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: sh * 0.02),
          Text(
            user.employeeName,
            style: TextStyle(
              fontSize: sw * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: sh * 0.005),
          Container(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sh * 0.005),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(sw * 0.05),
            ),
            child: Text(
              formatRole(user.role),
              style: TextStyle(
                fontSize: sw * 0.035,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, String title, IconData icon, double sw, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.03)),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: sw * 0.06),
                SizedBox(width: sw * 0.02),
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: sw * 0.045,
                    )),
              ],
            ),
            SizedBox(height: sw * 0.04),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, double sw) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sw * 0.25,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: sw * 0.035,
              ),
            ),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Text(value,
              style: TextStyle(
                  fontSize: sw * 0.04,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel user, double sw, double sh) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => EditUserScreen(user: user))
              );
            },
            icon: Icon(Icons.edit, size: sw * 0.05),
            label: Text('Edit Details', style: TextStyle(fontSize: sw * 0.04)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: sh * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
            ),
          ),
        ),
        SizedBox(height: sh * 0.015),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showContactOptions(context, user, sw),
            icon: Icon(Icons.contact_phone, size: sw * 0.05),
            label: Text('Contact', style: TextStyle(fontSize: sw * 0.04)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: sh * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showContactOptions(BuildContext context, UserModel user, double sw) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(sw * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone, size: sw * 0.06),
                title: const Text('Call'),
                subtitle: Text(user.employeePhone),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.email, size: sw * 0.06),
                title: const Text('Email'),
                subtitle: Text(user.employeeEmail),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.message, size: sw * 0.06),
                title: const Text('Message'),
                subtitle: Text(user.employeePhone),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String userName, String employeeId) {
    final TextEditingController _reasonController = TextEditingController();
    bool isButtonEnabled = false;
    int secondsRemaining = 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Start countdown once dialog opens
            if (!isButtonEnabled && secondsRemaining == 10) {
              Timer.periodic(const Duration(seconds: 1), (timer) {
                if (secondsRemaining == 1) {
                  timer.cancel();
                  setState(() {
                    isButtonEnabled = true;
                    secondsRemaining = 0;
                  });
                } else {
                  setState(() {
                    secondsRemaining--;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Delete User', style: Theme.of(context).textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Are you sure you want to delete "$userName"?',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Enter reason for deleting',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isButtonEnabled)
                    Text(
                      'Please wait $secondsRemaining seconds...',
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () async {
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reason is required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Call delete API
                    final result = await ref
                        .read(signupControllerProvider.notifier)
                        .deleteUser(employeeId, reason);

                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User deleted successfully')),
                      );
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close user screen
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete failed: $result')),
                      );
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    isButtonEnabled ? 'Delete' : 'Wait...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}