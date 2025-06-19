import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

import 'edit_dealer_screen.dart';

class DealerView extends StatelessWidget {
  final Map<String, dynamic> dealer;
  const DealerView({super.key, required this.dealer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          dealer['name'],
          style: AppTheme.appTitle1,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white60,
              shape: const CircleBorder(),
              padding:  EdgeInsets.all(screenWidth*0.02),
            ),
            child:  SvgPicture.asset(AppIcons.edit,colorFilter:ColorFilter.mode(Colors.blue,BlendMode.srcIn),),
            onPressed: () {
              // Handle edit action
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDealerScreen(dealerData: dealer,),
                ),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white60,
              shape: const CircleBorder(),
              padding:  EdgeInsets.all(screenWidth*0.02),
            ),
            onPressed: () {},
            child: SvgPicture.asset(AppIcons.delete,colorFilter:ColorFilter.mode(Colors.red,BlendMode.srcIn),)
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dealer Information',
                style: AppTheme.normalText5,
              ),
            ),
            Padding(
              padding:  EdgeInsets.all(screenWidth*0.02),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth*0.03),
                  child: Image.network(
                    dealer['image'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            _infoRow('Dealer Name', dealer['name']),
            _infoRow('Shop Name', dealer['shop']),
            _infoRow('Address', dealer['address']),
            _infoRow('Town', dealer['town']),
            _infoRow('District', dealer['district']),
            _infoRow('Dealer ID', dealer['id']),
            _infoRow('Total Orders', dealer['totalOrders'].toString()),
            _infoRow('Phone Number', dealer['phone']),
            _infoRow('Brands', (dealer['brands'] as List).join(', ')),
             SizedBox(height: screenHeight* 0.02),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.02),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: const StadiumBorder(),
                ),
                onPressed: () {},
                child:  Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth*0.08, vertical: screenHeight*0.015),
                  child: Text('Call Dealer',style: AppTheme.normalText2,),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.03, vertical:screenHeight* 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style:  AppTheme.appTitle1)),
           // SizedBox(width: screenWidth*0.02),
          Text(value, style: AppTheme.normalText1),
        ],
      ),
    );
  }
}
