import 'package:flutter/material.dart';

class MyFavorities extends StatefulWidget {
  const MyFavorities({super.key});

  @override
  State<StatefulWidget> createState() => _MyFavoritiesState();
}

class _MyFavoritiesState extends State<MyFavorities> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Mis Favoritos",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
