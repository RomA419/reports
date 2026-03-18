import 'package:flutter/material.dart';

// ИСПРАВЛЕННЫЕ ИМПОРТЫ:
import 'package:car_care/configs/car_config.dart';
import 'package:car_care/services/post_service.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CarConfig.primaryDark,
      appBar: AppBar(backgroundColor: CarConfig.primaryDark, title: const Text('AUTO SHOP', style: TextStyle(color: Colors.white))),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final p = snapshot.data![i];
              return Container(
                decoration: CarConfig.premiumCard,
                child: Column(children: [
                  Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), child: Image.network(p.image, fit: BoxFit.cover))),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Text(p.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(p.category, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 8),
                      Text(p.price, style: TextStyle(color: CarConfig.accentNeon, fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                  )
                ]),
              );
            },
          );
        },
      ),
    );
  }
}