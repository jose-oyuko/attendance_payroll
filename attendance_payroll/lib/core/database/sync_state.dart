/// Synchronisation status of a persisted record.
///
/// V1 has no server, so every record stays [localOnly]. The column exists now
/// so that adding synchronisation later does not require touching every row's
/// meaning.
enum SyncState { localOnly, pendingSync, synced, conflict, failed }
