import 'package:future_crm/core/api/crm_client.dart';
import 'package:future_crm/features/opportunities/opportunities_api.dart';
import 'package:future_crm/features/opportunities/opportunity.dart';

/// API de oportunidades en memoria. Con [failStageChanges] las peticiones
/// de etapa fallan, para probar que la UI deshace el cambio.
class MemoryOpportunitiesApi implements OpportunitiesApi {
  MemoryOpportunitiesApi({
    List<OpportunityContact>? contacts,
    List<Opportunity>? seed,
    this.failStageChanges = false,
    this.failingContacts = const {},
  }) : _contacts = List.of(contacts ?? sampleContacts),
       _items = List.of(seed ?? sampleOpportunities());

  final List<OpportunityContact> _contacts;
  final List<Opportunity> _items;
  final bool failStageChanges;
  final Set<String> failingContacts;
  final Map<String, List<PipelineEntry>> _history = {};
  bool failHistory = false;
  int _nextId = 100;

  final List<String> stageRequests = [];

  @override
  Future<List<OpportunityContact>> contacts() async => List.of(_contacts);

  @override
  Future<List<Opportunity>> forContact(String contactId) async {
    if (failingContacts.contains(contactId)) {
      throw CrmApiException('Fallo de red');
    }
    return _items.where((o) => o.contactId == contactId).toList();
  }

  @override
  Future<void> create(OpportunityDraft draft) async {
    _items.add(
      Opportunity(
        id: 'op-${_nextId++}',
        contactId: draft.contactId,
        name: draft.name,
        company: draft.company,
        amount: draft.amount,
        stage: draft.stage,
        owner: draft.owner,
      ),
    );
  }

  @override
  Future<void> update(Opportunity opportunity) async {
    final index = _items.indexWhere((o) => o.id == opportunity.id);
    if (index >= 0) _items[index] = opportunity;
  }

  @override
  Future<void> updateStage(
    String id,
    OpportunityStage stage, {
    String note = '',
  }) async {
    stageRequests.add('$id:${stage.raw}');
    if (failStageChanges) throw CrmApiException('No se pudo guardar la etapa');
    final index = _items.indexWhere((o) => o.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(stage: stage);
    _history
        .putIfAbsent(id, () => [])
        .add(PipelineEntry(stage: stage, note: note, at: DateTime.now()));
  }

  @override
  Future<List<PipelineEntry>> history(String id) async {
    if (failHistory) throw CrmApiException('Historial no disponible');
    return List.of(_history[id] ?? const []);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((o) => o.id == id);
  }
}

const sampleContacts = [
  OpportunityContact(id: 'c-1', name: 'Laura Méndez', company: 'Nexora Labs'),
  OpportunityContact(id: 'c-2', name: 'Pablo Ortiz', company: 'Grupo Aurelia'),
  OpportunityContact(id: 'c-3', name: 'Inés Duarte', company: 'Kairos Retail'),
  OpportunityContact(id: 'c-4', name: 'Tomás Rey', company: 'Orbita Fintech'),
];

List<Opportunity> sampleOpportunities() {
  final now = DateTime.now();
  Opportunity op(
    int n,
    String contact,
    String name,
    String company,
    double amount,
    OpportunityStage stage,
    String owner,
    int days,
  ) => Opportunity(
    id: 'op-$n',
    contactId: contact,
    name: name,
    company: company,
    amount: amount,
    stage: stage,
    owner: owner,
    closeDate: now.add(Duration(days: days)),
  );
  const s = OpportunityStage.values;
  return [
    op(
      1,
      'c-1',
      'Plataforma de analítica',
      'Nexora Labs',
      128000,
      s[4],
      'Camila R.',
      9,
    ),
    op(
      2,
      'c-2',
      'Licencias anuales Pro',
      'Grupo Aurelia',
      84500,
      s[3],
      'Diego M.',
      16,
    ),
    op(
      3,
      'c-1',
      'Migración a la nube',
      'Nexora Labs',
      212000,
      s[4],
      'Sofía L.',
      6,
    ),
    op(
      4,
      'c-2',
      'Automatización de ventas',
      'Grupo Aurelia',
      36800,
      s[1],
      'Andrés P.',
      28,
    ),
    op(
      5,
      'c-3',
      'Portal de clientes',
      'Kairos Retail',
      61200,
      s[0],
      'Camila R.',
      41,
    ),
    op(
      6,
      'c-4',
      'Soporte premium 24/7',
      'Orbita Fintech',
      47900,
      s[5],
      'Diego M.',
      -4,
    ),
    op(
      7,
      'c-3',
      'Integración ERP',
      'Kairos Retail',
      154000,
      s[2],
      'Sofía L.',
      22,
    ),
    op(
      8,
      'c-4',
      'Suite de seguridad',
      'Orbita Fintech',
      99000,
      s[4],
      'Camila R.',
      11,
    ),
    op(
      9,
      'c-1',
      'Consultoría de datos',
      'Nexora Labs',
      25600,
      s[6],
      'Sofía L.',
      -9,
    ),
    op(
      10,
      'c-2',
      'Renovación de contrato',
      'Grupo Aurelia',
      54000,
      s[5],
      'Andrés P.',
      -2,
    ),
    op(
      11,
      'c-3',
      'Chatbot de atención',
      'Kairos Retail',
      31500,
      s[3],
      'Camila R.',
      19,
    ),
    op(
      12,
      'c-4',
      'Piloto descartado',
      'Orbita Fintech',
      18000,
      s[7],
      'Diego M.',
      -20,
    ),
  ];
}
