import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonPaymentPinPage extends StatefulWidget {
  const PersonPaymentPinPage({
    super.key,
    required this.debtId,
    this.userId = '',
    this.note = '',
  });

  final String debtId;
  final String userId;
  final String note;

  @override
  State<PersonPaymentPinPage> createState() => _PersonPaymentPinPageState();
}

class _PersonPaymentPinPageState extends State<PersonPaymentPinPage> {
  static const Color _primary = Color(0xFF8D000B);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6F5555);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _pinBorder = Color(0xFFE4C5C5);

  String _pin = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _storedPin;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSecurityPin();
  }

  Future<void> _loadSecurityPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String userId = await _resolveCurrentUserId();
      final Map<String, dynamic>? profile = await Supabase.instance.client
          .from('profiles')
          .select('id,email,pin_created,pin_hash')
          .eq('id', userId)
          .maybeSingle();

      final String pin = (profile?['pin_hash'] ?? '').toString();
      if (profile == null || pin.isEmpty) {
        throw const _PinException(
          'PIN keamanan belum dibuat. Buat PIN dari pengaturan akun terlebih dahulu.',
        );
      }

      if (!mounted) return;
      setState(() {
        _storedPin = pin;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _readError(error);
      });
    }
  }

  Future<String> _resolveCurrentUserId() async {
    if (_isUuid(widget.userId)) return widget.userId;

    final String? authUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_isUuid(authUserId ?? '')) return authUserId!;

    final Map<String, dynamic>? row = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .limit(1)
        .maybeSingle();
    final String profileId = (row?['id'] ?? '').toString();
    if (_isUuid(profileId)) return profileId;

    throw const _PinException('Session tidak ditemukan. Silakan login ulang.');
  }

  void _addDigit(String digit) {
    if (_isSubmitting || _pin.length >= 4) return;
    setState(() => _pin += digit);
  }

  void _removeDigit() {
    if (_isSubmitting || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _confirmPayment() async {
    if (_isSubmitting) return;
    if (_pin.length < 4) {
      _showMessage('Masukkan 4 digit PIN keamanan.');
      return;
    }

    if (_pin != _storedPin) {
      setState(() => _pin = '');
      _showMessage('PIN salah. Coba lagi.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String now = DateTime.now().toUtc().toIso8601String();
      await Supabase.instance.client
          .from('personal_expense_debts')
          .update(<String, dynamic>{
            'status': 'paid',
            'paid_at': now,
            'updated_at': now,
            if (widget.note.trim().isNotEmpty) 'note': widget.note.trim(),
          })
          .eq('id', widget.debtId)
          .select('id')
          .single();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(_readError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _errorMessage != null
            ? _PinErrorState(message: _errorMessage!, onRetry: _loadSecurityPin)
            : Column(
                children: <Widget>[
                  const _PinHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 72, 32, 24),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'Masukkan PIN Keamanan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 76),
                          _PinDots(length: _pin.length),
                          const SizedBox(height: 38),
                          TextButton(
                            onPressed: () => _showMessage(
                              'Gunakan menu profil untuk membuat atau mengganti PIN.',
                            ),
                            child: const Text(
                              'Lupa PIN?',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 58),
                          _NumberPad(
                            onDigit: _addDigit,
                            onBackspace: _removeDigit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _PinSubmitBar(
                    isLoading: _isSubmitting,
                    onConfirm: _confirmPayment,
                  ),
                ],
              ),
      ),
    );
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _readError(Object error) {
    final String message = error.toString();
    if (error is _PinException) return error.message;
    if (message.contains('pin_hash') || message.contains('PGRST204')) {
      return 'Kolom pin_hash belum ada di tabel profiles.';
    }
    if (message.contains('row-level security') || message.contains('42501')) {
      return 'Policy Supabase belum mengizinkan validasi PIN atau update pembayaran.';
    }
    return 'Gagal memproses pembayaran: $error';
  }
}

class _PinHeader extends StatelessWidget {
  const _PinHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back,
                color: _PersonPaymentPinPageState._ink,
              ),
              iconSize: 30,
            ),
          ),
          const Text(
            'SplitSync',
            style: TextStyle(
              color: _PersonPaymentPinPageState._primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length});

  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int index = 0; index < 4; index++)
          Container(
            width: 23,
            height: 23,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < length
                  ? _PersonPaymentPinPageState._primary
                  : Colors.transparent,
              border: Border.all(
                color: _PersonPaymentPinPageState._pinBorder,
                width: 2.3,
              ),
            ),
          ),
      ],
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final List<String> keys = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      'backspace',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 30,
        crossAxisSpacing: 32,
      ),
      itemBuilder: (BuildContext context, int index) {
        final String key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        if (key == 'backspace') {
          return Center(
            child: IconButton(
              onPressed: onBackspace,
              icon: const Icon(
                Icons.backspace_outlined,
                color: _PersonPaymentPinPageState._muted,
                size: 34,
              ),
            ),
          );
        }
        return _NumberButton(value: key, onTap: () => onDigit(key));
      },
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              color: _PersonPaymentPinPageState._ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinSubmitBar extends StatelessWidget {
  const _PinSubmitBar({required this.isLoading, required this.onConfirm});

  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      color: _PersonPaymentPinPageState._surface,
      child: SizedBox(
        width: double.infinity,
        height: 62,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: _PersonPaymentPinPageState._primary,
            disabledBackgroundColor: _PersonPaymentPinPageState._primary
                .withValues(alpha: 0.55),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(36),
            ),
          ),
          iconAlignment: IconAlignment.end,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send_outlined, size: 22),
          label: Text(
            isLoading ? 'Memproses...' : 'Confirmasi pembayaran',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _PinErrorState extends StatelessWidget {
  const _PinErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.lock_outline,
              color: _PersonPaymentPinPageState._primary,
              size: 38,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _PersonPaymentPinPageState._muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _PinException implements Exception {
  const _PinException(this.message);

  final String message;

  @override
  String toString() => message;
}
