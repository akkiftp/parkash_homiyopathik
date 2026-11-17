import '../core/storage/local_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<ApiResponse<UserModel>> login(String email, String password) async {
    final response = await _api.post<UserModel>(
      '/login',
      data: {
        'email': email,
        'password': password,
      },
      fromData: (data) {
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        LocalStorage.saveToken(token);
        LocalStorage.saveUser(user.toJson());
        return user;
      },
    );
    return response;
  }

  Future<ApiResponse<UserModel>> getMe() async {
    return _api.get<UserModel>(
      '/me',
      fromData: (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> logout() async {
    final res = await _api.post<dynamic>('/logout');
    await LocalStorage.removeToken();
    return res;
  }
}
