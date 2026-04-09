import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/globals/text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // ✅ Pre-fill email if coming from signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['email'] != null) {
        _emailController.text = args['email'];

        // Show welcome message
        ScaffoldMessenger.of(context).showSnackBar(
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
                    'Welcome! Please log in with your new account.',
                    style: TextStyle(fontSize: context.captionFontSize),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryMaroon,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.borderRadius('medium')),
            ),
            margin: EdgeInsets.all(context.mainPadding),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Clear any previous errors
      authProvider.clearError();

      // ✅ Call login with await
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        debugPrint('🔵 Login state after call: ${authProvider.state}');
        if (authProvider.state == AuthState.authenticated) {
          debugPrint('✅ Login reported as authenticated by provider');
          
          // ✅ Navigate to dashboard IMMEDIATELY using the GlobalKey for stability
          debugPrint('🚀 Navigating to /dashboard...');
          HiBlankitsApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
        } else if (authProvider.state == AuthState.error) {
          debugPrint('❌ Login error reported by provider: ${authProvider.errorMessage}');
          // ❌ Login failed - Show error snackbar safely
          if (mounted) {
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
                          authProvider.errorMessage ?? l10n.loginFailed,
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          // Left Side - Branding
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
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
                      l10n.welcomeBack,
                      style: TextStyle(
                        fontSize: context.headerFontSize,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.pureWhite.withOpacity(0.9),
                      ),
                    ),

                    SizedBox(height: context.smallPadding),

                    Text(
                      l10n.brandName,
                      style: TextStyle(
                        fontSize: context.headingFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.pureWhite,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: context.cardPadding),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.mainPadding,
                      ),
                      child: Text(
                        l10n.tagline,
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

          // Right Side - Login Form
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
                      maxWidth: context.maxContentWidth * 0.5,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.signIn,
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
                            l10n.accessDashboard,
                            style: TextStyle(
                              fontSize: context.headerFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: context.mainPadding * 1.5),

                          // Email Field
                          PremiumTextField(
                            label: l10n.emailAddress,
                            hint: l10n.enterEmail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.pleaseEnterEmail;
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value!)) {
                                return l10n.pleaseEnterValidEmail;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: context.cardPadding),

                          // Password Field
                          PremiumTextField(
                            label: l10n.password,
                            hint: l10n.enterPassword,
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
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: context.iconSize('medium'),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return l10n.pleaseEnterPassword;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: context.smallPadding),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.forgotPasswordComingSoon,
                                      style: TextStyle(
                                        fontSize: context.captionFontSize,
                                      ),
                                    ),
                                    backgroundColor: AppTheme.primaryMaroon,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        context.borderRadius('medium'),
                                      ),
                                    ),
                                    margin: EdgeInsets.all(context.mainPadding),
                                  ),
                                );
                              },
                              child: Text(
                                l10n.forgotPassword,
                                style: TextStyle(
                                  fontSize: context.bodyFontSize,
                                  color: AppTheme.primaryMaroon,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: context.mainPadding),

                          // Login Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return PremiumButton(
                                text: l10n.signIn,
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleLogin,
                                isLoading: authProvider.isLoading,
                                height: context.buttonHeight / 1.5,
                              );
                            },
                          ),

                          SizedBox(height: context.cardPadding),

                          // Enhanced Error Message Display
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.errorMessage != null) {
                                return Container(
                                  margin: EdgeInsets.only(
                                    top: context.smallPadding,
                                  ),
                                  padding: EdgeInsets.all(context.cardPadding),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(
                                      context.borderRadius('medium'),
                                    ),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: context.iconSize('medium'),
                                      ),
                                      SizedBox(width: context.smallPadding),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.loginFailed,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: context.bodyFontSize,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(
                                              height: context.smallPadding / 2,
                                            ),
                                            Text(
                                              authProvider.errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red.shade600,
                                                fontSize:
                                                context.captionFontSize,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            authProvider.clearError(),
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

                          // Sign Up Link
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.noAccount,
                                style: TextStyle(
                                  fontSize: context.bodyFontSize,
                                  color: Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                child: Text(
                                  l10n.signUp,
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
