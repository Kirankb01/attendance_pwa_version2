import 'package:flutter/material.dart';
import '../widgets/debug_overlay.dart'; // Reusing the DebugLogger from here

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1828),
        title: const Text(
          'System Logs',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: () => DebugLogger().clear(),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: DebugLogger().logs,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No logs available yet.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isError = log.toUpperCase().contains('ERROR') || log.contains('Exception');
              
              return SelectableText(
                log,
                style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
