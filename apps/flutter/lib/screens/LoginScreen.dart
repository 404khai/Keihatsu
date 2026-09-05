import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final brandColor = themeProvider.brandColor;
    // Enforce white background and black text/icons for LoginScreen
    const bgColor = Colors.white;
    const textColor = Colors.black87;
    const subTextColor = Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'images/keihatsu.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.menu_book, size: 100, color: brandColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Welcome Back!",
                  style: GoogleFonts.hennyPenny(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Text(
                  "Log in to sync your library and continue your journey",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 14),
                ),
                const SizedBox(height: 50),

                // Google Sign In
                if (authProvider.isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await authProvider.loginWithGoogle();
                          if (context.mounted && authProvider.isAuthenticated) {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Login failed: ${e.toString()}'),
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/google.png',
                            height: 20,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.login,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Sign in with Google",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 15),

                // Skip for now
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text(
                    "Skip for now",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/register'),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: textColor, fontSize: 14),
                      children: [
                        const TextSpan(text: "Don't have an account? ", style: TextStyle(color: subTextColor)),
                        TextSpan(
                          text: "Register",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
