import 'dart:convert';
import 'package:http/http.dart' as http;

class Product {
  final String title;
  final String price;
  final String image;
  final String category;

  Product({required this.title, required this.price, required this.image, required this.category});

  factory Product.fromJson(int index, double apiPrice) {
    // Список реальных товаров с прямыми ссылками на фото
    List<Map<String, String>> carProducts = [
      {
        "t": "Масло Motul 8100 5W-40",
        "c": "Смазочные материалы",
        "i": "https://cdn.motul.com/media/8100_X-cess_5W-40.png"
      },
      {
        "t": "Шины Michelin Pilot Sport 5",
        "c": "Шины",
        "i": "https://static.michelin.ru/master/image/Pilot-Sport-5-Tire.png"
      },
      {
        "t": "Видеорегистратор Xiaomi 70mai",
        "c": "Электроника",
        "i": "https://70mai.com/wp-content/uploads/2020/06/A800S-1.png"
      },
      {
        "t": "Тормозные колодки Brembo",
        "c": "Тормозная система",
        "i": "https://www.bremboparts.com/getmedia/pad-image.png"
      },
      {
        "t": "Набор инструментов SATA 120",
        "c": "Инструменты",
        "i": "https://satatools.com/images/products/09014.png"
      },
      {
        "t": "Ароматизатор Eikosha Air Spencer",
        "c": "Аксессуары",
        "i": "https://airspencer.com/en/img/product/as_can.png"
      },
    ];

    var item = carProducts[index % carProducts.length];
return Product(
  title: item["t"]!,
  category: item["c"]!,
  price: "${(apiPrice * 455).toInt()} ₸", 
  image: item["i"]!,
);
  }
}

Future<List<Product>> fetchProducts() async {
  final res = await http.get(Uri.parse('https://fakestoreapi.com/products?limit=6'));
  if (res.statusCode == 200) {
    List data = jsonDecode(res.body);
    return data.asMap().entries.map((e) => Product.fromJson(e.key, e.value['price'].toDouble())).toList();
  }
  return [];
}