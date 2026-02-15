/// Defines the possible states of the Pomodoro timer.
enum PomodoroStatus {
  /// The timer has not started yet.
  initial,

  /// The timer is actively counting down.
  running,

  /// The timer is paused.
  paused,

  /// The timer is for a break/rest period.
  resting,

  /// The timer has completed its countdown.
  finished,
}
