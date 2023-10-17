class SolveStopwatch {
  final Stopwatch _stopwatch = Stopwatch();
  Duration _elapsed = Duration.zero;

  void start() {
    _stopwatch.start();
  }

  void stop() {
    _stopwatch.stop();
  }

  void reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    _elapsed = Duration.zero;
  }

  void skip(Duration duration) {
    _elapsed += duration;
  }

  void backward(Duration duration) {
    _elapsed -= duration;
    if (elapsed.inMilliseconds < 0) {
      reset();
      start();
    }
  }

  void jumpTo(Duration duration) {
    _stopwatch.reset();
    _elapsed = duration;
  }

  Duration get elapsed => _elapsed + _stopwatch.elapsed;
}
