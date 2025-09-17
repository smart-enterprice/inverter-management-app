import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/model/brand_model.dart';
import '../../../model/dealer_discount_model.dart';
import '../controller/discount_controller.dart';

class DealerDiscountCreatePage extends ConsumerStatefulWidget {
  final String dealerId;
  final List<BrandModel>? brand;

  const DealerDiscountCreatePage({
    super.key,
    required this.dealerId,
    required this.brand,
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
    final discountState = ref.watch(dealerDiscountControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Create Dealer Discount",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: SvgPicture.asset(AppIcons.brand),
            tooltip: "Add Brand",
            onPressed: _showBrandSelectionDialog,
          ),
        ],
        leading: IconButton(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          icon: SvgPicture.asset(
            AppIcons.back_Arrow,
            width: screenWidth * 0.07,
            colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_brandDiscounts.isEmpty)
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
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
                      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
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
                                    width: screenWidth * 0.06,
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
                                  width: screenWidth * 0.06,
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
                                            width: screenWidth * 0.06,
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
                      : Text(
                          "Create Discounts",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  void _showBrandSelectionDialog() {
    if (widget.brand == null || widget.brand!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No brands available for this dealer")),
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
            itemCount: widget.brand!.length,
            itemBuilder: (context, index) {
              final brand = widget.brand![index];
              return ListTile(
                title: Text(brand.brandName),
                onTap: () {
                  setState(() {
                    _brandDiscounts
                        .add(BrandDiscount(brand: brand, modelDiscounts: []));
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
          title: Text(editIndex != null ? "Edit Model Discount" : "Add Model Discount"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button to open model selection dialog
              ElevatedButton(
                onPressed: () async {
                  final chosenModel = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text("Select Model"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: getAvailableModels()
                              .map((modelName) => ListTile(
                            title: Text(modelName),
                            onTap: () => Navigator.pop(context, modelName),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                if (selectedModel == null || discountController.text.isEmpty) return;
                final value = double.tryParse(discountController.text);
                if (value == null || value <= 0) return;
                final modelDiscount = ModelDiscount(
                  modelName: selectedModel!,
                  discountValue: value,
                  isPercentage: isPercentage,
                );

                setState(() {
                  if (editIndex != null) {
                    _brandDiscounts[brandIndex].modelDiscounts[editIndex] = modelDiscount;
                  } else {
                    _brandDiscounts[brandIndex].modelDiscounts.add(modelDiscount);
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
              content:
                  Text("${discounts.length} discount(s) created successfully")),
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
