import 'package:flutter/material.dart';

import '../../services/identity_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _identity = IdentityService.instance;

  String _display = '0';
  String _expression = '';

  final List<String> _buttons = const [
    'C', '⌫', '/', '*',
    '7', '8', '9', '-',
    '4', '5', '6', '+',
    '1', '2', '3', '.',
    '0', '00', '=', '',
  ];

  void _onTap(String value) async {
    if (value.isEmpty) return;

    if (value == 'C') {
      setState(() {
        _display = '0';
        _expression = '';
      });
      return;
    }

    if (value == '⌫') {
      setState(() {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
        } else {
          _display = '0';
        }
      });
      return;
    }

    if (value == '=') {
      final candidate = '${_expression.trim()}=';
      final unlock = await _identity.validateSecretCode(candidate);

      if (unlock) {
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      final result = _evaluate(_expression);
      setState(() {
        _display = result;
        _expression = result == 'Error' ? '' : result;
      });
      return;
    }

    setState(() {
      if (_display == '0' && value != '.') {
        _expression = value;
      } else {
        _expression += value;
      }
      _display = _expression;
    });
  }

  String _evaluate(String expression) {
    try {
      final tokens = _tokenize(expression);
      final output = <String>[];
      final ops = <String>[];

      int precedence(String op) => (op == '+' || op == '-') ? 1 : 2;

      for (final token in tokens) {
        if (_isNumber(token)) {
          output.add(token);
        } else {
          while (ops.isNotEmpty &&
              precedence(ops.last) >= precedence(token)) {
            output.add(ops.removeLast());
          }
          ops.add(token);
        }
      }

      while (ops.isNotEmpty) {
        output.add(ops.removeLast());
      }

      final stack = <double>[];
      for (final token in output) {
        if (_isNumber(token)) {
          stack.add(double.parse(token));
        } else {
          if (stack.length < 2) return 'Error';
          final b = stack.removeLast();
          final a = stack.removeLast();
          switch (token) {
            case '+':
              stack.add(a + b);
              break;
            case '-':
              stack.add(a - b);
              break;
            case '*':
              stack.add(a * b);
              break;
            case '/':
              if (b == 0) return 'Error';
              stack.add(a / b);
              break;
          }
        }
      }

      if (stack.length != 1) return 'Error';

      final value = stack.single;
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    } catch (_) {
      return 'Error';
    }
  }

  List<String> _tokenize(String exp) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < exp.length; i++) {
      final ch = exp[i];
      if ('0123456789.'.contains(ch)) {
        buffer.write(ch);
      } else if ('+-*/'.contains(ch)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(ch);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  bool _isNumber(String value) {
    return double.tryParse(value) != null;
  }

  Widget _calcButton(String text) {
    final isOperator = '/-*+='.contains(text) || text == '⌫' || text == 'C';

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 64,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isOperator ? Colors.white12 : Colors.white10,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: () => _onTap(text),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleButtons = _buttons.where((e) => e.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Standard Calculator',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _display,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: visibleButtons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                return _calcButton(visibleButtons[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}