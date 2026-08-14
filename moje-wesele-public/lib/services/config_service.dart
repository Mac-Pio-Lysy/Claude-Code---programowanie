import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/couple.dart';
import '../models/currency.dart';
import 'firestore_service.dart';

/// Dane konfiguracji z formularza Ustawień.
class AppConfigDraft {
  AppConfigDraft({
    required this.eventName,
    required this.displayNames,
    required this.ceremonyPlace,
    required this.receptionPlace,
    required this.weddingDate,
    required this.weddingTime,
    required this.person1,
    required this.person2,
    required this.menuOptions,
    required this.expenseCategories,
    this.witnessCount = 2,
    this.coupleType = CoupleType.mixed,
    this.verificationSurnames = '',
    this.withChildren = false,
  });

  final String eventName;
  final String displayNames;
  final String ceremonyPlace;
  final String receptionPlace;
  final String weddingDate;
  final String weddingTime;
  final String person1;
  final String person2;
  final List<String> menuOptions;
  final List<String> expenseCategories;

  /// Docelowa liczba świadków (domyślnie 2; można ustawić więcej).
  final int witnessCount;

  /// Typ uroczystości — decyduje o etykietach pary w całej aplikacji.
  final CoupleType coupleType;

  /// Nazwisko / nazwiska Pary Młodej — używane WYŁĄCZNIE do weryfikacji
  /// gościa przy dołączaniu kodem. Nigdzie nie jest wyświetlane.
  ///
  /// Osobne pole, bo „Osoby" zawierają IMIONA („Ania i Piotr"), a ekran
  /// dołączania pyta gościa o NAZWISKO. Bez tego pola prawidłowe dane były
  /// odrzucane (zgłoszenie #23).
  final String verificationSurnames;

  /// Czy na weselu będą dzieci (`budgetData.withChildren`).
  ///
  /// Trzymane w `budgetData`, a nie w `appConfig`, bo tego pola używają już
  /// kalkulacje sali i napojów. Konfiguracja tylko je udostępnia w drugim
  /// miejscu — szczegóły cenowe zostają w Budżet → Sala.
  final bool withChildren;
}

/// Operacje na konfiguracji aplikacji (`appConfig`, `weddingDate`,
/// `weddingTime`, `budgetData.coupleNames`) oraz eksport/import całych danych.
class ConfigService {
  ConfigService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Zapisuje konfigurację (odwzorowuje `saveConfig` z wersji web).
  Future<void> saveConfig(AppConfigDraft d) async {
    await _firestore.mainDoc.set({
      'appConfig': {
        'eventName':
            d.eventName.isEmpty ? 'Ceremonia Weselna' : d.eventName,
        'displayNames':
            d.displayNames.isEmpty ? 'Patrycji i Piotra' : d.displayNames,
        'ceremonyPlace': d.ceremonyPlace,
        'receptionPlace': d.receptionPlace,
        'menuOptions': d.menuOptions,
        'expenseCategories': d.expenseCategories,
        'witnessCount': d.witnessCount < 1 ? 2 : d.witnessCount,
        'coupleType': d.coupleType.name,
        'verificationSurnames': d.verificationSurnames.trim(),
      },
      'weddingDate': d.weddingDate.isEmpty ? null : d.weddingDate,
      'weddingTime': d.weddingTime.isEmpty ? '16:00' : d.weddingTime,
      'budgetData': {
        'coupleNames': [
          d.person1.isEmpty ? 'Osoba 1' : d.person1,
          d.person2.isEmpty ? 'Osoba 2' : d.person2,
        ],
        // Głębokie scalanie — reszta `budgetData` (ceny, menu dziecięce,
        // tryb liczenia dzieci) zostaje nietknięta.
        'withChildren': d.withChildren,
      },
    }, SetOptions(merge: true));
  }

  /// Zapisuje ustawienia budżetu z Konfiguracji: budżet planowany
  /// (`budgetData.total`) i rezerwę (`budgetData.reserve`). Głębokie scalanie —
  /// pozostałe pola `budgetData` (wydatki, sala, napoje…) pozostają nietknięte.
  Future<void> saveBudgetSettings({
    required num plannedBudget,
    required num reserve,
  }) =>
      _firestore.mainDoc.set({
        'budgetData': {
          'total': plannedBudget < 0 ? 0 : plannedBudget,
          'reserve': reserve < 0 ? 0 : reserve,
        },
      }, SetOptions(merge: true));

  /// Zapisuje walutę budżetu (`appConfig.currency`).
  ///
  /// Osobno od [saveConfig], bo waluta jest ustawieniem wesela zmienianym
  /// z karty „Język i region", a nie z formularza konfiguracji. Głębokie
  /// scalanie — reszta `appConfig` zostaje nietknięta.
  ///
  /// ⚠️ Zmiana waluty NIE przelicza kwot — to wyłącznie symbol przy liczbach
  /// (patrz [Currency]).
  Future<void> saveCurrency(Currency currency) => _firestore.mainDoc.set({
        'appConfig': {'currency': currency.code},
      }, SetOptions(merge: true));

  /// Pełny dokument danych (do eksportu).
  Future<Map<String, dynamic>> exportData() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  /// Nadpisuje cały dokument danych (import). UWAGA: zastępuje istniejące dane.
  Future<void> importData(Map<String, dynamic> data) =>
      _firestore.mainDoc.set(data);
}
