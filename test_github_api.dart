import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final owner = 'AymanTegany';
  final repo = 'sparta_gym';

  try {
    print('Fetching latest release...');
    final response = await dio.get(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );

    if (response.statusCode == 200) {
      print('Success!');
      print('Tag Name: ${response.data['tag_name']}');

      final assets = response.data['assets'] as List;
      print('Found ${assets.length} assets.');

      for (var asset in assets) {
        print('Asset Name: ${asset['name']}');
        print('Asset URL: ${asset['browser_download_url']}');
      }
    }
  } catch (e) {
    if (e is DioException) {
      print('DioError: ${e.message}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
