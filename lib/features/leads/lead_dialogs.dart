import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../animations/animations.dart';
import '../../core/api/crm_session.dart';
import '../../core/theme/app_colors.dart';
import 'lead.dart';
import 'lead_details_dialog.dart';
import 'leads_store.dart';

Future<Lead?> showLeadForm(BuildContext context, {Lead? lead}) {
  return Navigator.of(
    context,
  ).push<Lead>(SlideUpRoute(builder: (context) => LeadFormDialog(lead: lead)));
}

Future<void> showLeadDetails(BuildContext context, Lead lead) {
  return Navigator.of(context).push<void>(
    SlideUpRoute(builder: (context) => LeadDetailsDialog(lead: lead)),
  );
}

Future<bool> confirmDeleteLead(BuildContext context, Lead lead) async {
  final palette = AppPalette.of(context);
  final result = await Navigator.of(context).push<bool>(
    SlideUpRoute(
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar lead'),
          content: Text('Se eliminará a ${lead.fullName} del pipeline.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ScaleOnPress(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.destructive,
                  foregroundColor: palette.destructiveForeground,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ),
          ],
        );
      },
    ),
  );
  return result ?? false;
}

class LeadFormDialog extends StatefulWidget {
  const LeadFormDialog({super.key, this.lead});

  final Lead? lead;

  @override
  State<LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends State<LeadFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int _failedAttempts = 0;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _mobile;
  late final TextEditingController _web;
  late final TextEditingController _company;
  late final TextEditingController _jobTitle;
  late final TextEditingController _industry;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _stateName;
  late final TextEditingController _country;
  late final TextEditingController _postal;
  late final TextEditingController _qualification;
  late final TextEditingController _owner;
  late final TextEditingController _assignee;
  late final TextEditingController _notes;
  late LeadType _type;
  late CommercialStatus _status;
  late String _source;
  late String? _interest;

