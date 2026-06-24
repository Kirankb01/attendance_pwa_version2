import 'package:flutter/material.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final ValueNotifier<List<String>> logs = ValueNotifier([]);

  void log(String message) {
    debugPrint('[DebugLogger] $message');
    final currentLogs = List<String>.from(logs.value);
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    currentLogs.insert(0, '[$timestamp] $message'); // Add to top
    if (currentLogs.length > 50) {
      currentLogs.removeLast(); // Keep only last 50 logs
    }
    logs.value = currentLogs;
  }

  void clear() {
    logs.value = [];
  }
}

class DebugOverlay extends StatelessWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: IgnorePointer(
              ignoring: true, // Let taps pass through
              child: ValueListenableBuilder<List<String>>(
                valueListenable: DebugLogger().logs,
                builder: (context, logs, _) {
                  if (logs.isEmpty) return const SizedBox.shrink();
                  return Container(
                    height: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                    ),
                    child: ListView.builder(
                      reverse: true, // Newest at bottom visually if reversed, but we insert at top. Wait, we insert at top, so reverse=true puts newest at bottom. Let's just use normal list.
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            logs[index],
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
