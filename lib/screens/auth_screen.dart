import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/firebase_config.dart';
import '../core/validation.dart';
import '../state/session_controller.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController(),
      _confirm = TextEditingController();
  bool _register = false, _obscure = true;
  @override
  void dispose() {
    for (final c in [_email, _password, _name, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final session = context.read<SessionController>();
    FocusScope.of(context).unfocus();
    await performAction(
      context,
      () => _register
          ? session.register(_name.text, _email.text, _password.text)
          : session.signIn(_email.text, _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Campus Care',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _register
                            ? 'A better campus starts with you.'
                            : 'Welcome back. Make a difference.',
                        style: const TextStyle(fontSize: 17, color: muted),
                      ),
                      const SizedBox(height: 28),
                      if (useEmulators)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Local development - no cloud charges',
                            style: TextStyle(color: brand),
                          ),
                        ),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          autofillHints: const [AutofillHints.name],
                          validator: (v) => Validation.text(v, 'Name', 2, 60),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'ALU email',
                          hintText: 'you@alustudent.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        validator: Validation.email,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autocorrect: false,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _register
                            ? Validation.password
                            : (v) => (v?.isEmpty ?? true)
                                  ? 'Enter your password.'
                                  : null,
                        textInputAction: _register
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_register && !session.busy) _submit();
                        },
                      ),
                      if (_register) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (v) => v == _password.text
                              ? null
                              : 'Passwords do not match.',
                        ),
                      ],
                      if (!_register)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: session.busy
                                ? null
                                : () => performAction(
                                    context,
                                    () => session.resetPassword(_email.text),
                                    success:
                                        'If an account exists, a password reset link has been sent.',
                                  ),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                      const SizedBox(height: 20),
                      BusyButton(
                        label: _register ? 'Create account' : 'Sign in',
                        busy: session.busy,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: session.busy
                              ? null
                              : () => setState(() {
                                  _register = !_register;
                                  _form.currentState?.reset();
                                }),
                          child: Text(
                            _register
                                ? 'Already have an account? Sign in'
                                : 'New here? Create an account',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Only verified @alustudent.com and @alueducation.com accounts can access reports. Your reports are visible to you and authorized campus staff.',
                        style: TextStyle(color: muted, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: brand,
                    size: 72,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Check your ALU inbox',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open the verification link sent to ${session.user?.email}. Then return here to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  BusyButton(
                    label: 'I have verified my email',
                    busy: session.busy,
                    onPressed: () async {
                      final ok = await performAction(context, session.refresh);
                      if (ok && context.mounted && !session.verified) {
                        showMessage(
                          context,
                          'Not verified yet. Open the email link and try again.',
                        );
                      }
                    },
                  ),
                  TextButton(
                    onPressed: session.busy
                        ? null
                        : () => performAction(
                            context,
                            session.sendVerification,
                            success: 'Verification email sent.',
                          ),
                    child: const Text('Resend verification email'),
                  ),
                  TextButton(
                    onPressed: session.busy
                        ? null
                        : () => performAction(context, session.signOut),
                    child: const Text('Use another account'),
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
