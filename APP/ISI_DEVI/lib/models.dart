// lib/models.dart

class LigneArticle {
  String id;
  String item;
  String description;
  String unite;
  double qte;
  double prixUnit;
  double remise;

  LigneArticle({
    required this.id,
    this.item = '',
    this.description = '',
    this.unite = 'U',
    this.qte = 0,
    this.prixUnit = 0,
    this.remise = 0,
  });

  double get prixBrut => qte * prixUnit;
  double get remiseMontant => prixBrut * (remise / 100);
  double get prixTotHT => prixBrut - remiseMontant;

  LigneArticle copyWith({
    String? item,
    String? description,
    String? unite,
    double? qte,
    double? prixUnit,
    double? remise,
  }) {
    return LigneArticle(
      id: id,
      item: item ?? this.item,
      description: description ?? this.description,
      unite: unite ?? this.unite,
      qte: qte ?? this.qte,
      prixUnit: prixUnit ?? this.prixUnit,
      remise: remise ?? this.remise,
    );
  }
}

class StyleDevis {
  bool objBold;
  bool objUpper;
  bool clientBold;
  bool clientUpper;
  bool metaBold;
  bool metaUpper;
  bool articlesBold;
  bool articlesUpper;
  bool financeBold;
  bool financeUpper;
  bool termsBold;
  bool termsUpper;

  StyleDevis({
    this.objBold = true,
    this.objUpper = true,
    this.clientBold = true,
    this.clientUpper = false,
    this.metaBold = true,
    this.metaUpper = false,
    this.articlesBold = false,
    this.articlesUpper = false,
    this.financeBold = true,
    this.financeUpper = true,
    this.termsBold = true,
    this.termsUpper = false,
  });

  StyleDevis copyWith({
    bool? objBold, bool? objUpper,
    bool? clientBold, bool? clientUpper,
    bool? metaBold, bool? metaUpper,
    bool? articlesBold, bool? articlesUpper,
    bool? financeBold, bool? financeUpper,
    bool? termsBold, bool? termsUpper,
  }) {
    return StyleDevis(
      objBold: objBold ?? this.objBold,
      objUpper: objUpper ?? this.objUpper,
      clientBold: clientBold ?? this.clientBold,
      clientUpper: clientUpper ?? this.clientUpper,
      metaBold: metaBold ?? this.metaBold,
      metaUpper: metaUpper ?? this.metaUpper,
      articlesBold: articlesBold ?? this.articlesBold,
      articlesUpper: articlesUpper ?? this.articlesUpper,
      financeBold: financeBold ?? this.financeBold,
      financeUpper: financeUpper ?? this.financeUpper,
      termsBold: termsBold ?? this.termsBold,
      termsUpper: termsUpper ?? this.termsUpper,
    );
  }
}

class DevisData {
  String num;
  String date;
  String suivi;
  String ref;
  String att;
  String cont;
  String tel;
  String obj;
  String vld;
  String dlv;
  bool rxOn;
  double rxPct;
  List<LigneArticle> lignes;
  StyleDevis style;

  DevisData({
    this.num = '26PPTT39',
    this.date = '',
    this.suivi = 'Amadou OUATTARA',
    this.ref = 'N/A',
    this.att = '',
    this.cont = '',
    this.tel = '',
    this.obj = '',
    this.vld = '1 mois',
    this.dlv = '1 semaine',
    this.rxOn = false,
    this.rxPct = 10,
    List<LigneArticle>? lignes,
    StyleDevis? style,
  })  : lignes = lignes ?? [],
        style = style ?? StyleDevis();

  double get totalBrut => lignes.fold(0, (s, l) => s + l.prixBrut);
  double get totalRemise => lignes.fold(0, (s, l) => s + l.remiseMontant);
  double get sousTotal => totalBrut - totalRemise;
  double get remExcMontant => rxOn ? sousTotal * (rxPct / 100) : 0;
  double get totalNet => sousTotal - remExcMontant;
}
