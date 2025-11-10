import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const Z91PrinterApp());

class Z91PrinterApp extends StatelessWidget {
  const Z91PrinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Z91 Printer',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const PrinterHomePage(),
    );
  }
}

class PrinterHomePage extends StatefulWidget {
  const PrinterHomePage({super.key});

  @override
  State<PrinterHomePage> createState() => _PrinterHomePageState();
}

class _PrinterHomePageState extends State<PrinterHomePage> {
  static const platform = MethodChannel('z91_printer');
  String _statusMessage = "Ready to print";
  bool _isPrinting = false;

  Future<void> _printSample() async {
    if (_isPrinting) return;
    setState(() {
      _statusMessage = "🕓 Printing in progress...";
      _isPrinting = true;
    });

    try {
      final result = await platform.invokeMethod(
        'printText',
        {'text': 'Hello from Flutter Z91 Printer!\n'},
      );
      setState(() {
        _statusMessage = "✅ Print successful: $result";
      });
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = "❌ Print failed: ${e.message}";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "⚠️ Unexpected error: $e";
      });
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.print_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Z91 Android Printer",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isPrinting ? null : _printSample,
                icon: const Icon(Icons.print),
                label: Text(_isPrinting ? "Printing..." : "Print Sample Text"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size.width * 0.85,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                "Developed in Flutter",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}