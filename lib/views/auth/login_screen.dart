import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../views/dashboard/main_dashboard_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRegister = false;

  final confirmPasswordController = TextEditingController();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 13, 14),
      body: Center(
        child: Container(
          width: 480,
          constraints: const BoxConstraints(minHeight: 750),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 235, 244, 255),
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 50,
                spreadRadius: -12,
                offset: const Offset(0, 25),
                color: Colors.black.withOpacity(0.25),
              )
            ],
          ),
          child: Stack(
            children: [
              /// Decorative blob (top right)
              Positioned(
                top: -96,
                right: -96,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF137FEC).withOpacity(.05),
                  ),
                ),
              ),

              /// Decorative blob (bottom left)
              Positioned(
                bottom: -128,
                left: -128,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF137FEC).withOpacity(.05),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    // smooth scale & fade for clean/formal feel
                    final fade =
                        FadeTransition(opacity: animation, child: child);
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                            parent: animation, curve: Curves.easeOutQuad),
                      ),
                      child: fade,
                    );
                  },
                  child: Column(
                    key: ValueKey(isRegister),
                    children: [
                      const SizedBox(height: 64),

                      /// Header Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF137FEC).withOpacity(.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          color: Color(0xFF137FEC),
                          size: 30,
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Title
                      Text(
                        isRegister ? "Create Account" : "Hello !!",
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111418),
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// Subtitle
                      Text(
                        isRegister
                            ? "Register to start managing\nyour organization."
                            : "Sign in to manage your\norganization's tasks and finances\nsecurely.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Color(0xFF617589),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      if (isRegister) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "User",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: fullNameController,
                              decoration: InputDecoration(
                                hintText: "User",
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      /// Email Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Email Address",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: "name@gmail.com",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Password",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isRegister) ...[
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Confirm Password",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: "••••••••",
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      /// Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final authVM = Provider.of<AuthViewModel>(context,
                                listen: false);

                            if (authVM.isLoading) return;

                            if (isRegister) {
                              final success = await authVM.register(
                                emailController.text,
                                passwordController.text,
                                fullName: fullNameController.text,
                              );

                              if (success && context.mounted) {
                                setState(() {
                                  isRegister = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Registration successful! Please sign in with your new credentials."),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(authVM.errorMessage ??
                                          "Registration failed")),
                                );
                              }
                            } else {
                              final success = await authVM.login(
                                emailController.text,
                                passwordController.text,
                              );
                              if (success && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MainDashboardScreen(),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(authVM.errorMessage ??
                                          "Login failed")),
                                );
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromARGB(255, 21, 68, 114),
                                  Color(0xFF4A90E2)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Center(
                              child: Consumer<AuthViewModel>(
                                builder: (context, authVM, child) {
                                  return authVM.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : Text(
                                          isRegister
                                              ? "Register Account"
                                              : "Sign In",
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Divider
                      Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              isRegister
                                  ? "ALREADY HAVE AN ACCOUNT?"
                                  : "DON'T HAVE AN ACCOUNT?",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF617589),
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: Text(
                            isRegister ? "Back to Login" : "Register",
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFDbe0e6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              isRegister = !isRegister;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
