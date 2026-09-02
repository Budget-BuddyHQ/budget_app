import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Persistent state variables so calculations remain saved when closed
String _savedDisplay = '0';
double _savedFirstOperand = 0;
String _savedOperator = '';
bool _savedShouldResetDisplay = false;

class BasicCalculatorDialog extends StatefulWidget {
  const BasicCalculatorDialog({super.key});

  @override
  State<BasicCalculatorDialog> createState() => _BasicCalculatorDialogState();
}

class _BasicCalculatorDialogState extends State<BasicCalculatorDialog> {
  late String _display = _savedDisplay;
  late double _firstOperand = _savedFirstOperand;
  late String _operator = _savedOperator;
  late bool _shouldResetDisplay = _savedShouldResetDisplay;

  Offset _position = const Offset(0, 0);
  bool _isPositionInitialized = false;

  void _updatePersistentState() {
    _savedDisplay = _display;
    _savedFirstOperand = _firstOperand;
    _savedOperator = _operator;
    _savedShouldResetDisplay = _shouldResetDisplay;
  }

  void _onNumberTap(String value) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = value;
        _shouldResetDisplay = false;
      } else {
        _display += value;
      }
      _updatePersistentState();
    });
  }

  void _onOperatorTap(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _shouldResetDisplay = true;
      _updatePersistentState();
    });
  }

  void _onCalculate() {
    if (_operator.isEmpty) return;
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case '×':
        result = _firstOperand * secondOperand;
        break;
      case '÷':
        result = secondOperand != 0 ? _firstOperand / secondOperand : 0;
        break;
    }

    setState(() {
      _display = result % 1 == 0
          ? result.toInt().toString()
          : result.toStringAsFixed(2);
      _operator = '';
      _shouldResetDisplay = true;
      _updatePersistentState();
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _firstOperand = 0;
      _operator = '';
      _shouldResetDisplay = false;
      _updatePersistentState();
    });
  }

  Widget _buildButton(
    String label, {
    Color? color,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color ?? const Color(0xFF1E3E33),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.pixelifySans(
              color: textColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Center starting position on first load
    if (!_isPositionInitialized) {
      _position = Offset(
        (screenSize.width - 280) / 2,
        (screenSize.height - 380) / 2,
      );
      _isPositionInitialized = true;
    }

    final buttons = [
      ('C', const Color(0xFFFF6B6B), Colors.white, _onClear),
      ('÷', const Color(0xFFFFB84D), const Color(0xFF3A2400), () => _onOperatorTap('÷')),
      ('×', const Color(0xFFFFB84D), const Color(0xFF3A2400), () => _onOperatorTap('×')),
      ('-', const Color(0xFFFFB84D), const Color(0xFF3A2400), () => _onOperatorTap('-')),
      ('7', null, null, () => _onNumberTap('7')),
      ('8', null, null, () => _onNumberTap('8')),
      ('9', null, null, () => _onNumberTap('9')),
      ('+', const Color(0xFFFFB84D), const Color(0xFF3A2400), () => _onOperatorTap('+')),
      ('4', null, null, () => _onNumberTap('4')),
      ('5', null, null, () => _onNumberTap('5')),
      ('6', null, null, () => _onNumberTap('6')),
      ('=', const Color(0xFF85EFAC), const Color(0xFF062C21), _onCalculate),
      ('1', null, null, () => _onNumberTap('1')),
      ('2', null, null, () => _onNumberTap('2')),
      ('3', null, null, () => _onNumberTap('3')),
      ('0', null, null, () => _onNumberTap('0')),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss when tapping outside the dialog
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _position += details.delta;
                });
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A21),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x5585EFAC)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calculate_rounded,
                                color: Color(0xFF85EFAC),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Calculator',
                                style: GoogleFonts.pixelifySans(
                                  color: const Color(0xFF85EFAC),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071711),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x3385EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_operator.isNotEmpty)
                              Text(
                                '$_firstOperand $_operator',
                                style: GoogleFonts.quicksand(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              _display,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.pixelifySans(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: buttons.length,
                        itemBuilder: (context, index) {
                          final btn = buttons[index];
                          return _buildButton(
                            btn.$1,
                            color: btn.$2,
                            textColor: btn.$3,
                            onTap: btn.$4,
                          );
                        },
                      ),
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
