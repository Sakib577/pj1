import 'package:flutter/material.dart';

/// Shows a full-screen PIN entry sheet with a dot display and numpad.
///
/// The user enters a 4-digit PIN. When [confirm] is true the sheet first asks
/// for the new PIN and then asks again to confirm; a mismatch resets the flow.
/// Pops with the confirmed PIN (or `null` if the sheet is dismissed).
///
/// [cancelLabel] replaces the default back button label (used for the unlock
/// screen where the user can back out).
Future<String?> showPinEntrySheet(
  BuildContext context, {
  required String title,
  bool confirmPin = false,
  String cancelLabel = 'Cancel',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: !confirmPin,
    builder: (_) => PinEntrySheet(
      title: title,
      confirmPin: confirmPin,
      cancelLabel: cancelLabel,
    ),
  );
}

class PinEntrySheet extends StatefulWidget {
  const PinEntrySheet({
    super.key,
    required this.title,
    this.confirmPin = false,
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final bool confirmPin;
  final String cancelLabel;

  @override
  State<PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends State<PinEntrySheet> {
  static const int _length = 4;

  bool _confirming = false;
  String _entry = '';
  String? _originalPin;
  String _error = '';

  void _onDigit(String digit) {
    if (_entry.length >= _length) return;
    setState(() {
      _error = '';
      _entry += digit;
      if (_entry.length == _length) {
        if (widget.confirmPin && !_confirming) {
          _originalPin = _entry;
          _entry = '';
          _confirming = true;
        } else if (widget.confirmPin) {
          if (_entry == _originalPin) {
            Navigator.of(context).pop(_entry);
          } else {
            _error = 'PINs did not match. Try again.';
            _originalPin = null;
            _confirming = false;
            _entry = '';
          }
        } else {
          Navigator.of(context).pop(_entry);
        }
      }
    });
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() {
      _error = '';
      _entry = _entry.substring(0, _entry.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.confirmPin
        ? (_confirming ? 'Confirm your PIN' : 'Set your PIN')
        : widget.title;

    return Dialog(
      backgroundColor: const Color(0xFFFFFCF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.confirmPin
                  ? 'Choose a 4-digit code to protect your data.'
                  : 'Enter your 4-digit PIN to continue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _Dots(length: _length, filled: _entry.length),
            SizedBox(
              height: 18,
              child: _error.isEmpty
                  ? null
                  : Text(
                      _error,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _Numpad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                widget.cancelLabel,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.length, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFE5E0D6),
            ),
          ),
      ],
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final digit in row)
                _Key(label: digit, onTap: () => onDigit(digit)),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 72),
            _Key(label: '0', onTap: () => onDigit('0')),
            InkResponse(
              onTap: onBackspace,
              radius: 28,
              child: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.all(6),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.backspace_outlined,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F5EF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.all(6),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}