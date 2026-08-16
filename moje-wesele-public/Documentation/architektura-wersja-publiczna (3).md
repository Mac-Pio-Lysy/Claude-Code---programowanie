# Architektura wersji publicznej — „Moje Wesele – Wedding Planner"

Dokument roboczy. Opisuje jak aplikacja ma działać dla **wielu par**
(a nie tylko dla Was). To plan — jeszcze nie kod. Wracaj tu przy każdej
decyzji i przy każdym prompcie do Claude Code.

---

## 1. Główna idea w jednym zdaniu

Jedna aplikacja (jeden kod Flutter), dwie role wybierane przy wejściu —
**Para Młoda** (pełny panel, loguje się) i **Gość** (wchodzi przez QR/link,
bez instalacji i bez logowania) — a każde wesele ma swoje **ID**, które
oddziela jego dane od wszystkich innych wesel.

---

## 2. Role użytkowników i ścieżki wejścia

Przy wejściu do aplikacji użytkownik idzie jedną z dwóch ścieżek:
**Zalogowany** (konto) albo **Gość** (ID/QR).

### Zalogowany (organizator / Para / planer)
- Loguje się kontem (na start Google).
- **Może mieć WIELE wesel** na jednym koncie:
  - zwykła para: zwykle jedno wesele,
  - **planer weselny: wiele wesel** — to osobna grupa docelowa (biznes!).
- Po zalogowaniu **wybiera wesele** z listy swoich wesel albo **tworzy nowe**.
- Każde wesele może mieć **kilku organizatorów** (Para + świadek + planer) —
  pole `role` przy powiązaniu użytkownik–wesele.
- Ma pełny panel wybranego wesela: goście, budżet, plan sali, harmonogram,
  gry, pamiątki itd.

### Gość
- Wchodzi **bez logowania**: podaje **ID wesela** lub **skanuje QR**.
- Trafia do jednego, konkretnego wesela — z **ograniczonym dostępem**:
  swoje miejsce (stolik), galeria/zdjęcia, gry, muzyka, RSVP, harmonogram
  dla gości. NIE widzi budżetu, pełnego panelu itd.
- Podaje swoje imię przy interakcjach.
- **Może założyć konto** → w przyszłości sam organizuje swoje wesele
  (naturalne przejście: gość → własny klient).

> Ta sama aplikacja Flutter buduje się i jako **app na Androida**,
> i jako **strona web** (gość wchodzi przez QR w przeglądarce, bez instalacji).
> Jeden kod, dwa wyjścia.

### Model uprawnień (kto co może)

**Para Młoda = ZAWSZE nadrzędny właściciel wesela.** Ma najwyższą władzę,
nawet nad planerem. To płacący klient — zawsze może odciąć każdego.

| Rola            | Dostęp                          | Kto nadaje / kontroluje            |
|-----------------|---------------------------------|------------------------------------|
| Para (owner)    | Pełny panel, władza nadrzędna   | pierwotny, sam się rejestruje      |
| Planer          | Pełny panel, ale **z datą ważności** i **odcinany przez Parę** | dodany/zatwierdzony przez Parę |
| Współorganizator| Pełny panel (świadek, mama)     | dodany + **potwierdzony w apce** przez Parę |
| Gość            | Ograniczony: swoje miejsce, galeria, gry, muzyka, RSVP | sam dołącza kodem + weryfikacja |

**Zasady:**
- Tylko **Para** może dodać współorganizatora/planera — i musi to
  **dodatkowo potwierdzić w aplikacji** (świadoma zgoda).
- Para może **w każdej chwili zablokować / usunąć** dostęp każdemu
  (planerowi, współorganizatorowi).
- **Planer**: dostęp z **datą ważności konta** (wygasa); Para może
  blokować i **przywracać wielokrotnie**.
- **Gość** dołącza sam: **kod QR + data wesela + nazwisko Państwa Młodych**
  (potrójna weryfikacja, bo sam kod QR bywa jawny na stołach).
  Gość dostaje TYLKO ograniczony dostęp — nigdy pełny panel przez sam kod.
- Gość może później założyć własne konto → własne wesele.

---

## 3. Wesela po ID — serce rozwiązania

Dziś (wersja dla Was): jeden zestaw danych w `weddingPlanner/main`,
trzy maile na sztywno. To działa dla jednego wesela.

Wersja publiczna: **każde wesele = osobny dokument z własnym ID.**

```
weddings/
  {weddingId}/           ← unikalne ID, np. "abc123"
      config             ← nazwa, data, miejsca, ustawienia
      guests             ← goście tego wesela
      budget             ← budżet tego wesela
      tables, schedule, tasks, vendors, ...
      games, keepsakes   ← gry i pamiątki tego wesela
```

- Para Młoda po założeniu wesela dostaje swoje `weddingId`.
- Wszystkie jej dane lądują pod `weddings/{jejId}/...`.
- Gość wchodzi na `...?w={weddingId}` → widzi dane tylko tego wesela.

### Powiązanie konta z weselami (wiele wesel na konto)

Użytkownik ↔ wesele to relacja **wiele-do-wielu** (jedno konto może mieć
wiele wesel; jedno wesele może mieć wielu organizatorów).

