import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/model/brand_model.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../model/dealer_discount_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../controller/discount_controller.dart';

// Add this provider at the top level (outside the class)
final dealerBrandsProvider = FutureProvider.family<List<BrandModel>, String>((ref, dealerId) async {
  return ref.read(brandControllerProvider.notifier).getBrandsByDealer(dealerId);
});

class DealerDiscountCreatePage extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerDiscountCreatePage({
    super.key,
    required this.dealerId,
  });

  @override
  ConsumerState<DealerDiscountCreatePage> createState() =>
      _DealerDiscountCreatePageState();
}

class _DealerDiscountCreatePageState
    extends ConsumerState<DealerDiscountCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  /// multiple brand discounts
  final List<BrandDiscount> _brandDiscounts = [];

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(dealerBrandsProvider(widget.dealerId));
    final discountState = ref.watch(dealerDiscountControllerProvider);
    return brandsAsync.when(
        data: (brands){
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(child: _buildContent(discountState, brandsAsync)),
          );
        },
        error: (error, _) =>
        _buildErrorState(context, error, brandsAsync, Screen.w(context), Screen.h(context), ref),
        loading: () => Scaffold(
          backgroundColor: Colors.grey[50],
          body: GlobalLoader(),
        ),
    );
  }
  Widget _buildErrorState(BuildContext context, Object error,
      AsyncValue<List<BrandModel>> brandAsync, double sw, double sh, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Error"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(sw * 0.08),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: sw * 0.15,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(height: sh * 0.03),
              Text(
                'Error loading dealer details',
                style: TextStyle(
                  fontSize: sw * 0.05,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: sh * 0.015),
              Text(
                '$error',
                style: TextStyle(
                  fontSize: sw * 0.035,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: sh * 0.04),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(dealerBrandsProvider(widget.dealerId));
                },
                icon: Icon(Icons.refresh_rounded, size: sw * 0.05),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: sw * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.08,
                    vertical: sh * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sw * 0.03),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildContent(AsyncValue discountState,brandsAsync) {
    return Padding(
      padding: EdgeInsets.all(Screen.w(context) * 0.04),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: Screen.h(context) * 0.015,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// BACK BUTTON
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  /// LEFT SPACER (for center title)
                  const Spacer(),

                  /// TITLE
                  Text(
                    "Create Dealer Discount",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  /// RIGHT SPACER (balances back button)
                  const Spacer(),

                  /// ACTION (Add Brand)
                  IconButton(
                    tooltip: "Add Brand",
                    onPressed: brandsAsync.hasValue
                        ? _showBrandSelectionDialog
                        : null,
                    icon: SvgPicture.asset(
                      AppIcons.brand,
                      width: Screen.w(context) * 0.07,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_brandDiscounts.isEmpty)
                    Container(
                      padding: EdgeInsets.all(Screen.w(context) * 0.06),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "No brand discounts added yet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the + icon above to add a brand and its model discounts.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _brandDiscounts.length,
                      itemBuilder: (context, brandIndex) {
                        final brandDiscount = _brandDiscounts[brandIndex];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: EdgeInsets.only(bottom: Screen.h(context) * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Brand Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      brandDiscount.brand.brandName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        AppIcons.delete,
                                        width: Screen.w(context) * 0.06,
                                        colorFilter: ColorFilter.mode(
                                            Colors.red, BlendMode.srcIn),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _brandDiscounts.removeAt(brandIndex);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(),
                                // Add model button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showModelDiscountDialog(brandIndex),
                                    icon: SvgPicture.asset(
                                      AppIcons.add,
                                      width: Screen.w(context) * 0.06,
                                      colorFilter: ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                    ),
                                    label: const Text("Add Model"),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Models list
                                if (brandDiscount.modelDiscounts.isEmpty)
                                  Text(
                                    "No models added",
                                    style: TextStyle(color: Colors.grey[600]),
                                  )
                                else
                                  ...brandDiscount.modelDiscounts
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) {
                                      final index = entry.key;
                                      final md = entry.value;
                                      return ListTile(
                                        title: Text(md.modelName),
                                        subtitle: Text(md.isPercentage
                                            ? "${md.discountValue}%"
                                            : "₹${md.discountValue}"),
                                        trailing: Wrap(
                                          spacing: 8,
                                          children: [
                                            IconButton(
                                              icon: SvgPicture.asset(
                                                AppIcons.edit,
                                                width: screenWidth * 0.06,
                                                colorFilter: ColorFilter.mode(
                                                    Theme.of(context).primaryColor,
                                                    BlendMode.srcIn),
                                              ),
                                              onPressed: () =>
                                                  _showModelDiscountDialog(
                                                      brandIndex,
                                                      editIndex: index),
                                            ),
                                            IconButton(
                                              icon: SvgPicture.asset(
                                                AppIcons.delete,
                                                width: Screen.w(context) * 0.06,
                                                colorFilter: ColorFilter.mode(
                                                    Colors.red, BlendMode.srcIn),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  brandDiscount.modelDiscounts
                                                      .removeAt(index);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description (Optional)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                      _brandDiscounts.isNotEmpty ? _createDiscounts : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _brandDiscounts.isNotEmpty ? null : Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: discountState.isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                          : const Text(
                        "Create Discounts",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandSelectionDialog() {
    final brandsAsync = ref.read(dealerBrandsProvider(widget.dealerId));

    // Since we only call this when data is available, we can use valueOrNull
    final brands = brandsAsync.valueOrNull ?? [];

    if (brands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No brands available for this dealer")),
      );
      return;
    }

    // Filter out already added brands
    final availableBrands = brands.where((brand) {
      return !_brandDiscounts
          .any((bd) => bd.brand.brandName == brand.brandName);
    }).toList();

    if (availableBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All brands have been added")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Select Brand"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableBrands.length,
            itemBuilder: (context, index) {
              final brand = availableBrands[index];
              return ListTile(
                title: Text(brand.brandName),
                onTap: () {
                  setState(() {
                    _brandDiscounts.add(
                      BrandDiscount(brand: brand, modelDiscounts: []),
                    );
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showModelDiscountDialog(int brandIndex, {int? editIndex}) {
    final brand = _brandDiscounts[brandIndex].brand;
    final models = brand.brandModels ?? [];
    final TextEditingController discountController = TextEditingController();
    String? selectedModel;
    bool isPercentage = true;

    // Pre-fill values when editing
    if (editIndex != null) {
      final existing = _brandDiscounts[brandIndex].modelDiscounts[editIndex];
      selectedModel = existing.modelName;
      discountController.text = existing.discountValue.toString();
      isPercentage = existing.isPercentage;
    }

    List<String> getAvailableModels() {
      return models.where((modelName) {
        final alreadyAdded = _brandDiscounts[brandIndex]
            .modelDiscounts
            .any((md) => md.modelName == modelName);
        if (editIndex != null) {
          final currentModel =
              _brandDiscounts[brandIndex].modelDiscounts[editIndex].modelName;
          return modelName == currentModel || !alreadyAdded;
        } else {
          return !alreadyAdded;
        }
      }).toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(editIndex != null
              ? "Edit Model Discount"
              : "Add Model Discount"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button to open model selection dialog
              ElevatedButton(
                onPressed: () async {
                  final availableModels = getAvailableModels();
                  if (availableModels.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("No more models available")),
                    );
                    return;
                  }

                  final chosenModel = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text("Select Model"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: availableModels
                              .map((modelName) => ListTile(
                            title: Text(modelName),
                            onTap: () =>
                                Navigator.pop(context, modelName),
                          ))
                              .toList(),
                        ),
                      ),
                    ),
                  );
                  if (chosenModel != null) {
                    setDialogState(() => selectedModel = chosenModel);
                  }
                },
                child: Text(selectedModel ?? "Select Model"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount value';
                  }
                  final numValue = double.tryParse(value);
                  if (numValue == null || numValue <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  if (isPercentage && numValue > 100) {
                    return 'Percentage cannot exceed 100';
                  }
                  return null;
                },
                controller: discountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Discount Value",
                  border: const OutlineInputBorder(),
                  suffix: Text(isPercentage ? "%" : "₹"),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Is Percentage?"),
                  Switch(
                    value: isPercentage,
                    onChanged: (v) => setDialogState(() => isPercentage = v),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedModel == null || discountController.text.isEmpty) {
                  return;
                }
                final value = double.tryParse(discountController.text);
                if (value == null || value <= 0) return;
                final modelDiscount = ModelDiscount(
                  modelName: selectedModel!,
                  discountValue: value,
                  isPercentage: isPercentage,
                );

                setState(() {
                  if (editIndex != null) {
                    _brandDiscounts[brandIndex].modelDiscounts[editIndex] =
                        modelDiscount;
                  } else {
                    _brandDiscounts[brandIndex]
                        .modelDiscounts
                        .add(modelDiscount);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(editIndex != null ? "Update" : "Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDiscounts() async {
    try {
      final discounts = <DealerDiscountModel>[];
      for (final bd in _brandDiscounts) {
        for (final md in bd.modelDiscounts) {
          discounts.add(DealerDiscountModel.fromJson({
            "dealer_id": widget.dealerId,
            "brand_name": bd.brand.brandName,
            "model_name": md.modelName,
            "discount_value": md.discountValue,
            "is_percentage": md.isPercentage,
            "description": _descriptionController.text.trim(),
          }));
        }
      }

      await ref
          .read(dealerDiscountControllerProvider.notifier)
          .createDealerDiscounts(discounts);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                  "${discounts.length} discount(s) created successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

class BrandDiscount {
  final BrandModel brand;
  final List<ModelDiscount> modelDiscounts;

  BrandDiscount({required this.brand, required this.modelDiscounts});
}

class ModelDiscount {
  final String modelName;
  final double discountValue;
  final bool isPercentage;

  ModelDiscount({
    required this.modelName,
    required this.discountValue,
    required this.isPercentage,
  });
}