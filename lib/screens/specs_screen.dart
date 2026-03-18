import 'package:flutter/material.dart';
import 'package:car_care/models/car_model.dart';

class SpecsScreen extends StatelessWidget {
  const SpecsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем выбранную машину из аргументов навигатора
    final Car car = ModalRoute.of(context)!.settings.arguments as Car;

    return Scaffold(
      appBar: AppBar(title: Text('Характеристики ${car.name}')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: car.specs.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text(car.specs[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}