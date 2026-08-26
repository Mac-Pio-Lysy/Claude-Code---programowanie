import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/services/wedding_service.dart';

/// Testy `WeddingService.buildResetWeddingData` — Opcja 2 „Wyczyść wszystkie
/// dane wesela" (Strefa zagrożenia). Funkcja CZYSTA (bez zapisu), więc testy
/// nie potrzebują atrapy Firestore'a.
///
/// Sprawdzają dwie strony tej samej monety: pola z listy ZOSTAJE przetrwały
/// z bieżącego dokumentu, a pola „planowania" (i wszystko nieznane) zniknęły —
/// bo wywołujący zapisuje wynik przez `.set()` BEZ merge.
void main() {
  Map<String, dynamic> weddingDoc() => {
        'ownerId': 'user-1',
        'joinCode': 'ABCD-EFGH',
        'guestToken': 'tok123',
        'tier': 'premium',
        'createdAt': 'sentinel-created-at',
        'appConfig': {
          'eventName': 'Wesele Ani i Piotra',
          'displayNames': 'Ania i Piotr',
          'coupleType': 'mixed',
          'witnessCount': 3,
          'ceremonyPlace': 'Kościół św. Anny',
          'receptionPlace': 'Dwór Sielanka',
          'menuOptions': ['Wege', 'Mięsne'],
          'expenseCategories': ['Fotograf', 'DJ'],
        },
        'weddingDate': '2027-06-12',
        'weddingTime': '17:30',
        'budgetData': {
          'coupleNames': ['Ania', 'Piotr'],
          'total': 50000,
          'alcoholItems': [
            {'bottles': 10, 'pricePerBottle': 40}
          ],
        },
        'guests': [
          {'id': 1, 'firstName': 'Jan', 'lastName': 'Kowalski'}
        ],
        'nextGuestId': 42,
        'tables': [
          {'id': 1, 'seatsData': [1, null]}
        ],
        'tasks': [
          {'id': 1, 'name': 'Zamówić tort'}
        ],
        'vendors': [
          {'id': 1, 'companyName': 'Foto Studio'}
        ],
        'vehicles': [
          {'id': 1, 'guestIds': [1]}
        ],
        'hotels': [
          {'id': 1, 'name': 'Hotel Pod Różą'}
        ],
        'staffTables': [
          {'id': 1, 'persons': 5}
        ],
        'photoContests': {'c1': 'config'},
        'scheduleEvents': [
          {'id': 1, 'name': 'Ceremonia'}
        ],
      };

  group('pola ZOSTAJĄ (tożsamość wesela)', () {
    test('ownerId, joinCode, guestToken przetrwały bez zmian', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['ownerId'], 'user-1');
      expect(clean['joinCode'], 'ABCD-EFGH');
      expect(clean['guestToken'], 'tok123');
    });

    test('tier (poziom konta) przetrwał — KRYTYCZNE dla monetyzacji', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['tier'], 'premium');
    });

    test('brak tier w dokumencie → free (zgodność wsteczna), nie null', () {
      final doc = weddingDoc()..remove('tier');
      final clean = WeddingService.buildResetWeddingData(doc);
      expect(clean['tier'], 'free');
    });

    test('createdAt przetrwał', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['createdAt'], 'sentinel-created-at');
    });

    test('weddingDate przetrwała', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['weddingDate'], '2027-06-12');
    });

    test('appConfig: eventName/displayNames/coupleType/witnessCount przetrwały', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      final cfg = clean['appConfig'] as Map<String, dynamic>;
      expect(cfg['eventName'], 'Wesele Ani i Piotra');
      expect(cfg['displayNames'], 'Ania i Piotr');
      expect(cfg['coupleType'], 'mixed');
      expect(cfg['witnessCount'], 3);
    });

    test('budgetData.coupleNames przetrwały — bieżące imiona, nie placeholdery', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      final bd = clean['budgetData'] as Map<String, dynamic>;
      expect(bd['coupleNames'], ['Ania', 'Piotr']);
    });
  });

  group('pola CZYSZCZONE (planowanie)', () {
    test('appConfig: ceremonyPlace/receptionPlace/menuOptions/expenseCategories wyczyszczone', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      final cfg = clean['appConfig'] as Map<String, dynamic>;
      expect(cfg['ceremonyPlace'], '');
      expect(cfg['receptionPlace'], '');
      expect(cfg['menuOptions'], isEmpty);
      expect(cfg['expenseCategories'], isEmpty);
    });

    test('weddingTime wraca do domyślnej wartości', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['weddingTime'], '16:00');
    });

    test('budgetData: total zresetowany do 0, reszta (alkohol itp.) zniknęła', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      final bd = clean['budgetData'] as Map<String, dynamic>;
      expect(bd['total'], 0);
      expect(bd.containsKey('alcoholItems'), isFalse);
    });

    test('guests: tylko Para Młoda (z coupleNames), stary gość zniknął', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      final guests = clean['guests'] as List;
      expect(guests.length, 2);
      expect(guests[0]['firstName'], 'Ania');
      expect(guests[1]['firstName'], 'Piotr');
      expect(guests.any((g) => g['lastName'] == 'Kowalski'), isFalse);
    });

    test('nextGuestId = couple.length + 1 (nie literalne 1 — unika kolizji ID)', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['nextGuestId'], 3);
    });

    test('tables/tasks/vendors/scheduleEvents puste', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean['tables'], isEmpty);
      expect(clean['tasks'], isEmpty);
      expect(clean['vendors'], isEmpty);
      expect(clean['scheduleEvents'], isEmpty);
    });

    test('pola spoza szablonu (vehicles/hotels/staffTables/photoContests) w ogóle nie istnieją', () {
      final clean = WeddingService.buildResetWeddingData(weddingDoc());
      expect(clean.containsKey('vehicles'), isFalse);
      expect(clean.containsKey('hotels'), isFalse);
      expect(clean.containsKey('staffTables'), isFalse);
      expect(clean.containsKey('photoContests'), isFalse);
    });
  });

  group('braki danych — nie wywraca się', () {
    test('pusty dokument daje bezpieczny, kompletny szkielet', () {
      final clean = WeddingService.buildResetWeddingData(const {});
      expect(clean['tier'], 'free');
      expect(clean['guests'], isEmpty);
      expect(clean['nextGuestId'], 1);
      final bd = clean['budgetData'] as Map<String, dynamic>;
      expect(bd['coupleNames'], ['', '']);
    });

    test('createdAt brakujący → FieldValue.serverTimestamp (nowa sygnatura czasu)', () {
      final clean = WeddingService.buildResetWeddingData(const {});
      expect(clean['createdAt'], isA<FieldValue>());
    });
  });
}
