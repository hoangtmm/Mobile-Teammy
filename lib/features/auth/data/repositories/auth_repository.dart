import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required this.remoteDataSource,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final AuthRemoteDataSource remoteDataSource;

  Future<AuthSession> signInWithGoogle() async {
    final idToken = await _acquireFirebaseIdToken();
    final response = await remoteDataSource.exchangeIdToken(idToken);
    return AuthSession(
      accessToken: response.accessToken,
      userId: response.userId,
      email: response.email,
      displayName: response.displayName,
      role: response.role,
    );
  }

  Future<String> _acquireFirebaseIdToken() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException(
        'sign_in_cancelled',
        'Sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) {
      throw const AuthException(
        'id_token_missing',
        'Unable to acquire Firebase ID token.',
      );
    }
    return idToken;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
