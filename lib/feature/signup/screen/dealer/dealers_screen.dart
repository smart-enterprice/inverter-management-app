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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../model/user_model.dart';
import '../../repository/signUp_repository.dart';


// StateNotifier to handle pagination
class DealerListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SignupRepository _repo;
  int _page = 1;
  final int _limit = 20;
  int _totalPages = 1; // update from API if backend gives it
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

      // If backend returns total pages, set it here
      // Example:
      // _totalPages = response.data['pages'];

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

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more when near the bottom
        ref.read(dealerListProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context,) {
    final dealersAsync = ref.watch(dealerListProvider);
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
            colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Dealers', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDealerScreen()));
            },
            icon: SvgPicture.asset(
              AppIcons.add,
              width: screenWidth * 0.07,
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: dealersAsync.when(
          loading: () => FutureBuilder(
            future: Future.delayed(const Duration(seconds: 2)),
            builder: (context, snapshot) {
              return const Center(child: CircularProgressIndicator());
            },),
          error: (e, st) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No Internet Connection",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(dealerListProvider); // retry
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          },
          data: (dealers) {
            return RefreshIndicator(
              backgroundColor: Colors.white,
              color: Theme.of(context).primaryColor,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 2));
                ref.invalidate(dealerListProvider);
              },
              child: ListView.builder(
                itemCount: dealers.length,
                itemBuilder: (context, index) {
                  final dealer = dealers[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DealerView(dealerId: dealer.employeeId.toString()),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.06),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(screenWidth * 0.04),
                        leading: CircleAvatar(
                          radius: screenWidth * 0.07,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: dealer.photo != null && dealer.photo!.isNotEmpty
                              ? CachedNetworkImageProvider(dealer.photo!)
                              : null,
                          child: (dealer.photo == null || dealer.photo!.isEmpty)
                              ? Icon(Icons.person, size: screenWidth * 0.07, color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          dealer.employeeName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: screenWidth * 0.01),
                            _buildInfoRow(Icons.location_on_outlined, dealer.town.toString(), context),
                            SizedBox(height: screenWidth * 0.01),
                            _buildInfoRow(Icons.phone, dealer.employeePhone, context),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.05, color: Theme.of(context).primaryColor),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }
}