import '../datasources/invitation_remote_data_source.dart';
import '../models/invitation_model.dart';

class InvitationRepository {
  final InvitationRemoteDataSource remoteDataSource;

  InvitationRepository({required this.remoteDataSource});

  Future<List<InvitationModel>> getPendingInvitations() async {
    return await remoteDataSource.fetchPendingInvitations();
  }

  Future<void> acceptInvitation(String invitationId) async {
    return await remoteDataSource.acceptInvitation(invitationId);
  }

  Future<void> declineInvitation(String invitationId) async {
    return await remoteDataSource.declineInvitation(invitationId);
  }
}
