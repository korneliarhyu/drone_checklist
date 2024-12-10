import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

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

  // Get Submission by ID
  @GET("class/database/submission.php")
  Future<dynamic> getSubmissionById(@Query("id") int id);
}
