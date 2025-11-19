import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../model/product_model.dart';
import '../../brand/controller/brand_controller.dart';
import '../controller/product_controller.dart';

// ======== CONTROLLER / PROVIDER ========
final productProvider =
StateNotifierProvider<ProductController, AsyncValue<void>>((ref) {
  return ProductController(ref);
});

class ProductController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  Timer? _timer;

  ProductController(this._ref) : super(const AsyncData(null)) {
    refreshProducts();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshProducts();
    });
    _ref.onDispose(() {
      _timer?.cancel();
    });
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      print("API sent: $data");
      await refreshProducts();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refreshProducts() async {
    try {
      print("Refreshing product data...");
    } catch (e) {
      print("Error refreshing products: $e");
    }
  }
}

// ======== SCREEN ========
class ProductCreateScreen extends ConsumerStatefulWidget {
  const ProductCreateScreen({super.key});

  @override
  ConsumerState<ProductCreateScreen> createState() => _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers grouped for better organization
  late final Map<String, TextEditingController> _controllers;
  bool _isFormValid = false;
  bool _isSubmitting = false;
  String? selectedBrand;
  String? selectedModel;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'brand': TextEditingController(),
      'name': TextEditingController(),
      'model': TextEditingController(),
      'type': TextEditingController(),
      'price': TextEditingController(),
      'packedStock': TextEditingController(),
      'unpackedStock': TextEditingController(),
      'packedNotes': TextEditingController(),
      'unpackedNotes': TextEditingController(),
    };
  }
  void _validateForm() {
    final brandValid = selectedBrand != null && selectedBrand!.isNotEmpty;
    final modelValid = selectedModel != null && selectedModel!.isNotEmpty;

    setState(() {
      _isFormValid =  brandValid && modelValid;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(
          AppIcons.back_Arrow,
          width: screenWidth * 0.07,
          colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColor,
              BlendMode.srcIn
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'New Product',
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBody(List<BrandModel> brands) {
    final brandController = ref.read(activeBrandControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBrandDropdown(brands, brandController),
            _buildModelDropdown(brandController),
            ..._buildBasicInputs(),
            ..._buildStockInputs(),
            SizedBox(height: screenHeight * 0.02),
            _buildSubmitButton(),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }


  Widget _buildBrandDropdown(List<BrandModel> brands, dynamic brandController) {
    return _buildSingleSelectDropdown(
      label: 'Brand',
      hint: 'Select brand',
      items: brandController.brandNames,
      selectedItem: selectedBrand,
      onChanged: (value) {
        setState(() {
          selectedBrand = value;
          selectedModel = null;
        });
      },
    );
  }



  Widget _buildModelDropdown(dynamic brandController) {
    final models = selectedBrand != null
        ? (brandController.getBrandByName(selectedBrand!)?.brandModels ?? [])
        : <String>[];

    return _buildSingleSelectDropdown(
      label: 'Model',
      hint: selectedBrand == null ? 'Select brand first' : 'Select model',
      items: models,
      selectedItem: selectedModel,
      enabled: selectedBrand != null,
      onChanged: (value) => setState(() => selectedModel = value),
    );
  }

  List<Widget> _buildBasicInputs() {
    return [
      _buildInput(
        label: 'Product Name',
        hint: 'Enter product name',
        controller: _controllers['name']!,
      ),
      _buildInput(
        label: 'Product Type',
        hint: 'Enter product type',
        controller: _controllers['type']!,
      ),
      _buildInput(
        label: 'Product Price',
        hint: 'Enter price',
        controller: _controllers['price']!,
        keyboardType: TextInputType.number,
        digitsOnly: true,
      ),
    ];
  }

  List<Widget> _buildStockInputs() {
    return [
      _buildInput(
        label: 'Packed Stock',
        hint: 'Enter packed stock quantity',
        controller: _controllers['packedStock']!,
        keyboardType: TextInputType.number,
        digitsOnly: true,
      ),
      _buildInput(
        label: 'Packed Stock Notes',
        hint: 'Enter notes for packed stock',
        controller: _controllers['packedNotes']!,
        maxLines: 3,
      ),
      _buildInput(
        label: 'Unpacked Stock',
        hint: 'Enter unpacked stock quantity',
        controller: _controllers['unpackedStock']!,
        keyboardType: TextInputType.number,
        digitsOnly: true,
      ),
      _buildInput(
        label: 'Unpacked Stock Notes',
        hint: 'Enter notes for unpacked stock',
        controller: _controllers['unpackedNotes']!,
        maxLines: 3,
      ),
    ];
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: screenWidth * 0.5,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
        ),
        onPressed: _isSubmitting ? null : _handleSubmit,
        child: _isSubmitting
            ?  SizedBox(
            height: screenHeight * 0.04,
            width: screenWidth * 0.05,
          child: CircularProgressIndicator(
            color: Colors.grey,
          )
        )
            : Text(
          'Submit',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _hasAttemptedSubmit = true;
    });
    if (!_formKey.currentState!.validate()) return;

    final priceValue = double.tryParse(_controllers['price']!.text);
    if (priceValue == null || priceValue <= 0) {
      _showSnackBar('Please enter a valid price', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final newProduct = _createProductModel(priceValue);

    try {
      await ref.read(productControllerProvider.notifier).createProduct(newProduct);
      _showSnackBar('✅ Product created successfully', isError: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('$e', isError: true);
      print('error : $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  ProductModel _createProductModel(double priceValue) {
    return ProductModel(
      brand: selectedBrand,
      model: selectedModel,
      productName: _controllers['name']!.text.trim(),
      productType: _controllers['type']!.text.trim(),
      price: priceValue,
      stocks: [
        Stocks(
          type: 'ADD',
          stockType: 'PACKED',
          stock: int.tryParse(_controllers['packedStock']!.text),
          stockNotes: _controllers['packedNotes']!.text.trim(),
        ),
        Stocks(
          type: 'ADD',
          stockType: 'UNPACKED',
          stock: int.tryParse(_controllers['unpackedStock']!.text),
          stockNotes: _controllers['unpackedNotes']!.text.trim(),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        content: Text(message),
      ),
    );
  }

  Widget _buildSingleSelectDropdown({
    required String label,
    required String hint,
    required List<String> items,
    String? selectedItem,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: FormField<String>(
        autovalidateMode: _hasAttemptedSubmit
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        validator: (value) {
          if ((selectedItem == null || selectedItem.isEmpty) && enabled) {
            return 'Please select $label';
          }
          return null;
        },
        builder: (fieldState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: screenHeight * 0.008),
              InkWell(
                onTap: enabled && items.isNotEmpty
                    ? () => _showSingleSelectDialog(context, items, selectedItem, onChanged)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(
                      color: fieldState.hasError ? Colors.red : Colors.grey.shade400,
                      width: 1,
                    ),
                    color: enabled ? Colors.white : Colors.grey.shade200,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedItem ?? hint,
                          style: TextStyle(
                            color: selectedItem == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: enabled ? Colors.grey : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              if (fieldState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 5),
                  child: Text(
                    fieldState.errorText ?? '',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSingleSelectDialog(
      BuildContext context,
      List<String> items,
      String? selectedItem,
      void Function(String?) onChanged,
      )
  async {
    if (items.isEmpty) return;
    await showDialog(
      context: context,
      builder: (context) {
        String searchQuery = ""; // 👈 declare here
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.6,
              maxWidth: screenWidth * 0.8,
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Select",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value; // 👈 updates persist
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Builder(
                        builder: (context) {
                          final filteredItems = items
                              .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
                              .toList();
                          onChanged: (value) {
                            setState(() {
                              selectedBrand = value;
                              selectedModel = null;
                            });
                            _validateForm(); // 👈 check after brand changes
                          };
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return ListTile(
                                title: Text(item),
                                trailing: item == selectedItem
                                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                                    : null,
                                onTap: () {
                                  onChanged(item);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Close",
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool digitsOnly = false,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: screenHeight * 0.008),
          TextFormField(
            // ✅ Remove autovalidateMode or set to disabled
            autovalidateMode: _hasAttemptedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
            onChanged: (_) => _validateForm(), // Just for button state, not validation
            decoration: InputDecoration(
              suffixIcon: suffixIcon,
              filled: false,
              fillColor: Theme.of(context).focusColor,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.018,
              ),
              hintStyle: TextStyle(
                fontSize: screenWidth * 0.038,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final brandState = ref.watch(activeBrandControllerProvider);
    return brandState.when(
      loading: () => const Scaffold(
        body: GlobalLoader(),
      ),
      error: (err, st) => Scaffold(
        body: Center(child: Text('❌ Error loading brands: $err')),
      ),
      data: (brands) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(),
          body: _buildBody(brands), // pass data down
        );
      },
    );
  }

}