```
users/
  {userId}/
      displayName, email
      accountType        ← "para" lub "planer" (planer = wiele wesel)

memberships/             ← kto ma dostęp do którego wesela i jako kto
  {membershipId}/
      userId
      weddingId
      role               ← "owner" (Para) / "planner" / "collaborator"
```

- Po zalogowaniu aplikacja czyta `memberships` danego `userId` →
  pokazuje **listę jego wesel** → użytkownik wybiera jedno (lub tworzy nowe).
- Planer ma po prostu wiele wpisów `memberships` (wiele wesel).
- Współorganizator = kolejny wpis `memberships` dla tego samego `weddingId`.

---

## 4. Izolacja i bezpieczeństwo danych (KRYTYCZNE)

### Sekwencja wdrożenia reguł 5b (kolejność krytyczna!)
0. Backup: eksport danych + skopiuj OBECNE opublikowane reguły z konsoli
   Firebase do pliku (NIE stary OPEN-BACKUP — on jest sprzed izolacji).
1. Indeksy: `firebase deploy --only firestore:indexes` → czekaj aż 9 sztuk
   ma status „Enabled" w konsoli. (bezpieczne, nie zmieniają uprawnień)
2. Migracja legacy — w aplikacji jako owner, na STARYCH regułach:
   Ustawienia → „Dane starych sekcji" → Sprawdź → Migruj → Sprawdź
   (cel: wszędzie „do migracji 0"). Przypisuje bezpańskie wpisy do
   aktywnego wesela — uruchom w weselu z którego dane pochodzą.
3. Walidacja składni: wklej `firestore.rules` w konsoli Firebase →
   Reguły (NIE publikuj — edytor pokaże błędy składni).
4. Symulator (w konsoli): sprawdź 3 scenariusze —
   get `weddings/{id}` jako gość = przejdzie (znany D1);
   create `roleInvites` jako współorganizator = ODMOWA;
   update `guestTokens/{cudzy}` z innym weddingId = ODMOWA.
   (uwaga: symulator NIE odwzorowuje zapytań list — nie ufaj mu dla list)
5. Reguły: `firebase deploy --only firestore:rules`.
6. Testy dymne legacy: otwórz Galeria, Księga, Rady, Mapa, Kapsuła,
   wyniki gier. Szukaj w konsoli:
   - `permission-denied` → reguły blokują listę (problem #2) → ROLLBACK + plan B
   - `failed-precondition ... requires an index` → brak indeksu, poczekaj
   - dane widoczne → OK

**ROLLBACK (< 1 min):** konsola Firebase → Firestore → Reguły → wklej
zapisane reguły z kroku 0 → Publikuj.

**Plan B** (gdyby listy legacy dostały permission-denied): przenieść legacy
ze ścieżki globalnej pod `weddings/{id}/legacy...` (reguła oprze się na
ścieżce zamiast na `resource.data` — dla list działa pewnie). Większa
migracja — tylko jeśli test tego wymaga.

### Znane, ZAAKCEPTOWANE ryzyka po 5b (do domknięcia przed wydaniem)
- Gość-członek (dołączył kodem) czyta CAŁY dokument wesela (budżet, RSVP) —
  to D1. Kod 6-znakowy + brute-force też tu prowadzi. Ochrona = rozdzielenie
  danych (D1 droga B).
- Brak limitu LICZBY wpisów gościa (spam) — reguły tego nie rozwiążą,
  potrzebny App Check / Cloud Function z licznikiem.
- Regresja: gdy nie-owner (planer/współorg.) zmieni datę/nazwiska, indeks
  `weddingCodes` się nie zaktualizuje → gość dostanie „nieprawidłowe dane".
  Obejście: owner raz zapisuje konfigurację. Ostrzeżenie w UI dodane.
  Trwałe: Cloud Function na triggerze `weddings/{id}`.
- Ryzyko techniczne: zapytania LISTOWE legacy oparte na `resource.data.weddingId`
  mogą dostać permission-denied (niesprawdzone bez emulatora/Javy). Wykryjemy
  w testach dymnych; plan B gotowy.

To jest najważniejsza część — od niej zależy prywatność ludzi.

### ⚠️ ZADANIE PRZED WYDANIEM PUBLICZNYM (case D1 — rozdzielenie danych)

**Problem:** całe wesele jest trzymane w JEDNYM dokumencie Firestore
(budżet, goście, dostawcy — wszystko jako pola). Reguły Firestore działają
na poziomie całego dokumentu, nie pojedynczych pól. Dlatego **gość, który
musi czytać dokument wesela (bo jego panel go czyta), technicznie widzi
całość — łącznie z budżetem.** Interfejs to ukrywa („miękkie" ograniczenie),
ale surowe dane są dostępne.

**Decyzja (podjęta):** droga A — na etapie budowy/testów izolujemy WESELA
od siebie (konto A nie widzi wesela B — to działa w pełni), a ukrycie
budżetu przed gościem zostaje na poziomie interfejsu. Rozdzielenie danych
robimy później.

**REALIZACJA — wariant rekomendowany (NIE pełny podział!):** analiza Claude
Code wykazała, że przenoszenie budżetu do `weddings/{id}/private/...` NIE daje
bezpieczeństwa (reguły Firestore nie są dziedziczone między dokumentem a
podkolekcją). Cel osiąga się prościej: (1) gość przestaje czytać
`weddings/{id}` — czyta mały `weddings/{id}/guestView/main` (guestToken +
nazwa + data) i całą treść z `guestSpaces/{token}` (już działa); (2) reguła
odczytu `weddings/{id}` zawęża się z `activeMember` do `fullAccess`.
~200 linii w ~4 plikach zamiast ~2000 w ~50. Ten sam efekt bezpieczeństwa.

**Kolejność etapów (reguła zmienia się OSTATNIA):**
0. Pomiar rozmiaru dokumentu wesela (jeśli >400 KB → D3 pilniejsze).
1. `guestView/main` zapisywany przy syncu mirrora, jeszcze nieużywany.
2. Migracja: owner każdego wesela raz otwiera Ustawienia → guestView powstaje.
3. Przepięcie `listForUser`: gość czyta guestView, nie dokument wesela.
4. `GuestHomeScreen` → renderuje `GuestWebHome` (ten sam interfejs co QR).
5. DOPIERO teraz: reguła `weddings/{w}` read → `fullAccess`.
6. Sprzątanie + filtrowanie harmonogramu do mirrora (domyka audyt 5a).

**Pułapka #1 (jak przy legacy):** `listForUser` robi `get()` na dokumencie
wesela dla KAŻDEGO membershipu (też gościa). Zacieśnienie reguły PRZED naprawą
tej pętli wywali gościowi listę wesel wyjątkiem. Reguła MUSI iść po kodzie.

**D3 — pełny podział dokumentu (OSOBNE zadanie, nie teraz):** uzasadnione
limitem 1 MB Firestore na dokument (guests+tables+expenses przy ~250 gościach
zbliża się do granicy), NIE bezpieczeństwem. Duże (~50 plików). Odłożone.

**„Twoje miejsce" gościa:** osobny projekt (powiązanie konta z wpisem gościa
+ dane per osoba). Dziś placeholder. D1 go nie rozwiązuje.

**Status:** W TOKU (wariant rekomendowany). Na czas budowy droga A wystarcza.
NIE wydawać publicznie bez dokończenia D1.

**Zasada:** użytkownik może czytać i pisać TYLKO dane wesela, do którego
należy. Nigdy cudze.

Reguły Firestore (koncepcyjnie, nie finalny kod):
- `weddings/{weddingId}` — zapis/odczyt tylko jeśli `users/{ktoś}.weddingId
  == weddingId` (czyli należy do tego wesela).
- Dane gości (publiczne, przez QR) — osobne, ograniczone kolekcje
  z zapisem publicznym, ale **tylko** pod konkretnym `weddingId`
  (gość pary A nie zapisze nic parze B).

> Bez poprawnych reguł każdy mógłby zobaczyć cudze wesele. To jest ten
> punkt, w którym NIE wolno się spieszyć i który trzeba przetestować.

---

## 5. Strony dla gości — jedna wspólna strona po ID (rozwiązanie A)

Zamiast osobnej strony na parę (Wasza `ceremonia-patrycji-i-piotra.pl`):

**Jedna wspólna strona/hosting dla całej platformy**, która pokazuje
dane konkretnego wesela na podstawie ID w adresie.

Przykłady linków w QR:
```
twojaplatforma.pl/rsvp?w=abc123        ← RSVP wesela abc123
twojaplatforma.pl/galeria?w=abc123     ← galeria wesela abc123
twojaplatforma.pl/quiz?w=abc123        ← quiz wesela abc123
```

- Para generuje QR w panelu → QR zawiera jej `weddingId`.
- Gość skanuje → strona czyta `w=abc123` → pokazuje to wesele.
- Ta sama strona obsługuje tysiące wesel, każde po swoim ID.

**Zalety:** jeden hosting, najtańsze utrzymanie, skaluje się, brak
instalacji dla gości.

**Do przemyślenia później:** ładniejsze linki (np. `/kowalscy` zamiast
`?w=abc123`) — możliwe, ale to dodatkowa warstwa; na start wystarczy ID.

---

## 6. Gdzie wchodzi PREMIUM (plany płatne)

Model do doprecyzowania, ale szkielet:

| Funkcja                                  | Free           | Premium/Płatny |
|------------------------------------------|----------------|----------------|
| Jedno wesele, podstawowy panel           | ✅             | ✅             |
| Goście, budżet, plan sali, harmonogram   | ✅             | ✅             |
| Gry i pamiątki dla gości                 | częściowo?     | ✅ pełne       |
| Współorganizatorzy (zespół 3/4/8 osób)   | ❌             | ✅             |
| Ikona premium (Dashboard)                | ❌             | ✅             |
| (inne — do ustalenia)                    | —              | —              |

- Rozpoznawanie premium: **Google Play Billing** (zakup w aplikacji).
- Na czas budowy/testów: flaga `isPremium` (już wprowadzana).
- Status premium zapisany przy weselu/koncie i sprawdzany przy funkcjach.

---

## 7. Co trzeba usunąć / zmienić względem wersji dla Was

- ❌ Lista trzech maili na sztywno → ✅ rejestracja dowolnego konta.
- ❌ Wasze imiona / data / miejsca na sztywno → ✅ puste, wypełniane przez
  parę przy zakładaniu wesela (onboarding).
- ❌ `weddingPlanner/main` (jeden zestaw) → ✅ `weddings/{id}/...` (per para).
- ❌ Linki gości do `ceremonia-patrycji-i-piotra.pl` → ✅ wspólna strona
  z `?w={weddingId}`.
- ➕ Wybór roli przy wejściu (Para / Gość).
- ➕ Ekran zakładania wesela (pierwsze uruchomienie Pary).
- ➕ Polityka prywatności + regulamin (wymóg Google Play, dane osobowe gości).

---

## 8. Bezpieczna kolejność budowania

Robimy po kolei, testując po każdym kroku. NIE wszystko naraz.

1. **Fundament danych** — struktura `weddings/{id}` + `users/{id}` +
   `memberships`. Tworzenie wesela → nadanie ID → wpis membership (owner).
2. **Wybór/lista wesel** — po zalogowaniu ekran „Twoje wesela": lista
   z `memberships` + przycisk „Nowe wesele". Wybór wczytuje dane wesela.
   (obsługuje też planera z wieloma weselami)
3. **Izolacja** — reguły Firestore: użytkownik czyta/pisze tylko wesela,
   do których ma `membership`. Przetestować że konto A nie widzi wesela B.
4. **Rejestracja / logowanie** — usunięcie listy maili, dowolne konto Google,
   onboarding zakładania pierwszego wesela.
5. **Rola Gość + strony po ID** — wejście gościa przez ID/QR, ograniczony
   dostęp (miejsce, zdjęcia, gry, muzyka, RSVP), wspólna strona z `?w=id`.
   Gość może założyć konto → własne wesele.
6. **Współorganizatorzy** — zapraszanie do wesela (dodatkowe `memberships`),
   role (owner/planner/collaborator). Część premium.
7. **Czyszczenie** — usunięcie wszystkiego „Waszego", domyślne puste dane.
8. **Premium** — plany, Google Play Billing, blokady funkcji (w tym zespół,
   limit wesel dla planera itd.).
9. **Formalne** — polityka prywatności, regulamin, zgody, publikacja w Google Play.

### ⚠️ Twarde zadania PRZED wydaniem publicznym (nie zapomnieć!)
- [x] ~~**D1 — rozdzielenie danych**: gość nie widzi budżetu/danych wrażliwych.~~
      ✅ ZAMKNIĘTE (6 etapów: guestView/main + reguła weddings→fullAccess;
      gość czyta tylko guestView + guestSpaces; harmonogram filtrowany białą
      listą, punkty private ukryte, responsible/locationUrl kontrolowane;
      wyłapano realny wyciek prywatnych punktów harmonogramu). D3 (podział dla
      skalowania) i „Twoje miejsce" gościa zostają osobno.
- [x] ~~Zastąpić testowe reguły `if true` prawdziwymi regułami izolacji.~~ ✅ ZROBIONE
- [ ] Przywrócić logowanie / wyłączyć `bypassLogin` na stałe. (logowanie już wróciło,
      flaga zostaje do testów — wyłączyć przed wydaniem)
- [ ] Usunąć wszystkie dane „Wasze" (imiona, data, prywatne linki).
- [ ] Polityka prywatności + regulamin (wymóg Google Play).
- [ ] Podmienić linki gości z prywatnej domeny na wspólną platformę `?w=id`.
      (mechanizm tokenów gościa już działa)
- [ ] Osobne konto Google + docelowy projekt Firebase pod markę.
- [ ] **Zmienić applicationId na DOCELOWY** (`com.ceremonia.*` nieodwracalny po Play).
      UWAGA: obecnie już zmieniony na TYMCZASOWY `com.ceremonia.mojewesele.pub`
      (stary `com.ceremonia.moje_wesele` kolidował z prywatną — ten sam
      package+SHA-1 nie może być w 2 projektach OAuth naraz → logowanie Android
      padało). Pod wydanie zmienić na docelowy pod markę.
      Przy zmianie package naprawiono też logowanie Google Android: w
      auth_service.dart `serverClientId` wskazywał na projekt PRYWATNY
      (prefiks 719030954518) — poprawiono na publiczny
      (221816723659-n11b...apps.googleusercontent.com); firebase_options.dart
      android appId poprawiony na nowy (1:221816723659:android:8376d7fc...).
      Klient OAuth Android tworzy się automatycznie po dodaniu SHA-1 w Firebase.
      NIE usuwać serverClientId (google_sign_in v7 go wymaga na Androidzie).
- [ ] **mobile_scanner + KGP** — plugin używa starego Kotlin Gradle Plugin;
      przyszłe wersje Fluttera mogą wymagać aktualizacji (dziś tylko ostrzeżenie,
      działa). Sprawdzić przy większej aktualizacji Fluttera.
- [ ] Przywrócić release keystore / podpis produkcyjny (nie debug) do Google Play.
- [ ] **Dłuższy kod wesela** (obecnie 6 znaków — teoretycznie brute-force; wydłużyć).
- [x] ~~Domknąć „governance": nie pozwalać nadać drugiej roli owner.~~ (roleInvites→isOwner ✅)
- [x] ~~Wyczyścić stare testowe memberships.~~ ✅ ZROBIONE (blokowały listę wesel)
- [x] ~~Filtrować harmonogram do mirrora gości.~~ ✅ ZROBIONE w D1 etap 6
      (biała lista pól; punkty private ukryte; responsible nigdy; locationUrl
      tylko gdy showLinkToGuests; sortowanie chronologiczne)
- [ ] **Antyspam strefy gości** (analiza zrobiona — realne zagrożenie: znudzony
      gość z telefonem, nie botnet; token jest na QR na stołach):
      - [x] ~~Cloudinary limity — największa realna dziura (koszt zdjęć).~~ ✅
      - [x] ~~**Jeden RSVP/wpis na gościa** (anonimowe logowanie + ID = uid).~~
            ✅ ZROBIONE (etapy A-D: anonimowe logowanie w tle gdy currentUser==null;
            RSVP/mapa/wyniki gier/bingo/foto-wyzwania pod uid = jeden na gościa
            z edycją własnego; list zamknięte na orgOf; foto-wyzwania isSelfChallenge;
            księga/rady/galeria bez limitu). To „jeden na przeglądarkę" — spowalniacz.
      - [ ] **App Check** — reCAPTCHA v3 JEST dostępne bez Blaze (sprawdzone
            w konsoli, obok Enterprise). ODŁOŻONE do przenosin na docelowe konto/
            projekt (żeby nie konfigurować dwa razy). Wtedy: klucz reCAPTCHA v3
            (localhost + domena) → rejestracja web w App Check → init w kodzie
            (try/catch, tylko web) → monitoring 24h → wymuszenie dopiero po
            czystych statystykach. NIGDY nie włączać wymuszenia w tygodniu wesela.

### 🔔 POWIADOMIENIA
**Etap 1 — ✅ ZROBIONE (darmowe, Spark): dzwoneczek in-app.**
Mechanizm: DIFF SNAPSHOTU (nie dziennik zdarzeń) — porównanie bieżących danych
z ostatnio widzianym odciskiem w SharedPreferences (notif_seen_{uid}_{weddingId}),
zero zmian w regułach/serwisach/kolekcjach. Deterministyczne ID powiadomień
(przeczytane nie wraca). Pierwsze uruchomienie po cichu (bez zalewu). Dzwoneczek
z licznikiem, panel z kumulacją po sekcjach, tekst „co zrobiono", nawigacja do
sekcji. OWNER/PLANER: RSVP, nowy gość, stoły, zadania, harmonogram, terminy,
nowa osoba, treści gości. GOŚĆ: tylko zmiany w harmonogramie (z mirrora).
Ekran ustawień push gotowy (przełączniki, SharedPreferences, baner „wkrótce").
Ograniczenie (świadome): „nieprzeczytane" per urządzenie, zmiany przy zamkniętej
apce widać zbiorczo przy otwarciu — OK dla in-app.
**Etap 2 — PÓŹNIEJ (pakiet Blaze): PUSH na telefon** gdy apka zamknięta
(FCM + Cloud Function). Preferencje push przeniosą się z SharedPreferences do
Firestore (users/{uid}) — wtedy zmiana reguł. PushPrefsService ma wąskie API
(load/save/toggle), więc podmiana magazynu nie dotknie ekranu ustawień.

### 📦 PAKIET BLAZE (jedna decyzja przed wydaniem publicznym — nie po kawałku!)
Te zadania wymagają planu Blaze (karta płatnicza; darmowe progi wystarczą, koszt grosze):
- Cloud Function: liczniki limitów N wpisów gościa (księga, galeria, foto-wyzwania)
- Cloud Function: backfill guestView + trigger onWrite (D1 — dla tysięcy par)
- Cloud Function: synchronizacja indeksu weddingCodes przy zmianie daty/nazwisk
- Wymuszenie App Check (po okresie monitorowania)
- PUSH notyfikacje (FCM + Cloud Function) — etap 2 powiadomień
Podjąć świadomie razem, gdy projekt przechodzi na Blaze.
- [x] ~~RSVP: osobna reguła odczytu (tylko organizator).~~ ✅ ZROBIONE (RSVP + kapsuła)
- [x] ~~5b-part-2: galeria (upload), muzyka, gry pod guestSpaces/{token}.~~ ✅ ZROBIONE
      (muzyka+wyniki gier = tylko organizator; galeria+foto-wyzwania = publiczne;
      walidacja pól/rozmiaru/timestamp + regex Cloudinary; reguły wdrożone)
- [ ] Trwałe: Cloud Function synchronizująca indeks `weddingCodes` przy zmianie
      daty/nazwisk przez nie-ownera (dziś obejście: owner zapisuje konfigurację).
      **+ backfill/trigger guestView** (D1) — ta sama funkcja: przy wydaniu
      publicznym nie zmusi się tysiąca par do klikania „Przygotuj strefę gości",
      potrzebny backfill w Cloud Function + trigger onWrite. Zrobić naraz z
      weddingCodes, gdy projekt przejdzie na plan Blaze.
- [x] ~~Cloudinary — ustawić limity (rozmiar, formaty, folder).~~ ✅ ZROBIONE
      (preset Ceremonia_Patrycji_i_Piotra — ustawione limity; przetestować że
      upload nadal działa dla normalnych zdjęć)
- [ ] **Quiz: odpowiedzi w mirrorze** (correctIndex, isTrue) — da się podejrzeć
      w DevTools przed grą. Pełna naprawa = liczenie punktów w Cloud Function.
      (akceptowalne dla zabawy weselnej; wyniki i tak widzi tylko Para)
- [ ] **Wyniki gier liczone na kliencie** — da się wysłać 10/10. Skutek
      ograniczony (widzi tylko Para). Docelowo walidacja serwerowa.
- [ ] **D3 — próg alarmowy rozmiaru dokumentu**: ostrzeżenie w panelu przy
      ~500 KB (limit 1 MB odrzuca zapis = wesele niezapisywalne, bez łagodnego
      przejścia). Ponowny pomiar gdy pojawi się realne wesele >150 gości.
      (etap 0 D1: duże wesele ~28% limitu, skrajne ~47% — zapas 2-4x, spokojnie)

> Każdy krok = osobna sesja / seria promptów + test. Krok 2 (izolacja)
> jest najważniejszy dla bezpieczeństwa i tam idziemy najwolniej.

---

## 9. Rzeczy do decyzji (otwarte pytania)

- [ ] Nazwa marki/platformy i domena (wpływa na linki gości i konto Google Play).
- [ ] Czy Free ma limit (np. liczba gości), czy różni się tylko funkcjami?
- [ ] Cena i model: jednorazowo za wesele czy subskrypcja?
- [ ] Czy gość kiedykolwiek może się zalogować (np. by widzieć „swoje"
      wesela na które jest zaproszony), czy zawsze tylko przez QR?
- [ ] Osobne konto Google + osobny projekt Firebase pod markę (planowane).
- [ ] Ładne linki gości (`/nazwa`) teraz czy później.

---

## 10. Zasady bezpieczeństwa pracy (żeby nie stracić danych)

- Wersja dla Was (`moje-wesele-flutter`, projekt `wedding-planner-27148`)
  **nietknięta** — to Wasze prawdziwe wesele.
- Wersja publiczna (`moje-wesele-public`, projekt `wedding-planner-pub`)
  — tu budujemy, tu eksperymentujemy.
- Przed każdą większą zmianą: `git commit`.
- Nigdy nie mieszać projektów Firebase (sprawdzać `firebase use`).

---

## 11. LISTA POPRAWEK z testów (Chrome, sierpień 2026) — 24 punkty

**A. Konfiguracja / tworzenie wesela:**
1. ✅ ZROBIONE — LOKALIZACJA (infrastruktura + pl + en, wariant A). 2276 kluczy,
   - Mechanizm: flutter_localizations + gen-l10n + pliki .arb (typowane klucze,
     ICU plural, .arb = czysty JSON, zero nowych zależności).
   - Skala: ~2500-3000 kluczy w 124 plikach, 8 etapów. Największa pojedyncza partia.
   - WARIANT A (wybrany): pełna EKSTRAKCJA wszystkich tekstów do app_pl.arb TERAZ
     (najwięcej roboty), TŁUMACZENIE później aktualizacją (dorzucenie app_en.arb itd.).
   - Docelowe języki: pl, en, de, fr, it, es + chiński, japoński (te dwa WYMAGAJĄ
     weryfikacji natywnego mówcy przed wydaniem).
   - LocaleController jak DisplayModeController (ValueNotifier + SharedPreferences
     locale_$uid). Domyślny: ustawienia urządzenia, fallback POLSKI.
   - Strefa gościa: własny przełącznik (globus w nagłówku), klucz locale_guest
     (localStorage, bez uid). Tłumaczymy INTERFEJS, nie treści wpisane przez parę.
   - KLUCZOWE: wartość w bazie zostaje POLSKA, tłumaczy się tylko etykieta (wzorzec
     CoupleLabels) — inaczej zerwie dane wesel i wersję web. Rozszerzyć na
     GuestOptions.categories, menu, diety, groom/bride.
   - Pułapka const z #20: Listenable.merge dla przebudowy po zmianie języka.
   - Etapy: E1 infrastruktura+próbka → E2 wspólne → E3 goście/stoły → E4 budżet
     → E5 harmonogram/gry/pamiątki → E6 ustawienia+strefa gościa → E7 help+onboarding
     → E8 CoupleLabels/mapy wartość-etykieta/sprzątanie _plural.
   - WALUTA (przy okazji): wybór waluty jako ETYKIETA symbolu (PLN/EUR/USD...),
     BEZ przeliczania kursów — tylko zmienia się symbol przy kwotach. Format przez
     NumberFormat. Para płaci w swojej walucie niezależnie od języka gościa.

   **STAN KOŃCOWY (✅ zrobione, 8 etapów):**
   - 2276 kluczy w app_pl.arb i app_en.arb, zero rozjazdu, brak nieprzetłumaczonych.
   - 16 kluczy ICU plural zastąpiło WSZYSTKIE ręczne funkcje odmiany (_plural itd.).
   - 230 description dla tłumacza, 260 kluczy z podstawieniami. 285 testów zielonych.
   - Wygenerowane app_localizations*.dart w repo (nie gitignore).
   - LocaleController (locale_$uid), przełącznik w Ustawieniach (karta „Język
     i region"); strefa gościa ma własny przełącznik-globus w nagłówku
     (locale_guest, bez uid — bo gość niezalogowany). Globus w pasku NAD treścią,
     więc działa nawet przy komunikacie „nieprawidłowy link".
   - **LOGIKA DOBORU JĘZYKA (priorytety):**
     1. Ręczny wybór użytkownika (jeśli był) — zapamiętany, wygrywa ze wszystkim.
     2. Język urządzenia/przeglądarki (jeśli obsługiwany) — domyślnie automatycznie.
     3. POLSKI (fallback) — gdy język urządzenia nieobsługiwany (np. niemiecki →
        polski, NIE angielski; produkt jest polski, polski = bezpieczne „nie wiem").
     Skutek: telefon po angielsku → apka po angielsku; po niemiecku → po polsku;
     użytkownik może nadpisać ręcznie. Gość: start = język przeglądarki, fallback
     polski, własny zapis (locale_guest).
   - Waluta: Currency (PLN/EUR/USD/GBP/CZK/CHF) w appConfig.currency, tylko symbol,
     bez przeliczania kursów. Brak pola → PLN.
   - Wartości bazy zostają POLSKIE (labelFor pattern), tłumaczy się tylko etykieta —
     zero migracji, wersja web czyta te same wartości. Reguł NIE dotykano.
   - Bugi wyłapane po drodze: statusy członkostwa po tekście UI (→ po stanie),
     placeholderNames 'Osoba 1/2' porównywane z bazą, GuestSectionDef key vs label,
     symbol waluty na sztywno, luka w teście kompletności (ICU jako placeholder).
   **DODANIE KOLEJNEGO JĘZYKA = tylko nowy plik app_XX.arb + Locale('XX') w liście.**
   Docelowo: de, fr, it, es + chiński/japoński (te dwa WYMAGAJĄ natywnej weryfikacji).
   ⚠️ WERYFIKACJA RĘCZNA do zrobienia: przejście apki po angielsku, zwłaszcza PDF-y
   (księga/rady/bingo), okno biometrii Android, strefa gościa z QR — renderują się
   poza zwykłym drzewem widgetów.
2. ✅ ZROBIONE — typ uroczystości (mixed/women/men/neutral), etykiety z CoupleLabels.
8. ✅ ZROBIONE — przełącznik dzieci przy tworzeniu wesela + w Konfiguracji.
9. ✅ ZROBIONE — opcjonalne imiona Pary przy tworzeniu → rekordy gości.

**B. Goście — osoba towarzysząca / relacje / dzieci:**
3. ✅ ZROBIONE — typ relacji os. towarzyszącej (rodzina/para/nieznana).
4. ✅ ZROBIONE — os. towarzysząca powiązana z zapraszającym (invitedByGuestId);
   przy usuwaniu zapraszającego pyta czy usunąć oboje.
5. ✅ ZROBIONE — opcja os. towarzyszącej bez imienia (placeholder do uzupełnienia).
6. ✅ ZROBIONE — flaga isChild na gościu, tryb auto/manual liczenia, menu dziecięce, kalkulacje.
24. ✅ ZROBIONE — licznik odliczający czas do wesela w sekcji gości.

**C. Para Młoda (owner):**
11. ✅ ZROBIONE — etykiety wg typu uroczystości (CoupleLabels), imiona dla par jednopłciowych.
12. ✅ ZROBIONE — Para Młoda bez os. towarzyszącej (blokada w serwisie i UI).
13. ✅ ZROBIONE — limit 2 osób Pary Młodej (walidacja w serwisie).
23. ⚠️ BUG WERYFIKACJI (wykryty przy planie): ekran dołączania pyta o NAZWISKO
    Pary, ale porównuje z displayNames które ma IMIONA → gość z dobrymi danymi
    odrzucony. Naprawa: osobne pole „nazwisko do weryfikacji" (robione w partii
    typ uroczystości). ✅ RESZTA #23 ZROBIONA: sekcja QR z pełnymi danymi (kod,
    data, nazwisko do weryfikacji) + opis krok po kroku jak gość dołącza.

**D. Plan sali:**
7. ✅ ZROBIONE — stół dla dzieci (dostępny z obu sekcji, oznaczenie, ostrzeżenie przy sadzaniu).
10. ✅ ZROBIONE — rozmiar stołu w edycji działa.
14. ✅ ZROBIONE — widok odświeża się po dodaniu do stołu + komunikat potwierdzenia.

**E. Harmonogram:**
15. ✅ ZROBIONE — harmonogram pokazuje wpisane dane po dodaniu.
16. (literówka — nieaktualne)

**F. Przewodnik / pomoc / onboarding:**
17. ✅ ZROBIONE — kreator „Poprowadź mnie za rękę" (czwarty byt: co wpisać w apce);
    poziomy podstawowa/zaawansowana; postęp LICZONY detektorami done() bez zapisu.
18. ✅ ZROBIONE — krok „od czego zacząć" pokazuje podgląd kroków planowania w dymku.
21. ✅ ZROBIONE — wariant gościa: jeden przewodnik (całość), baner podglądu dla organizatora.
22. ✅ ZROBIONE — Pomoc + przewodnik: jak dodać planera/współorganizatora (rola, kod, data ważności).

**G. Inne sekcje / bugi:**
19. ✅ ZROBIONE — Analityka naprawiona (diagnoza + stan pusty/wykresy).
20. ✅ ZROBIONE — wymuszenie trybu telefon/tablet działa.

**Status:** DO ZROBIENIA. Grupować w partie (nie wszystko jednym promptem).
Sugerowana kolejność: najpierw bugi blokujące (4,10,14,15,19,20), potem typ
uroczystości + para (2,11,12,13,23) bo dotyka etykiet wszędzie, potem dzieci
(6,7,8), potem reszta.

---

## 12. STRATEGIA MONETYZACJI (decyzja — przygotować grunt już teraz)

**Kolejność wdrażania (od najprostszego):**
1. **START: aplikacja DARMOWA, bez reklam** — zbudować bazę użytkowników, opinie,
   sprawdzić czy się chwyta. Zero przychodu = zero formalności (bez VAT/JDG).
   Tylko Android na start (iOS: 99 USD/rok + nazwisko zamiast marki — później).
2. **POTEM: reklamy** (AdMob) — dla wersji darmowej.
3. **POTEM: premium** — wersja płatna bez reklam + funkcje premium.

**KLUCZOWE — projektować już teraz tak, by dało się to dołożyć bez rewolucji:**
- **Flaga poziomu konta** — ✅ ZROBIONE. Pole `tier: 'free'/'premium'` w
  weddings/{id}, domyślnie 'free', brak/nieznane → free (bez migracji).
  wedding_tier.dart: WeddingTier + PremiumAccess (jedyne miejsce decyzji).
  `tierOf()` = co zapisane (diagnostyka), `isPremium()` = co wolno.
  ⚠️ GŁÓWNY WYŁĄCZNIK: PremiumAccess.monetizationEnabled = false → isPremium()
  zawsze false, nawet gdy ktoś ręcznie wpisze tier:premium (ochrona kliencka).
  Grandfathering zapisany w kodzie (4 zasady). Zero ograniczeń/UI/płatności teraz.
  ⚠️⚠️ PRZED WŁĄCZENIEM MONETYZACJI (monetizationEnabled=true): KONIECZNIE zmienić
  reguły — klient NIE może zapisywać pola tier (dziś może, bo zapisuje cały
  dokument wesela). Zapis premium TYLKO z serwera (Cloud Function weryfikująca
  zakup Google Play). Dziś chroni wyłącznik w kodzie = zabezpieczenie klienckie,
  nie serwerowe. To zadanie do pakietu Blaze.
- **Miejsca na reklamy** przemyślane w layoutcie (gdzie baner nie psuje eleganckiego
  charakteru; NIE w strefie gości — to psuje wrażenie pary; raczej w panelu organizatora).
- **Premium NIE może przeszkadzać obecnym użytkownikom**: kto zaczął jako free,
  zostaje z pełnym dostępem do tego co miał (grandfathering) — nowe ograniczenia
  tylko dla nowych, albo premium = DODATKOWE funkcje, nie odbieranie istniejących.
- **Reklamy tylko w wersji free**; premium = brak reklam + ekstra funkcje.
- Rozdzielić w kodzie „co jest za darmo" od „co premium" flagą, nie hardkodem —
  żeby zmiana progu była zmianą konfiguracji, nie przepisywaniem.

**Uwagi formalne (potwierdzić z księgowym przy monetyzacji):**
- Reklamy AdMob = przychód od Google Ireland → prawdopodobnie VAT-UE (rejestracja
  VAT-R + VAT-UE) nawet w działalności nierejestrowanej. Dużo formalności za grosze.
- Reklamy w aplikacji weselnej dają realnie mało (krótki cykl życia użytkownika,
  utility nie gra, próg wypłaty AdMob 10 USD) — kilkadziesiąt zł/mies. przy niszy.
- **Model PŁATNY (jednorazowo za wesele, np. 30-50 zł) pasuje LEPIEJ** niż reklamy:
  więcej pieniędzy, lepszy UX, mniej formalności. Rozważyć jako główny model
  zamiast/obok reklam.
- Ścieżka firmy: darmowa (bez firmy) → nierejestrowana (limit 10 813,50 zł/kwartał
  2026, bez ZUS) → JDG gdy urośnie (ulgi: start 6 mies. ~430 zł, preferencyjny
  24 mies. ~900 zł). JDG można ZAWIESIĆ gdy nie zarabia (zero ZUS).
