import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Wynik wysłania pliku do Cloudinary.
class CloudinaryUpload {
  CloudinaryUpload({required this.url, required this.publicId});
  final String url;
  final String publicId;
}

/// Wgrywanie zdjęć do Cloudinary (unsigned upload preset) — ten sam projekt
/// co publiczna galeria (`galeria.html`): cloud `dybgmjmu3`, preset
/// `Ceremonia_Patrycji_i_Piotra`. Zwraca `secure_url` zapisywany w Firestore.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String cloudName = 'dybgmjmu3';
  static const String uploadPreset = 'Ceremonia_Patrycji_i_Piotra';

  Uri get _endpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Wgrywa bajty obrazu. Rzuca [Exception] przy błędzie.
  Future<CloudinaryUpload> uploadImage(Uint8List bytes,
      {String filename = 'photo.jpg'}) async {
    final req = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Cloudinary ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary: brak secure_url w odpowiedzi');
    }
    return CloudinaryUpload(
      url: url,
      publicId: (data['public_id'] as String?) ?? '',
    );
  }
}
