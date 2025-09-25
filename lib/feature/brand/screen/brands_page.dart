import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/model/brand_model.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/media_query/media_query.dart';
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
  String selectedFilter = 'All';
  final List<String> statusOptions = ['All', 'Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    final brandState = ref.watch(brandControllerProvider);
    return brandState.when(
        loading: () => Scaffold(body: GlobalLoader()),
        error: (err, st) => Scaffold(body: Center(child: Text('Error'))),
        data: (brand) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
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
              centerTitle: true,
              title: Text(
                'Brands',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              actions: [
                IconButton(
                  padding: EdgeInsets.only(right: screenWidth * 0.04),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BrandCreateScreen()),
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
              child: brandState.when(
                /// ✅ LOADING STATE
                loading: () => FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 2)),
                  builder: (context, snapshot) {
                    return GlobalLoader();
                  },
                ),

                /// ✅ ERROR STATE (with retry)
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                      SizedBox(height: screenHeight * 0.01),
                      const Text(
                        "No Internet Connection",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(brandControllerProvider); // retry
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),

                /// ✅ DATA STATE
                data: (brands) {
                  final filteredBrands = brands.where((brand) {
                    if (selectedFilter == 'Active')
                      return brand.status?.toLowerCase() == 'active';
                    if (selectedFilter == 'Inactive')
                      return brand.status?.toLowerCase() == 'inactive';
                    return true;
                  }).toList();

                  return RefreshIndicator(
                    backgroundColor: Colors.white,
                    color: Theme.of(context).primaryColor,
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 2));
                      ref.invalidate(brandControllerProvider);
                    },
                    child: Column(
                      children: [
                        /// Filter Chips
                        SizedBox(
                          height: screenWidth * 0.1,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: statusOptions.length,
                            itemBuilder: (context, index) {
                              final status = statusOptions[index];
                              final isSelected = status == selectedFilter;
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  backgroundColor: Colors.white,
                                  selectedColor: Theme.of(context).primaryColor,
                                  label: Text(
                                    status,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => selectedFilter = status);
                                    ref.invalidate(brandControllerProvider);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.01),
                          child: Text(
                            'Showing ${filteredBrands.length} of ${brands.length} brands',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                        /// Brands Grid
                        Expanded(
                          child: GridView.builder(
                            itemCount: filteredBrands.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: screenWidth > 600 ? 3 : 2,
                              crossAxisSpacing: screenWidth * 0.04,
                              mainAxisSpacing: screenWidth * 0.04,
                              childAspectRatio: 0.95,
                            ),
                            itemBuilder: (context, index) {
                              final brand = filteredBrands[index];
                              final isActive =
                                  brand.status?.toLowerCase() == 'active';
                              return GestureDetector(
                                onTap: () {
                                  print('Brand ID: ${brand.brandId}');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BrandDetailsScreen(
                                          brandId: brand.brandId!),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.05),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.black12,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(screenWidth * 0.03),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          brand.brandName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Models: ',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              brand.brandModels.length
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.03,
                                            vertical: screenHeight * 0.005,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                                screenWidth * 0.03),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
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
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        });
  }
}
