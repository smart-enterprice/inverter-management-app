import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/model/brand_model.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/media_query/media_query.dart';
import '../../../core/const/icons.dart';
import '../../../widgets/circle_button.dart';
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
    final brandState = ref.watch(loadBrandsControllerProvider);

    return brandState.when(
      /// ✅ LOADING
      loading: () => const Scaffold(
        body: GlobalLoader(),
      ),
      /// ✅ ERROR
      error: (e, st) {
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
                            ref.invalidate(loadBrandsControllerProvider);
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
      },

      /// ✅ DATA (ONLY ONE when)
      data: (brands) {
        final filteredBrands = brands.where((brand) {
          if (selectedFilter == 'Active') {
            return brand.status?.toLowerCase() == 'active';
          }
          if (selectedFilter == 'Inactive') {
            return brand.status?.toLowerCase() == 'inactive';
          }
          return true;
        }).toList();
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
              child: RefreshIndicator(
                backgroundColor: Colors.white,
                color: Theme.of(context).primaryColor,
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 2));
                  ref.invalidate(loadBrandsControllerProvider);
                },
                child: Column(
                  children: [
                    Padding(
                padding: EdgeInsets.symmetric(
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
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          CircularIconButton(
                            icon: Icons.add,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BrandCreateScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Screen.h(context) * 0.02),
                    /// FILTER CHIPS
                    SizedBox(
                      height: Screen.w(context) * 0.1,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: statusOptions.length,
                        itemBuilder: (context, index) {
                          final status = statusOptions[index];
                          final isSelected = status == selectedFilter;
            
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Screen.w(context) * 0.02),
                            child: ChoiceChip(
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              selectedColor:
                              Theme.of(context).primaryColor,
                              label: Text(
                                status,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: Screen.w(context) * 0.035,
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
            
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: Screen.h(context) * 0.01),
                      child: Text(
                        'Showing ${filteredBrands.length} of ${brands.length} brands',
                        style: TextStyle(
                          fontSize: Screen.w(context) * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
            
                    /// BRANDS GRID
                    Expanded(
                      child: GridView.builder(
                        itemCount: filteredBrands.length,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                          Screen.w(context) > 600 ? 3 : 2,
                          crossAxisSpacing: Screen.w(context) * 0.04,
                          mainAxisSpacing: Screen.w(context) * 0.04,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, index) {
                          final brand = filteredBrands[index];
                          final isActive =
                              brand.status?.toLowerCase() == 'active';
            
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BrandDetailsScreen(
                                    brandId: brand.brandId!,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    Screen.w(context) * 0.05),
                              ),
                              elevation: 3,
                              shadowColor: Colors.black12,
                              color: Colors.white,
                              child: Padding(
                                padding:
                                EdgeInsets.all(Screen.w(context) * 0.03),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      brand.brandName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize:
                                        Screen.w(context) * 0.045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Models: ',
                                          style: TextStyle(
                                            fontSize:
                                            Screen.w(context) * 0.04,
                                          ),
                                        ),
                                        Text(
                                          brand.brandModels.length.toString(),
                                          style: TextStyle(
                                            fontSize:
                                            Screen.w(context) * 0.045,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: Screen.h(context) * 0.01),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                        Screen.w(context) * 0.03,
                                        vertical:
                                        Screen.h(context) * 0.005,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green[50]
                                            : Colors.red[50],
                                        borderRadius:
                                        BorderRadius.circular(
                                            Screen.w(context) * 0.03),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                          fontSize:
                                          Screen.w(context) * 0.03,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
