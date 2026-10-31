import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../view_models/auth_view_model.dart';

enum UserRoleChoice { passenger, driver }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true; // Defaults to "Create account" as shown in the design
  UserRoleChoice _selectedRole = UserRoleChoice.passenger; // Defaults to Passenger as highlighted in the design

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Amaka Nwosu');
  final _emailController = TextEditingController(text: 'you@example.com');
  final _phoneController = TextEditingController(text: '+234 802 000 0000');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();

    bool success;
    if (_isSignUp) {
      success = await vm.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole == UserRoleChoice.driver ? 'driver' : 'passenger',
      );
    } else {
      success = await vm.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      if (_selectedRole == UserRoleChoice.passenger) {
        context.go('/rides');
      } else {
        context.go('/board');
      }
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Welcome Title & Subtitle
                        Text(
                          'Welcome to DOGO',
                          style: GoogleFonts.sora(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose how you want to use DOGO.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Role Selection Cards (Passenger vs Rider / Driver)
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                role: UserRoleChoice.passenger,
                                icon: Icons.person_outline_rounded,
                                title: 'Passenger',
                                description: 'Book a Taxi or Tricycle ride, or send a package.',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildRoleCard(
                                role: UserRoleChoice.driver,
                                icon: Icons.two_wheeler_outlined,
                                title: 'Rider / Driver',
                                description: 'Drive and manage your trips.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Main Auth Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12141B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0x1FFFFFFF),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(80),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Create account vs Sign in Segmented Toggle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C0E14),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0x24FFFFFF),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isSignUp = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _isSignUp ? const Color(0xFF2563EB) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Create account',
                                              style: GoogleFonts.manrope(
                                                fontSize: 13,
                                                fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                                                color: _isSignUp ? Colors.white : const Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isSignUp = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: !_isSignUp ? const Color(0xFF2563EB) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Sign in',
                                              style: GoogleFonts.manrope(
                                                fontSize: 13,
                                                fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                                                color: !_isSignUp ? Colors.white : const Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Full Name (Only on Sign Up)
                                if (_isSignUp) ...[
                                  _buildFieldLabel('Full name'),
                                  const SizedBox(height: 6),
                                  _buildTextInput(
                                    controller: _nameController,
                                    hintText: 'Amaka Nwosu',
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Email Address
                                _buildFieldLabel('Email address'),
                                const SizedBox(height: 6),
                                _buildTextInput(
                                  controller: _emailController,
                                  hintText: 'you@example.com',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                                ),
                                const SizedBox(height: 16),

                                // Phone Number (Only on Sign Up)
                                if (_isSignUp) ...[
                                  _buildFieldLabel('Phone number'),
                                  const SizedBox(height: 6),
                                  _buildTextInput(
                                    controller: _phoneController,
                                    hintText: '+234 802 000 0000',
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Password
                                _buildFieldLabel('Password'),
                                const SizedBox(height: 6),
                                _buildTextInput(
                                  controller: _passwordController,
                                  hintText: '••••••••',
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Password must be at least 6 characters'
                                      : null,
                                ),
                                const SizedBox(height: 24),

                                // Action Button
                                SizedBox(
                                  height: 48, 
                                  child: ElevatedButton(
                                    onPressed: vm.isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: vm.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _buttonLabel,
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Demo / Security Notice (One-Tap Demo Explore)
                                InkWell(
                                  onTap: () async {
                                    final router = GoRouter.of(context);
                                    final role = _selectedRole;
                                    await vm.demoSignIn(
                                      role: role == UserRoleChoice.passenger ? 'passenger' : 'driver',
                                    );
                                    if (!mounted) return;
                                    if (role == UserRoleChoice.passenger) {
                                      router.go('/rides');
                                    } else {
                                      router.go('/board');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0x14F59E0B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x33F59E0B)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.shield_outlined,
                                          color: Color(0xFFF59E0B),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Demo mode — tap here to enter instantly.',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFFBBF24),
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _buttonLabel {
    if (_isSignUp) {
      return _selectedRole == UserRoleChoice.passenger
          ? 'Continue as Customer'
          : 'Continue as Driver / Rider';
    } else {
      return _selectedRole == UserRoleChoice.passenger
          ? 'Sign in as Customer'
          : 'Sign in to Crew Console';
    }
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE5E7EB),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.manrope(
          color: const Color(0xFF4B5563),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF0C0E14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleCard({
    required UserRoleChoice role,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10131B) : const Color(0xFF14161E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(50),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: const Color(0xFF9CA3AF),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

