import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/health/data/health_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final sample = {
    'code': '3017620422003',
    'product_name': 'Ореховая паста',
    'nutriments': {
      'energy-kcal_100g': 539,
      'proteins_100g': 6.3,
      'fat_100g': 30.9,
      'carbohydrates_100g': 57.5,
    },
  };

  test('поиск передаёт запрос и возвращает КБЖУ на 100 г', () async {
    final repository = HealthRepository(httpClient: MockClient((request) async {
      expect(request.url.path, '/cgi/search.pl');
      expect(request.url.queryParameters['search_terms'], 'паста');
      expect(request.headers['User-Agent'], contains('HealthApp/1.0'));
      return http.Response(
          jsonEncode({
            'products': [sample]
          }),
          200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final products = await repository.searchProductsOnline('паста');
    expect(products, hasLength(1));
    expect(products.single.id, 0);
    expect(products.single.kcal, 539);
    expect(products.single.protein, 6.3);
  });

  test('штрихкод ищет товар и корректно обрабатывает отсутствие', () async {
    final found = HealthRepository(httpClient: MockClient((request) async {
      expect(request.url.path, '/api/v2/product/3017620422003.json');
      return http.Response(jsonEncode({'status': 1, 'product': sample}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    expect((await found.findProductByBarcodeOnline('3017620422003'))?.name,
        'Ореховая паста');
    final missing = HealthRepository(
        httpClient: MockClient(
            (request) async => http.Response(jsonEncode({'status': 0}), 200)));
    expect(await missing.findProductByBarcodeOnline('3017620422003'), isNull);
  });

  test('ошибка сети сообщает о недоступности подключения', () async {
    final repository = HealthRepository(httpClient: MockClient((request) async {
      throw const SocketException('offline');
    }));
    expect(
        () => repository.searchProductsOnline('молоко'),
        throwsA(isA<ProductLookupException>().having(
            (error) => error.message, 'сообщение', contains('интернету'))));
  });

  test('пустой ответ поиска возвращает пустой список', () async {
    final repository = HealthRepository(
        httpClient: MockClient((request) async =>
            http.Response(jsonEncode({'products': []}), 200)));
    expect(await repository.searchProductsOnline('неизвестный'), isEmpty);
  });
}

