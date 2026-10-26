import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/core/api/crm_client.dart';
import 'package:future_crm/features/leads/lead.dart';
import 'package:future_crm/features/leads/leads_api.dart';
import 'package:future_crm/features/leads/leads_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'memory_leads_api.dart';
import 'sample_leads.dart';

void main() {
  group('LeadsStore', () {
    late LeadsStore store;

    setUp(() async {
      store = LeadsStore(api: MemoryLeadsApi(sampleLeads), owner: '123');
      await store.refresh();
    });

    test('loads leads and paginates', () {
      expect(store.loading, isFalse);
      expect(store.total, sampleLeads.length);
      expect(store.pageItems.length, LeadsStore.pageSize);
    });

    test('filter and query reset the page', () {
      store.setPage(1);
      store.setQuery('zzz-no-match');
      expect(store.page, 0);
      expect(store.filtered, isEmpty);
      expect(store.pageCount, 1);
    });

    test('remove deletes the lead', () async {
      final id = sampleLeads.first.id;
      expect(await store.remove(id), isNull);
      expect(store.total, sampleLeads.length - 1);
    });

    test('changeStage moves the lead to the new stage', () async {
      final id = sampleLeads.first.id;
      expect(await store.changeStage(id, LeadStage.contacted), isNull);
      expect(
        store.filtered.firstWhere((lead) => lead.id == id).stageValue,
        LeadStage.contacted,
      );
    });

    test('only contacts in the lead status are listed', () async {
      final prospect = sampleLeads.first.copyWith(
        id: 'prospect-1',
        commercialStatus: CommercialStatus.prospect.raw,
        stage: 'reunion',
      );
      final mixed = LeadsStore(
        api: MemoryLeadsApi([prospect, ...sampleLeads]),
        owner: '123',
      );
      await mixed.refresh();
      expect(mixed.total, sampleLeads.length);
      expect(mixed.filtered.any((lead) => lead.id == 'prospect-1'), isFalse);
    });

    test('changeStage on unknown id reports an error', () async {
      expect(
        await store.changeStage('missing', LeadStage.contacted),
        isNotNull,
      );
    });
  });

  group('HttpLeadsApi / CrmClient', () {
    test('maps API failures to CrmApiException', () async {
      final client = CrmClient(
        client: MockClient(
          (_) async =>
              http.Response('{"ok":false,"mensaje":"Token inválido"}', 200),
        ),
      );
      final api = HttpLeadsApi(client: client);
      expect(
        api.listContacts('123'),
        throwsA(
          isA<CrmApiException>().having(
            (e) => e.message,
            'message',
            'Token inválido',
          ),
        ),
      );
    });

    test('invalid JSON is reported with its cause', () async {
      final client = CrmClient(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );
      expect(
        client.post('contactos', {}),
        throwsA(
          isA<CrmApiException>().having(
            (e) => e.cause,
            'cause',
            isA<FormatException>(),
          ),
        ),
      );
    });

    test('sends the request names from the API spec', () async {
      final sent = <Map<String, dynamic>>[];
      final client = CrmClient(
        token: 't',
        client: MockClient((request) async {
          sent.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('{"ok":true,"datos":[]}', 200);
        }),
      );
      final api = HttpLeadsApi(client: client);
      final lead = sampleLeads.first;
      await api.listContacts('123');
      await api.create(lead);
      await api.update(lead);
      await api.updateStage(lead.id, LeadStage.contacted.raw);

      expect(sent.map((body) => body['request']), [
        'contactos',
        'crear_contacto',
        'actualizar_contacto',
        'actualizar_etapa_contacto',
      ]);
      expect(sent[0]['datos'], {'exec': 'ok'});
      expect(sent[2]['datos']['id_contacto'], lead.id);
      expect(sent[3]['datos'], {
        'id_contacto': lead.id,
        'etapa': 'abierto - contactado',
      });
    });

    test('skips deleted contacts', () async {
      final client = CrmClient(
        client: MockClient(
          (_) async => http.Response(
            '{"ok":true,"datos":[{"id":"1","eliminado":null},{"id":"2","eliminado":"2026-01-01"}]}',
            200,
          ),
        ),
      );
      final leads = await HttpLeadsApi(client: client).listContacts('123');
      expect(leads.map((l) => l.id), ['1']);
    });
  });
}
