/// The game's lifecycle states. Single source of truth.
/// Owned by [SkyHopperGame]. Read by overlays (Module 6), never written
/// from outside the game.
enum GameState {
  /// Pre‑run. Player visible, world static. Waits for first tap to start.
  ready,

  /// Normal gameplay. Updates and collisions run.
  playing,

  /// Player paused. All game updates frozen. Rendering continues.
  paused,

  /// Run ended. Awaits restart or exit.
  gameOver,
}
