import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/user_model.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/product_controller.dart';

class ProductView extends ConsumerStatefulWidget {
  const ProductView({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends ConsumerState<ProductView> {
  late bool isActive;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.id));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const Scaffold(
            body: Center(child: Text("Product not found")),
          );
        }

        isActive = (product.status ?? '').toLowerCase() == 'active';

        return Scaffold(
          appBar: _buildAppBar(context),
          body: FutureBuilder<UserModel?>(
            future: ref
                .read(signupControllerProvider.notifier)
                .getEmployeeById(product.createdBy ?? ""),
            builder: (context, snapshot) {
              final createdByUser = snapshot.data;
              return Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Product Name
                      Text(
                        product.productName ?? "N/A",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      /// Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.004,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius:
                          BorderRadius.circular(screenWidth * 0.08),
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

                      /// Stock Info
                      Text(
                        "Packed Stock: ${product.packedStock}",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        "Unpacked Stock: ${product.unpackedStock}",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        "Total Stock: ${product.availableStock ?? 0}",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      /// Price
                      Text(
                        "Price: ₹${product.price ?? 0}",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      /// Brand
                      Text(
                        "Brand: ${product.brand ?? "N/A"}",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      /// Created By
                      Text(
                        'Created By',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      if (snapshot.connectionState ==
                          ConnectionState.waiting)
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
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text("Error: $err")),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
        'Product',
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }
}
