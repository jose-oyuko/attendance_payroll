/// The app's retry policy for failed providers: never retry automatically.
///
/// Riverpod retries a provider that fails with an exception up to ten
/// times, with growing delays, and reports it as still loading meanwhile.
/// Everything here is local: a validation, permission, not-found or
/// database failure does not go away by trying again, and retrying would
/// keep a spinner on screen for about 40 seconds instead of the message.
/// Screens offer "Try again" instead, so the user decides.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
