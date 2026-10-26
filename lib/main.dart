import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreenSpaghetti(),
    );
  }
}



// TOT EN UN SÒL FITXER I DINS D'UN STATEFUL WIDGET
class LoginScreenSpaghetti extends StatefulWidget {
  const LoginScreenSpaghetti({super.key});

  @override
  State<LoginScreenSpaghetti> createState() => _LoginScreenSpaghettiState();
}

class _LoginScreenSpaghettiState extends State<LoginScreenSpaghetti> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  // Lògica de xarxa, negoci i persistència dins de la UI
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Lògica de validació de formulari barrejada
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Si us plau, introdueix un email vàlid.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'La contrasenya ha de tenir mínim 6 caràcters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Crida directament a la REST API amb la URL a "hardcoded"
      final response = await http.post(
        Uri.parse('https://api.meudomini.com/v1/auth/login'),
        headers: {'Content-Type': 'json/application'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Parseig manual de dades de l'API
        final data = jsonDecode(response.body);
        final String token = data['token'];
        final String userId = data['user']['id'];

        // Persistència local (SharedPreferences) fets directament al controlador de la UI
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', userId);

        if (!mounted) return;

        // Navegació hardcodejada directament des de la funció d'un botó
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        setState(() {
          _errorMessage = 'Credencials incorrectes (${response.statusCode})';
        });
      }
    } catch (e) {
      // Fràgil: barreja errors de xarxa, de parseig i inesperats, i mostra
      // el detall intern de l'excepció directament a l'usuari.
      setState(() {
        _errorMessage = 'Error de connexió a la xarxa: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sessió')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Container(
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correu electrònic'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contrasenya'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Entrar'),
                  ),
          ],
        ),
      ),
    );
  }
}