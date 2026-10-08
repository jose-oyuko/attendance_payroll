import 'package:uuid/uuid.dart';

/// Produces identifiers for new business entities. Injected so tests are
/// deterministic.
typedef IdGenerator = String Function();

const Uuid _uuid = Uuid();

/// A time-ordered UUID (version 7).
///
/// UUIDs let every device create records independently, which future
/// synchronisation requires. Version 7 starts with a timestamp, so new keys are
/// appended to primary-key indexes instead of being scattered through them.
String generateUuidV7() => _uuid.v7();
