part of 'main.dart';

const _authRedirectUrl = 'io.supabase.flutter://reset-callback/';

extension PasswordRecoveryActions on ImpactHubPageState {
  Future<void> requestPasswordReset() async {
    final email = _email.text.trim();
    final at = email.indexOf('@');
    final validEmail = at > 0 &&
        at == email.lastIndexOf('@') &&
        email.indexOf('.', at) > at + 1 &&
        !email.contains(RegExp(r'\s'));
    if (!validEmail) {
      setState(() {
        _error = 'Enter a valid email address to reset your password.';
        _notice = null;
      });
      return;
    }

    setState(() {
      _working = true;
      _error = null;
      _notice = null;
    });
    try {
      await _db.auth
          .resetPasswordForEmail(email, redirectTo: _authRedirectUrl)
          .timeout(_requestTimeout);
      _notice =
          'If an account exists for this email, a password reset link has been sent.';
    } catch (error) {
      _error = _friendly(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> showPasswordRecoveryDialog() async {
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;
    String? submitError;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Set a new password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                    validator: (value) => value == null || value.length < 8
                        ? 'Use at least 8 characters.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (value) => value != password.text
                        ? 'The passwords do not match.'
                        : null,
                  ),
                  if (submitError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          submitError!,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          saving = true;
                          submitError = null;
                        });
                        try {
                          await _db.auth
                              .updateUser(
                                UserAttributes(password: password.text),
                              )
                              .timeout(_requestTimeout);
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          setState(
                            () => _notice = 'Your password has been updated.',
                          );
                        } catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(
                              () => submitError = _friendly(error),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(() => saving = false);
                          }
                        }
                      },
                child: Text(saving ? 'Updating…' : 'Update password'),
              ),
            ],
          ),
        ),
      );
    } finally {
      password.dispose();
      confirmPassword.dispose();
    }
  }
}
