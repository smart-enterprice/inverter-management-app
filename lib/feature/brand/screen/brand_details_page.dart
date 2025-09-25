import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../model/user_model.dart';
import '../../../screen/loadingScreen.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/brand_controller.dart';

class BrandDetailsScreen extends ConsumerStatefulWidget {
  final String brandId;

  const BrandDetailsScreen({super.key, required this.brandId});

  @override
  ConsumerState<BrandDetailsScreen> createState() => _BrandDetailsScreenState();
}

class _BrandDetailsScreenState extends ConsumerState<BrandDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool? isActive;
  BrandModel? currentBrand;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load the brand via Riverpod
    ref.read(brandControllerProvider.notifier).getBrandById(widget.brandId).then((brand) {
      if (brand != null && isActive == null) {
        isActive = (brand.status ?? '').toLowerCase() == 'active';
        currentBrand = brand;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final brandState = ref.watch(brandControllerProvider);

    return brandState.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const GlobalLoader(),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text('Error loading brand', style: theme.textTheme.titleLarge),
        ),
      ),
      data: (brands) {
        final brand = brands.firstWhere(
              (b) => b.brandId == widget.brandId,
          // orElse: () => currentBrand ?? BrandModel.empty(),
        );
        isActive ??= (brand.status ?? '').toLowerCase() == 'active';
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, theme),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrandInfoCard(context, theme, ColorScheme.of(context),brand),
                        SizedBox(height: screenHeight * 0.04),
                        FutureBuilder<UserModel?>(
                          future: ref
                              .read(signupControllerProvider.notifier)
                              .getEmployeeById(brand.createdBy.toString()),
                          builder: (context, userSnapshot) {
                            return _buildCreatedBySection(context, theme, userSnapshot);
                          },
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        _buildDateInfo(context, theme, brand),
                        SizedBox(height: screenHeight * 0.04),
                        _buildModelsSection(context, theme,ColorScheme.of(context), brand,),
                        SizedBox(height: screenHeight * 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        padding: EdgeInsets.only(left: screenWidth * 0.04),
        icon: SvgPicture.asset(
          AppIcons.back_Arrow,
          width: screenWidth * 0.07,
          colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: screenWidth * 0.13, bottom: screenHeight * 0.02),
        title: Text("Brand Details", style: theme.textTheme.titleLarge),
      ),
    );
  }

  Widget _buildBrandInfoCard(BuildContext context, ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Avatar/Icon
                Container(
                  width: screenWidth * 0.14,
                  height: screenHeight * 0.06,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.brand,
                      width: screenWidth * 0.07,
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.brandName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        brand.description ?? "No description available",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatusToggle(context, theme, colorScheme, brand),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(BuildContext context, ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: isActive!
            ? theme.primaryColor.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Brand Status",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isActive! ? "Active" : "Inactive",
                    key: ValueKey(isActive),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive! ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Custom animated switch
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 51,
            height: 31,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              color: isUpdating
                  ? Colors.grey.withValues(alpha: 0.3)
                  : (isActive! ? Colors.green : Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                // Background track with subtle animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 51,
                  height: 31,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    color: isUpdating
                        ? Colors.grey.withValues(alpha: 0.1)
                        : (isActive! ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1)),
                  ),
                ),
                // Thumb with smooth animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: isActive! ? 20 : 2,
                  top: 2,
                  child: GestureDetector(
                    onTap: isUpdating ? null : () => _updateStatus(!isActive!, brand),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCreatedBySection(BuildContext context, ThemeData theme, AsyncSnapshot<UserModel?> snapshot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: theme.primaryColor,
                size: screenWidth * 0.06,
              ),
              const SizedBox(width: 8),
              Text(
                "Created By",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
           SizedBox(height: screenHeight * 0.01),
          if (snapshot.data != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.primaryColor,
                  child: Text(
                    (snapshot.data!.employeeName ?? "U").substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.data!.employeeName ?? "Unknown User",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      snapshot.data!.role ?? "No role specified",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 16,
                ),
                SizedBox(width: screenWidth * 0.04),
                Text(
                  "User not found",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context, ThemeData theme, BrandModel brand) {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(
            context,
            AppTheme.accentYellow.withValues(alpha: 0.1),
            AppTheme.accentYellow,
            theme,
            Icons.calendar_today_outlined,
            "Created",
            brand.createdAt != null ? DateFormat('MMM dd, yyyy').format(brand.createdAt!) : "Unknown",
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: _buildDateCard(
            context,
            AppTheme.accentGreen.withValues(alpha: 0.1),
            AppTheme.accentGreen,
            theme,
            Icons.update_outlined,
            "Updated",
            brand.updatedAt != null ? DateFormat('MMM dd, yyyy').format(brand.updatedAt!) : "Never",
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(BuildContext context, Color? color, Color? color2, ThemeData theme, IconData icon, String label, String date) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: screenWidth * 0.04,
                color: color2,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            date,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelsSection(BuildContext context, ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: Theme.of(context).primaryColor,
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              "Models",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.005),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Text(
                "${brand.brandModels.length}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        if (brand.brandModels.isEmpty)
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                SizedBox(width: screenWidth * 0.04),
                Text(
                  "No models added yet",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: brand.brandModels
                .map((model) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppIcons.box,
                    width: screenWidth * 0.05,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Text(
                    model,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
      ],
    );
  }

  Future<void> _updateStatus(bool value, BrandModel brand) async {
    setState(() {
      isUpdating = true;
    });

    try {
      final newStatus = value ? "active" : "inactive";
      final updatedBrand = brand.copyWith(status: newStatus);

      await ref.read(brandControllerProvider.notifier).updateBrand(updatedBrand, brand.brandName);

      // Update the current brand and isActive state
      setState(() {
        isActive = value;
        currentBrand = updatedBrand;
        isUpdating = false;
      });

      // Invalidate the brands list provider to refresh the main screen
      ref.invalidate(brandControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text("Status updated to $newStatus"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text("Failed to update status"),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Edit Options",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Edit Brand Details"),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit page
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Add Model"),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add model functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}