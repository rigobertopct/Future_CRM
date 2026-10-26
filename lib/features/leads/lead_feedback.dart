import 'package:flutter/material.dart';

import 'lead_dialogs.dart';
import 'leads_store.dart';

Future<void> createLead(BuildContext context, LeadsStore store) async {
  final lead = await showLeadForm(context);
  if (lead == null || !context.mounted) return;
  final message = await store.add(lead);
  if (!context.mounted || message == null) return;
  showLeadMessage(context, message);
}

void reportLeadResult(BuildContext context, Future<String?> result) {
  result.then((message) {
    if (message == null || !context.mounted) return;
    showLeadMessage(context, message);
  });
}

void showLeadMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
