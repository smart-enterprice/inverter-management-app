import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../../../core/const/icons.dart';
import '../../../model/brand_model.dart';
import '../../../model/user_model.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/brand_controller.dart';
import 'edit_brand_page.dart';
class BrandDetailsScreen extends ConsumerStatefulWidget {
  final BrandModel brand;

  const BrandDetailsScreen({super.key, required this.brand});

  @override
  ConsumerState<BrandDetailsScreen> createState() => _BrandDetailsScreenState();
}

class _BrandDetailsScreenState extends ConsumerState<BrandDetailsScreen> {
  late bool isActive;

  @override
  void initState() {
    super.initState();
    isActive = (widget.brand.status ?? '').toLowerCase() == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
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
          'Brand',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            onPressed: () {
              // Add edit page logic here if needed
            },
            icon: SvgPicture.asset(
              AppIcons.edit,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: ref
            .read(signupControllerProvider.notifier)
            .getEmployeeById(brand.createdBy.toString()),
        builder: (context, snapshot) {
          final createdByUser = snapshot.data;

          return Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Name
                Text(
                  brand.brandName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.015),

                /// Status
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenHeight * 0.004,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(screenWidth * 0.08),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),

                /// Status Update Button (only creator)
                if (createdByUser?.employeeId == brand.createdBy)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.red : Colors.green,
                    ),
                    onPressed: () async {
                      final newStatus = isActive ? 'inactive' : 'active';
                      final updatedBrand = brand.copyWith(status: newStatus);

                      await ref
                          .read(brandControllerProvider.notifier)
                          .updateBrand(updatedBrand, brand.brandName);

                      // Instant UI update
                      setState(() {
                        isActive = !isActive;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status updated to $newStatus')),
                      );
                    },
                    child: Text(
                      isActive ? 'Set Inactive' : 'Set Active',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.025),

                /// Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  brand.description.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: screenHeight * 0.025),

                /// Created By
                Text(
                  'Created By',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.005),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else if (createdByUser != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        createdByUser.employeeName ?? "N/A",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        createdByUser.role ?? "",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  )
                else
                  const Text('User not found'),

                SizedBox(height: screenHeight * 0.025),

                /// Models
                Text(
                  'Models',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: screenHeight * 0.01),
                Wrap(
                  spacing: screenWidth * 0.02,
                  runSpacing: screenHeight * 0.01,
                  children: brand.brandModels
                      .map((model) => Chip(
                    label: Text(model),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    backgroundColor: Theme.of(context).primaryColor,
                  ))
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