  bool get _editing => widget.lead != null;

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    _firstName = TextEditingController(text: lead?.firstName ?? '');
    _lastName = TextEditingController(text: lead?.lastName ?? '');
    _email = TextEditingController(text: lead?.email ?? '');
    _phone = TextEditingController(text: lead?.phone ?? '');
    _mobile = TextEditingController(text: lead?.mobile ?? '');
    _web = TextEditingController(text: lead?.web ?? '');
    _company = TextEditingController(text: lead?.company ?? '');
    _jobTitle = TextEditingController(text: lead?.jobTitle ?? '');
    _industry = TextEditingController(text: lead?.industry ?? '');
    _address = TextEditingController(text: lead?.address ?? '');
    _city = TextEditingController(text: lead?.city ?? '');
    _stateName = TextEditingController(text: lead?.state ?? '');
    _country = TextEditingController(text: lead?.country ?? '');
    _postal = TextEditingController(text: lead?.postal ?? '');
    _qualification = TextEditingController(text: lead?.qualification ?? '');
    _owner = TextEditingController(text: lead?.owner ?? CrmSession.owner);
    _assignee = TextEditingController(text: lead?.assignee ?? '');
    _notes = TextEditingController(text: lead?.description ?? '');
    _type = lead?.typeValue ?? LeadType.person;
    _status = lead?.statusValue ?? CommercialStatus.lead;
    _source = _initialSource(lead?.source);
    _interest = lead?.interestValue?.raw;
  }

  String _initialSource(String? source) {
    if (source == null || source.isEmpty) return leadSourceOptions.first;
    final label = sourceLabel(source);
    if (leadSourceOptions.contains(label)) return label;
    if (leadSourceOptions.contains(source)) return source;
    return source;
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _mobile,
      _web,
      _company,
      _jobTitle,
      _industry,
      _address,
      _city,
      _stateName,
      _country,
      _postal,
      _qualification,
      _owner,
      _assignee,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _failedAttempts++);
      return;
    }
    final now = timestampNow();
    final current = widget.lead;
    final lead = Lead(
      id: current?.id ?? newLeadId(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      mobile: _mobile.text.trim(),
      company: _company.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      industry: _industry.text.trim(),
      web: _web.text.trim(),
      city: _city.text.trim(),
      state: _stateName.text.trim(),
      country: _country.text.trim(),
      address: _address.text.trim(),
      postal: _postal.text.trim(),
      description: _notes.text.trim(),
      source: _source,
      interest: _interest ?? '',
      qualification: _qualification.text.trim(),
      commercialStatus: _status.raw,
      stage: current?.stage ?? LeadStage.notContacted.raw,
      type: _type.raw,
      owner: _owner.text.trim(),
      assignee: _assignee.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    Navigator.pop(context, lead);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final sources = [
      ...leadSourceOptions,
      if (!leadSourceOptions.contains(_source)) _source,
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: palette.primary.withValues(alpha: 0.16),
                    child: Icon(Icons.person_add_alt_1, color: palette.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editing ? 'Editar lead' : 'Crear lead',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _editing
                              ? 'Actualiza los datos del contacto.'
                              : 'Añade un nuevo lead a tu pipeline.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.border),
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: staggerWidgets(
                    begin: const Offset(-0.7, 0),
                    step: const Duration(milliseconds: 50),
                    maxSteps: 8,
                    [
                      _pair(
                        wide,
                        _dropdown<LeadType>(
                          label: 'Tipo',
                          value: _type,
                          items: LeadType.values,
                          itemLabel: (item) => item.label,
                          onChanged: (value) => setState(() => _type = value),
                        ),
                        _dropdown<CommercialStatus>(
                          label: 'Estado comercial',
                          value: _status,
                          items: CommercialStatus.values,
                          itemLabel: (item) => item.label,
                          onChanged: (value) => setState(() => _status = value),
                        ),
                      ),
                      _pair(
                        wide,
                        _field(
                          _firstName,
                          'Nombre',
                          required: true,
                          key: const Key('lead-first-name'),
                        ),
                        _field(
                          _lastName,
                          'Apellidos',
                          required: true,
                          key: const Key('lead-last-name'),
                        ),
                      ),
                      _pair(
                        wide,
                        _field(
                          _email,
                          'Email',
                          required: true,
                          keyboard: TextInputType.emailAddress,
                          key: const Key('lead-email'),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return 'El email es obligatorio';
                            if (!text.contains('@')) return 'Email no válido';
                            return null;
                          },
                        ),
                        _field(
                          _phone,
                          'Teléfono',
                          keyboard: TextInputType.phone,
                        ),
                      ),
                      _pair(
                        wide,
                        _field(_mobile, 'Móvil', keyboard: TextInputType.phone),
                        _field(_web, 'Web', keyboard: TextInputType.url),
                      ),
                      _pair(
                        wide,
                        _field(_company, 'Empresa'),
                        _field(_jobTitle, 'Cargo'),
                      ),
                      _field(_industry, 'Industria'),
                      _field(_address, 'Dirección'),
                      _pair(
                        wide,
                        _field(_city, 'Ciudad'),
                        _field(_stateName, 'Estado'),
                      ),
                      _pair(
                        wide,
                        _field(_country, 'País'),
                        _field(_postal, 'C.P.'),
                      ),
                      _pair(
                        wide,
                        _dropdown<String>(
                          label: 'Origen',
                          value: _source,
                          items: sources,
                          itemLabel: (item) => item,
                          onChanged: (value) => setState(() => _source = value),
                        ),
                        _dropdown<String?>(
                          label: 'Interés',
                          value: _interest,
                          items: const [null, 'bajo', 'medio', 'alto'],
                          itemLabel: (item) => item == null
                              ? 'Selecciona...'
                              : LeadInterest.parse(item)!.label,
                          onChanged: (value) =>
                              setState(() => _interest = value),
                        ),
                      ),
                      _pair(
                        wide,
                        _field(_qualification, 'Calificación'),
                        _field(_owner, 'Propietario'),
                      ),
                      _field(_assignee, 'Responsable'),
                      _field(_notes, 'Notas', maxLines: 3),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  Shake(
                    trigger: _failedAttempts,
                    child: ScaleOnPress(
                      child: FilledButton(
                        key: const Key('lead-save'),
                        onPressed: _save,
                        child: Text(_editing ? 'Guardar' : 'Crear lead'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pair(bool wide, Widget left, Widget right) {
    if (!wide) {
      return Column(children: [left, right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    Key? key,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        validator:
            validator ??
            (required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label es obligatorio';
                    }
                    return null;
                  }
                : null),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(itemLabel(item))),
        ],
        onChanged: (next) {
          if (next != null || null is T) onChanged(next as T);
        },
      ),
    );
  }
}
