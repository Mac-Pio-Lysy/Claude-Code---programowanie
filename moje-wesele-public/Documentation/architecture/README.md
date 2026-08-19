# Architektura „Moje Wesele" — model LikeC4

Diagramy architektury w formacie **LikeC4** (nie PlantUML). Trzy pliki `.c4`
tworzą **jeden spójny model** z **wieloma widokami** — to jest cała siła
LikeC4 w porównaniu do osobnych obrazków: zmieniasz element raz, a
odświeżają się wszystkie widoki, w których się pojawia.

| Plik | Rola |
|---|---|
| `specification.c4` | Słownik: jakie rodzaje elementów istnieją (person/system/container/component) i jak wyglądają (kolory). |
| `model.c4` | **Jedyne źródło prawdy.** Wszystkie elementy (z opisami „za co odpowiada") i wszystkie relacje między nimi. |
| `views.c4` | Jak patrzymy na model — 7 widoków, od ogółu do szczegółu. |

Treść wygenerowana z rzeczywistego kodu (prawdziwe nazwy klas, ekranów,
kolekcji Firestore) — nie z opisu słownego. Poprzednie diagramy PlantUML
(`.puml`) zostały usunięte — ich treść jest w pełni odwzorowana tutaj, a
trzymanie dwóch równoległych źródeł tylko groziłoby rozjazdem.

---

## 1. Jak otworzyć podgląd w VS Code

1. Zainstaluj rozszerzenie **LikeC4** (`likec4.likec4-vscode`) z marketplace.
2. Otwórz dowolny plik `.c4` z tego folderu (np. `views.c4`).
3. Nad każdym blokiem `view ... { ... }` pojawi się mały napis **„Open
   Preview"** (CodeLens) — kliknij go.
   Alternatywnie: paleta poleceń `Cmd+Shift+P` → **„LikeC4: Open Preview"**.
4. Otworzy się interaktywny podgląd całego workspace'u (widoczne wszystkie
   3 pliki naraz jako jeden model) z listą widoków po lewej stronie.

Rozszerzenie na bieżąco podkreśla błędy składni wprost w edytorze — jeśli
coś czerwienieje, najedź kursorem, żeby zobaczyć komunikat.

---

## 2. Jak nawigować w głąb (drill-down)

W podglądzie niektóre prostokąty mają w prawym dolnym rogu **małą ikonę
lupy/strzałki** — to znaczy, że ten element ma **własny, głębszy widok**.
Kliknięcie w taki prostokąt (albo w samą ikonę) przenosi Cię do widoku „do
środka" tego elementu.

Mechanizm w kodzie: w `views.c4` widok zadeklarowany jako
`view nazwa of mojeWesele.sharedCore.authLayer { ... }` **automatycznie**
sprawia, że element `authLayer` staje się klikalny WSZĘDZIE, gdzie pojawia
się w innym widoku — nie trzeba nic dodatkowo spinać. Jeśli chcesz, żeby
nowy element też był klikalny „w głąb", wystarczy dopisać dla niego
`view of <ścieżka.do.elementu> { include * }` w `views.c4`.

### Ścieżka klikania w tym modelu

```
1. Kontekst (index)
   └─▶ kliknij "Moje Wesele"
2. Kontenery (containers)
   └─▶ kliknij "Wspólny kod Flutter (lib/)"
3. Wspólny kod — przegląd (sharedCoreOverview)
   ├─▶ kliknij "Warstwa uwierzytelniania"   → 4a. auth
   ├─▶ kliknij "Strefa gości..."            → 4b. guestZoneDetail
   └─▶ kliknij "Warstwa danych"             → 4c. dataLayerDetail
```

Osobna, równoległa ścieżka (Firestore ma własną wewnętrzną architekturę —
reguły bezpieczeństwa):

```
1. Kontekst (index) ─▶ kliknij "Cloud Firestore" ─▶ 5. firestoreRules
```

