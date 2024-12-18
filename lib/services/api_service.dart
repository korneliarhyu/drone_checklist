import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:drone_checklist/model/json_model.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: "http://103.102.152.249/webdrone/")
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // Download API
  @GET("class/database/download.php")
  Future<dynamic> downloadTemplate(@Query("templateId") int templateId);

  // Sync Data API
  @POST("class/database/syncData.php")
  Future<dynamic> syncData(@Body() Map<String, dynamic> data);

  // Get All Template
  @GET("class/database/template/all.php")
  // return type dari server berupa string
  Future<String> getAllTemplate();
}
