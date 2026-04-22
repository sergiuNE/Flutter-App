import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/discover_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _showPass = false;
  bool _showPassConfirm = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (name.isEmpty) {
      _showError('Vul je naam in.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Vul een geldig e-mailadres in.');
      return;
    }
    if (_passCtrl.text != _passConfirmCtrl.text) {
      _showError('Wachtwoorden komen niet overeen.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showError('Wachtwoord moet minstens 6 tekens zijn.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.register(
        email: email,
        password: _passCtrl.text,
        name: name,
        city: city,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiscoverScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Registratie mislukt: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF3C3C43),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account aanmaken',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Deel & verhuur in je buurt',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
              ),
              const SizedBox(height: 36),
              _label('Volledige naam'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Jan Janssen'),
              ),
              const SizedBox(height: 14),
              _label('E-mailadres'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'naam@email.be'),
              ),
              const SizedBox(height: 14),
              _label('Wachtwoord'),
              const SizedBox(height: 6),
              TextField(
                controller: _passCtrl,
                obscureText: !_showPass,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: const Color(0xFF8E8E93),
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _label('Wachtwoord bevestigen'),
              const SizedBox(height: 6),
              TextField(
                controller: _passConfirmCtrl,
                obscureText: !_showPassConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                      color: const Color(0xFF8E8E93),
                    ),
                    onPressed: () =>
                        setState(() => _showPassConfirm = !_showPassConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _label('Stad / gemeente (optioneel)'),
              const SizedBox(height: 6),
              TextField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  hintText: 'Antwerpen (optioneel)',
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Registreren'),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Al een account? ',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Aanmelden',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
