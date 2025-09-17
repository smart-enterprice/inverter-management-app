import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/model/user_model.dart';
import '../../../../core/const/icons.dart';
import '../../../../core/const/roll_converter.dart';
import '../../../../model/brand_model.dart';
import '../../../../model/dealer_discount_model.dart';
import '../../../brand/controller/brand_controller.dart';
import '../../../discount/controller/discount_controller.dart';
import '../../../discount/screen/discount_create.dart';
import '../../controller/signUp_controller.dart';
import 'edit_dealer_screen.dart';

class DealerView extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerView({super.key, required this.dealerId});

  @override
  ConsumerState<DealerView> createState() => _DealerViewState();
}

class _DealerViewState extends ConsumerState<DealerView> {
  late Future<UserModel?> dealerFuture;
  bool _isEditingDiscounts = false;
  // bool _isEditingBrands = false;
  @override
  void initState() {
    super.initState();
    // Dealer info API call once
    dealerFuture = ref.read(signupControllerProvider.notifier)
        .getEmployeeById(widget.dealerId);

    // Dealer discounts API call once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dealerDiscountControllerProvider.notifier)
          .getDealerDiscounts(widget.dealerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = screenWidth;
    final sh = screenHeight;
    final brandAsync = ref.watch(brandControllerProvider);
    final dealerDiscountsAsync = ref.watch(dealerDiscountControllerProvider);

    return FutureBuilder<UserModel?>(
      future: dealerFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (asyncSnapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, null, brandAsync, sw),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: sw * 0.15, color: Theme.of(context).colorScheme.error),
                  SizedBox(height: sh * 0.02),
                  Text('Error loading dealer details',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: sh * 0.01),
                  Text('${asyncSnapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        } else if (asyncSnapshot.hasData) {
          final dealer = asyncSnapshot.data!;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, dealer, brandAsync, sw),
            body: RefreshIndicator(
              backgroundColor: Colors.white,
              color: Theme.of(context).primaryColor,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 2));
                // Reload dealer details
                final newDealer = await ref
                    .read(signupControllerProvider.notifier)
                    .getEmployeeById(widget.dealerId);
                setState(() {
                  dealerFuture = Future.value(newDealer);
                });

                // Reload discounts
                await ref
                    .read(dealerDiscountControllerProvider.notifier)
                    .getDealerDiscounts(widget.dealerId);
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(sw * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, dealer, sw, sh),
                    SizedBox(height: sh * 0.03),
                    _buildSectionCard(
                      context,
                      'Personal Information',
                      Icons.person,
                      sw,
                      [
                        _buildInfoRow(context, 'Employee ID', dealer.employeeId ?? 'N/A', sw),
                        _buildInfoRow(context, 'Name', dealer.employeeName ?? 'N/A', sw),
                        _buildInfoRow(context, 'Email', dealer.employeeEmail ?? 'N/A', sw),
                        _buildInfoRow(context, 'Phone', dealer.employeePhone ?? 'N/A', sw),
                      ],
                    ),
                    SizedBox(height: sh * 0.02),
                    _buildSectionCard(
                      context,
                      'Address Information',
                      Icons.location_on,
                      sw,
                      [
                        _buildInfoRow(context, 'Address', dealer.address ?? 'N/A', sw),
                        _buildInfoRow(context, 'District', dealer.district ?? 'N/A', sw),
                        _buildInfoRow(context, 'Town', dealer.town ?? 'N/A', sw),
                      ],
                    ),
                    SizedBox(height: sh * 0.02),
                    _buildSectionCard(
                      // text: _isEditingBrands ? 'Cancel' : 'Edit',
                      // onPressed: (){
                      //   setState(() {
                      //     _isEditingBrands=!_isEditingBrands;
                      //   });
                      // },
                      context,
                      'Business Information',
                      Icons.business,
                      sw,
                      [
                        _buildInfoRow(context, 'Shop Name', dealer.shopName ?? 'N/A', sw),
                        brandAsync.when(
                          data: (brands) {
                            final brandNames = dealer.brand?.map((id) {
                              final brand = brands.firstWhere(
                                    (b) => b.brandId == id,
                                orElse: () => BrandModel(
                                  brandId: id,
                                  brandName: 'Unknown',
                                  brandModels: [],
                                  description: '',
                                ),
                              );
                              return brand.brandName;
                            }).toList();
              
                            return _buildBrandsList(context, brandNames ?? [], sw);
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (err, st) => const Text('Error loading brands'),
                        ),
                      ],
                    ),
                    SizedBox(height: sh * 0.02),
                    dealerDiscountsAsync.when(
                      data: (discounts) {
                        if (discounts.isEmpty) {
                          return _buildSectionCard(
                            context,
                            'Dealer Discounts',
                            Icons.percent,
                            sw,
                            [Text('No discounts available', style: TextStyle(fontSize: sw * 0.035))],
                          );
                        }
              
                        return _buildSectionCard(
                          context,
                          'Dealer Discounts',
                          Icons.percent,
                          sw,
                          text: _isEditingDiscounts ? 'Cancel' : 'Edit',
                          onPressed: () {
                            setState(() {
                              _isEditingDiscounts = !_isEditingDiscounts;
                            });
                          },
                          discounts.map((discount) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: sw * 0.015),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      discount.brandName ?? 'Unknown Brand',
                                      style: TextStyle(fontSize: sw * 0.035, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      discount.modelName ?? 'Unknown Brand',
                                      style: TextStyle(fontSize: sw * 0.035, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    discount.isPercentage == true
                                        ? '${discount.discountValue}%'
                                        : '₹${discount.discountValue}',
                                    style: TextStyle(
                                      fontSize: sw * 0.035,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (_isEditingDiscounts) // 👈 show edit button only in edit mode
                                    TextButton(
                                      child:Text('Edit',style: TextStyle(color: Theme.of(context).primaryColor,),),
                                      onPressed: () => _showUpdateDialog(context, discount),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (err, st) => Text('Error loading discounts', style: TextStyle(color: Colors.red)),
                    ),
                    SizedBox(height: sh * 0.03),
                    _buildActionButtons(context, dealer, sw, sh),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, null, brandAsync, sw),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off,
                      size: sw * 0.15, color: Theme.of(context).disabledColor),
                  SizedBox(height: sh * 0.02),
                  Text('No dealer found',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  void _showUpdateDialog(BuildContext context, DealerDiscountModel discount) {
    bool isPercentage = discount.isPercentage;
    final valueController = TextEditingController(
        text: discount.discountValue.toString() ?? '');
    final descController = TextEditingController(text: discount.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context,setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Center(child: Text("Update Discount")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Discount Value"),
                  ),
                  SizedBox(height: screenHeight*0.01,),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: "Description"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Is Percentage?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Transform.scale(
                        scale: screenWidth*0.002, // 🔹 make the switch smaller (0.7–0.9 works well)
                        child: Switch(
                          value: isPercentage,
                          onChanged: (v) => setDialogState(() => isPercentage = v),
                          activeColor: Colors.white,
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel",style: TextStyle(color: Theme.of(context).primaryColor),),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = discount.copyWith(
                      dealerDiscountId: discount.dealerDiscountId,
                      discountValue: int.tryParse(valueController.text),
                      description: descController.text,
                      isPercentage: isPercentage,
                    );
                    await ref
                        .read(dealerDiscountControllerProvider.notifier)
                        .updateDealerDiscount(updated);
                    Navigator.pop(ctx); // close dialog
                  },
                  child: Text("Update"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel? dealer, AsyncValue<List<BrandModel>> brandAsync, double sw) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        padding: EdgeInsets.only(left: screenWidth * 0.04),
        icon: SvgPicture.asset(
          AppIcons.back_Arrow,
          width: screenWidth * 0.07,
          colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Dealer Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: sw * 0.05,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        if (dealer != null) ...[
          brandAsync.when(
            data: (brands) => IconButton(
              icon: SvgPicture.asset(
                AppIcons.percentage,
                width: sw * 0.07,
                colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
              ),
              onPressed: () {
                final dealerBrands = brands
                    .where((b) => dealer.brand?.contains(b.brandId) ?? false)
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DealerDiscountCreatePage(
                      dealerId: widget.dealerId,
                      brand: dealerBrands,
                    ),
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.04),
            icon: SvgPicture.asset(
              AppIcons.delete,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
            ),
            onPressed: () => _showDeleteDialog(context,dealer.employeeId!),
          ),
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.04, right: screenWidth * 0.04),
            icon: SvgPicture.asset(
              AppIcons.edit,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
            ),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (ctx)=>EditDealerScreen(dealer: dealer,)));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel dealer, double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sw * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(sw * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: sw * 0.03,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: sw * 0.25,
            height: sw * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: sw * 0.01),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: sw * 0.02,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: dealer.photo != null && dealer.photo!.isNotEmpty
                  ? Image.network(
                dealer.photo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person,
                    size: sw * 0.1, color: Colors.grey[600]),
              )
                  : Icon(Icons.person, size: sw * 0.1, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: sh * 0.02),
          Text(
            dealer.employeeName ?? 'N/A',
            style: TextStyle(
              fontSize: sw * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: sh * 0.005),
          Container(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sh * 0.005),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(sw * 0.05),
            ),
            child: Text(
              formatRole(dealer.role ?? 'N/A'),
              style: TextStyle(
                fontSize: sw * 0.035,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, String title, IconData icon, double sw, List<Widget> children,{void Function()? onPressed,String? text}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.03)),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: sw * 0.06),
                SizedBox(width: sw * 0.02),
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: sw * 0.045,
                    )),
                Spacer(),
                if(text!=null)
                GestureDetector(onTap: onPressed, child:Text(text,style: TextStyle(color: Theme.of(context).primaryColor,fontWeight: FontWeight.bold),))
              ],
            ),
            SizedBox(height: sw * 0.04),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, double sw) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sw * 0.25,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: sw * 0.035,
              ),
            ),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: sw * 0.04,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsList(BuildContext context, List<String>? brands, double sw) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sw * 0.25,
            child: Text('Brands',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontSize: sw * 0.035,
                )),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: brands != null && brands.isNotEmpty
                ? Wrap(
              spacing: sw * 0.02,
              runSpacing: sw * 0.015,
              children: brands.map((brand) {
                return Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.03, vertical: sw * 0.015),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(1),
                    borderRadius: BorderRadius.circular(sw * 0.05),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    brand,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: sw * 0.03,
                    ),
                  ),
                );
              }).toList(),
            )
                : Text('No brands assigned',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel dealer, double sw, double sh) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.edit, size: sw * 0.05),
            label: Text('Edit Details', style: TextStyle(fontSize: sw * 0.04)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: sh * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
            ),
          ),
        ),
        SizedBox(height: sh * 0.015),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showContactOptions(context, dealer, sw),
            icon: Icon(Icons.contact_phone, size: sw * 0.05),
            label: Text('Contact', style: TextStyle(fontSize: sw * 0.04)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: sh * 0.015),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showContactOptions(BuildContext context, UserModel dealer, double sw) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(sw * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone, size: sw * 0.06),
                title: const Text('Call'),
                subtitle: Text(dealer.employeePhone ?? 'No phone number'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.email, size: sw * 0.06),
                title: const Text('Email'),
                subtitle: Text(dealer.employeeEmail ?? 'No email address'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.message, size: sw * 0.06),
                title: const Text('Message'),
                subtitle: Text(dealer.employeePhone ?? 'No phone number'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String dealerId) {
    TextEditingController reasonController = TextEditingController();
    bool isButtonEnabled = false;
    int secondsRemaining = 10;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Start countdown once dialog opens
            if (!isButtonEnabled && secondsRemaining == 10) {
              Timer.periodic(const Duration(seconds: 1), (timer) {
                if (secondsRemaining == 1) {
                  timer.cancel();
                  setDialogState(() {
                    isButtonEnabled = true;
                    secondsRemaining = 0;
                  });
                } else {
                  setDialogState(() {
                    secondsRemaining--;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Delete User"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: "Reason for deletion",
                    ),
                    maxLines: 2,
                  ),
                  if (!isButtonEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Please wait $secondsRemaining seconds",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:  Text("Cancel",style: TextStyle(color: Theme.of(context).primaryColor),),
                ),
                ElevatedButton(
                  onPressed: isButtonEnabled
                      ? () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a reason")),
                      );
                      return;
                    }

                    // Call delete API
                    final result = await ref
                        .read(signupControllerProvider.notifier)
                        .deleteUser(dealerId, reason);

                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User deleted successfully")),
                      );
                      Navigator.pop(ctx); // close dialog
                      Navigator.pop(context); // close dealer screen
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Delete failed: $result")),
                      );
                    }
                  }
                      : null,
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

}