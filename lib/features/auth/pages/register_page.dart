import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService authService = AuthService();

  final TextEditingController namaController =
      TextEditingController();

  final TextEditingController nimController =
      TextEditingController();

  final TextEditingController prodiController =
      TextEditingController();

  final TextEditingController angkatanController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> register() async {
    if (namaController.text.trim().isEmpty ||
        nimController.text.trim().isEmpty ||
        prodiController.text.trim().isEmpty ||
        angkatanController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field wajib diisi"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    print("REGISTER START");

    try {
      String? result = await authService.register(
        nama: namaController.text.trim(),
        nim: nimController.text.trim(),
        prodi: prodiController.text.trim(),
        angkatan: angkatanController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("REGISTER RESULT : $result");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Register Success"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
          ),
        );
      }
    } catch (e) {
      print("REGISTER ERROR : $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    nimController.dispose();
    prodiController.dispose();
    angkatanController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              buildTextField(
                controller: namaController,
                label: "Nama Lengkap",
              ),
              buildTextField(
                controller: nimController,
                label: "NIM",
              ),
              buildTextField(
                controller: prodiController,
                label: "Program Studi",
              ),
              buildTextField(
                controller: angkatanController,
                label: "Angkatan",
              ),
              buildTextField(
                controller: emailController,
                label: "Email",
              ),
              buildTextField(
                controller: passwordController,
                label: "Password",
                obscureText: true,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : register,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Register"),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginPage(),
                    ),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}