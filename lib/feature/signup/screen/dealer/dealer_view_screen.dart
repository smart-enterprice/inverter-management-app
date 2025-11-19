import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/model/user_model.dart';
import '../../../../core/const/district.dart';
import '../../../../core/const/icons.dart';
import '../../../../core/const/roll_converter.dart';
import '../../../../model/brand_model.dart';
import '../../../../model/dealer_discount_model.dart';
import '../../../../screen/loadingScreen.dart';
import '../../../brand/controller/brand_controller.dart';
import '../../../discount/controller/discount_controller.dart';
import '../../../discount/screen/discount_create.dart';
import '../../controller/signUp_controller.dart';
import 'edit_dealer_screen.dart';

// Create a provider for the dealer data
final dealerProvider = FutureProvider.family<UserModel?, String>((ref, dealerId) async {
  return await ref.read(signupControllerProvider.notifier).getEmployeeById(dealerId);
});

class DealerView extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerView({super.key, required this.dealerId});

  @override
  ConsumerState<DealerView> createState() => _DealerViewState();
}

class _DealerViewState extends ConsumerState<DealerView> with SingleTickerProviderStateMixin {
  bool _isEditingDiscounts = false;
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dealerDiscountControllerProvider.notifier)
          .getDealerDiscounts(widget.dealerId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = screenWidth;
    final sh = screenHeight;
    final brandAsync = ref.watch(loadBrandsControllerProvider);
    final dealerDiscountsAsync = ref.watch(dealerDiscountControllerProvider);
    final dealerAsync = ref.watch(dealerProvider(widget.dealerId));

    return dealerAsync.when(
      data: (dealer) {
        if (dealer == null) {
          return _buildNotFoundState(context, sw, sh);
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, dealer, brandAsync, sw),
          body: RefreshIndicator(
            backgroundColor: Colors.white,
            color: Theme.of(context).primaryColor,
            strokeWidth: 3,
            displacement: 40,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
              ref.invalidate(dealerProvider(widget.dealerId));
              await ref.read(dealerDiscountControllerProvider.notifier)
                  .getDealerDiscounts(widget.dealerId);
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(context, dealer, sw, sh),
                        SizedBox(height: sh * 0.02),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAnimatedSection(0, _buildPersonalInfoSection(context, dealer, sw)),
                      SizedBox(height: sh * 0.015),
                      _buildAnimatedSection(1, _buildAddressSection(context, dealer, sw)),
                      SizedBox(height: sh * 0.015),
                      _buildAnimatedSection(2, _buildBusinessSection(context, dealer, sw)),
                      SizedBox(height: sh * 0.015),
                      _buildAnimatedSection(3, _buildDiscountsSection(context, dealerDiscountsAsync, sw, sh)),
                      SizedBox(height: sh * 0.1),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.grey[50],
        body: GlobalLoader(),
      ),
      error: (error, stackTrace) => _buildErrorState(context, error, brandAsync, sw, sh),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildNotFoundState(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, null, const AsyncValue.data([]), sw),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(sw * 0.08),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_outlined,
                  size: sw * 0.15, color: Colors.grey[400]),
            ),
            SizedBox(height: sh * 0.03),
            Text('No dealer found',
                style: TextStyle(
                  fontSize: sw * 0.05,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                )),
            SizedBox(height: sh * 0.01),
            Text('The dealer you\'re looking for doesn\'t exist',
                style: TextStyle(fontSize: sw * 0.035, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, AsyncValue<List<BrandModel>> brandAsync, double sw, double sh) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, null, brandAsync, sw),
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
                child: Icon(Icons.error_outline,
                    size: sw * 0.15, color: Colors.red[400]),
              ),
              SizedBox(height: sh * 0.03),
              Text('Error loading dealer details',
                  style: TextStyle(
                    fontSize: sw * 0.05,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center),
              SizedBox(height: sh * 0.015),
              Text('$error',
                  style: TextStyle(fontSize: sw * 0.035, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
              SizedBox(height: sh * 0.04),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(dealerProvider(widget.dealerId));
                },
                icon: Icon(Icons.refresh_rounded, size: sw * 0.05),
                label: Text('Retry', style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.08, vertical: sh * 0.02),
                  elevation: 0,
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

  Widget _buildPersonalInfoSection(BuildContext context, UserModel dealer, double sw) {
    return _buildModernSectionCard(
      context,
      'Personal Information',
      Icons.person_outline_rounded,
      sw,
      [
        _buildModernInfoRow(context, Icons.badge_outlined, 'Employee ID', dealer.employeeId ?? 'N/A', sw),
        _buildModernInfoRow(context, Icons.person_outline, 'Name', dealer.employeeName ?? 'N/A', sw),
        _buildModernInfoRow(context, Icons.email_outlined, 'Email', dealer.employeeEmail ?? 'N/A', sw),
        _buildModernInfoRow(context, Icons.phone_outlined, 'Phone', dealer.employeePhone ?? 'N/A', sw),
      ],
      onEdit: () => _showEditPersonalInfoDialog(context, dealer),
    );
  }

  Widget _buildAddressSection(BuildContext context, UserModel dealer, double sw) {
    return _buildModernSectionCard(
      context,
      'Address Information',
      Icons.location_on_outlined,
      sw,
      [
        _buildModernInfoRow(context, Icons.home_outlined, 'Address', dealer.address ?? 'N/A', sw),
        _buildModernInfoRow(context, Icons.map_outlined, 'District', dealer.district ?? 'N/A', sw),
        _buildModernInfoRow(context, Icons.location_city_outlined, 'Town', dealer.town ?? 'N/A', sw),
      ],
      onEdit: () => _showEditAddressDialog(context, dealer),
    );
  }

  Widget _buildBusinessSection(BuildContext context, UserModel dealer, double sw) {
    return _buildModernSectionCard(
      context,
      'Business Information',
      Icons.business_center_outlined,
      sw,
      [
        _buildModernInfoRow(context, Icons.store_outlined, 'Shop Name', dealer.shopName ?? 'N/A', sw),
        SizedBox(height: sw * 0.02),
        FutureBuilder<List<BrandModel>>(
          future: ref.read(brandControllerProvider.notifier)
              .getBrandsByDealer(widget.dealerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: sw * 0.03),
                  child: SizedBox(
                    width: sw * 0.06,
                    height: sw * 0.06,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.all(sw * 0.03),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(sw * 0.02),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: sw * 0.04, color: Colors.red[700]),
                    SizedBox(width: sw * 0.02),
                    Expanded(
                      child: Text('Error loading brands',
                          style: TextStyle(fontSize: sw * 0.032, color: Colors.red[700])),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(sw * 0.03),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(sw * 0.02),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: sw * 0.04, color: Colors.grey[600]),
                    SizedBox(width: sw * 0.02),
                    Text('No active brands assigned',
                        style: TextStyle(fontSize: sw * 0.032, color: Colors.grey[600])),
                  ],
                ),
              );
            } else {
              final brands = snapshot.data!;
              final brandNames = brands.map((b) => b.brandName).toList();
              return _buildModernBrandsList(context, brandNames, sw);
            }
          },
        ),
      ],
      onEdit: () => _showEditBusinessDialog(context, ref, dealer),
    );
  }

  Widget _buildModernSectionCard(
      BuildContext context,
      String title,
      IconData icon,
      double sw,
      List<Widget> children, {
        VoidCallback? onEdit,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.045),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(sw * 0.025),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(sw * 0.025),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor, size: sw * 0.055),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: sw * 0.042,
                      color: Colors.grey[900],
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (onEdit != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(sw * 0.02),
                      child: Container(
                        padding: EdgeInsets.all(sw * 0.02),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(sw * 0.02),
                        ),
                        child: SvgPicture.asset(
                          AppIcons.edit,
                          width: sw * 0.045,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: sw * 0.04),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(BuildContext context, IconData icon, String label, String value, double sw) {
    return Padding(
      padding: EdgeInsets.only(bottom: sw * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(sw * 0.015),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(sw * 0.015),
            ),
            child: Icon(icon, size: sw * 0.04, color: Colors.grey[700]),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: sw * 0.032,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: sw * 0.01),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: sw * 0.038,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBrandsList(BuildContext context, List<String>? brands, double sw) {
    if (brands == null || brands.isEmpty) {
      return Container(
        padding: EdgeInsets.all(sw * 0.03),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(sw * 0.02),
        ),
        child: Text('No brands assigned',
            style: TextStyle(fontSize: sw * 0.032, color: Colors.grey[600])),
      );
    }

    return Wrap(
      spacing: sw * 0.02,
      runSpacing: sw * 0.02,
      children: brands.map((brand) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.02),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(sw * 0.06),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            brand,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: sw * 0.032,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Edit Personal Info Dialog
  void _showEditPersonalInfoDialog(BuildContext context, UserModel dealer) {
    final nameController = TextEditingController(text: dealer.employeeName);
    final emailController = TextEditingController(text: dealer.employeeEmail);
    final phoneController = TextEditingController(text: dealer.employeePhone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: Theme.of(context).primaryColor, size: screenWidth * 0.06),
              ),
              SizedBox(width: screenWidth * 0.03),
              const Text('Edit Personal Info'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Update your name',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Update your email',
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      hintText: 'Update your phone number',
                      prefixIcon: const Icon(Icons.phone),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _updateDealerInfo(
                    dealer,
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                elevation: 0,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Edit Address Dialog
  void _showEditAddressDialog(BuildContext context, UserModel dealer) {
    final addressController = TextEditingController(text: dealer.address);
    final townController = TextEditingController(text: dealer.town);
    final formKey = GlobalKey<FormState>();

    String? selectedDistrict;
    if (dealer.district != null && dealer.district!.isNotEmpty) {
      final normalizedDealerDistrict = dealer.district!.trim().toLowerCase();
      selectedDistrict = keralaDistricts.firstWhere(
            (district) => district.toLowerCase() == normalizedDealerDistrict,
        orElse: () => dealer.district!,
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Icon(Icons.location_on_outlined,
                        color: Theme.of(context).primaryColor, size: screenWidth * 0.06),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  const Text('Edit Address'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          hintText: 'Update your address',
                          prefixIcon: const Icon(Icons.home),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      DropdownButtonFormField<String>(
                        value: keralaDistricts.contains(selectedDistrict)
                            ? selectedDistrict
                            : null,
                        decoration: InputDecoration(
                          hintText: selectedDistrict != null &&
                              !keralaDistricts.contains(selectedDistrict)
                              ? 'Current: $selectedDistrict (Select new)'
                              : 'Select district',
                          prefixIcon: const Icon(Icons.map),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: keralaDistricts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDistrict = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'District is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: townController,
                        decoration: InputDecoration(
                          hintText: 'Update your town',
                          prefixIcon: const Icon(Icons.location_city),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Town is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _updateDealerInfo(
                        dealer,
                        address: addressController.text.trim(),
                        district: selectedDistrict!,
                        town: townController.text.trim(),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // FIXED: Edit Business Dialog
  void _showEditBusinessDialog(BuildContext context, WidgetRef ref, UserModel dealer) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      // Fetch brands
      final allBrandsAsync = ref.read(activeBrandControllerProvider);

      await allBrandsAsync.when(
        data: (allBrands) async {
          // Close loading dialog
          Navigator.pop(context);

          List<String> selectedBrands = List<String>.from(dealer.brand ?? []);
          final shopNameController = TextEditingController(text: dealer.shopName ?? '');

          // Show the actual dialog
          await showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          child: Icon(Icons.business_center_outlined,
                              color: Theme.of(context).primaryColor, size: screenWidth * 0.06),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        const Text('Edit Business Info'),
                      ],
                    ),
                    content: SizedBox(
                      width: screenWidth * 0.8,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: shopNameController,
                              decoration: InputDecoration(
                                labelText: 'Shop Name',
                                prefixIcon: const Icon(Icons.store),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Select Brands',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              height: screenHeight * 0.3,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              child: allBrands.isEmpty
                                  ? const Center(child: Text('No brands available'))
                                  : ListView.builder(
                                itemCount: allBrands.length,
                                itemBuilder: (context, index) {
                                  final brand = allBrands[index];
                                  final brandId = brand.brandId ?? '';
                                  final isSelected = selectedBrands.contains(brandId);

                                  return CheckboxListTile(
                                    title: Text(brand.brandName ?? 'Unknown'),
                                    value: isSelected,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          if (!selectedBrands.contains(brandId)) {
                                            selectedBrands.add(brandId);
                                          }
                                        } else {
                                          selectedBrands.remove(brandId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          shopNameController.dispose();
                          Navigator.pop(dialogContext);
                        },
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _updateDealerInfo(
                            dealer,
                            shopName: shopNameController.text.trim(),
                            brand: selectedBrands,
                          );
                          shopNameController.dispose();
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Update'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        loading: () async {
          // Keep loading dialog open
          await Future.delayed(Duration(seconds: 30)); // Timeout
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Loading brands timed out'), backgroundColor: Colors.red),
            );
          }
        },
        error: (err, _) async {
          // Close loading dialog
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load brands: $err'), backgroundColor: Colors.red),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Update Dealer Info Method
  void _updateDealerInfo(
      UserModel dealer, {
        String? name,
        String? email,
        String? phone,
        String? address,
        String? district,
        String? town,
        String? shopName,
        List<String>? brand,
      }) async {
    try {
      final result = await ref.read(signupControllerProvider.notifier).updateUser(
        oldUser: dealer,
        name: name,
        email: email,
        phone: phone,
        address: address,
        district: district,
        town: town,
        shopName: shopName,
        brand: brand,
      );

      if (result == null) {
        ref.invalidate(dealerProvider(widget.dealerId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: screenWidth * 0.02),
                  Text('Dealer information updated successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(child: Text('Update failed: $result')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: screenWidth * 0.02),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildDiscountsSection(BuildContext context, AsyncValue<List<DealerDiscountModel>> dealerDiscountsAsync, double sw, double sh) {
    return dealerDiscountsAsync.when(
      data: (discounts) {
        return _buildModernSectionCard(
          context,
          'Dealer Discounts',
          Icons.local_offer_outlined,
          sw,
          [
            if (discounts.isEmpty)
              Container(
                padding: EdgeInsets.all(sw * 0.04),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.discount_outlined, size: sw * 0.1, color: Colors.grey[400]),
                    SizedBox(height: sw * 0.02),
                    Text('No discounts available',
                        style: TextStyle(
                          fontSize: sw * 0.035,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              )
            else
              ...discounts.map((discount) {
                return Container(
                  margin: EdgeInsets.only(bottom: sw * 0.02),
                  padding: EdgeInsets.all(sw * 0.035),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[50]!, Colors.green[50]!.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(sw * 0.03),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(sw * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(sw * 0.02),
                        ),
                        child: Icon(Icons.local_offer, color: Colors.green[700], size: sw * 0.05),
                      ),
                      SizedBox(width: sw * 0.03),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discount.brandName ?? 'Unknown Brand',
                              style: TextStyle(
                                fontSize: sw * 0.038,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: sw * 0.005),
                            Text(
                              discount.modelName ?? 'Unknown Model',
                              style: TextStyle(
                                fontSize: sw * 0.032,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(sw * 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          discount.isPercentage == true
                              ? '${discount.discountValue}%'
                              : '₹${discount.discountValue}',
                          style: TextStyle(
                            fontSize: sw * 0.036,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_isEditingDiscounts) ...[
                        SizedBox(width: sw * 0.02),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showUpdateDialog(context, discount),
                            borderRadius: BorderRadius.circular(sw * 0.02),
                            child: Container(
                              padding: EdgeInsets.all(sw * 0.02),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(sw * 0.02),
                              ),
                              child: SvgPicture.asset(
                                AppIcons.edit,
                                width: sw * 0.04,
                                colorFilter: ColorFilter.mode(
                                    Theme.of(context).primaryColor, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            if (discounts.isNotEmpty) ...[
              SizedBox(height: sw * 0.02),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isEditingDiscounts = !_isEditingDiscounts;
                      });
                    },
                    borderRadius: BorderRadius.circular(sw * 0.05),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.05, vertical: sw * 0.025),
                      decoration: BoxDecoration(
                        color: _isEditingDiscounts
                            ? Colors.grey[300]
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(sw * 0.05),
                        border: Border.all(
                          color: _isEditingDiscounts
                              ? Colors.grey[400]!
                              : Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isEditingDiscounts ? Icons.check : Icons.edit_outlined,
                            size: sw * 0.04,
                            color: _isEditingDiscounts
                                ? Colors.grey[700]
                                : Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: sw * 0.02),
                          Text(
                            _isEditingDiscounts ? 'Done' : 'Edit Discounts',
                            style: TextStyle(
                              color: _isEditingDiscounts
                                  ? Colors.grey[700]
                                  : Theme.of(context).primaryColor,
                              fontSize: sw * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => _buildModernSectionCard(
        context,
        'Dealer Discounts',
        Icons.local_offer_outlined,
        sw,
        [
          Container(
            padding: EdgeInsets.symmetric(vertical: sh * 0.03),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        ],
      ),
      error: (err, st) => _buildModernSectionCard(
        context,
        'Dealer Discounts',
        Icons.local_offer_outlined,
        sw,
        [
          Container(
            padding: EdgeInsets.all(sw * 0.04),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(sw * 0.03),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: sw * 0.05, color: Colors.red[700]),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Text('Error loading discounts',
                      style: TextStyle(fontSize: sw * 0.035, color: Colors.red[700])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, DealerDiscountModel discount) {
    bool isPercentage = discount.isPercentage ?? false;
    final valueController = TextEditingController(
        text: discount.discountValue.toString());
    final descController = TextEditingController(text: discount.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          child: Icon(Icons.edit_rounded,
                              color: Theme.of(context).primaryColor, size: screenWidth * 0.06),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          "Update Discount",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Discount Value",
                        prefixIcon: Icon(Icons.percent),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.description_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Is Percentage?",
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Switch(
                            value: isPercentage,
                            onChanged: (v) => setDialogState(() => isPercentage = v),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                          ),
                          child: Text("Cancel",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(width: screenWidth * 0.02),
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
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            ),
                            elevation: 0,
                          ),
                          child: Text("Update",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel? dealer, AsyncValue<List<BrandModel>> brandAsync, double sw) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        padding: EdgeInsets.only(left: screenWidth * 0.04),
        icon: Container(
          padding: EdgeInsets.all(sw * 0.02),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(sw * 0.02),
          ),
          child: SvgPicture.asset(
              AppIcons.back_Arrow,
              colorFilter: ColorFilter.mode(Colors.grey[800]!, BlendMode.srcIn),
              width: screenWidth * 0.05),

        ),
        onPressed: () => Navigator.pop(context, true),
      ),
      title: Text(
        'Dealer Details',
        style: TextStyle(
          color: Colors.grey[900],
          fontSize: sw * 0.048,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (dealer != null) ...[
          brandAsync.when(
            data: (brands) => IconButton(
              icon: Container(
                padding: EdgeInsets.all(sw * 0.02),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(sw * 0.02),
                ),
                child: SvgPicture.asset(
                  AppIcons.percentage,
                  width: sw * 0.05,
                  colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
                ),
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
                    ),
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.01),
            icon: Container(
              padding: EdgeInsets.all(sw * 0.02),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
              child: SvgPicture.asset(
                AppIcons.delete,
                width: screenWidth * 0.05,
                colorFilter: ColorFilter.mode(Colors.red[600]!, BlendMode.srcIn),
              ),
            ),
            onPressed: () => _showDeleteDialog(context, dealer.employeeId!),
          ),
          IconButton(
            padding: EdgeInsets.only(left: screenWidth * 0.01, right: screenWidth * 0.04),
            icon: Container(
              padding: EdgeInsets.all(sw * 0.02),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
              child: SvgPicture.asset(
                AppIcons.edit,
                width: screenWidth * 0.05,
                colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
              ),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => EditDealerScreen(dealer: dealer)),
              );
              if (result == true) {
                ref.invalidate(dealerProvider(widget.dealerId));
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel dealer, double sw, double sh) {
    return Container(
      margin: EdgeInsets.all(sw * 0.04),
      padding: EdgeInsets.all(sw * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(sw * 0.05),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: sw * 0.28,
                height: sw * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: dealer.photo != null && dealer.photo!.isNotEmpty
                      ? Image.network(
                    dealer.photo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white,
                      child: Icon(Icons.person,
                          size: sw * 0.12, color: Colors.grey[400]),
                    ),
                  )
                      : Container(
                    color: Colors.white,
                    child: Icon(Icons.person,
                        size: sw * 0.12, color: Colors.grey[400]),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(sw * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    color: Theme.of(context).primaryColor,
                    size: sw * 0.05,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.025),
          Text(
            dealer.employeeName ?? 'N/A',
            style: TextStyle(
              fontSize: sw * 0.065,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sh * 0.008),
          Container(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sh * 0.008),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(sw * 0.05),
            ),
            child: Text(
              formatRole(dealer.role ?? 'N/A'),
              style: TextStyle(
                fontSize: sw * 0.038,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
              ),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.025),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          child: Icon(Icons.warning_amber_rounded,
                              color: Colors.orange[700], size: screenWidth * 0.07),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            "Delete User",
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        "⚠️ This action cannot be undone. Please provide a reason for deletion.",
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.red[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: "Reason for deletion",
                        hintText: "Enter the reason here...",
                        prefixIcon: Icon(Icons.edit_note),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                    if (!isButtonEnabled)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.02),
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: screenWidth * 0.045, color: Colors.amber[900]),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                "Please wait $secondsRemaining seconds",
                                style: TextStyle(
                                    color: Colors.amber[900],
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            reasonController.dispose();
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                          ),
                          child: Text("Cancel",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        ElevatedButton.icon(
                          onPressed: isButtonEnabled && reasonController.text.trim().isNotEmpty
                              ? () async {
                            final reason = reasonController.text.trim();
                            final result = await ref
                                .read(signupControllerProvider.notifier)
                                .deleteUser(dealerId, reason);

                            if (result == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text("User deleted successfully"),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(screenWidth * 0.02),
                                    ),
                                  ),
                                );
                                reasonController.dispose();
                                Navigator.pop(ctx);
                                Navigator.pop(context, true);
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white),
                                        SizedBox(width: screenWidth * 0.02),
                                        Expanded(child: Text("Delete failed: $result")),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(screenWidth * 0.02),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                              : null,
                          icon: Icon(Icons.delete_outline, size: screenWidth * 0.045),
                          label: Text("Delete User",
                              style: TextStyle(
                                  fontSize: screenWidth * 0.038, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}