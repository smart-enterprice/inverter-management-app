import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../feature/signup/controller/signUp_controller.dart';
import 'card.dart';


class InfoCard extends ConsumerWidget {
  const InfoCard({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final dealersAsync = ref.watch(dealerListProvider);
    final dealerCount = dealersAsync.asData?.value.length ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BoxCard(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppIcons.shop,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),),
                    SizedBox(height: screenHeight*0.01,),
                    Text(dealerCount.toString(),style: Theme.of(context).textTheme.bodyLarge,),
                    Text('Dealers',style: Theme.of(context).textTheme.bodyLarge)
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: BoxCard(
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(AppIcons.box,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn)),
                  SizedBox(height: screenHeight*0.01,),
                  Text('200',style: Theme.of(context).textTheme.bodyLarge,),
                  Text('Total Orders placed',style: Theme.of(context).textTheme.bodyLarge,)
                ],
              ),))
          ],
        ),
        SizedBox(height: screenHeight*0.01,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BoxCard(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppIcons.chart,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn)),
                    SizedBox(height: screenHeight*0.01,),
                    Text('50/200',style: Theme.of(context).textTheme.bodyLarge,),
                    Text('25%',style: Theme.of(context).textTheme.bodyLarge,),
                    Text('This Month\'s Goal ',style: Theme.of(context).textTheme.bodyLarge,),
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: BoxCard(
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(AppIcons.delivery,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn)),
                  SizedBox(height: screenHeight*0.01,),
                  Text('200',style: Theme.of(context).textTheme.bodyLarge,),
                  Text('Deliveries completed',style: Theme.of(context).textTheme.bodyLarge,)
                ],
              ),))
          ],
        ),
        SizedBox(height: screenHeight*0.01,),
        Row(
          children: [
            Expanded(
              child: BoxCard(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppIcons.alert,colorFilter: ColorFilter.mode(Colors.orange, BlendMode.srcIn)),
                    SizedBox(height: screenHeight*0.01,),
                    Text('2',style: Theme.of(context).textTheme.bodyLarge,),
                    Text('Low Stock',style: Theme.of(context).textTheme.bodyLarge,)
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: SizedBox())
          ],
        ),
      ],
    );
  }
}
