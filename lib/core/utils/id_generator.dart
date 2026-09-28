import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class IdGenerator {
  IdGenerator({Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _now;
  int _sequence = 0;

  String uuid() => _uuid.v4();

  String clientTransactionId(String prefix) {
    _sequence += 1;
    final stamp = DateFormat('yyyyMMdd').format(_now());
    return '$prefix-$stamp-${_sequence.toString().padLeft(6, '0')}';
  }

  String photoId() => 'PHO-${_uuid.v4().substring(0, 8).toUpperCase()}';
}
