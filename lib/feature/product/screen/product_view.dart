import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/product_model.dart';
import '../../../model/user_model.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/product_controller.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  ProductModel? currentProduct;
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

    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return _buildErrorScreen("Product not found", theme);
        }

        currentProduct ??= product;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, theme, colorScheme, product),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.all(Screen.w(context) * 0.04),
                      child: Column(
                        children: [
                          _buildProductHeaderCard(theme, colorScheme, product),
                          SizedBox(height: Screen.h(context) * 0.03),
                          _buildStatusCard(theme, colorScheme, product),
                          SizedBox(height: Screen.h(context) * 0.03),
                          _buildStockInfoCard(theme, colorScheme, product),
                          SizedBox(height: Screen.h(context) * 0.03),
                          _buildPricingCard(theme, colorScheme, product),
                          SizedBox(height: Screen.h(context) * 0.03),
                          FutureBuilder<UserModel?>(
                            future: ref
                                .read(signupControllerProvider.notifier)
                                .getEmployeeById(product.createdBy ?? ""),
                            builder: (context, userSnapshot) {
                              return _buildCreatorCard(theme, colorScheme, userSnapshot);
                            },
                          ),
                          SizedBox(height: Screen.h(context) * 0.03),
                          _buildDateInfoRow(theme, colorScheme, product),
                          SizedBox(height: Screen.h(context) * 0.04),
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
      loading: () => GlobalLoader(),
      error: (err, _) => _buildErrorScreen("Error: $err", theme),
    );
  }

  Widget _buildErrorScreen(String message, ThemeData theme) {
    return Scaffold(
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
                    'Brands',
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
                    SizedBox(height: Screen.h(context) * 0.02),
                    ElevatedButton(
                      onPressed: () {
                        ref.watch(productByIdProvider(widget.productId));
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

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, ColorScheme colorScheme, ProductModel product) {
    return SliverAppBar(
      expandedHeight: Screen.h(context) * 0.2,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        padding: EdgeInsets.only(left: Screen.w(context) * 0.04),
        icon: CircularIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onTap: () => Navigator.pop(context),
        ),
        onPressed: (){},
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: Screen.w(context) * 0.15, bottom: Screen.h(context) * 0.016),
        title: Text(
          "Product Details",
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
  color: theme.scaffoldBackgroundColor
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeaderCard(ThemeData theme, ColorScheme colorScheme, ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(Screen.w(context)*0.04),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(Screen.w(context) * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Screen.w(context) * 0.04),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: theme.primaryColor),
                ),
                SizedBox(width: Screen.w(context) * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName ?? "Unnamed Product",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Screen.h(context) * 0.005),
                      Text(
                        product.model ?? "No Model",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add Edit Button
                IconButton(
                  onPressed: () => _showEditProductDetailsDialog(context, product),
                  icon: SvgPicture.asset(AppIcons.edit,colorFilter: ColorFilter.mode(theme.primaryColor, BlendMode.srcIn),width: Screen.w(context) * 0.05),
                  tooltip: 'Edit Product Details',
                ),
              ],
            ),
            SizedBox(height: Screen.h(context) * 0.02),
            Wrap(
              spacing: Screen.w(context) * 0.02,
              runSpacing: Screen.h(context) * 0.01,
              children: [
                _buildInfoChip(Icons.category, "Type", product.productType ?? "N/A", theme),
                _buildInfoChip(Icons.branding_watermark, "Brand", product.brand ?? "N/A", theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDetailsDialog(BuildContext context, ProductModel product) {
    final productNameController = TextEditingController(
      text: product.productName ?? '',
    );
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              SizedBox(width: Screen.w(context) * 0.02),
              const Text('Edit Product Name'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: Screen.h(context) * 0.02),
                  TextFormField(
                    controller: productNameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Product name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: Screen.h(context) * 0.02),
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
                  _updateProductDetails(
                    product,
                    productNameController.text.trim(),
                    product.model!,
                    product.brand!,
                    product.productType!,
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

  void _updateProductDetails(
      ProductModel product,
      String productName,
      String model,
      String brand,
      String productType,
      ) async
  {
    final productUpdate = ref.read(productControllerProvider.notifier);

    try {
      final updatedProduct = product.copyWith(
        productName: productName,
        model: model,
        brand: brand,
        productType: productType,
      );

      await productUpdate.updateProduct(product.productId!, updatedProduct);

      // Refresh the product data
      ref.invalidate(productByIdProvider(product.productId!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product details updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label, String value, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.03, vertical: Screen.h(context) * 0.008),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.primaryColor),
          SizedBox(width: Screen.w(context) * 0.01),
          Text(
            "$label: ",
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, ColorScheme colorScheme, ProductModel product) {
    // ✅ Read directly from product, not from cached state
    final bool active = (product.status ?? '').toLowerCase() == 'active';
    final productUpdate = ref.watch(productControllerProvider.notifier);

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
        padding: EdgeInsets.all(Screen.w(context) * 0.04),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: EdgeInsets.all(Screen.w(context) * 0.03),
              decoration: BoxDecoration(
                color: active ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? Icons.check_circle : Icons.pause_circle,
                color: Colors.white,
                size: Screen.w(context) * 0.05,
              ),
            ),
            SizedBox(width: Screen.w(context) * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Product Status",
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
                  final updatedStatus = product.copyWith(status: status);

                  await productUpdate.updateProduct(widget.productId, updatedStatus);

                  // ✅ Refresh the data from the provider
                  ref.invalidate(productByIdProvider(widget.productId));

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

  Widget _buildStockInfoCard(ThemeData theme, ColorScheme colorScheme, ProductModel product) {
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
        padding: EdgeInsets.all(Screen.w(context) * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_outlined, color: theme.primaryColor, size: Screen.w(context) * 0.06),
                SizedBox(width: Screen.w(context) * 0.03),
                Text(
                  "Stock Information",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: Screen.h(context) * 0.02),
            Row(
              children: [
                Expanded(child: _buildStockItem("Packed", Icons.draw_outlined, product.packedStock ?? 0, Colors.blue)),
                Expanded(child: _buildStockItem("Unpacked", Icons.inventory_2, product.unpackedStock ?? 0, Colors.orange)),
                Expanded(child: _buildStockItem("Total", Icons.summarize, product.availableStock ?? 0, theme.primaryColor)),
              ],
            ),
            SizedBox(height: Screen.h(context) * 0.02),
            if ((product.status ?? '').toLowerCase() == 'active')
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateStockDialog(context, product),
                icon: SvgPicture.asset(AppIcons.edit,colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),width: Screen.w(context) * 0.05),
                label: const Text("Update Stock"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showUpdateStockDialog(BuildContext context, ProductModel product) {
    final packedController = TextEditingController();
    final unpackedController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Update Stock"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: packedController,
                decoration: const InputDecoration(
                  labelText: "Packed Stock to Add",
                  hintText: "Enter quantity",
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: Screen.h(context) * 0.02),
              TextField(
                controller: unpackedController,
                decoration: const InputDecoration(
                  labelText: "Unpacked Stock to Add",
                  hintText: "Enter quantity",
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: Screen.h(context) * 0.02),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: "Notes (Optional)",
                  hintText: "Add notes about this stock update",
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final packed = int.tryParse(packedController.text) ?? 0;
              final unpacked = int.tryParse(unpackedController.text) ?? 0;

              if (packed == 0 && unpacked == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter at least one stock value'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Create stock items list
                List<StockItem> stockItems = [];

                if (unpacked > 0) {
                  stockItems.add(StockItem(
                    stock: unpacked,
                    stockType: "UNPACKED",
                    type: "ADD",
                    stockNotes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  ));
                }

                if (packed > 0) {
                  stockItems.add(StockItem(
                    stock: packed,
                    stockType: "PACKED",
                    type: "ADD",
                    stockNotes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  ));
                }

                // Create the update object
                final stockUpdate = StockUpdate(
                  stockMap: {
                    product.productId!: stockItems,
                  },
                );

                // Call the API
                await ref
                    .read(productControllerProvider.notifier)
                    .updateStock(stockUpdate);

                // Refresh the product data
                ref.invalidate(productByIdProvider(product.productId!));

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update stock: $e'),
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
      ),
    );
  }


  Widget _buildStockItem(String label, IconData icon, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Screen.w(context) * 0.03),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: Screen.w(context) * 0.05),
        ),
        SizedBox(height: Screen.h(context) * 0.01),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: Screen.w(context) * 0.045,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Screen.w(context) * 0.03,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(ThemeData theme, ColorScheme colorScheme, ProductModel product) {
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
        padding: EdgeInsets.all(Screen.w(context) * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('₹',style: TextStyle(fontSize: Screen.w(context)*0.06,color: Colors.green),),
                    SizedBox(width: Screen.w(context) * 0.03),
                    Text(
                      "Pricing",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showEditPriceDialog(context, product),
                  icon: SvgPicture.asset(AppIcons.edit,colorFilter: ColorFilter.mode(Colors.green, BlendMode.srcIn),width: Screen.w(context) * 0.05),
                  tooltip: 'Edit Price',
                ),
              ],
            ),
            SizedBox(height: Screen.h(context) * 0.02),
            Container(
              padding: EdgeInsets.all(Screen.w(context) * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.green.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Price",
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "₹${product.price ?? '0.00'}",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  void _showEditPriceDialog(BuildContext context, ProductModel product) {
    final TextEditingController priceController = TextEditingController(
      text: product.price?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Price'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text('Cancel',style: TextStyle(color: Theme.of(context).primaryColor),),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newPrice = double.parse(priceController.text);
                  _updatePrice(product, newPrice);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _updatePrice(ProductModel product, double newPrice) async{
    final productUpdate = ref.read(productControllerProvider.notifier);

    try {
      final updatedProduct = product.copyWith(price: newPrice);

      await productUpdate.updateProduct(product.productId!, updatedProduct);
      ref.invalidate(productByIdProvider(product.productId!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Price updated to ₹$newPrice'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update price: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        padding: EdgeInsets.all(Screen.w(context) * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: theme.primaryColor, size: Screen.w(context) * 0.06),
                SizedBox(width: Screen.w(context) * 0.03),
                Text(
                  "Created By",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: Screen.h(context) * 0.02),
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildLoadingState()
            else if (snapshot.hasData && snapshot.data != null)
              _buildUserInfo(theme, snapshot.data!)
            else
              _buildErrorState(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GlobalLoader();
  }

  Widget _buildUserInfo(ThemeData theme, UserModel user) {
    return Row(
      children: [
        CircleAvatar(
          radius: Screen.w(context) * 0.06,
          backgroundColor: theme.primaryColor,
          child: Text(
            (user.employeeName ?? "U").substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: Screen.w(context) * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.employeeName ?? "Unknown User",
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: Screen.h(context) * 0.005),
              Text(
                user.role ?? "No role specified",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              ...[
              SizedBox(height: Screen.h(context) * 0.003),
              Text(
                user.employeeEmail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: Screen.w(context) * 0.05),
        SizedBox(width: Screen.w(context) * 0.03),
        Text(
          "Creator information not available",
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildDateInfoRow(ThemeData theme, ColorScheme colorScheme, ProductModel product) {
    return Row(
      children: [
        Expanded(child: _buildDateCard("Created", Icons.calendar_today, product.createdAt, theme)),
        SizedBox(width: Screen.w(context) * 0.03),
        Expanded(child: _buildDateCard("Updated", Icons.update, product.updatedAt, theme)),
      ],
    );
  }

  Widget _buildDateCard(String title, IconData icon, dynamic date, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(Screen.w(context) * 0.04),
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
              Icon(icon, size: Screen.w(context) * 0.04, color: theme.primaryColor),
              SizedBox(width: Screen.w(context) * 0.02),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: Screen.h(context) * 0.01),
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