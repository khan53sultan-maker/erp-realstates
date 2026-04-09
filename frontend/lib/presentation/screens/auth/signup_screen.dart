import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/globals/text_field.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedRole = 'ADMIN';

  final Map<String, String> _roles = {
    'ADMIN': 'Admin',
    'MANAGER': 'Manager',
    'SALES_AGENT': 'Sales Agent',
    'ACCOUNTANT': 'Accountant',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseAcceptTerms,
              style: TextStyle(fontSize: context.captionFontSize),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius('medium')),
            ),
            margin: EdgeInsets.all(context.mainPadding),
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.clearError();

      // Store email for pre-filling login form
      final userEmail = _emailController.text.trim();

      // ✅ Call signup method (returns bool)
      final success = await authProvider.signup(
        _nameController.text.trim(),
        userEmail,
        _selectedRole,
        _passwordController.text,
        _confirmPasswordController.text,
        _acceptTerms,
      );

      if (mounted) {
        if (success) {
          // ✅ Signup successful - Show success message safely
          final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
          if (scaffoldMessenger != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.pureWhite,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        l10n.accountCreatedSuccessfully,
                        style: TextStyle(fontSize: context.captionFontSize),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius('medium')),
                ),
                margin: EdgeInsets.all(context.mainPadding),
              ),
            );
          }

          // ✅ Navigate to login screen after delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/login',
                arguments: {'email': userEmail}, // Pass email to pre-fill
              );
            }
          });
        } else {
          // ❌ Signup failed - Show error snackbar safely
          final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
          if (scaffoldMessenger != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.pureWhite,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage ?? l10n.registrationFailedMessage,
                        style: TextStyle(fontSize: context.captionFontSize),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius('medium')),
                ),
                margin: EdgeInsets.all(context.mainPadding),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: ResponsiveBreakpoints.responsive(
              context,
              tablet: 2,
              small: 2,
              medium: 2,
              large: 2,
              ultrawide: 2,
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppTheme.secondaryMaroon, AppTheme.primaryMaroon],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: context.iconSize('special') * 1.5,
                      height: context.iconSize('special') * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.pureWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: context.shadowBlur(),
                            offset: Offset(0, context.smallPadding),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/iconic_logo.png'),
                    ),

                    SizedBox(height: context.mainPadding),

                    Text(
                      l10n.joinOur,
                      style: TextStyle(
                        fontSize: context.headerFontSize,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.pureWhite.withOpacity(0.9),
                      ),
                    ),

                    SizedBox(height: context.smallPadding),

                    Text(
                      l10n.premiumFamily,
                      style: TextStyle(
                        fontSize: context.headingFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.pureWhite,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: context.cardPadding),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.mainPadding),
                      child: Text(
                        l10n.signupWelcomeMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.pureWhite.withOpacity(0.8),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            flex: ResponsiveBreakpoints.responsive(
              context,
              tablet: 2,
              small: 2,
              medium: 1,
              large: 1,
              ultrawide: 1,
            ),
            child: Container(
              color: AppTheme.creamWhite,
              child: Center(
                child: SingleChildScrollView(
                  padding: context.pagePadding,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: context.maxContentWidth * 0.9,
                        small: context.maxContentWidth * 0.7,
                        medium: context.maxContentWidth * 0.6,
                        large: context.maxContentWidth * 0.5,
                        ultrawide: context.maxContentWidth * 0.4,
                      ),
                      minWidth: 300, // Ensure minimum width in pixels
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.createAccount,
                            style: TextStyle(
                              fontSize: context.headingFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.charcoalGray,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: context.smallPadding),

                          Text(
                            l10n.joinExclusiveCommunity,
                            style: TextStyle(
                              fontSize: context.headerFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: context.mainPadding * 1.5),

                          PremiumTextField(
                            label: l10n.fullName,
                            hint: l10n.enterYourFullName,
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.pleaseEnterFullName;
                              }
                              if (value!.length < 2) {
                                return l10n.nameMinLength;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: context.formFieldSpacing),

                          PremiumTextField(
                            label: l10n.emailAddress,
                            hint: l10n.enterYourEmail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.pleaseEnterEmail;
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                return l10n.pleaseEnterValidEmail;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: context.formFieldSpacing),

                          const Text('Account Role:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                            onChanged: (v) => setState(() => _selectedRole = v!),
                          ),

                          SizedBox(height: context.formFieldSpacing),

                          PremiumTextField(
                            label: l10n.password,
                            hint: l10n.createStrongPassword,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: context.iconSize('medium'),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.pleaseEnterPassword;
                              }
                              if (value!.length < 8) {
                                return l10n.passwordMinLength;
                              }
                              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                                return l10n.passwordMustContain;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: context.formFieldSpacing),

                          PremiumTextField(
                            label: l10n.confirmPassword,
                            hint: l10n.reenterPassword,
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: context.iconSize('medium'),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.pleaseConfirmPassword;
                              }
                              if (value != _passwordController.text) {
                                return l10n.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: context.cardPadding),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: context.iconSize('medium'),
                                  height: context.iconSize('medium'),
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptTerms = value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryMaroon,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.smallPadding * 2),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: context.smallPadding / 4),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: l10n.iAgreeToThe,
                                            style: TextStyle(
                                              fontSize: context.bodyFontSize,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextSpan(
                                            text: l10n.termsOfService,
                                            style: TextStyle(
                                              fontSize: context.bodyFontSize,
                                              color: AppTheme.primaryMaroon,
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                          TextSpan(
                                            text: l10n.and,
                                            style: TextStyle(
                                              fontSize: context.bodyFontSize,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextSpan(
                                            text: l10n.privacyPolicy,
                                            style: TextStyle(
                                              fontSize: context.bodyFontSize,
                                              color: AppTheme.primaryMaroon,
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.mainPadding),

                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return PremiumButton(
                                text: l10n.createAccount,
                                onPressed: authProvider.isLoading ? null : _handleSignup,
                                isLoading: authProvider.isLoading,
                                height: context.buttonHeight / 1.5,
                              );
                            },
                          ),

                          SizedBox(height: context.cardPadding),

                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.errorMessage != null) {
                                return Container(
                                  margin: EdgeInsets.only(top: context.smallPadding),
                                  padding: EdgeInsets.all(context.cardPadding),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(context.borderRadius('medium')),
                                    border: Border.all(color: Colors.red.shade200, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: context.iconSize('medium'),
                                      ),
                                      SizedBox(width: context.smallPadding),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.registrationFailed,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: context.bodyFontSize,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: context.smallPadding / 2),
                                            Text(
                                              authProvider.errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red.shade600,
                                                fontSize: context.captionFontSize,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => authProvider.clearError(),
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red.shade400,
                                          size: context.iconSize('small'),
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          SizedBox(height: context.mainPadding),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyHaveAccount,
                                style: TextStyle(
                                  fontSize: context.bodyFontSize,
                                  color: Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  l10n.signIn,
                                  style: TextStyle(
                                    fontSize: context.headerFontSize,
                                    color: AppTheme.primaryMaroon,
                                    fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
      ),
    );
  }
}
