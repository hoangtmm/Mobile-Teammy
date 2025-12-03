import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profile_update.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepository {
  UserRepository({required this.remoteDataSource});

  final UserRemoteDataSource remoteDataSource;

  Future<UserProfile> fetchProfile(String accessToken) {
    return remoteDataSource.getProfile(accessToken);
  }

  Future<void> updateProfile({
    required String accessToken,
    required UserProfileUpdate update,
  }) {
    return remoteDataSource.updateProfile(
      accessToken: accessToken,
      payload: update,
    );
  }
}
