import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;

  const AuthScreen({Key? key, this.isLogin = true}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _firstNameController.clear();
      _lastNameController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _contactController.clear();
      _locationController.clear();
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _login();
      } else {
        await _register();
      }
    } catch (e) {
      print('Error caught: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    try {
      print('Attempting login with:');
      print('Username: ${_usernameController.text}');
      print('Password: ${_passwordController.text}');

      final response = await http.post(
        Uri.parse('http://13.217.166.111:8080/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');
        final userName = data['userName'] ?? _usernameController.text;
        print('Using userName: $userName');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              userName: userName,
              onLogout: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              ),
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
      } else {
        throw Exception('Login failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> _register() async {
    try {
      print('Attempting registration with:');
      print('First Name: ${_firstNameController.text}');
      print('Last Name: ${_lastNameController.text}');
      print('Email: ${_usernameController.text}');
      print('Password: ${_passwordController.text}');
      print('Contact: ${_contactController.text}');
      print('Location: ${_locationController.text}');

      final response = await http.post(
        Uri.parse('http://13.217.166.111:8080/api/users/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _usernameController.text,
          'password': _passwordController.text,
          'contact': _contactController.text,
          'location': _locationController.text,
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');
        final userName = data['userName'] ?? '${_firstNameController.text} ${_lastNameController.text}';
        print('Using userName: $userName');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              userName: userName,
              onLogout: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              ),
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      } else {
        throw Exception('Registration failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1B5E20), const Color(0xFFFBC02D)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Join Banana_Assist',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 10, color: Colors.black38, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isLogin ? 'Sign in to continue' : 'Start growing smarter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              _buildTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                icon: Icons.person_outline,
                                validator: (value) =>
                                value!.isEmpty ? 'Enter your first name' : null,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                icon: Icons.person_outline,
                                validator: (value) =>
                                value!.isEmpty ? 'Enter your last name' : null,
                              ),
                              const SizedBox(height: 10),
                            ],
                            _buildTextField(
                              controller: _usernameController,
                              label: _isLogin ? 'Username' : 'Email',
                              icon: _isLogin ? Icons.person : Icons.email,
                              validator: (value) => value!.isEmpty
                                  ? _isLogin
                                  ? 'Enter your username'
                                  : 'Enter your email'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock,
                              obscureText: !_isPasswordVisible,
                              validator: (value) =>
                              value!.isEmpty ? 'Enter your password' : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 20,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 10),
                              _buildTextField(
                                controller: _contactController,
                                label: 'Contact (+256...)',
                                icon: Icons.phone,
                                validator: (value) =>
                                value!.isEmpty ? 'Enter your contact' : null,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                controller: _locationController,
                                label: 'Location',
                                icon: Icons.location_on,
                                validator: (value) =>
                                value!.isEmpty ? 'Enter your location' : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildButton(
                        text: _isLogin ? 'Sign In' : 'Sign Up',
                        onPressed: _submit,
                        color: const Color(0xFFB71C1C),
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: Icons.facebook,
                            color: const Color(0xFF1877F2),
                            onPressed: () {
                              print('Signing in with Facebook');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainScreen(
                                    userName: 'Facebook User',
                                    onLogout: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                          _buildSocialButton(
                            icon: Icons.message,
                            color: const Color(0xFF1DA1F2),
                            onPressed: () {
                              print('Signing in with Twitter');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainScreen(
                                    userName: 'Twitter User',
                                    onLogout: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(
                          _isLogin ? 'Create an account' : 'Already have an account? Sign In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'By signing up, you agree to our terms',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      // Removed the extra SizedBox(height: 20) here
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white, size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.3), size.width * 0.25, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), size.width * 0.2, paint);

    final Paint leafPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Path leafPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.55, size.width * 0.4, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.8, size.width * 0.15, size.height * 0.75);
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}