Widoki 4a/4b/4c są też wzajemnie połączone (np. w widoku „Warstwa auth"
zobaczysz `dataLayer` jako jeden klikalny prostokąt — kliknięcie w niego
przenosi do „Warstwa danych") — bo to naprawdę TE SAME komponenty w modelu,
tylko oglądane z innej strony.

---

## 3. Mapa wszystkich widoków

| # | Widok (`view ...`) | Poziom C4 | Co pokazuje | Kiedy używać |
|---|---|---|---|---|
| 1 | `index` | Context | Organizator/Współorganizator/Gość + Firebase Auth, Google Sign-In, Firestore, Cloudinary, Deezer, Nominatim | Punkt startowy — „co to za system i z kim rozmawia" |
| 2 | `containers` | Container | Appka mobilna, appka web, statyczne strony gości (`zrodlo-web/`), wspólny kod Flutter | „Jak to jest wdrożone/uruchamiane" |
| 3 | `sharedCoreOverview` | Component (grupy) | 3 duże warstwy: auth, strefa gości, dane | Szybki przegląd, zanim zejdziesz w konkretną warstwę |
| 4a | `auth` | Component | AuthGate, AuthService, LoginScreen, EmailAuthScreen, LockScreen, WeddingsListScreen, GuestIdentity | Pytanie „jak działa logowanie" |
| 4b | `guestZoneDetail` | Component | InviteEntryApp, IdentityPickerScreen, GuestWebHome, InvitationsScreen, UnassignedIdentitiesScreen, model paczek | Pytanie „jak działają indywidualne zaproszenia / strefa gości" |
| 4c | `dataLayerDetail` | Component | FirestoreService/ActiveWedding kontra GuestSpaceService/InviteIdentityService, WeddingService, MembershipService, GuestService, serwisy domenowe | Pytanie „jak i gdzie zapisujemy dane w Firestore" |
| 5 | `firestoreRules` | Component | Funkcje pomocnicze `firestore.rules` (signedIn, activeMember, fullAccess, orgOf, validIdentity...) i bloki `match` (weddings, guestView, memberships, inviteCodes, guestSpaces, identities...) | Pytanie „kto ma prawo co czytać/pisać" |

---

## 4. Jak czytać diagramy

- **Strzałka `A → B` z podpisem** = A korzysta z / wywołuje / czyta-zapisuje
  B. Podpis mówi CO konkretnie (np. „claim(doc, identity)",
  „guestSpaces/{token}/*"). Kierunek strzałki = kto inicjuje, nie „przepływ
  danych" w drugą stronę.
- **Kolory** (zdefiniowane w `specification.c4`):
  - szary/slate = osoba (person),
  - niebieski = system (nasza appka albo system zewnętrzny),
  - indygo = kontener,
  - jasnoniebieski (sky) = komponent.
- **Poziom zagnieżdżenia** = poziom C4. Prostokąt WEWNĄTRZ innego
  prostokąta jest jego częścią (np. `authLayer` jest wewnątrz `sharedCore`,
  które jest wewnątrz `mojeWesele`).
- **Ikona lupy w rogu prostokąta** = da się kliknąć głębiej (patrz sekcja 2).
- Widok „firestoreRules" wygląda inaczej niż reszta — to nie jest kod
  aplikacji, tylko wewnętrzna architektura pliku `firestore.rules`
  (funkcje pomocnicze + bloki `match` dla kolekcji). Świadomie zamodelowany
  tym samym językiem, bo ma realną strukturę warstwową, którą warto widzieć.

---

## 5. Jak dodać / zmienić element, gdy architektura się zmieni

Wszystko dzieje się w **`model.c4`** (elementy + relacje). `views.c4`
zwykle NIE wymaga zmian, bo widoki nadrzędne używają `include *`, które
automatycznie łapie nowe dzieci.

### Przykład: dodajesz nowy serwis `NotificationService` do warstwy danych

1. **Zadeklaruj element** w `model.c4`, wewnątrz `component dataLayer { ... }`:
   ```
   component notificationService "NotificationService" {
     technology "Dart class, services/notification_service.dart"
     description "Krótko: za co odpowiada ten serwis."
   }
   ```
2. **Dopisz jego relacje** w sekcji `// RELACJE` na końcu `model.c4`, PEŁNĄ
   ścieżką od korzenia (tak jak wszystkie inne):
   ```
   mojeWesele.sharedCore.dataLayer.notificationService -> firestore "opis relacji"
   ```
3. **Widoki** — nic nie trzeba zmieniać: `dataLayerDetail` używa
   `include *`, więc nowy element pojawi się w nim sam przy następnym
   odświeżeniu podglądu. Jeśli nowy element powinien być widoczny też w
   INNYM widoku (np. w `auth`), dopisz tam ręcznie:
   ```
   include mojeWesele.sharedCore.dataLayer.notificationService
   ```
   (dokładnie tak, jak zrobiłem to dla `membershipService` w widoku `auth`
   — zobacz `views.c4`).
4. **Sprawdź się** (opcjonalnie, jeśli masz Node.js):
   ```
   npx likec4 validate Documentation/architecture
   ```
   Wypisze błędy składni albo nierozwiązane odwołania, zanim otworzysz
   podgląd w VS Code.

### Zasady, o których łatwo zapomnieć

- **Relacje zawsze pełną ścieżką** od najwyższego elementu (np.
  `mojeWesele.sharedCore.authLayer.authGate`), nawet jeśli oba końce są
  „blisko siebie" w drzewie — to jednoznaczne i bezpieczne.
- **Element musi być zadeklarowany, zanim** użyjesz go w relacji — trzymaj
  się kolejności: najpierw cała sekcja elementów w `model.c4`, potem sekcja
  `RELACJE` na końcu.
- Jeśli chcesz, żeby nowa GRUPA komponentów (np. „Warstwa płatności") miała
  **własny widok do klikania**, dodaj w `views.c4`:
  ```
  view platnosci of mojeWesele.sharedCore.platnosci {
    title "..."
    include *
  }
  ```
  — od tej chwili `platnosci` jest klikalny wszędzie, gdzie się pojawia.

---

## 6. Za co odpowiada każdy główny komponent (skrót)

Pełne opisy są przy każdym elemencie w `model.c4` (pole `description`) —
tu tylko szybka ściągawka.

**Warstwa uwierzytelniania**
- `AuthGate` — bramka: wg stanu logowania pokazuje właściwy ekran.
- `AuthService` — Google + e-mail/hasło, jedno miejsce wywołań Firebase Auth.
- `GuestIdentity` — **osobna** anonimowa tożsamość gościa (celowo
  niezależna od `AuthService`, żeby logowanie gościa nigdy nie wylogowało
  organizatora).
- `MembershipService` — rola i status użytkownika w danym weselu.

**Strefa gości i indywidualne zaproszenia**
- `InviteEntryApp` / `IdentityPickerScreen` — wejście kodem paczki (`?i=`),
  wybór „kim jesteś".
- `GuestWebHome` — właściwa strefa gościa (księga, RSVP, galeria, gry...).
- `InvitationsScreen` / `UnassignedIdentitiesScreen` — zarządzanie
  zaproszeniami po stronie organizatora.
- `InviteCodeService` — generowanie/unieważnianie kodów paczek.
- `InviteIdentityService` / `GuestSpaceService` — zapis/odczyt po stronie
  gościa, bez znajomości `weddingId` (tylko token/kod).

**Warstwa danych**
- `FirestoreService` + `ActiveWedding` — dostęp organizatora, w kontekście
  wybranego wesela.
- `GuestSpaceService` / `InviteIdentityService` — dostęp gościa, WŁASNA
  instancja Firestore, klucz to token/kod, nigdy `weddingId`.
- `PdfService` — wydruk zaproszeń (w tym indywidualnych, z QR).

**Reguły Firestore**
- `fullAccess(w)` — czy rola to owner/planner/collaborator (gość
  wykluczony).
- `orgOf(token)` — czy jesteś organizatorem wesela, do którego należy ten
  token strefy gości.
- `validIdentity` — pilnuje poprawności zapisu „ta przeglądarka to Anna z
  zaproszenia X".
- `ownerIndex*` — tylko właściciel wesela może wystawiać kody/zaproszenia.
