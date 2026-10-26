import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Campo de [showQuickForm]. Con [options] se muestra como selección única;
/// con [date] abre un calendario y devuelve la fecha como `AAAA-MM-DD`.
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.keyboard = TextInputType.text,
    this.required = true,
    this.options,
    this.initial = '',
    this.validator,
    this.date = false,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final TextInputType keyboard;
  final bool required;
  final List<String>? options;
  final String initial;
  final String? Function(String value)? validator;
  final bool date;
  final int maxLines;
}

/// Abre una hoja inferior con un formulario corto y devuelve los valores por
/// clave, o `null` si se cancela. Valida antes de cerrar y respeta el teclado.
Future<Map<String, String>?> showQuickForm(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  required String submitLabel,
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: AppMotion.sheet(context),
    backgroundColor: AppPalette.of(context).card,
    builder: (context) =>
        _QuickForm(title: title, fields: fields, submitLabel: submitLabel),
  );
}

class _QuickForm extends StatefulWidget {
  const _QuickForm({
    required this.title,
    required this.fields,
    required this.submitLabel,
  });

  final String title;
  final List<FieldSpec> fields;
  final String submitLabel;

  @override
  State<_QuickForm> createState() => _QuickFormState();
}

class _QuickFormState extends State<_QuickForm> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      if (f.options == null) f.key: TextEditingController(text: f.initial),
  };
  late final Map<String, String> _choices = {
    for (final f in widget.fields)
      if (f.options != null)
        f.key: f.initial.isNotEmpty ? f.initial : f.options!.first,
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FieldSpec field) async {
    final controller = _controllers[field.key]!;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: field.label,
    );
    if (picked == null || !mounted) return;
    String two(int value) => value.toString().padLeft(2, '0');
    setState(() {
      controller.text =
          '${picked.year}-${two(picked.month)}-${two(picked.day)}';
    });
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop({
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
      ..._choices,
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final field in widget.fields) ...[
                if (field.options != null)
                  _choiceField(context, field, palette)
                else
                  TextFormField(
                    key: ValueKey('field-${field.key}'),
                    controller: _controllers[field.key],
                    keyboardType: field.maxLines > 1
                        ? TextInputType.multiline
                        : field.keyboard,
                    textInputAction: field.maxLines > 1
                        ? TextInputAction.newline
                        : TextInputAction.next,
                    minLines: 1,
                    maxLines: field.maxLines,
                    readOnly: field.date,
                    onTap: field.date ? () => _pickDate(field) : null,
                    decoration: InputDecoration(
                      labelText: field.required
                          ? '${field.label} *'
                          : field.label,
                      suffixIcon: field.date ? _dateSuffix(field) : null,
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (field.required && text.isEmpty) {
                        return '${field.date ? 'Elige' : 'Escribe'} ${field.label.toLowerCase()}.';
                      }
                      return field.validator?.call(text);
                    },
                  ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 4),
              FilledButton(
                key: const ValueKey('quick-form-submit'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _submit,
                child: Text(widget.submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateSuffix(FieldSpec field) {
    final controller = _controllers[field.key]!;
    if (!field.required && controller.text.isNotEmpty) {
      return IconButton(
        tooltip: 'Quitar ${field.label.toLowerCase()}',
        icon: const Icon(Icons.close),
        onPressed: () => setState(controller.clear),
      );
    }
    return IconButton(
      tooltip: 'Elegir ${field.label.toLowerCase()}',
      icon: const Icon(Icons.calendar_today_outlined),
      onPressed: () => _pickDate(field),
    );
  }

  Widget _choiceField(
    BuildContext context,
    FieldSpec field,
    AppPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: palette.mutedForeground),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in field.options!)
              ChoiceChip(
                key: ValueKey('choice-${field.key}-$option'),
                label: Text(option),
                selected: _choices[field.key] == option,
                onSelected: (_) => setState(() => _choices[field.key] = option),
              ),
          ],
        ),
      ],
    );
  }
}

/// Porcentaje entero entre 0 y 100. Vacío es válido (campo opcional).
String? percentValue(String value) {
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 0 || parsed > 100) {
    return 'Ingresa un porcentaje entre 0 y 100.';
  }
  return null;
}

/// Validador numérico positivo para importes.
String? positiveNumber(String value) {
  final parsed = double.tryParse(value.replaceAll(',', '.'));
  if (parsed == null || parsed <= 0) {
    return 'Ingresa un importe mayor que cero.';
  }
  return null;
}
