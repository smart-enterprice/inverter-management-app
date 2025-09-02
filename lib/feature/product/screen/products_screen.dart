import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/product/screen/product_create_screen.dart';
import 'package:inverter_management_app/feature/product/screen/product_view.dart';
import '../../../core/const/icons.dart';
import '../controller/product_controller.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productControllerProvider);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        leading: IconButton(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          icon: SvgPicture.asset(
            AppIcons.back_Arrow,
            width: screenWidth * 0.07,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColor,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Products',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            onPressed: () {
              final controller = ref.read(productControllerProvider.notifier);
              final brands = controller.uniqueBrandNames;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Select Brand"),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: const Text("All Brands"),
                          onTap: () {
                            controller.clearFilter();
                            Navigator.pop(context);
                          },
                        ),
                        ...brands.map((brand) => ListTile(
                          title: Text(brand!),
                          onTap: () {
                            controller.filterByBrand(brand);
                            Navigator.pop(context);
                          },
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
            icon: SvgPicture.asset(
              AppIcons.filter,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          IconButton(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductCreateScreen(),
                ),
              );
            },
            icon: SvgPicture.asset(
              AppIcons.add,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            SizedBox(
              height: screenWidth * 0.14,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                children: ['All', 'Active', 'Inactive'].map((filter) {
                  final isSelected = filter == selectedFilter;
                  return Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: productState.when(
                data: (products) {
                  final filtered = products.where((product) {
                    if (selectedFilter == 'Active') {
                      return product.status?.toLowerCase() == 'active';
                    } else if (selectedFilter == 'Inactive') {
                      return product.status?.toLowerCase() == 'inactive';
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final isActive =
                          product.status?.toLowerCase() == 'active';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductView(id: product.productId!)));
                        },
                        child: Card(
                          color: Theme.of(context).focusColor,
                          margin: EdgeInsets.only(bottom: screenWidth * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                          ),
                          elevation: 0.2,
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // First row: product info + status badge
                                Wrap(
                                  spacing: screenWidth * 0.03,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      product.productName!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      product.model!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      product.productType!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.025,
                                        vertical: screenHeight * 0.003,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(
                                            screenWidth * 0.03),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                 SizedBox(height: screenHeight*0.01),
                                // Second row: stock info
                                Wrap(
                                  spacing: screenWidth * 0.04,
                                  runSpacing: 5,
                                  children: [
                                    Text(
                                      "Packed: ${product.packedStock}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                    Text(
                                      "Unpacked: ${product.unpackedStock}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                    Text(
                                      "Total stock: ${product.availableStock}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ],
                                ),
                                Text(
                                  "Price: ${product.price}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (err, _) {
                  print("error is: $err");
                  return Center(child: Text('Error: $err'));
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
