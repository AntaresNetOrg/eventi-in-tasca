/// A region of the site's search menu.
class Regione {
  const Regione({required this.rid, required this.nome});

  factory Regione.fromJson(Map<String, dynamic> json) =>
      Regione(rid: json['rid'] as String, nome: json['nome'] as String);

  /// Value of the `RID` URL parameter.
  final String rid;
  final String nome;

  Map<String, Object?> toJson() => {'rid': rid, 'nome': nome};
}

/// An event type of the site's search menu.
class TipoEvento {
  const TipoEvento({
    required this.cid,
    required this.nome,
    required this.gruppo,
    this.livello,
  });

  factory TipoEvento.fromJson(Map<String, dynamic> json) => TipoEvento(
    cid: json['cid'] as String,
    nome: json['nome'] as String,
    gruppo: json['gruppo'] as bool,
    livello: json['livello'] as int?,
  );

  /// Value of the `CID` URL parameter.
  final String cid;
  final String nome;

  /// True for an entry that groups other types, such as "L/C" (V-03).
  final bool gruppo;

  /// The N of the site's `LevelN` CSS class; only group entries have one.
  final int? livello;

  Map<String, Object?> toJson() => {
    'cid': cid,
    'nome': nome,
    'gruppo': gruppo,
    if (livello != null) 'livello': livello,
  };
}

/// Regions and event types, read from the site or from the bundled fallback.
class MenuEventi {
  const MenuEventi({required this.regioni, required this.tipi});

  factory MenuEventi.fromJson(Map<String, dynamic> json) => MenuEventi(
    regioni: (json['regioni'] as List<dynamic>)
        .map((item) => Regione.fromJson(item as Map<String, dynamic>))
        .toList(),
    tipi: (json['tipi'] as List<dynamic>)
        .map((item) => TipoEvento.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  final List<Regione> regioni;
  final List<TipoEvento> tipi;

  Map<String, Object?> toJson() => {
    'regioni': regioni.map((regione) => regione.toJson()).toList(),
    'tipi': tipi.map((tipo) => tipo.toJson()).toList(),
  };
}
