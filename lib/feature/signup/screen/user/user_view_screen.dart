import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/signup/screen/user/edit_user_screen.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../model/user_model.dart';
import '../../../../screen/loadingScreen.dart';
import '../../controller/signUp_controller.dart';

String formatRole(String role) {
  if (role.startsWith('ROLE_')) {
    final cleaned = role.replaceFirst('ROLE_', '');
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }
  return role;
}

// Create a provider for the user data
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  return await ref.read(signupControllerProvider.notifier).getEmployeeById(userId);
});

class UserViewScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserViewScreen({super.key, required this.userId});

  @override
  ConsumerState<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends ConsumerState<UserViewScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = screenWidth;
    final sh = screenHeight;
    final userAsync = ref.watch(userProvider(widget.userId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return _buildNotFoundState(context, sw, sh);
        }
        return _buildUserView(context, user, sw, sh);
      },
      loading: () => GlobalLoader(),
      error: (error, stackTrace) => _buildErrorState(context, error, sw, sh),
    );
  }

  Widget _buildUserView(BuildContext context, UserModel user, double sw, double sh) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, user, sw),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        color: Theme.of(context).primaryColor,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          // Invalidate the provider to reload user details
          ref.invalidate(userProvider(widget.userId));
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, user, sw, sh),
                  SizedBox(height: sh * 0.03),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPersonalInfoSection(context, user, sw),
                  SizedBox(height: sh * 0.02),
                  _buildAddressSection(context, user, sw),
                  SizedBox(height: sh * 0.03),
                  _buildActionButtons(context, user, sw, sh),
                  SizedBox(height: sh * 0.05),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error, double sw, double sh) {
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: Text('$error',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ),
            SizedBox(height: sh * 0.03),
            ElevatedButton.icon(
              onPressed: () {
                // Invalidate the provider to retry
                ref.invalidate(userProvider(widget.userId));
              },
              icon: Icon(Icons.refresh, size: sw * 0.04),
              label: Text('Retry', style: TextStyle(fontSize: sw * 0.035)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, double sw, double sh) {
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
            SizedBox(height: sh * 0.01),
            Text('The requested user could not be found',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, UserModel user, double sw) {
    return _buildSectionCard(
      context,
      'Personal Information',
      Icons.person_outline_rounded,
      sw,
      [
        _buildInfoRow(context, 'Employee ID', user.employeeId ?? 'N/A', sw),
        _buildInfoRow(context, 'Name', user.employeeName, sw),
        _buildInfoRow(context, 'Email', user.employeeEmail, sw),
        _buildInfoRow(context, 'Phone', user.employeePhone, sw),
        _buildInfoRow(context, 'Role', formatRole(user.role), sw),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context, UserModel user, double sw) {
    return _buildSectionCard(
      context,
      'Address Information',
      Icons.location_on_outlined,
      sw,
      [
        _buildInfoRow(context, 'Address', user.address, sw),
      ],
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
          fontSize: sw * 0.045,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (user != null) ...[
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.02),
            icon: Container(
              padding: EdgeInsets.all(sw * 0.015),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                AppIcons.delete,
                width: screenWidth * 0.055,
                colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
              ),
            ),
            onPressed: () => _showDeleteDialog(context, user.employeeName, user.employeeId!),
          ),
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.02, right: screenWidth * 0.04),
            icon: Container(
              padding: EdgeInsets.all(sw * 0.015),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                AppIcons.edit,
                width: screenWidth * 0.055,
                colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
              ),
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
      margin: EdgeInsets.all(sw * 0.04),
      padding: EdgeInsets.all(sw * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
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
          Stack(
            children: [
              Container(
                width: sw * 0.25,
                height: sw * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: sw * 0.01),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(sw * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    color: Theme.of(context).primaryColor,
                    size: sw * 0.04,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.02),
          Text(
            user.employeeName,
            style: TextStyle(
              fontSize: sw * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
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
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sw * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(sw * 0.02),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor, size: sw * 0.05),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: sw * 0.04,
                        color: Colors.black87,
                      )),
                ),
              ],
            ),
            SizedBox(height: sw * 0.03),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, double sw) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sw * 0.3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: sw * 0.035,
              ),
            ),
          ),
          SizedBox(width: sw * 0.02),
          Expanded(
            child: Text(value,
              style: TextStyle(
                fontSize: sw * 0.035,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => EditUserScreen(user: user))
              );
            },
            icon: Icon(Icons.edit_rounded, size: sw * 0.045),
            label: Text('Edit Details', style: TextStyle(fontSize: sw * 0.037)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: sh * 0.018),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
              elevation: 2,
            ),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Container(
          width: sh * 0.07,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(sw * 0.02),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: IconButton(
            onPressed: () => _showContactOptions(context, user, sw),
            icon: Icon(Icons.contact_phone_rounded,
                size: sw * 0.05, color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  void _showContactOptions(BuildContext context, UserModel user, double sw) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(sw * 0.05),
          topRight: Radius.circular(sw * 0.05),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(sw * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: sw * 0.15,
                height: 4,
                margin: EdgeInsets.only(bottom: sw * 0.03),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Contact User',
                style: TextStyle(
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: sw * 0.03),
              if (user.employeePhone.isNotEmpty)
                _buildContactOption(
                  context,
                  Icons.phone_rounded,
                  'Call',
                  user.employeePhone,
                      () => Navigator.pop(context),
                  Colors.green,
                ),
              if (user.employeeEmail.isNotEmpty)
                _buildContactOption(
                  context,
                  Icons.email_rounded,
                  'Email',
                  user.employeeEmail,
                      () => Navigator.pop(context),
                  Colors.blue,
                ),
              if (user.employeePhone.isNotEmpty)
                _buildContactOption(
                  context,
                  Icons.message_rounded,
                  'Message',
                  user.employeePhone,
                      () => Navigator.pop(context),
                  Colors.purple,
                ),
              SizedBox(height: sw * 0.02),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactOption(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: screenWidth * 0.055, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
    );
  }

  void _showDeleteDialog(BuildContext context, String userName, String employeeId) {
    final TextEditingController reasonController = TextEditingController();
    bool isButtonEnabled = false;
    int secondsRemaining = 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: screenWidth * 0.06),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          "Delete User",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Are you sure you want to delete "$userName"?',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      "This action cannot be undone. Please provide a reason for deletion.",
                      style: TextStyle(
                        fontSize: screenWidth * 0.033,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: "Reason for deletion",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    if (!isButtonEnabled)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.015),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: screenWidth * 0.04, color: Colors.grey),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              "Please wait $secondsRemaining seconds",
                              style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.033),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.025),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                          ),
                          child: Text("Cancel", style: TextStyle(fontSize: screenWidth * 0.035)),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        ElevatedButton(
                          onPressed: isButtonEnabled && reasonController.text.trim().isNotEmpty
                              ? () async {
                            final reason = reasonController.text.trim();
                            final result = await ref
                                .read(signupControllerProvider.notifier)
                                .deleteUser(employeeId, reason);

                            if (result == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("User deleted successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Delete failed: $result"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            ),
                          ),
                          child: Text(
                            isButtonEnabled ? 'Delete' : 'Wait...',
                            style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}