// ─────────────────────────────────────────────────────────────────────────────
// lib/core/role/app_role.dart
//
// Drop-in role-based access system.
// Usage:
//   1. Add role_provider.dart to your Riverpod ProviderScope.
//   2. Wrap any widget with RoleGuard to show/hide by role.
//   3. Use AppPermissions.canAccess(role, feature) for logic gates.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';





// ─── 1. Role enum ─────────────────────────────────────────────────────────────
enum AppRole {
  superAdmin,
  admin,
  manager,
  salesman,
  production,
  packing,
  accounts,
  delivery,
  dealer,
  unknown;

  /// Convert the stored SharedPreferences string → AppRole
  static AppRole fromString(String? role) {
    switch (role) {
      case 'ROLE_SUPER_ADMIN':     return AppRole.superAdmin;
      case 'ROLE_ADMIN':           return AppRole.admin;
      case 'ROLE_MANAGER':         return AppRole.manager;
      case 'ROLE_SALESMAN':        return AppRole.salesman;
      case 'ROLE_PRODUCTION':      return AppRole.production;
      case 'ROLE_PACKING':         return AppRole.packing;
      case 'ROLE_ACCOUNTS':        return AppRole.accounts;
      case 'ROLE_DELIVERY':        return AppRole.delivery;
      case 'ROLE_DEALER':          return AppRole.dealer;
      default:                     return AppRole.unknown;
    }
  }


  String get displayName {
    switch (this) {
      case AppRole.superAdmin:  return 'Super Admin';
      case AppRole.admin:       return 'Admin';
      case AppRole.manager:     return 'Manager';
      case AppRole.salesman:    return 'Salesman';
      case AppRole.production:  return 'Production';
      case AppRole.packing:     return 'Packing';
      case AppRole.accounts:    return 'Accounts';
      case AppRole.delivery:    return 'Delivery';
      case AppRole.dealer:      return 'Dealer';
      default:                  return 'Unknown';
    }
  }
}

// ─── 2. Feature keys ──────────────────────────────────────────────────────────
// Add a new string here whenever you add a new gated feature.
class AppFeature {
  AppFeature._();

  // Orders
  static const String viewAllOrders     = 'view_all_orders';
  static const String createOrder       = 'create_order';
  static const String updateOrderStatus = 'update_order_status';
  static const String cancelOrder       = 'cancel_order';
  static const String updatePayment     = 'update_payment';

  // Products & Brands
  static const String viewProducts      = 'view_products';
  static const String createProduct     = 'create_product';
  static const String updateProduct     = 'update_product';
  static const String createBrand       = 'create_brand';
  static const String viewBrands        = 'view_brands';
  static const String updateBrand = 'update_brand';
  static const String updatePrice   = 'update_price';
  static const String viewPrice     = 'view_price';
  static const String viewStock = 'view_stock';
  static const String viewPriceHistory     = 'view_price_history';
  static const String updateStock        = 'update_stock';
  static const String viewTimestamps          = 'view_timestamps';
  static const String updateStatus = 'update_status';
  static const String updateUnpackedStock = 'update_unpacked_stock';
  static const String updatePackedStock = 'update_packed_stock';

  // People
  static const String viewCreator     = 'view_creator';
  static const String viewDealers       = 'view_dealers';
  static const String viewDealerBasic   = 'view_dealer_basic';
  static const String createDealer      = 'create_dealer';
  static const String editDealer        = 'edit_dealer';
  static const String deleteDealer      = 'delete_dealer';
  static const String viewEmployees     = 'view_employees';
  static const String createEmployee    = 'create_employee';
  static const String deleteEmployee    = 'delete_employee';
  static const String discountCreate = 'discount_create';
  static const String discountView = 'discount_view';
  static const String paymentView = 'payment_view';
  static const String infoView = 'info_view';
  static const String handleUser = 'handle_user';

  // Discounts
  static const String manageDiscounts   = 'manage_discounts';

  // Dashboard
  static const String viewDashboard     = 'view_dashboard';
  static const String viewReports       = 'view_reports';

  // Create section
  static const String accessCreatePanel = 'access_create_panel';
  static const String accessControlPanel= 'access_control_panel';

