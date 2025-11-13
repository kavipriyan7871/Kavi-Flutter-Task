import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _mobile = TextEditingController();

  bool _register = false;
  bool _loading = false;
  String? _error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const skyBlue = Color(0xFF0A99FF);
  static const darkBlue = Color(0xFF073C70);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _mobile.dispose();
    _animController.dispose();
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
          throw Exception("Enter valid mobile number");
        }
        await auth.registerWithEmail(
          _email.text.trim(),
          _password.text.trim(),
          _displayName.text.trim(),
          _mobile.text.trim(),
        );
      } else {
        await auth.signInWithEmail(
          _email.text.trim(),
          _password.text.trim(),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021F39),

      body: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: skyBlue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: skyBlue.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            ],
          ),

          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _register ? "Create Account" : "Login",
                    style: const TextStyle(
                      color: skyBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (_register) ...[
                    _inputBox(controller: _displayName, hint: "Display Name"),
                    const SizedBox(height: 12),
                    _inputBox(
                      controller: _mobile,
                      hint: "Mobile Number",
                      type: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _inputBox(controller: _email, hint: "Email Address"),
                  const SizedBox(height: 12),

                  _inputBox(
                      controller: _password,
                      hint: "Password",
                      obscure: true),

                  const SizedBox(height: 14),

                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),

                  const SizedBox(height: 12),

                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: skyBlue),
                        )
                      : GestureDetector(
                          onTap: _submit,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 50),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient:
                                  const LinearGradient(colors: [skyBlue, darkBlue]),
                              boxShadow: [
                                BoxShadow(
                                  color: skyBlue.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _register ? "Register" : "Login",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 18),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _register = !_register);
                        _animController.forward(from: 0);
                      },
                      child: Text(
                        _register
                            ? "Already have an account? Login →"
                            : "Create a new account →",
                        style: const TextStyle(
                          color: skyBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// TextField
  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    const skyBlue = Color(0xFF0A99FF);
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.09),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: skyBlue, width: 2),
        ),
      ),
    );
  }
}
