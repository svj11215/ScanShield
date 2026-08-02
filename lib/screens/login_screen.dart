import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful! Welcome back.'),
            backgroundColor: AppColors.safe,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful! Welcome back.'),
            backgroundColor: AppColors.safe,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool isResetLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Reset Password', style: AppTextStyles.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your email to receive a password reset link.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isResetLoading ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isResetLoading
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty) return;

                          setDialogState(() => isResetLoading = true);
                          try {
                            await _authService.resetPassword(email);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset email sent! Please check your inbox.'),
                                  backgroundColor: AppColors.safe,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => isResetLoading = false);
                          }
                        },
                  child: isResetLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shield_rounded,
                            size: 52,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Heading
                  Text(
                    AppStrings.loginTitle,
                    style: AppTextStyles.headingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'Login to continue',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingLarge * 1.5),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),

                  // Forgot Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _showForgotPasswordDialog,
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                        child: Text(
                          'OR',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Google Sign-In Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    child: _isGoogleLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Navigation to Signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