  // order status update
  static const orderConfirmed = 'CONFIRMED';
  static const productionCompleted = 'PRODUCTION';
  static const packedCompleted = 'PACKED';
  static const invoiceCompleted = 'INVOICE';
  static const shippedCompleted = 'SHIPPED';
  static const deliveredCompleted = 'DELIVERED';
  static const orderCompleted = 'COMPLETED';
  static const orderCancelled = 'CANCELLED';
  static const orderRejected = 'REJECTED';
}

// ─── 3. Permissions map ───────────────────────────────────────────────────────
class AppPermissions {
  AppPermissions._();

  /// Returns true if [role] is allowed to use [feature].
  static bool canAccess(AppRole role, String feature) {
    final allowed = _permissions[role] ?? {};
    return allowed.contains(feature);
  }

  /// Returns true if role has ALL of the given features.
  static bool canAccessAll(AppRole role, List<String> features) =>
      features.every((f) => canAccess(role, f));

  /// Returns true if role has ANY of the given features.
  static bool canAccessAny(AppRole role, List<String> features) =>
      features.any((f) => canAccess(role, f));

  static const Map<AppRole, Set<String>> _permissions = {

    // ── Super Admin — everything ───────────────────────────────────────────
    AppRole.superAdmin: {
      AppFeature.viewCreator,
      AppFeature.viewAllOrders,
      AppFeature.createOrder,
      AppFeature.updateOrderStatus,
      AppFeature.cancelOrder,
      AppFeature.updatePayment,
      AppFeature.viewPrice,
      AppFeature.updateStatus,
      AppFeature.viewPriceHistory,
      AppFeature.viewStock,
      AppFeature.updateStock,
      AppFeature.viewProducts,
      AppFeature.updateProduct,
      AppFeature.createProduct,
      AppFeature.updatePrice,
      AppFeature.viewTimestamps,
      AppFeature.createBrand,
      AppFeature.viewBrands,
      AppFeature.updateBrand,
      AppFeature.viewDealers,
      AppFeature.viewDealerBasic,
      AppFeature.createDealer,
      AppFeature.editDealer,
      AppFeature.deleteDealer,
      AppFeature.viewEmployees,
      AppFeature.createEmployee,
      AppFeature.deleteEmployee,
      AppFeature.manageDiscounts,
      AppFeature.viewDashboard,
      AppFeature.viewReports,
      AppFeature.accessCreatePanel,
      AppFeature.accessControlPanel,
      AppFeature.discountCreate,
      AppFeature.discountView,
      AppFeature.paymentView,
      AppFeature.infoView,
      AppFeature.handleUser,
      AppFeature.updateUnpackedStock,
      AppFeature.updatePackedStock,
      // order status updates
      AppFeature.orderConfirmed,
      AppFeature.productionCompleted,
      AppFeature.packedCompleted,
      AppFeature.invoiceCompleted,
      AppFeature.shippedCompleted,
      AppFeature.deliveredCompleted,
      AppFeature.orderCompleted,
      AppFeature.orderCancelled,
      AppFeature.orderRejected,
    },

    // ── Admin — same full access as Super Admin ────────────────────────────
    AppRole.admin: {
      AppFeature.viewCreator,
      AppFeature.viewAllOrders,
      AppFeature.createOrder,
      AppFeature.updateOrderStatus,
      AppFeature.cancelOrder,
      AppFeature.updatePayment,
      AppFeature.viewProducts,
      AppFeature.viewPrice,
      AppFeature.viewPriceHistory,
      AppFeature.updateStatus,
      AppFeature.updateProduct,
      AppFeature.createProduct,
      AppFeature.viewStock,
      AppFeature.updateStock,
      AppFeature.updatePrice,
      AppFeature.viewTimestamps,
      AppFeature.createBrand,
      AppFeature.updateBrand,
      AppFeature.viewBrands,
      AppFeature.viewDealers,
      AppFeature.viewDealerBasic,
      AppFeature.createDealer,
      AppFeature.editDealer,
      AppFeature.deleteDealer,
      AppFeature.viewEmployees,
      AppFeature.createEmployee,
      AppFeature.deleteEmployee,
      AppFeature.manageDiscounts,
      AppFeature.viewDashboard,
      AppFeature.viewReports,
      AppFeature.accessCreatePanel,
      AppFeature.accessControlPanel,
      AppFeature.discountCreate,
      AppFeature.discountView,
      AppFeature.paymentView,
      AppFeature.infoView,
      AppFeature.handleUser,
      AppFeature.updateUnpackedStock,
      AppFeature.updatePackedStock,
      // order status updates
      AppFeature.orderConfirmed,
      AppFeature.productionCompleted,
      AppFeature.packedCompleted,
      AppFeature.invoiceCompleted,
      AppFeature.shippedCompleted,
      AppFeature.deliveredCompleted,
      AppFeature.orderCompleted,
      AppFeature.orderCancelled,
      AppFeature.orderRejected,
    },

    // ── Manager ────────────────────────────────────────────────────────────
    AppRole.manager: {
      AppFeature.viewCreator,
      AppFeature.viewAllOrders,
      AppFeature.createOrder,
      AppFeature.updateOrderStatus,
      AppFeature.cancelOrder,
      AppFeature.updatePayment,
      AppFeature.viewProducts,
      AppFeature.viewPrice,
      AppFeature.viewPriceHistory,
      // AppFeature.updateStatus,
      AppFeature.viewStock,
      AppFeature.updateStock,
      // AppFeature.updateProduct,
      // AppFeature.createProduct,
      // AppFeature.updatePrice,
      AppFeature.viewTimestamps,
      AppFeature.viewBrands,
      // AppFeature.updateBrand,
      AppFeature.viewDealers,
      AppFeature.viewDealerBasic,
      // AppFeature.createDealer,
      // AppFeature.editDealer,
      // AppFeature.deleteDealer,
      AppFeature.viewEmployees,
      // AppFeature.createEmployee,
      AppFeature.deleteEmployee,
      AppFeature.manageDiscounts,
      AppFeature.viewDashboard,
      AppFeature.viewReports,
      AppFeature.accessCreatePanel,
      AppFeature.accessControlPanel,
      // AppFeature.discountCreate,
      AppFeature.discountView,
      AppFeature.paymentView,
      AppFeature.infoView,
      // AppFeature.handleUser,
      AppFeature.updateUnpackedStock,
      AppFeature.updatePackedStock,
      // order status updates
      AppFeature.orderConfirmed,
      AppFeature.productionCompleted,
      AppFeature.packedCompleted,
      AppFeature.invoiceCompleted,
      AppFeature.shippedCompleted,
      AppFeature.deliveredCompleted,
      AppFeature.orderCompleted,
      AppFeature.orderCancelled,
      AppFeature.orderRejected,
    },

    // ── Salesman — view only, no dealer create/edit ────────────────────────
    AppRole.salesman: {
      AppFeature.viewCreator,
      AppFeature.viewAllOrders,
      AppFeature.createOrder,
      AppFeature.viewProducts,
      AppFeature.viewPrice,
      AppFeature.viewStock,
      AppFeature.viewBrands,        // view only — no createBrand
      AppFeature.viewDealers,       // view only — no createDealer, no editDealer
      AppFeature.viewDealerBasic,
      AppFeature.manageDiscounts,
      AppFeature.accessCreatePanel,
      AppFeature.discountView,
      AppFeature.paymentView,
      AppFeature.infoView,

    },

    // ── Production ─────────────────────────────────────────────────────────
    AppRole.production: {
      AppFeature.viewAllOrders,
      AppFeature.updateOrderStatus,
      AppFeature.viewStock,
      AppFeature.updateStock,
      AppFeature.viewTimestamps,
      AppFeature.viewProducts,
      AppFeature.viewDealerBasic,
      AppFeature.updateUnpackedStock,
      // order status updates
      AppFeature.productionCompleted,
      // AppFeature.packedCompleted,

    },

    // ── Packing ────────────────────────────────────────────────────────────
    AppRole.packing: {
      AppFeature.viewAllOrders,
      AppFeature.viewTimestamps,
      AppFeature.viewStock,
      AppFeature.updateStock,
      AppFeature.updateOrderStatus,
      AppFeature.viewDealerBasic,
      AppFeature.updatePackedStock,
      // order status updates
      // AppFeature.productionCompleted,
      AppFeature.packedCompleted,
      AppFeature.shippedCompleted,

    },

    // ── Accounts — payment + order status update ───────────────────────────
    AppRole.accounts: {
      AppFeature.viewCreator,
      AppFeature.viewAllOrders,
      AppFeature.updateOrderStatus,
      AppFeature.updatePayment,
      AppFeature.viewPrice,
      AppFeature.viewPriceHistory,
      AppFeature.viewStock,
      AppFeature.viewTimestamps,
      AppFeature.viewReports,
      AppFeature.viewDashboard,
      AppFeature.discountView,
      AppFeature.paymentView,
      // order status updates
      AppFeature.invoiceCompleted,
      AppFeature.shippedCompleted,

    },

    // ── Delivery ───────────────────────────────────────────────────────────
    AppRole.delivery: {
      AppFeature.viewAllOrders,
      AppFeature.updateOrderStatus,
      // order status updates
      AppFeature.deliveredCompleted,

    },

    // ── Dealer — no access in app currently ───────────────────────────────
    AppRole.dealer: {},

    // ── Unknown — no access ────────────────────────────────────────────────
    AppRole.unknown: {},
  };
}

