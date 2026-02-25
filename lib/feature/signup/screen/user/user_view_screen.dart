import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/signup/screen/user/edit_user_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../model/user_model.dart';
import '../../../../screen/loadingScreen.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';

String formatRole(String role) {
  if (role.startsWith('ROLE_')) {
    final cleaned = role.replaceFirst('ROLE_', '');
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }
  return role;
}

// Create a provider for the user data
final userProvider =
    FutureProvider.family<UserModel, String>((ref, userId) async {
  final user =
      await ref.read(signupControllerProvider.notifier).getEmployeeById(userId);
  return user;
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
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final userAsync = ref.watch(userProvider(widget.userId));

    return userAsync.when(
      data: (user) {
        return _buildUserView(context, user, sw, sh);
      },
      loading: () => GlobalLoader(),
      error: (error, stackTrace) => _buildErrorScaffold(context, error, sw, sh),
    );
  }

  Widget _buildUserView(
      BuildContext context, UserModel user, double sw, double sh) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: Screen.w(context) * 0.02,
                  bottom: Screen.w(context) * 0.03,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircularIconButton(
                      icon: Icons.arrow_back_ios_sharp,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      'Employee Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // CircularIconButton(
                    //   icon: Icons.delete,
                    //   iconColor: Colors.red,
                    //   onTap: () => _showDeleteDialog(
                    //       context, user.employeeName, user.employeeId!),
                    // ),
                    CircularIconButton(
                      icon: Icons.edit,
                      iconColor: Theme.of(context).primaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditUserScreen(user: user,),
                        ),
                    ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                    // Invalidate the provider to reload user details
                    ref.invalidate(userProvider(widget.userId));
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileHeader(context, user, sw, sh),
                        SizedBox(height: sh * 0.005),
                        _buildActionButtons(sw, user),
                        SizedBox(height: sh * 0.02),
                        _buildPersonalInfoSection(context, user, sw),
                        SizedBox(height: sh * 0.02),
                        _buildAddressSection(context, user, sw),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildErrorScaffold(
    BuildContext context,
    Object error,
    double sw,
    double sh,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR (custom, no AppBar)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Screen.w(context) * 0.04,
                vertical: Screen.h(context) * 0.02,
              ),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Users',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // keeps title centered
                  SizedBox(width: Screen.w(context) * 0.1),
                  // balance back button space
                ],
              ),
            ),

            /// ERROR BODY
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 50,
                      color: Colors.grey,
                    ),
                    SizedBox(height: Screen.h(context) * 0.01),
                    const Text(
                      "No Internet Connection",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: sh * 0.02),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(userProvider(widget.userId));
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(18),
                      ),
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPersonalInfoSection(
      BuildContext context, UserModel user, double sw) {
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


  Widget _buildProfileHeader(
      BuildContext context, UserModel user, double sw, double sh) {
    return Container(
      width: sw*1,
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
              Container(
                width: sw * 0.5,
                height: sh * 0.25,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: sw * 0.01),
                  // borderRadius: BorderRadius.circular(sw*0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: sw * 0.02,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: user.photo != null && user.photo!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.photo!,
                        fit: BoxFit.fitWidth,
                        errorWidget: (_, __, ___) => Icon(Icons.person,
                            size: sw * 0.1, color: Colors.grey[600]),
                      )
                    : Icon(Icons.person,
                        size: sw * 0.1, color: Colors.grey[600]),
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
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.03, vertical: sh * 0.005),
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

  Widget _buildSectionCard(BuildContext context, String title, IconData icon,
      double sw, List<Widget> children) {
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
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: Theme.of(context).primaryColor, size: sw * 0.05),
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

  Widget _buildInfoRow(
      BuildContext context, String label, String value, double sw) {
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
            child: Text(
              value,
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

  // calling ,whatsApp, email functions can be added in onTap callbacks above.
  Widget _actionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F2FF), // light blue background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1677FF), // primary blue
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double sw, UserModel user) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.04,
        vertical: sw * 0.04,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionItem(
            icon: Icons.call,
            label: 'Call',
            onTap: () => _makeCall(user.employeePhone),
          ),
          _actionItem(
            icon: Icons.email,
            label: 'Email',
            onTap: () => _sendEmail(user.employeeEmail),
          ),
          _actionItem(
            icon: Icons.chat_bubble_rounded,
            label: 'WhatsApp',
            onTap: () => _sendWhatsApp(
              user.employeePhone,
              'Hi ${user.employeeName}',
            ),
          )
        ],
      ),
    );
  }


  void _showDeleteDialog(
      BuildContext context,
      String userName,
      String employeeId,
      ) {
    final reasonController = TextEditingController();
    bool isButtonEnabled = false;
    int secondsRemaining = 10;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Start countdown timer
            if (countdownTimer == null && !isButtonEnabled) {
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (secondsRemaining == 1) {
                  timer.cancel();
                  setDialogState(() {
                    isButtonEnabled = true;
                    secondsRemaining = 0;
                  });
                } else {
                  setDialogState(() => secondsRemaining--);
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Screen.w(context) * 0.05),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(Screen.w(context) * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Screen.w(context) * 0.025),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(Screen.w(context) * 0.02),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange[700],
                              size: Screen.w(context) * 0.07,
                            ),
                          ),
                          SizedBox(width: Screen.w(context) * 0.03),
                          Expanded(
                            child: Text(
                              'Delete "$userName"?',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Screen.h(context) * 0.025),

                      // Reason input
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          hintText: "Enter the reason here...",
                          prefixIcon: const Icon(Icons.edit_note),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        maxLines: 3,
                        onChanged: (_) => setDialogState(() {}),
                      ),

                      // Countdown timer
                      if (!isButtonEnabled)
                        Padding(
                          padding: EdgeInsets.only(top: Screen.h(context) * 0.02),
                          child: Container(
                            padding: EdgeInsets.all(Screen.w(context) * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(Screen.w(context) * 0.02),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: Screen.w(context) * 0.045,
                                  color: Colors.amber[900],
                                ),
                                SizedBox(width: Screen.w(context) * 0.02),
                                Text(
                                  "Please wait $secondsRemaining seconds",
                                  style: TextStyle(
                                    color: Colors.amber[900],
                                    fontSize: Screen.w(context) * 0.035,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: Screen.h(context) * 0.03),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              countdownTimer?.cancel();
                              reasonController.dispose();
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: Screen.w(context) * 0.05,
                                vertical: Screen.h(context) * 0.015,
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: Screen.w(context) * 0.02),
                          ElevatedButton.icon(
                            onPressed: isButtonEnabled && reasonController.text.trim().isNotEmpty
                                ? () async {
                              countdownTimer?.cancel();
                              final reason = reasonController.text.trim();
                              reasonController.dispose();

                              Navigator.pop(ctx);

                              final result = await ref
                                  .read(signupControllerProvider.notifier)
                                  .deleteUser(employeeId, reason);

                              if (!context.mounted) return;

                              ref.invalidate(dealerListProvider);
                              Navigator.pop(context);

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          result == null ? Icons.check_circle : Icons.error_outline,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: Screen.w(context) * 0.02),
                                        Expanded(
                                          child: Text(
                                            result == null
                                                ? "User deleted successfully"
                                                : "Delete failed: $result",
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: result == null ? Colors.green : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Screen.w(context) * 0.02),
                                    ),
                                  ),
                                );
                              });
                            }
                                : null,
                            icon: Icon(Icons.delete_outline, size: Screen.w(context) * 0.045),
                            label: Text(
                              "Delete User",
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              padding: EdgeInsets.symmetric(
                                horizontal: Screen.w(context) * 0.05,
                                vertical: Screen.h(context) * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Screen.w(context) * 0.02),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => countdownTimer?.cancel());
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch email');
    }
  }

  Future<void> _sendWhatsApp(String phone, String name) async {
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent('Hi $name')}',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch WhatsApp');
    }
  }
}
