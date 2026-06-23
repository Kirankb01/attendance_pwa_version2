import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';

class AgentRegisterScreen extends StatefulWidget {
  const AgentRegisterScreen({super.key});

  @override
  State<AgentRegisterScreen> createState() => _AgentRegisterScreenState();
}

class _AgentRegisterScreenState extends State<AgentRegisterScreen> {
  final _agentApiService = AgentApiService();
  
  final _agentNameController = TextEditingController();
  final _cityController = TextEditingController();
  
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  Future<void> _submit() async {
    final agentName = _agentNameController.text.trim();
    final city = _cityController.text.trim();

    if (agentName.isEmpty || city.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter both Agent Name and City.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isSuccess = false;
    });

    final success = await _agentApiService.registerAgent(
      agentName: agentName,
      city: city,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = success;
        _statusMessage = success
            ? 'Agent registered successfully!'
            : 'Failed to register agent. Check logs.';
      });
      
      if (success) {
        _agentNameController.clear();
        _cityController.clear();
      }
    }
  }

  @override
  void dispose() {
    _agentNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Register API Agent',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Agent Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Other fields will be populated automatically.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Agent Name Input
            TextField(
              controller: _agentNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Agent Name',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                ),
                filled: true,
                fillColor: const Color(0xFF0F1828),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF00D4FF)),
              ),
            ),
            const SizedBox(height: 16),
            
            // City Input
            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                ),
                filled: true,
                fillColor: const Color(0xFF0F1828),
                prefixIcon: const Icon(Icons.location_city, color: Color(0xFF00D4FF)),
              ),
            ),
            const SizedBox(height: 32),
            
            if (_statusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? const Color(0xFF0A2A1A) : const Color(0xFF2A0A14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF00C87A)
                        : const Color(0xFFFF4D6D).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _isSuccess ? const Color(0xFF00C87A) : const Color(0xFFFF4D6D),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSuccess ? const Color(0xFF00C87A) : const Color(0xFFFF4D6D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            GestureDetector(
              onTap: _isLoading ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey : const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0A0E1A),
                          ),
                        )
                      : const Text(
                          'Submit via API',
                          style: TextStyle(
                            color: Color(0xFF0A0E1A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