// ─── 4. Riverpod provider ─────────────────────────────────────────────────────
/// Reads the saved role from SharedPreferences and exposes it as AppRole.
/// Add this to your ProviderScope — it auto-reads on first access.
final appRoleProvider = FutureProvider<AppRole>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final roleString = prefs.getString('user_role');
  return AppRole.fromString(roleString);
});

/// Synchronous notifier — call [setRole] after login, [clearRole] after logout.
/// Use this for instant UI updates without waiting for SharedPreferences reads.
class RoleNotifier extends StateNotifier<AppRole> {
  RoleNotifier() : super(AppRole.unknown);

  void setRole(String? roleString) {
    state = AppRole.fromString(roleString);
  }

  void clearRole() {
    state = AppRole.unknown;
  }

  bool canAccess(String feature) =>
      AppPermissions.canAccess(state, feature);
}

final roleNotifierProvider =
StateNotifierProvider<RoleNotifier, AppRole>((ref) => RoleNotifier());

// ─── 5. RoleGuard widget ──────────────────────────────────────────────────────
/// Wrap any widget to conditionally show it based on role + feature.
///
/// Example:
/// ```dart
/// RoleGuard(
///   feature: AppFeature.deleteDealer,
///   child: IconButton(icon: Icon(Icons.delete), onPressed: _delete),
/// )
/// ```
///
/// With custom fallback:
/// ```dart
/// RoleGuard(
///   feature: AppFeature.createBrand,
///   fallback: Text('No permission'),
///   child: BrandCreateButton(),
/// )
/// ```
class RoleGuard extends ConsumerWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleNotifierProvider);
    final allowed = AppPermissions.canAccess(role, feature);
    if (allowed) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Multi-feature variant — shows child only if role has ALL listed features.
class RoleGuardAll extends ConsumerWidget {
  final List<String> features;
  final Widget child;
  final Widget? fallback;

  const RoleGuardAll({
    super.key,
    required this.features,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleNotifierProvider);
    final allowed = AppPermissions.canAccessAll(role, features);
    if (allowed) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

// ─── 6. AccessDeniedScreen ────────────────────────────────────────────────────
/// Full-screen gate — use as a route replacement when a whole screen is locked.
///
/// Example in splash/router:
/// ```dart
/// case 'ROLE_DEALER':
///   Navigator.pushReplacement(context,
///     MaterialPageRoute(builder: (_) => DealerHomeScreen()));
///   break;
/// ```
class AccessDeniedScreen extends StatelessWidget {
  final String? message;
  const AccessDeniedScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 20),
            const Text('Access Denied',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1C3F))),
            const SizedBox(height: 8),
            Text(
              message ?? 'You don\'t have permission to view this page.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Text('Go back',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4FD8))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}