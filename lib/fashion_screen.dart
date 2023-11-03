import 'package:flutter/material.dart';
import 'package:universal_recommendation_system/util/colors.dart';

class FashionScreen extends StatelessWidget {
  const FashionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController searchControllerfashion = TextEditingController();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            width: 500,
            child: TextField(
              controller: searchControllerfashion,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.search,
                    color: AppColors.bgColors,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
