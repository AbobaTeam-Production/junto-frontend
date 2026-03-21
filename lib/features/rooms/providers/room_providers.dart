import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/auth_provider.dart';

class RoomInfo {
  final String id;
  final String inviteCode;
  final String hostName;
  final int memberCount;
  final String status;
  final DateTime expiresAt;

  const RoomInfo({
    required this.id,
    required this.inviteCode,
    required this.hostName,
    required this.memberCount,
    required this.status,
    required this.expiresAt,
  });

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'].toString(),
      inviteCode: json['invite_code'] as String,
      hostName: (json['host']?['username'] as String?) ?? 'Unknown',
      memberCount: json['member_count'] as int? ?? 0,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

final myRoomsProvider =
    AsyncNotifierProvider<MyRoomsNotifier, List<RoomInfo>>(MyRoomsNotifier.new);

class MyRoomsNotifier extends AsyncNotifier<List<RoomInfo>> {
  @override
  Future<List<RoomInfo>> build() async {
    final auth = ref.watch(authStateProvider);
    if (auth.status != AuthStatus.authenticated) {
      return [];
    }
    return _fetchRooms();
  }

  Future<List<RoomInfo>> _fetchRooms() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(ApiEndpoints.rooms);
    final list = response.data as List;
    return list.map((e) => RoomInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchRooms());
  }
}

class CreateRoomResult {
  final String roomId;
  final String inviteCode;

  const CreateRoomResult({required this.roomId, required this.inviteCode});
}

Future<CreateRoomResult> createRoom(WidgetRef ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.post(ApiEndpoints.roomCreate);
  return CreateRoomResult(
    roomId: response.data['room_id'] as String,
    inviteCode: response.data['invite_code'] as String,
  );
}

class JoinRoomResult {
  final String roomId;
  final String inviteCode;

  const JoinRoomResult({required this.roomId, required this.inviteCode});
}

Future<JoinRoomResult> joinRoom(WidgetRef ref, String inviteCode) async {
  final dio = ref.read(dioProvider);
  final response = await dio.post(
    ApiEndpoints.roomJoin,
    data: {'invite_code': inviteCode},
  );
  return JoinRoomResult(
    roomId: response.data['id'].toString(),
    inviteCode: response.data['invite_code'] as String,
  );
}

Future<void> deleteRoom(WidgetRef ref, String roomId) async {
  final dio = ref.read(dioProvider);
  await dio.delete(ApiEndpoints.roomDetail(roomId));
  ref.invalidate(myRoomsProvider);
}

final roomDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, roomId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiEndpoints.roomDetail(roomId));
  return response.data as Map<String, dynamic>;
});
