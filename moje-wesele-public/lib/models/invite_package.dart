import 'guest.dart';

/// Tryb zapraszania gości — jeden wspólny link czy kody per zaproszenie.
///
/// Wartość zapisywana w `appConfig.inviteMode`. Brak pola = [shared], czyli
/// DOKŁADNIE dotychczasowe zachowanie: jeden link/QR dla wszystkich. Żadne
/// istniejące wesele nie wymaga migracji.
class InviteMode {
  const InviteMode._();

  /// Jeden wspólny link/QR dla wszystkich gości (dotychczasowy model).
  static const String shared = 'shared';

  /// Dodatkowo kod per paczka zaproszeniowa.
  ///
  /// ⚠️ NIE zastępuje wspólnego linku — dokłada się do niego. Wspólny link
  /// działa równolegle: dla gości, którzy zgubili zaproszenie, dla starszych
  /// osób i dla zabaw przy stole, gdzie kod QR leży na środku.
  static const String individual = 'individual';

  static const List<String> all = [shared, individual];

  /// Odczyt z surowego dokumentu wesela. Nieznana wartość → [shared].
  static String fromRaw(Map<String, dynamic> raw) {
    final cfg = raw['appConfig'];
    final v = (cfg is Map ? cfg['inviteMode'] as String? : null)?.trim();
    return all.contains(v) ? v! : shared;
  }
}

/// Jedna osoba w paczce zaproszeniowej.
class PackageMember {
  const PackageMember({
    required this.guestId,
    required this.name,
    required this.isMain,
    required this.namePending,
  });

  /// `id` rekordu gościa — trwałe powiązanie z listą gości.
  final int guestId;

  /// Imię do pokazania gościowi przy wyborze „kim jesteś".
  ///
  /// Puste, gdy [namePending] — para wie, że ktoś przyjdzie, ale nie wie kto.
  final String name;

  /// Czy to gość główny (ten, do kogo zaadresowane jest zaproszenie).
  final bool isMain;

  /// Imię jeszcze nieznane — osoba towarzysząca bez danych.
  final bool namePending;
}

/// Paczka zaproszeniowa — jedno zaproszenie, czyli jeden gość główny
/// wraz ze wszystkimi jego osobami towarzyszącymi.
///
/// ⚠️ PACZKA JEST WYLICZANA, NIE PRZECHOWYWANA. Powstaje z istniejącego
/// powiązania `Guest.companionOfId` przy każdym odczycie. Świadomie NIE
/// dokładamy gościom pola `packageId`: powielałoby ono `companionOfId`
/// i mogłoby się z nim rozjechać — a wtedy jedna osoba trafiłaby do dwóch
/// zaproszeń albo zniknęła z obu. Ta sama zasada, dla której relacja
/// towarzysząca jest jednokierunkowa (patrz [Guest.companionOfId]).
///
/// Identyfikatorem paczki jest `id` gościa głównego.
class InvitePackage {
  const InvitePackage({required this.main, required this.companions});

  /// Gość główny — adresat zaproszenia.
  final Guest main;

  /// Osoby towarzyszące powiązane z [main].
  final List<Guest> companions;

  /// Identyfikator paczki = `id` gościa głównego.
  int get id => main.id ?? -1;

  /// Ile osób obejmuje to zaproszenie.
  int get size => 1 + companions.length;

  /// Czy zaproszenie jest jednoosobowe.
  bool get isSingle => companions.isEmpty;

  /// Wszyscy goście paczki, główny na pierwszym miejscu.
  List<Guest> get everyone => [main, ...companions];

  /// Czy ktokolwiek w paczce czeka na uzupełnienie imienia.
  bool get hasPendingNames => everyone.any((g) => g.namePending);

  /// Skład paczki w postaci przygotowanej dla gościa (etap 3 i publiczny
  /// indeks kodów w etapie 2).
  ///
  /// ⚠️ WYŁĄCZNIE IMIONA. Nazwisko dokładamy tylko wtedy, gdy w tej samej
  /// paczce dwie osoby mają identyczne imię — inaczej gość nie odróżniłby
  /// „Anna" od „Anna". Nigdy nie wychodzą stąd telefon, dieta, kategoria
  /// ani przypisanie do stołu.
  List<PackageMember> get members {
    final list = everyone;
    final counts = <String, int>{};
    for (final g in list) {
      final key = g.firstName.toLowerCase();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    return [
      for (final g in list)
        PackageMember(
          guestId: g.id ?? -1,
          name: g.namePending
              ? ''
              : ((counts[g.firstName.toLowerCase()] ?? 0) > 1
                  ? g.fullName
                  : g.firstName),
          isMain: identical(g, list.first),
          namePending: g.namePending,
        ),
    ];
  }

  /// Buduje paczki z surowej listy gości wesela.
  ///
  /// Zasada: gość BEZ `companionOfId` zakłada paczkę; gość z `companionOfId`
  /// dołącza do paczki wskazanego zapraszającego. Osoba towarzysząca
  /// wskazująca na nieistniejącego gościa (np. usuniętego) NIE ginie —
  /// dostaje własną, jednoosobową paczkę, żeby nie wypaść z zaproszeń bez
  /// śladu.
  static List<InvitePackage> buildAll(List<dynamic> rawGuests) {
    final guests = [
      for (final g in rawGuests)
        if (g is Map) Guest(Map<String, dynamic>.from(g)),
    ];

    final byId = <int, Guest>{
      for (final g in guests)
        if (g.id != null) g.id!: g,
    };
    final companionsOf = <int, List<Guest>>{};
    final mains = <Guest>[];

    for (final g in guests) {
      final host = g.companionOfId;
      if (host != null && byId.containsKey(host)) {
        companionsOf.putIfAbsent(host, () => []).add(g);
      } else {
        // Brak powiązania ALBO powiązanie „w próżnię" (zapraszający usunięty).
        mains.add(g);
      }
    }

    return [
      for (final m in mains)
        InvitePackage(
          main: m,
          companions: companionsOf[m.id] ?? const [],
        ),
    ];
  }

  /// Odcisk składu paczki — zmienia się dokładnie wtedy, gdy zmienia się to,
  /// co publikujemy w `inviteCodes`.
  ///
  /// Po to, żeby wykryć „kod nieaktualny": zapisujemy odcisk w chwili
  /// synchronizacji i porównujemy z bieżącym. Świadomie liczony z [members]
  /// (a nie z surowych rekordów gościa) — zmiana diety albo stołu NIE ma
  /// unieważniać kodu, bo te dane nigdy nie opuszczają dokumentu wesela.
  String get rosterFingerprint => members
      .map((m) => '${m.guestId}:${m.name}:${m.namePending ? 1 : 0}')
      .join('|');

  /// Liczba paczek i osób — do podsumowania na ekranie.
  static PackageStats statsOf(List<InvitePackage> packages) => PackageStats(
        packages: packages.length,
        people: packages.fold(0, (sum, p) => sum + p.size),
        multi: packages.where((p) => !p.isSingle).length,
        pendingNames: packages.where((p) => p.hasPendingNames).length,
      );
}

/// Podsumowanie paczek dla ekranu zaproszeń.
class PackageStats {
  const PackageStats({
    required this.packages,
    required this.people,
    required this.multi,
    required this.pendingNames,
  });

  /// Ile zaproszeń (kodów) trzeba będzie wydrukować.
  final int packages;

  /// Ile osób obejmują wszystkie zaproszenia razem.
  final int people;

  /// Ile zaproszeń jest wieloosobowych.
  final int multi;

  /// Ile zaproszeń ma osobę bez uzupełnionego imienia.
  final int pendingNames;
}
