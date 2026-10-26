import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/core/api/crm_client.dart';
import 'package:future_crm/features/clients/clients_store.dart';
import 'package:future_crm/features/dashboard/dashboard_store.dart';
import 'package:future_crm/features/invoices/invoices_store.dart';
import 'package:future_crm/features/opportunities/opportunities_store.dart';
import 'package:future_crm/features/settings/settings_store.dart';
import 'package:future_crm/features/tasks/tasks_store.dart';

import 'memory_opportunities_api.dart';

void main() {
  group('OpportunitiesStore', () {
    Future<OpportunitiesStore> loaded([MemoryOpportunitiesApi? api]) async {
      final store = OpportunitiesStore(api: api ?? MemoryOpportunitiesApi());
      await store.refresh();
      return store;
    }

    test('loads every contact\'s opportunities', () async {
      final store = await loaded();
      expect(store.loading, isFalse);
      expect(store.error, isNull);
      expect(store.all.length, sampleOpportunities().length);
      expect(store.contacts.length, sampleContacts.length);
    });

    test('a failing contact keeps the rest and reports it', () async {
      final store = await loaded(
        MemoryOpportunitiesApi(failingContacts: {'c-1'}),
      );
      expect(store.all.any((o) => o.contactId == 'c-1'), isFalse);
      expect(store.all, isNotEmpty);
      expect(store.error, 'Algunas oportunidades no se pudieron cargar');
    });

    test('filters by stage and by search text', () async {
      final store = await loaded();
      final total = store.countFor(null);

      store.setStageFilter(OpportunityStage.won);
      expect(store.visible, isNotEmpty);
      expect(
        store.visible.every((o) => o.stage == OpportunityStage.won),
        isTrue,
      );

      store.setStageFilter(null);
      store.setQuery('nexora');
      expect(store.visible.map((o) => o.company).toSet(), {'Nexora Labs'});

      store.setQuery('inés');
      expect(store.visible.every((o) => o.contactId == 'c-3'), isTrue);

      store.setQuery('');
      expect(store.visible.length, total);
    });

    test('advance sends the next stage and refuses closed ones', () async {
      final api = MemoryOpportunitiesApi();
      final store = await loaded(api);

      expect(await store.advance('op-5'), isNull);
      expect(
        store.all.firstWhere((o) => o.id == 'op-5').stage,
        OpportunityStage.qualified,
      );
      expect(api.stageRequests, ['op-5:calificada']);

      final won = store.all.firstWhere((o) => o.stage == OpportunityStage.won);
      expect(store.advance(won.id), isNull);
    });

    test('a rejected stage change is rolled back', () async {
      final store = await loaded(
        MemoryOpportunitiesApi(failStageChanges: true),
      );

      final error = await store.setStage('op-5', OpportunityStage.won);

      expect(error, 'No se pudo guardar la etapa');
      expect(
        store.all.firstWhere((o) => o.id == 'op-5').stage,
        OpportunityStage.open,
      );
    });

    test('add creates a new opportunity and updates the totals', () async {
      final store = await loaded();
      final before = store.openValue;

      final error = await store.add(
        const OpportunityDraft(
          contactId: 'c-2',
          name: 'Piloto',
          company: 'Acme',
          amount: 10000,
        ),
      );

      expect(error, isNull);
      final created = store.all.firstWhere((o) => o.name == 'Piloto');
      expect(created.stage, OpportunityStage.open);
      expect(store.openValue, before + 10000);
    });

    test('remove deletes it', () async {
      final store = await loaded();
      expect(await store.remove('op-1'), isNull);
      expect(store.all.any((o) => o.id == 'op-1'), isFalse);
    });

    test('edit saves the fields and reloads the contact', () async {
      final store = await loaded();
      final item = store.all.firstWhere((o) => o.id == 'op-5');

      final error = await store.edit(
        item.copyWith(
          name: 'Portal renovado',
          amount: 70000,
          paymentType: PaymentType.monthly,
          closeDate: () => null,
        ),
      );

      expect(error, isNull);
      final fresh = store.all.firstWhere((o) => o.id == 'op-5');
      expect(fresh.name, 'Portal renovado');
      expect(fresh.amount, 70000);
      expect(fresh.paymentType, PaymentType.monthly);
      expect(fresh.closeDate, isNull);
    });

    test('stage notes end up in the history, newest first', () async {
      final store = await loaded();
      await store.setStage('op-5', OpportunityStage.qualified, note: 'Llamada');
      await store.setStage('op-5', OpportunityStage.meeting);

      final history = await store.history('op-5');
      expect(history.map((e) => e.stage), [
        OpportunityStage.meeting,
        OpportunityStage.qualified,
      ]);
      expect(history.last.note, 'Llamada');
    });

    test('history errors reach the caller', () async {
      final api = MemoryOpportunitiesApi()..failHistory = true;
      final store = await loaded(api);
      expect(store.history('op-5'), throwsA(isA<CrmApiException>()));
    });

    test('sorts by close date when asked', () async {
      final store = await loaded()
        ..setSort(OpportunitySort.closeDate);
      final dates = store.visible.map((o) => o.closeDate!).toList();
      expect(dates, [...dates]..sort());
    });
  });

  group('Opportunity JSON', () {
    test('parses the API record and its text numbers', () {
      final item = Opportunity.fromJson({
        'id': '1a83',
        'contacto': 'c-9',
        'nombre': 'App móvil',
        'empresa': 'Oakhaven',
        'etapa': 'reunion',
        'valor': '11000',
        'probabilidad': '40',
        'responsable': 'juan',
        'cierre': null,
      });
      expect(item.stage, OpportunityStage.meeting);
      expect(item.amount, 11000);
      expect(item.chance, 0.4);
      expect(item.closeDate, isNull);
    });

    test('empty probability falls back to the stage', () {
      final item = Opportunity.fromJson({
        'etapa': 'propuesta',
        'valor': '',
        'probabilidad': '',
      });
      expect(item.amount, 0);
      expect(item.chance, OpportunityStage.proposal.probability);
    });

    test('update omits an empty close date', () {
      final item = Opportunity.fromJson({
        'id': 'x',
        'nombre': 'A',
        'etapa': 'nueva',
        'valor': '1500',
        'cierre': '2026-12-31 00:00:00',
        'tipo_pago': 'pago anual',
      });
      expect(item.paymentType, PaymentType.yearly);
      expect(item.toUpdateDatos()['cierre'], '2026-12-31');
      expect(item.toUpdateDatos()['id_oportunidad'], 'x');

      final cleared = item.copyWith(closeDate: () => null);
      expect(cleared.toUpdateDatos().containsKey('cierre'), isFalse);
      expect(cleared.toUpdateDatos()['probabilidad'], '');
    });

    test('pipeline entries ignore the numeric duplicate keys', () {
      final entry = PipelineEntry.fromJson({
        'id': '9d87',
        '0': '9d87',
        'etapa': 'calificada',
        '2': 'calificada',
        'nota': '',
        'creado': '2026-10-24 22:55:23',
      });
      expect(entry.stage, OpportunityStage.qualified);
      expect(entry.note, '');
      expect(entry.at, DateTime(2026, 10, 24, 22, 55, 23));
    });

    test('draft sends the required fields', () {
      const draft = OpportunityDraft(
        contactId: 'c-1',
        name: 'Piloto',
        company: 'Acme',
        amount: 2500,
      );
      expect(draft.toDatos(), containsPair('id_contacto', 'c-1'));
      expect(draft.toDatos(), containsPair('etapa', 'nueva'));
      expect(draft.toDatos(), containsPair('valor', '2500'));
    });
  });

  group('ClientsStore', () {
    test('segment, favorites and search filters combine with the sort', () {
      final store = ClientsStore();

      store.setFilter(const SegmentClients(ClientSegment.startup));
      expect(
        store.visible.every((c) => c.segment == ClientSegment.startup),
        isTrue,
      );

      store.setFilter(const FavoriteClients());
      expect(store.visible.every((c) => c.favorite), isTrue);

      store.setFilter(const AllClients());
      store.setSort(ClientSort.name);
      final names = store.visible.map((c) => c.name).toList();
      expect(names, [...names]..sort());

      store.setQuery('retail');
      expect(store.visible.map((c) => c.industry).toSet(), {'Retail'});
    });

    test('toggleFavorite changes the favorites count', () {
      final store = ClientsStore();
      final before = store.countFor(const FavoriteClients());
      final id = store.all.firstWhere((c) => !c.favorite).id;

      store.toggleFavorite(id);
      expect(store.countFor(const FavoriteClients()), before + 1);
      store.toggleFavorite(id);
      expect(store.countFor(const FavoriteClients()), before);
    });

    test('inactive accounts do not count towards MRR', () {
      final store = ClientsStore();
      final before = store.totalMrr;
      final active = store.all.firstWhere(
        (c) => c.status == ClientStatus.active,
      );

      store.setStatus(active.id, ClientStatus.inactive);

      expect(store.totalMrr, before - active.mrr);
    });
  });

  group('TasksStore', () {
    test('filters open, today, overdue and done tasks', () {
      final store = TasksStore();

      store.setFilter(TaskFilter.overdue);
      expect(store.visible, isNotEmpty);
      expect(store.visible.every(store.isOverdue), isTrue);

      store.setFilter(TaskFilter.done);
      expect(store.visible.every((t) => t.done), isTrue);

      store.setFilter(TaskFilter.today);
      expect(store.visible.every(store.isToday), isTrue);
    });

    test('toggle moves a task between pending and completed', () {
      final store = TasksStore();
      final pending = store.countFor(TaskFilter.all);
      final done = store.countFor(TaskFilter.done);
      final id = store.visible.first.id;

      store.toggle(id);

      expect(store.countFor(TaskFilter.all), pending - 1);
      expect(store.countFor(TaskFilter.done), done + 1);
    });

    test('remove returns the task so it can be restored', () {
      final store = TasksStore();
      final id = store.visible.first.id;
      final pending = store.pendingCount;

      final removed = store.remove(id);
      expect(removed, isNotNull);
      expect(store.pendingCount, pending - 1);

      store.restore(removed!);
      expect(store.pendingCount, pending);
      store.restore(removed);
      expect(store.pendingCount, pending, reason: 'restoring twice is a no-op');
    });

    test('add creates an open task due on the requested day', () {
      final store = TasksStore();
      final created = store.add(
        title: 'Nueva',
        priority: TaskPriority.high,
        dueInDays: 1,
      );
      expect(created.done, isFalse);
      expect(
        created.due
            .difference(
              DateTime(store.now.year, store.now.month, store.now.day),
            )
            .inDays,
        1,
      );
    });
  });

  group('InvoicesStore', () {
    test('markPaid moves the amount from receivable to paid', () {
      final store = InvoicesStore();
      final invoice = store.all.firstWhere(
        (i) => i.status == InvoiceStatus.overdue,
      );
      final paid = store.totalFor(InvoiceStatus.paid);
      final overdue = store.totalFor(InvoiceStatus.overdue);

      store.markPaid(invoice.id);

      expect(store.totalFor(InvoiceStatus.paid), paid + invoice.amount);
      expect(store.totalFor(InvoiceStatus.overdue), overdue - invoice.amount);
    });

    test('remind only applies to invoices that are still receivable', () {
      final store = InvoicesStore();
      final pending = store.all.firstWhere(
        (i) => i.status == InvoiceStatus.pending,
      );
      final paid = store.all.firstWhere((i) => i.status == InvoiceStatus.paid);

      expect(store.remind(pending.id), isTrue);
      expect(store.remind(paid.id), isFalse);
      expect(
        store.all.firstWhere((i) => i.id == pending.id).reminders,
        pending.reminders + 1,
      );
    });

    test('status filter and search narrow the list', () {
      final store = InvoicesStore();
      store.setStatusFilter(InvoiceStatus.overdue);
      expect(
        store.visible.every((i) => i.status == InvoiceStatus.overdue),
        isTrue,
      );
      store.setQuery('zenit');
      expect(store.visible.single.client, 'Zenit Motors');
    });
  });

  group('DashboardStore', () {
    DashboardStore build({SettingsStore? settings}) => DashboardStore(
      settings: settings ?? SettingsStore(),
      random: math.Random(7),
      clock: () => DateTime(2026, 1, 1, 12),
    );

    test('a tick moves the series, feeds the activity and counts', () {
      final store = build();
      final before = List.of(store.series);
      final feedBefore = store.feed.length;

      store.tick();

      expect(store.series.length, DashboardStore.seriesLength);
      expect(store.series, isNot(before));
      expect(store.series.take(29), before.skip(1), reason: 'window rolls');
      expect(store.feed.length, feedBefore + 1);
      expect(store.ticks, 1);
    });

    test('the feed never grows past its limit', () {
      final store = build();
      for (var i = 0; i < 40; i++) {
        store.tick();
      }
      expect(store.feed.length, DashboardStore.feedLength);
      // El más nuevo va primero.
      expect(store.feed.first.id, greaterThan(store.feed.last.id));
    });

    test('revenue only grows and conversion stays in range', () {
      final store = build();
      var last = store.revenue;
      for (var i = 0; i < 60; i++) {
        store.tick();
        expect(store.revenue, greaterThanOrEqualTo(last));
        expect(store.conversion, inInclusiveRange(12, 28));
        last = store.revenue;
      }
    });

    test('changing the period resets the live totals', () {
      final store = build();
      for (var i = 0; i < 10; i++) {
        store.tick();
      }

      store.setPeriod(DashboardPeriod.week);

      expect(store.period, DashboardPeriod.week);
      expect(store.revenue, DashboardPeriod.week.revenue);
      expect(store.leads, DashboardPeriod.week.leads);
      expect(store.pipelineDrift, 0);
    });

    test('the timer follows attach, settings and lifecycle', () {
      final settings = SettingsStore();
      final store = build(settings: settings);
      expect(store.live, isFalse, reason: 'idle until a dashboard is shown');

      store.attach();
      expect(store.live, isTrue);

      settings.setLiveUpdates(false);
      expect(store.live, isFalse);
      settings.setLiveUpdates(true);
      expect(store.live, isTrue);

      store.setForeground(false);
      expect(store.live, isFalse, reason: 'paused in the background');
      store.setForeground(true);
      expect(store.live, isTrue);

      store.detach();
      expect(store.live, isFalse);
      store.dispose();
    });
  });
}
