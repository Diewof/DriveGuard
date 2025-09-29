import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import 'user_model.dart';

class AuthResultModel extends AuthResult {
  const AuthResultModel({
    super.user,
    super.isNewUser,
    super.message,
    super.errorMessage,
    super.isSuccess,
  });

  factory AuthResultModel.fromDomain(AuthResult authResult) {
    return AuthResultModel(
      user: authResult.user,
      isNewUser: authResult.isNewUser,
      message: authResult.message,
      errorMessage: authResult.errorMessage,
      isSuccess: authResult.isSuccess,
    );
  }

  factory AuthResultModel.create({
    required User user,
    bool isNewUser = false,
    String? message,
  }) {
    return AuthResultModel(
      user: UserModel.fromDomain(user),
      isNewUser: isNewUser,
      message: message,
      isSuccess: true,
    );
  }

  factory AuthResultModel.failure(String errorMessage) {
    return AuthResultModel(
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }
}