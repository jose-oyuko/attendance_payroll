/// Source of the current instant. Injected wherever time is recorded so tests
/// are deterministic.
typedef Clock = DateTime Function();

/// The current instant in UTC. Every persisted timestamp is UTC; the company
/// timezone is applied only when interpreting or displaying it.
DateTime systemClockUtc() => DateTime.now().toUtc();
