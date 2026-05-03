import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class PhoneVerificationArgs {
  const PhoneVerificationArgs({
    required this.name,
    required this.email,
    required this.phone,
    required this.verificationId,
  });

  final String name;
  final String email;
  final String phone;
  final String verificationId;
}

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key, required this.args});

  final PhoneVerificationArgs args;

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  late String _verificationId = widget.args.verificationId;
  bool _isLoading = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      await ref.read(authNotifierProvider.notifier).signUp(
            name: widget.args.name,
            email: widget.args.email,
            phone: widget.args.phone,
          );

      if (!mounted) return;
      context.go(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'invalid-verification-code'
          ? 'Código inválido. Verifique e tente novamente.'
          : 'Erro na verificação. Tente novamente.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.args.phone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Erro ao reenviar código.')),
          );
        },
        codeSent: (newVerificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = newVerificationId;
            _isLoading = false;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(28, 8, 28, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('Verificar número', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Enviamos um código SMS para ${widget.args.phone}',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 40),

            // ── OTP input ────────────────────────────────────────────────────
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: theme.textTheme.headlineMedium,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '------',
                counterText: '',
              ),
              onFieldSubmitted: (_) => _verify(),
              onChanged: (v) {
                if (v.length == 6) _verify();
              },
            ),

            const SizedBox(height: 32),

            // ── Verify button ────────────────────────────────────────────────
            FilledButton(
              onPressed: _isLoading ? null : _verify,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verificar'),
            ),

            const SizedBox(height: 16),

            // ── Resend ───────────────────────────────────────────────────────
            Center(
              child: _resendSeconds > 0
                  ? Text(
                      'Reenviar código em ${_resendSeconds}s',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    )
                  : TextButton(
                      onPressed: _isLoading ? null : _resend,
                      child: const Text('Reenviar código'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
