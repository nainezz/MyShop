import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/http_exception.dart';
import '../providers/auth.dart';
import '../theme.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandInk,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const Column(
              children: [
                _Logo(),
                SizedBox(height: 28),
                AuthCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in [10.0, 18.0, 26.0, 34.0])
              Container(
                width: 7,
                height: h,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: brandLime,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 10),
            const Text(
              AppConfig.shopName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontFamily: 'Anton',
                letterSpacing: 1,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Quality ex-UK & ex-USA phones in Nairobi',
          style: TextStyle(color: Color(0xFF8B93A1), fontSize: 15),
        ),
      ],
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  var _mode = AuthMode.login;
  var _isLoading = false;
  var _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<Auth>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    try {
      if (_mode == AuthMode.login) {
        await auth.login(email, password);
      } else {
        await auth.signup(email, password);
      }
    } on HttpException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not reach the server. Check your connection and try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _switchMode() => setState(() =>
      _mode = _mode == AuthMode.login ? AuthMode.signup : AuthMode.login);

  @override
  Widget build(BuildContext context) {
    final isSignup = _mode == AuthMode.signup;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isSignup ? 'Create your account' : 'Welcome back',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignup
                      ? 'Sign up to order phones and track your orders.'
                      : 'Log in to browse phones and order.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty || !v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction:
                      isSignup ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: (_) => isSignup ? null : _submit(),
                  validator: (value) => (value ?? '').length < 6
                      ? 'Use at least 6 characters.'
                      : null,
                ),
                if (isSignup) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => value != _passwordController.text
                        ? 'Passwords do not match.'
                        : null,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(isSignup ? 'Sign up' : 'Log in'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : _switchMode,
                  child: Text(isSignup
                      ? 'Already have an account? Log in'
                      : 'New here? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
