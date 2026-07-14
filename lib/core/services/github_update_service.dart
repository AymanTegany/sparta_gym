import 'package:dio/dio.dart';

class GithubUpdateService {
  final String owner;
  final String repo;
  final Dio _dio = Dio();

  GithubUpdateService({required this.owner, required this.repo});

  Future<String> getLatestVersion() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );
      if (response.statusCode == 200) {
        String tagName = response.data['tag_name'] as String;
        // إزالة حرف v إذا كان موجوداً، مثلا v1.0.0 تصبح 1.0.0
        if (tagName.startsWith('v')) {
          tagName = tagName.substring(1);
        }
        return tagName;
      }
    } catch (e) {
      print('Error fetching latest version: $e');
    }
    return ''; // إعادة نص فارغ في حالة الخطأ لتجنب التحديث
  }

  Future<String> getBinaryUrl(String? version) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );
      if (response.statusCode == 200) {
        final assets = response.data['assets'] as List;
        // البحث عن ملف بصيغة exe
        for (var asset in assets) {
          if (asset['name'].toString().toLowerCase().endsWith('.exe')) {
            return asset['browser_download_url'] as String;
          }
        }
      }
    } catch (e) {
      print('Error fetching binary url: $e');
    }
    return '';
  }
}
