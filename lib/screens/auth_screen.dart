import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utilities/validation.dart';
import '../data/firebase_services.dart';

class AuthScreen extends StatefulWidget {
  final bool register;
  const AuthScreen({super.key, required this.register});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool submitted = false, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      submitted = true;
      error = null;
    });
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (widget.register) {
        await FirebaseServices.auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await FirebaseServices.auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (!mounted) return;
      // Pop every public form; the root auth gate now renders List.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      if (widget.register) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
            duration: Duration(seconds: 12),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? e.code);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.register ? 'Register' : 'Login')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: form,
              autovalidateMode: submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field(email, 'Email', Validation.email),
                  field(
                    password,
                    'Password',
                    (s) => Validation.password(s, register: widget.register),
                    secret: true,
                  ),
                  if (widget.register)
                    field(
                      confirm,
                      'Confirm password',
                      (s) => Validation.confirm(s, password.text),
                      secret: true,
                    ),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      busy
                          ? 'Please wait…'
                          : widget.register
                          ? 'Register'
                          : 'Login',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
  Widget field(
    TextEditingController c,
    String label,
    String? Function(String?) validate, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      enabled: !busy,
      obscureText: secret,
      autocorrect: !secret,
      validator: validate,
      keyboardType: secret ? TextInputType.text : TextInputType.emailAddress,
      onChanged: (_) {
        if (submitted) form.currentState!.validate();
      },
      decoration: InputDecoration(labelText: label, errorMaxLines: 3),
    ),
  );
}
