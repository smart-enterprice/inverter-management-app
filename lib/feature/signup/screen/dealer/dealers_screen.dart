import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/signup/controller/signUp_controller.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealer_view_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealers_sign_up_screen.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../repository/signUp_repository.dart';

// StateNotifier to handle pagination
class DealerListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SignupRepository _repo;
  int _page = 1;
  final int _limit = 20;
  final int _totalPages = 1;
  bool _isLoadingMore = false;

  DealerListNotifier(this._repo) : super(const AsyncLoading()) {
    loadDealers(reset: true);
  }

  Future<void> loadDealers({bool reset = false}) async {
    if (reset) {
      _page = 1;
      state = const AsyncLoading();
    }

    try {
      final newData = await _repo.getDealers(page: _page, limit: _limit);

      if (reset) {
        state = AsyncData(newData);
      } else {
        final current = state.value ?? [];
        state = AsyncData([...current, ...newData]);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (_page >= _totalPages) return;

    _isLoadingMore = true;
    _page++;
    await loadDealers();
    _isLoadingMore = false;
  }
}

class DealersScreen extends ConsumerStatefulWidget {
  const DealersScreen({super.key});

  @override
  ConsumerState<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends ConsumerState<DealersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(dealerListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  List<UserModel> _filterDealers(List<UserModel> dealers) {
    if (_searchQuery.isEmpty) {
      return dealers;
    }

    final query = _searchQuery.toLowerCase();
    return dealers.where((dealer) {
      final name = dealer.employeeName.toLowerCase();
      final phone = dealer.employeePhone.toLowerCase();
      final town = (dealer.town ?? '').toLowerCase();

      return name.contains(query) ||
          phone.contains(query) ||
          town.contains(query);
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    final dealersAsync = ref.watch(dealerListProvider);
    return dealersAsync.when(
      loading: () => GlobalLoader(),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      'Dealers',
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
                          ref.invalidate(dealerListProvider);
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
      ),
      data: (dealers) {
        final filteredDealers = _filterDealers(dealers);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: Screen.w(context) * 0.02,
                    bottom: Screen.w(context) * 0.03,
                  left: Screen.w(context) * 0.04,
                    right: Screen.w(context) * 0.04,
                  ),
                  child: Row(
                    children: [
                      /// BACK BUTTON
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_sharp,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      /// LEFT SPACER (for center title)
                      const Spacer(),
                      /// TITLE
                      Text(
                        'Dealers',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      /// RIGHT SPACER (balances back button)
                      const Spacer(),
                      /// SEARCH
                      CircularIconButton(
                        icon: Icons.search_rounded,
                        onTap:_toggleSearch
                      ),
                      SizedBox(width: Screen.w(context) * 0.03),
                      /// ADD
                      CircularIconButton(
              icon: Icons.add,
              onTap:(){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDealerScreen()),
                );
              }
                      ),
                    ],
                  ),
                ),
                // Search Bar - Only show when _isSearching is true
                if (_isSearching)
                  Padding(
                    padding: EdgeInsets.all(Screen.w(context) * 0.04),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone, or location',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).primaryColor,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Results count
                if (_isSearching && _searchQuery.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredDealers.length} result${filteredDealers.length != 1 ? 's' : ''} found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                // Dealers List
                Expanded(
                  child: filteredDealers.isEmpty && _isSearching
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: Screen.h(context) * 0.02),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Start typing to search'
                              : 'No results found for "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      : dealers.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: Screen.h(context) * 0.02),
                        Text(
                          'No dealers available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                      : Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Screen.w(context) * 0.04),
                    child: RefreshIndicator(
                      backgroundColor: Colors.white,
                      color: Theme.of(context).primaryColor,
                      onRefresh: () async {
                        await Future.delayed(
                            const Duration(seconds: 2));
                        ref.invalidate(dealerListProvider);
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        itemCount: filteredDealers.length,
                        itemBuilder: (context, index) {
                          final dealer = filteredDealers[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DealerView(
                                      dealerId: dealer.employeeId
                                          .toString()),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(vertical: Screen.w(context) * 0.012),
                              color: Colors.white,
                              elevation: 2,
                              shadowColor: Colors.black.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Screen.w(context) * 0.05),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Screen.w(context) * 0.05),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(Screen.w(context) * 0.045),
                                  leading: Container(
                                    width: Screen.w(context) * 0.14,
                                    height: Screen.w(context) * 0.14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: dealer.photo != null && dealer.photo!.isNotEmpty
                                          ? CachedNetworkImage(
                                        imageUrl: dealer.photo!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[100],
                                          child: Icon(
                                            Icons.person,
                                            size: Screen.w(context) * 0.06,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey[100],
                                          child: Icon(
                                            Icons.person,
                                            size: Screen.w(context) * 0.06,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      )
                                          : Container(
                                        color: Colors.grey[100],
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: Screen.w(context) * 0.06,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    dealer.employeeName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: EdgeInsets.only(top: Screen.w(context) * 0.008),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoRow(
                                          Icons.location_on_outlined,
                                          dealer.town.toString(),
                                          context,
                                        ),
                                        SizedBox(height: Screen.w(context) * 0.008),
                                        _buildInfoRow(
                                          Icons.phone_rounded,
                                          dealer.employeePhone,
                                          context,
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Container(
                                    width: Screen.w(context) * 0.08,
                                    height: Screen.w(context) * 0.08,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: Screen.w(context) * 0.05,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: Screen.w(context) * 0.05,
            color: Theme.of(context).primaryColor),
        SizedBox(width: Screen.w(context) * 0.02),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }
}