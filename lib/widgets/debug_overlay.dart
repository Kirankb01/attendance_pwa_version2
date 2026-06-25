import 'package:flutter/material.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final ValueNotifier<List<String>> logs = ValueNotifier([]);

  void log(String message) {
    debugPrint('[DebugLogger] $message');
    Future.microtask(() {
      final currentLogs = List<String>.from(logs.value);
      final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
      currentLogs.insert(0, '[$timestamp] $message'); // Add to top
      if (currentLogs.length > 200) {
        currentLogs.removeLast(); // Keep only last 200 logs
      }
      logs.value = currentLogs;
    });
  }

  void clear() {
    logs.value = [];
  }
}

class DebugOverlay extends StatefulWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ValueListenableBuilder<List<String>>(
              valueListenable: DebugLogger().logs,
              builder: (context, logs, _) {
                if (logs.isEmpty) return const SizedBox.shrink();
                
                return _expanded
                    ? Container(
                        height: MediaQuery.of(context).size.height * 0.8,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.cyan.withOpacity(0.8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Debug Logs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _expanded = false),
                                  child: const Icon(Icons.close, color: Colors.white),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            Expanded(
                              child: ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      logs[index],
                                      style: TextStyle(
                                        color: logs[index].toUpperCase().contains('ERROR') || logs[index].contains('Exception') ? Colors.redAccent : Colors.greenAccent,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _expanded = true),
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                          ),
                          child: IgnorePointer(
                            ignoring: true,
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logs.length > 5 ? 5 : logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    logs[index],
                                    style: TextStyle(
                                      color: logs[index].toUpperCase().contains('ERROR') || logs[index].contains('Exception') ? Colors.redAccent : Colors.greenAccent,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
