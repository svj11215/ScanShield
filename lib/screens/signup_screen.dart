import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to ScanShield.'),
            backgroundColor: AppColors.safe,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
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
            content: Text('Account created successfully! Welcome to ScanShield.'),
            backgroundColor: AppColors.safe,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
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
                            size: 40,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Heading
                  Text(
                    AppStrings.signupTitle,
                    style: AppTextStyles.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'Join ScanShield today',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

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
                    textInputAction: TextInputAction.next,
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
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleSignup(),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text('Sign Up'),
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
                            child: CircularProgressIndicator(strokeWidth: 2.5),
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

                  // Navigation to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: Text(
                          'Login',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
