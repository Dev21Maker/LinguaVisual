import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../services/auth_service.dart'; // REMOVE - Accessed via provider
import 'signup_screen.dart'; // RE-ADD - For SignUpScreen navigation
import 'package:firebase_auth/firebase_auth.dart'; // Keep for exception handling
import '../../services/keep_signed_in_service.dart'; // RE-ADD for keep signed in functionality
import '../../providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Added this import

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.showDeleteDialog = false,  
  });

  final bool showDeleteDialog;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _keepSignedIn = true; // RE-ADD state for checkbox
  final _keepSignedInService = KeepSignedInService(); // RE-ADD service instance

  @override
  void initState() {
    super.initState();
    
    // Show success message after the first frame is rendered
    if (widget.showDeleteDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }
  }
  
  // Show a success dialog instead of a snackbar for better visibility
  void _showSuccessDialog() {
    if (!mounted) return;
    
    // Show a success banner at the top of the screen
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Success', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Account deleted successfully',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await _keepSignedInService.setKeepSignedIn(_keepSignedIn); // RE-ADD saving the preference
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(), 
        keepLoggedIn: _keepSignedIn, // Use the state variable
      );
      // No need to navigate here as the StreamBuilder in MyApp 
      // will automatically handle navigation when auth state changes
      
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? AppLocalizations.of(context)!.loginAuthError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginUnexpectedError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeInImage(
              placeholder: const AssetImage('assets/images/placeholder_login_bg.png'), 
              image: const AssetImage('assets/images/login_background.png'),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300), 
              fadeOutDuration: const Duration(milliseconds: 100), 
              // Optional: if your placeholder is not the exact same size/aspect ratio
              // placeholderFit: BoxFit.cover, 
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40), 
                      const Text(
                        "Welcome to\n Languador", 
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.black), // Added this line
                        decoration: InputDecoration(
                          hintText: "Email", 
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 25.0),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.loginEmailEmptyValidation;
                          }
                          if (!value.contains('@')) {
                            return l10n.loginEmailInvalidValidation;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.black), // Added this line
                        decoration: InputDecoration(
                          hintText: "Password", 
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[700]),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 25.0),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.loginPasswordEmptyValidation;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20), // Spacing before Keep me signed in
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Theme(
                            data: ThemeData(unselectedWidgetColor: Colors.white70), // Make checkbox border white when unchecked
                            child: Checkbox(
                              value: _keepSignedIn,
                              onChanged: (value) {
                                setState(() {
                                  _keepSignedIn = value ?? true;
                                });
                              },
                              activeColor: Colors.blue, // Color when checked
                              checkColor: Colors.white, // Color of the check mark
                            ),
                          ),
                          GestureDetector(
                             onTap: () {
                                setState(() {
                                  _keepSignedIn = !_keepSignedIn;
                                });
                              },
                            child: Text(
                              l10n.loginKeepSignedIn, // Using localization
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                          const Spacer(), // Pushes checkbox and text to the left if Row is stretched
                        ],
                      ),
                      const SizedBox(height: 30), // Spacing after Keep me signed in, before Login button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent, 
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Login", 
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        icon: SvgPicture.asset(
                          'assets/images/google_icon.svg', 
                          height: 22.0,
                          width: 22.0,
                        ),
                        label: const Text(
                          "Sign in with Google", 
                          style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(vertical: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!mounted) return;
                                setState(() => _isLoading = true);
                                final l10n = AppLocalizations.of(context)!; // Ensure l10n is accessible

                                try {
                                  final authService = ref.read(authServiceProvider);
                                  final userCredential = await authService.signInWithGoogle();

                                  if (userCredential != null && userCredential.user != null) {
                                    // Sign-in successful, navigation handled by auth state stream
                                    // No specific action needed here if login screen will be replaced
                                  } else {
                                    // User cancelled or a non-exception failure
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.loginGoogleSignInCancelled)),
                                      );
                                    }
                                  }
                                } on FirebaseAuthException catch (e) {
                                  if (mounted) {
                                    String errorMessage = l10n.loginAuthError;
                                    if (e.code == 'account-exists-with-different-credential') {
                                      errorMessage = l10n.loginGoogleAccountExists;
                                    } else if (e.code == 'invalid-credential') {
                                      errorMessage = l10n.loginGoogleInvalidCredential;
                                    } // Add more specific firebase auth error codes as needed
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Catch-all for other errors (network, plugin issues)
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.loginGoogleSignInFailed),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 20), 
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.loginSignUpPrompt, 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 30), 
                    ],
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
