import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_config.dart';

/// Client Socket.io — namespace /realtime
class RealtimeService {
  io.Socket? _socket;
  final _controller = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _controller.stream;
  bool get isConnected => _socket?.connected ?? false;

  void connect({required String userId}) {
    disconnect();

    const url = ApiConfig.baseUrl;
    _socket = io.io(
      '$url/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'userId': userId})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _socket!.emit('join', {'userId': userId});
        _controller.add(RealtimeEvent(type: 'connected', data: {}));
      })
      ..onDisconnect((_) {
        _controller.add(RealtimeEvent(type: 'disconnected', data: {}));
      })
      ..on('notification', (data) {
        _controller.add(RealtimeEvent(
          type: 'notification',
          data: Map<String, dynamic>.from(data as Map? ?? {}),
        ));
      })
      ..on('assignment:new', (data) {
        _controller.add(RealtimeEvent(
          type: 'assignment:new',
          data: Map<String, dynamic>.from(data as Map? ?? {}),
        ));
      })
      ..on('assignment:response', (data) {
        _controller.add(RealtimeEvent(
          type: 'assignment:response',
          data: Map<String, dynamic>.from(data as Map? ?? {}),
        ));
      })
      ..on('pointage:done', (data) {
        _controller.add(RealtimeEvent(
          type: 'pointage:done',
          data: Map<String, dynamic>.from(data as Map? ?? {}),
        ));
      })
      ..on('incident:new', (data) {
        _controller.add(RealtimeEvent(
          type: 'incident:new',
          data: Map<String, dynamic>.from(data as Map? ?? {}),
        ));
      });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

class RealtimeEvent {
  final String type;
  final Map<String, dynamic> data;

  RealtimeEvent({required this.type, required this.data});
}
