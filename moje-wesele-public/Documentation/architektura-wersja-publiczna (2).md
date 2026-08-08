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

**Co trzeba zrobić przed sprzedażą publiczną (droga B):** rozbić dokument
wesela na OSOBNE dokumenty/podkolekcje — np. `weddings/{id}/budget`,
`weddings/{id}/guests`, `weddings/{id}/public` (treści dla gości) itd. —
tak, aby reguły mogły dać gościowi dostęp TYLKO do części publicznej,
a budżet i dane organizacyjne były technicznie niedostępne dla roli guest.
To duża przebudowa (dotyka każdej sekcji — zmienia się gdzie każda sekcja
zapisuje). Musi być zrobiona i przetestowana przed publicznym wydaniem.

**Status:** ODŁOŻONE. Na czas budowy droga A wystarcza. NIE wydawać
publicznie bez drogi B.

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
- [ ] **D1 — rozdzielenie danych** (droga B): budżet/dane organizacyjne
      w osobnych dokumentach, technicznie niedostępne dla gościa. (patrz sekcja 4)
- [x] ~~Zastąpić testowe reguły `if true` prawdziwymi regułami izolacji.~~ ✅ ZROBIONE
- [ ] Przywrócić logowanie / wyłączyć `bypassLogin` na stałe. (logowanie już wróciło,
      flaga zostaje do testów — wyłączyć przed wydaniem)
- [ ] Usunąć wszystkie dane „Wasze" (imiona, data, prywatne linki).
- [ ] Polityka prywatności + regulamin (wymóg Google Play).
- [ ] Podmienić linki gości z prywatnej domeny na wspólną platformę `?w=id`.
      (mechanizm tokenów gościa już działa)
- [ ] Osobne konto Google + docelowy projekt Firebase pod markę.
- [ ] Przywrócić release keystore / podpis produkcyjny (nie debug) do Google Play.
- [ ] **Dłuższy kod wesela** (obecnie 6 znaków — teoretycznie brute-force; wydłużyć).
- [x] ~~Domknąć „governance": nie pozwalać nadać drugiej roli owner.~~ (roleInvites→isOwner ✅)
- [x] ~~Wyczyścić stare testowe memberships.~~ ✅ ZROBIONE (blokowały listę wesel)
- [ ] **Filtrować harmonogram do mirrora gości** — tylko pola jawnie dla gości.
- [ ] **Walidacja + limity LICZBY wpisów gości** + **Firebase App Check** (antyspam).
      (walidacja pól/rozmiaru + timestamp już są; brakuje limitu liczby wpisów)
- [x] ~~RSVP: osobna reguła odczytu (tylko organizator).~~ ✅ ZROBIONE (RSVP + kapsuła)
- [ ] **5b-part-2**: podłączyć galerię (upload), muzykę, gry pod guestSpaces/{token}
      (obecnie zablokowane domyślnie — do zwiring'owania).
- [ ] Trwałe: Cloud Function synchronizująca indeks `weddingCodes` przy zmianie
      daty/nazwisk przez nie-ownera (dziś obejście: owner zapisuje konfigurację).

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
