import 'package:cotorra_app/widgets/common/placeholder_widget.dart';
import 'package:flutter/material.dart';

class MyFavorities extends StatelessWidget {
  const MyFavorities({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderWidget(
      title: "Mis Favoritos",
      icon: Icons.favorite_border,
    );
  }
}
