import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../core/theme/theme.dart';
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
  BrandModel? currentBrand;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final brandState = ref.watch(loadBrandsControllerProvider);

    return brandState.when(
      loading: () => GlobalLoader(),
      error: (err, _) => _buildErrorScreen("Error: $err", theme),
      data: (brands) {
        final brand = brands.firstWhere(
              (b) => b.brandId == widget.brandId,
          orElse: () => currentBrand!,
        );

        currentBrand ??= brand;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, theme, colorScheme, brand),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        children: [
                          _buildBrandHeaderCard(theme, colorScheme, brand),
                          SizedBox(height: screenHeight * 0.03),
                          _buildStatusCard(theme, colorScheme, brand),
                          SizedBox(height: screenHeight * 0.03),
                          _buildModelsCard(theme, colorScheme, brand),
                          SizedBox(height: screenHeight * 0.03),
                          FutureBuilder<UserModel?>(
                            future: ref
                                .read(signupControllerProvider.notifier)
                                .getEmployeeById(brand.createdBy ?? ""),
                            builder: (context, userSnapshot) {
                              return _buildCreatorCard(theme, colorScheme, userSnapshot);
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          _buildDateInfoRow(theme, colorScheme, brand),
                          SizedBox(height: screenHeight * 0.04),
                        ],
                      ),
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

  Widget _buildErrorScreen(String message, ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: screenHeight * 0.02),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text("Go Back"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return SliverAppBar(
      expandedHeight: screenHeight * 0.2,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
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
        titlePadding: EdgeInsets.only(left: screenWidth * 0.15, bottom: screenHeight * 0.016),
        title: Text(
          "Brand Details",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            shadows: [
              Shadow(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeaderCard(ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
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
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppIcons.brand,
                    width: screenWidth * 0.07,
                    colorFilter: ColorFilter.mode(AppTheme.accentRed, BlendMode.srcIn),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        brand.description ?? "No description available",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditBrandDetailsDialog(context, brand),
                  icon: SvgPicture.asset(
                    AppIcons.edit,
                    colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                    width: screenWidth * 0.05,
                  ),
                  tooltip: 'Edit Brand Details',
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Wrap(
              spacing: screenWidth * 0.02,
              runSpacing: screenHeight * 0.01,
              children: [
                _buildInfoChip(
                  Icons.format_list_numbered,
                  "Models",
                  "${brand.brandModels.length}",
                  theme,
                ),
                _buildInfoChip(
                  Icons.category,
                  "Status",
                  brand.status ?? "N/A",
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBrandDetailsDialog(BuildContext context, BrandModel brand) {
    final brandNameController = TextEditingController(text: brand.brandName);
    final descriptionController = TextEditingController(text: brand.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              SizedBox(width: screenWidth * 0.02),
              const Text('Edit Brand Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: brandNameController,
                    decoration: InputDecoration(
                      // labelText: 'Brand Name',
                      // border: OutlineInputBorder(),
                      hint: Text('Brand Name'),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: SvgPicture.asset(AppIcons.brand,colorFilter:ColorFilter.mode(AppTheme.accentRed, BlendMode.srcIn,),width: screenWidth * 0.05,  // Set proper size
                            height: screenWidth * 0.05,),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Brand name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      // labelText: 'Description',
                      // border: OutlineInputBorder(),
                      hint: Text('Description'),
                      prefixIcon: Icon(Icons.description,color: Colors.blue,),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _updateBrandDetails(
                    brand,
                    brandNameController.text.trim(),
                    descriptionController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updateBrandDetails(BrandModel brand, String brandName, String description) async {
    final brandController = ref.read(loadBrandsControllerProvider.notifier);

    try {
      final updatedBrand = brand.copyWith(
        brandName: brandName,
        description: description,
      );

      await brandController.updateBrand(updatedBrand, brand.brandName);

      ref.invalidate(loadBrandsControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand details updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update brand details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label, String value, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.008,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.primaryColor),
          SizedBox(width: screenWidth * 0.01),
          Text(
            "$label: ",
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500,),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    final bool active = (brand.status ?? '').toLowerCase() == 'active';
    final brandController = ref.watch(loadBrandsControllerProvider.notifier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: active ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? Icons.check_circle : Icons.pause_circle,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Brand Status",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      active ? "Active" : "Inactive",
                      key: ValueKey(active),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: active,
              onChanged: (value) async {
                try {
                  final status = value ? "active" : "inactive";
                  final updatedBrand = brand.copyWith(status: status);
                  await brandController.updateBrand(updatedBrand, brand.brandName);

                  ref.invalidate(loadBrandsControllerProvider);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status updated to ${value ? "Active" : "Inactive"}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              activeColor: Colors.green,
              activeTrackColor: Colors.green.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsCard(ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.model,
                      width: screenWidth * 0.05,
                      colorFilter: ColorFilter.mode(AppTheme.accentYellow, BlendMode.srcIn),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      "Models",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showManageModelsDialog(context, brand),
                  icon: SvgPicture.asset(
                    AppIcons.edit,
                    colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),
                    width: screenWidth * 0.05,
                  ),
                  tooltip: 'Edit Models',
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            if (brand.brandModels.isEmpty)
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      "No models added yet",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.01,
                children: brand.brandModels
                    .map((model) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppIcons.model,
                        width: screenWidth * 0.05,
                        colorFilter: ColorFilter.mode(AppTheme.accentYellow, BlendMode.srcIn),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        model,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showManageModelsDialog(BuildContext context, BrandModel brand) {
    final newModelController = TextEditingController();

    // Track changes
    final Map<String, String> renamedModels = {}; // old -> new
    final List<String> deletedModels = [];
    final List<String> newModels = []; // List of new model names
    final List<String> currentModels = List.from(brand.brandModels);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Manage Models"),
            content: SingleChildScrollView(
              child: SizedBox(
                width: screenWidth * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add New Model Section
                    Text(
                      "Add New Model",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newModelController,
                            decoration: const InputDecoration(
                              // labelText: "Model Name",
                              hintText: "Enter model name",
                              // border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.add),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        IconButton(
                          onPressed: () {
                            if (newModelController.text.trim().isNotEmpty) {
                              final modelName = newModelController.text.trim();
                              setDialogState(() {
                                newModels.add(modelName);
                                newModelController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add_circle),
                          color: Theme.of(context).primaryColor,
                          iconSize: 32,
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Existing Models Section
                    Text(
                      "Existing Models",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),

                    if (currentModels.isEmpty && newModels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No models available"),
                      )
                    else
                      Column(
                        children: [
                          // Show current models
                          ...currentModels.where((m) => !deletedModels.contains(m)).map((model) {
                            final isRenamed = renamedModels.containsKey(model);
                            return Card(
                              color: Colors.white,
                              margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                              child: ListTile(
                                leading: SvgPicture.asset(AppIcons.model,colorFilter: ColorFilter.mode(AppTheme.accentYellow, BlendMode.srcIn) ,),
                                title: isRenamed
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      model,
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      renamedModels[model]!,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                                    : Text(model),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon:SvgPicture.asset(AppIcons.edit,colorFilter: ColorFilter.mode(AppTheme.primaryColor, BlendMode.srcIn) ,),
                                      onPressed: () => _showRenameDialog(
                                        context,
                                        model,
                                        setDialogState,
                                        renamedModels,
                                      ),
                                    ),
                                    IconButton(
                                      icon: SvgPicture.asset(AppIcons.delete,colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn) ,),
                                      onPressed: () {
                                        setDialogState(() {
                                          deletedModels.add(model);
                                          renamedModels.remove(model);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Show new models
                          ...newModels.map((model) {
                            return Card(
                              color: Colors.white,
                              margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                              child: ListTile(
                                leading: const Icon(Icons.fiber_new, color: Colors.green),
                                title: Text(
                                  model,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: SvgPicture.asset(AppIcons.delete,colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn) ,),
                                  onPressed: () {
                                    setDialogState(() {
                                      newModels.remove(model);
                                    });
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedBrand = BrandModel(
                      brandId: brand.brandId,
                      brandName: brand.brandName,
                      brandModels: brand.brandModels,
                      description: brand.description,
                      status: brand.status,
                      createdBy: brand.createdBy,
                      createdAt: brand.createdAt,
                      updatedAt: brand.updatedAt,
                    );

                    await ref
                        .read(loadBrandsControllerProvider.notifier)
                        .updateBrand(
                      updatedBrand,
                      brand.brandName,
                      brandModelsUpdate: renamedModels.isNotEmpty ? renamedModels : null,
                      deletedModels: deletedModels.isNotEmpty ? deletedModels : null,
                      addModel: newModels.isNotEmpty ? newModels : null,
                    );

                    ref.invalidate(loadBrandsControllerProvider);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Models updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update models: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context,
      String oldName,
      StateSetter setDialogState,
      Map<String, String> renamedModels,
      ) {
    final renameController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Rename Model"),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(
            // labelText: "New Model Name",
            hint: Text('New Model Name')
            // border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",style: TextStyle(color: AppTheme.primaryColor),),
          ),
          ElevatedButton(
            onPressed: () {
              if (renameController.text.trim().isNotEmpty &&
                  renameController.text.trim() != oldName) {
                setDialogState(() {
                  renamedModels[oldName] = renameController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorCard(ThemeData theme, ColorScheme colorScheme, AsyncSnapshot<UserModel?> snapshot) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: theme.primaryColor, size: screenWidth * 0.06),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  "Created By",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            if (snapshot.connectionState == ConnectionState.waiting)
              const GlobalLoader()
            else if (snapshot.hasData && snapshot.data != null)
              _buildUserInfo(theme, snapshot.data!)
            else
              _buildErrorState(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(ThemeData theme, UserModel user) {
    return Row(
      children: [
        CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundColor: theme.primaryColor,
          child: Text(
            (user.employeeName ?? "U").substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.employeeName ?? "Unknown User",
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                user.role ?? "No role specified",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: screenHeight * 0.003),
              Text(
                user.employeeEmail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: screenWidth * 0.05),
        SizedBox(width: screenWidth * 0.03),
        Text(
          "Creator information not available",
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildDateInfoRow(ThemeData theme, ColorScheme colorScheme, BrandModel brand) {
    return Row(
      children: [
        Expanded(child: _buildDateCard("Created", Icons.calendar_today, brand.createdAt, theme)),
        SizedBox(width: screenWidth * 0.03),
        Expanded(child: _buildDateCard("Updated", Icons.update, brand.updatedAt, theme)),
      ],
    );
  }

  Widget _buildDateCard(String title, IconData icon, dynamic date, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: screenWidth * 0.04, color: theme.primaryColor),
              SizedBox(width: screenWidth * 0.02),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            _formatDate(date),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "—";
    try {
      DateTime d = date is String ? DateTime.parse(date) : date as DateTime;
      return DateFormat('MMM dd, yyyy • HH:mm').format(d);
    } catch (e) {
      return "Invalid Date";
    }
  }
}