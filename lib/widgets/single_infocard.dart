import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../core/media_query/media_query.dart';
import 'card.dart';

class SingleInfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  const SingleInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor = Colors.black,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return BoxCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Screen.w(context) * 0.025),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                        Radius.circular(Screen.w(context) * 0.03)),
                    color: iconBackground),
                child: SvgPicture.asset(
                  icon,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
              SizedBox(width: Screen.h(context) * 0.01),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
