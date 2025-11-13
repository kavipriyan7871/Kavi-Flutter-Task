import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _mobile = TextEditingController();

  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      if (_register) {
        if (_mobile.text.trim().length < 10) {
          throw Exception('Enter valid mobile number');
        }
        await auth.registerWithEmail(
          _email.text.trim(),
          _password.text.trim(),
          _displayName.text.trim(),
          _mobile.text.trim(),
        );
      } else {
        await auth.signInWithEmail(_email.text.trim(), _password.text.trim());
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini WhatsApp - Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(children: [
            if (_register)
              Column(
                children: [
                  TextField(
                    controller: _displayName,
                    decoration: const InputDecoration(labelText: 'Display name'),
                  ),
                  TextField(
                    controller: _mobile,
                    decoration: const InputDecoration(labelText: 'Mobile number'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submit,
                child: Text(_register ? 'Register' : 'Login'),
              ),
            TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text(_register ? 'Have an account? Login' : 'Create an account'),
            ),
          ]),
        ),
      ),
    );
  }
}
