import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),

      body: Center(
        child: Container(
          width: 480,
          constraints: const BoxConstraints(minHeight: 750),
          decoration: BoxDecoration(
            color: Colors.white,
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

                child: Column(
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
                    const Text(
                      "Welcome back",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Subtitle
                    const Text(
                      "Sign in to manage your\norganization's tasks and finances\nsecurely.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF617589),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Email Address",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: "name@company.com",
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
                          children: const [

                            Text(
                              "Password",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            Text(
                              "Forgot?",
                              style: TextStyle(
                                color: Color(0xFF137FEC),
                                fontWeight: FontWeight.w600,
                              ),
                            )
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

                    const SizedBox(height: 24),

                    /// Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {
                          // TODO: Call ViewModel login()
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Divider
                    Row(
                      children: const [

                        Expanded(child: Divider()),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "DON'T HAVE AN ACCOUNT?",
                            style: TextStyle(
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
                        label: const Text(
                          "Register",
                          style: TextStyle(fontSize: 16),
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
                          // TODO: Navigate to register page
                        },
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}