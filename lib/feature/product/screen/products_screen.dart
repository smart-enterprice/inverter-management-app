import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/feature/product/screen/product_create_screen.dart';
import 'package:inverter_management_app/feature/product/screen/product_view.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/const/icons.dart';
import '../controller/product_controller.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String selectedFilter = 'All';
  final List<String> statusOptions = ['All', 'Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productControllerProvider);

    return productState.when(
      loading: () => const Scaffold(body: GlobalLoader()),
      error: (err, st){
        return Scaffold(body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: screenHeight * 0.01),
            ElevatedButton(
              onPressed: () {
                ref.read(productControllerProvider.notifier).fetchProducts();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ));},
      data: (products) {
        // Filter based on status
        final filteredProducts = products.where((product) {
          if (selectedFilter == 'Active') return product.status?.toLowerCase() == 'active';
          if (selectedFilter == 'Inactive') return product.status?.toLowerCase() == 'inactive';
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 1,
            leading: IconButton(
              padding: EdgeInsets.only(left: screenWidth * 0.04),
              icon: SvgPicture.asset(
                AppIcons.back_Arrow,
                width: screenWidth * 0.07,
                colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              'Products',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                padding: EdgeInsets.only(right: screenWidth * 0.04),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductCreateScreen()),
                  );
                },
                icon: SvgPicture.asset(
                  AppIcons.add,
                  width: screenWidth * 0.07,
                  colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            backgroundColor: Colors.white,
            color: Theme.of(context).primaryColor,
            onRefresh: () async {
              await ref.read(productControllerProvider.notifier).fetchProducts();
            },
            child: Column(
              children: [
                // Header Section with Filter and Stats
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Chips
                      SizedBox(
                        height: screenWidth * 0.1,
                        child: ListView.builder(

                          scrollDirection: Axis.horizontal,
                          itemCount: statusOptions.length,
                          itemBuilder: (context, index) {
                            final status = statusOptions[index];
                            final isSelected = status == selectedFilter;
                            return Padding(
                              padding: EdgeInsets.only(right: screenWidth * 0.03),
                              child: FilterChip(
                                showCheckmark: false,
                                backgroundColor: Colors.white,
                                selectedColor: Theme.of(context).primaryColor,
                                label: Text(
                                  status,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => selectedFilter = status);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // Statistics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Products',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${filteredProducts.length} of ${products.length}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child: filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                    padding: EdgeInsets.only(left: screenWidth * 0.04,right: screenWidth * 0.04,bottom: screenHeight * 0.02),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.015),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isActive = product.status?.toLowerCase() == 'active';
                      return _buildProductCard(context, product, isActive);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: screenWidth * 0.2,
            color: Colors.grey[300],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Try changing your filter or add a new product',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, product, bool isActive) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(productId: product.productId!),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Name and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.productName ?? 'Unnamed Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(
                        color: isActive ? Colors.green[100]! : Colors.red[100]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: screenWidth*0.02,
                          height: screenHeight*0.01,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green[800] : Colors.red[800],
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.008),
              // Product Details
              Row(
                children: [
                  SvgPicture.asset(
                    AppIcons.brand,
                    width: screenWidth * 0.05,
                    colorFilter: ColorFilter.mode(AppTheme.accentRed, BlendMode.srcIn),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Text(
                    product.brand ?? 'No model',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                children: [
                  SvgPicture.asset(
                    AppIcons.model,
                    width: screenWidth * 0.05,
                    colorFilter: ColorFilter.mode(AppTheme.accentYellow, BlendMode.srcIn),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Text(
                    product.model ?? 'No model',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                children: [
                  SvgPicture.asset(
                    AppIcons.type,
                    width: screenWidth * 0.05,
                    colorFilter: ColorFilter.mode(AppTheme.accentBlue, BlendMode.srcIn),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Text(
                    product.productType ?? 'No type',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              // Stock Information
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStockInfo('Packed', product.packedStock?.toString() ?? '0', AppIcons.box,AppTheme.accentGreen),
                    _buildStockInfo('Unpacked', product.unpackedStock?.toString() ?? '0', AppIcons.box,AppTheme.accentRed),
                    _buildStockInfo('Total', product.availableStock?.toString() ?? '0', AppIcons.product,AppTheme.accentBlue),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              // Price and Bottom Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '₹${product.price ?? '0.00'}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, String icon,Color? color) {
    return Column(
      children: [
        SvgPicture.asset(
          icon,
          width: screenWidth * 0.07,
          colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}