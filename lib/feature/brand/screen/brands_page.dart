import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../../../core/const/icons.dart';
import '../controller/brand_controller.dart';
import 'brand_create.dart';
import 'brand_details_page.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  String selectedFilter = 'All'; // Options: All, Active, Inactive
  final List<String> statusOptions = ['All', 'Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    final brandState = ref.watch(brandControllerProvider);

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
          'Brands',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BrandCreateScreen()),
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
      body: Column(
        children: [
          /// Filter Chips
          SizedBox(
            height: screenWidth * 0.12,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statusOptions.length,
              itemBuilder: (context, index) {
                final status = statusOptions[index];
                final isSelected = status == selectedFilter;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: ChoiceChip(

                    label: Text(status),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: Theme.of(context).cardColor,
                    onSelected: (_) {
                      setState(() => selectedFilter = status);
                    },
                  ),
                );
              },
            ),
          ),

          /// Brand Grid
          Expanded(
            child: brandState.when(
              data: (brands) {
                final filteredBrands = brands.where((brand) {
                  if (selectedFilter == 'Active') {
                    return brand.status?.toLowerCase() == 'active';
                  } else if (selectedFilter == 'Inactive') {
                    return brand.status?.toLowerCase() == 'inactive';
                  }
                  return true; // All
                }).toList();

                return Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: GridView.builder(
                    itemCount: filteredBrands.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenWidth * 0.04,
                    ),
                    itemBuilder: (context, index) {
                      final brand = filteredBrands[index];
                      final isActive = brand.status?.toLowerCase() == 'active';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrandDetailsScreen(brand: brand),
                            ),
                          );
                        },
                        child: Card(
                          color: Theme.of(context).cardColor,
                          elevation: 0.1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  brand.brandName,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                SizedBox(height: screenHeight * 0.008),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02,
                                    vertical: screenHeight * 0.004,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error loading brands: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
