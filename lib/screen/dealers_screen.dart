import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import '../core/const/icons.dart';
import 'dealer_view_screen.dart';
import 'dealers_sign_up_screen.dart';
import 'edit_dealer_screen.dart';

class DealersScreen extends StatelessWidget {
  const DealersScreen({super.key});

  void _showDeleteDialog(BuildContext context, String dealerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Delete Dealer', style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete "$dealerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('Deleted $dealerName');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: AppTheme.backgroundColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dealers = [
      {
        'name': 'Ava Ingram',
        'shop': 'Top Gear Auto',
        'phone': '555-841-4679',
        'id': '44556',
        'image': 'https://i.pravatar.cc/300?img=1',
        'brands': ['Brand A', 'Brand B'],
        'totalOrders': 24,
        'district': 'Malappuram',
        'town': 'Manjeri',
        'address': 'Near City Mall, Manjeri, Malappuram',
      },
      {
        'name': 'Ethan Foster',
        'shop': 'Precision Auto',
        'phone': '555-482-3457',
        'id': '97531',
        'image': 'https://i.pravatar.cc/300?img=2',
        'brands': ['Brand C', 'Brand D'],
        'totalOrders': 15,
        'district': 'Kozhikode',
        'town': 'Feroke',
        'address': 'Main Road, Feroke, Kozhikode',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          padding: EdgeInsets.only(left:screenWidth * 0.04),
          icon: SvgPicture.asset(AppIcons.back_Arrow,width: screenWidth*0.07,),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Dealers', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right:screenWidth * 0.04),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDealerScreen()));
            },
            icon: SvgPicture.asset(AppIcons.add,width: screenWidth*0.07,),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or town',
                hintStyle: AppTheme.labelText1,
                prefixIcon: Icon(Icons.search_outlined, color: Colors.grey),
                filled: true,
                fillColor: Color(0xFFF2F2F2),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: screenWidth * 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dealers.length,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              itemBuilder: (context, index) {
                final dealer = dealers[index];
                return GestureDetector(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DealerView(dealer: dealer),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth* 0.02),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.09,
                          backgroundImage: NetworkImage(dealer['image']!),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dealer: ${dealer['name']}', style: AppTheme.normalText1),
                              SizedBox(height: screenHeight* 0.005),
                              Text('Shop: ${dealer['shop']}', style: AppTheme.labelText1),
                              SizedBox(height: screenHeight* 0.003),
                              Text('Phone: ${dealer['phone']}', style: AppTheme.labelText1),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('ID: ${dealer['id']}', style:AppTheme.normalText1),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}