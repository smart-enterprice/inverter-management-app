import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
class AddButton extends StatelessWidget {
  const AddButton({super.key,required this.onTap,required this.text,this.icon});
 final void Function()? onTap;
 final String text;
 final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration:BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(screenWidth*0.03),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Center(
            child: Row(
              children: [
                Icon(icon,color: Colors.white,),
                Text(text,style: AppTheme.normalText2,),
              ],
            )
          ),
        ));
  }
}
