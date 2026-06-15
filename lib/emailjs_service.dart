import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJSService {
  static const String serviceId = "service_pofle0q";
  static const String templateId = "template_0t3hecm";
  static const String userId = "SS0whgKnX3h7brSdj";
  static const String accessToken = "AWMVYLlzzOs6qRudDJ25R"; // optional

  static Future<void> sendStaffCredentials({
    required String email,
    required String name,
    required String role,
    required String password,
  }) async {
    final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": userId,
        "accessToken": accessToken,

        "template_params": {
          "email": email,
          "name": name,
          "role": role,
          "password": password,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("EmailJS Error: ${response.body}");
    }
  }
}
