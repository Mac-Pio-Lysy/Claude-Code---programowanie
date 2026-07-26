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

## 2. Role użytkowników

### Para Młoda (organizator)
- Loguje się (konto — na start Google).
- Zakłada swoje wesele → dostaje **ID wesela**.
- Ma pełny panel: goście, budżet, plan sali, harmonogram, gry, pamiątki itd.
- Może zaprosić współorganizatorów (świadek, mama) — to już „zespół"
  (funkcja płatna / wyższy plan).

### Gość
- **Nie instaluje aplikacji. Nie loguje się.**
- Skanuje QR albo dostaje link → otwiera się **wersja web** z konkretnym
  weselem (ID w linku).
- Widzi tylko to jedno wesele: RSVP, galeria, muzyka, gry, harmonogram
  dla gości, księga gości itd.
- Podaje swoje imię przy interakcjach (bez konta).

> Ta sama aplikacja Flutter buduje się i jako **app na Androida** (dla Pary),
> i jako **strona web** (dla Gości). Jeden kod, dwa wyjścia.

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

### Powiązanie konta z weselem
```
users/
  {userId}/
      weddingId          ← do którego wesela należy ten użytkownik
      role               ← "owner" (Para) lub "collaborator" (zespół)
```
Jeden użytkownik może mieć dostęp do jednego wesela (lub kilku, jeśli
kiedyś zechcesz — np. ktoś planuje dwa). Na start: jedno.

---

## 4. Izolacja i bezpieczeństwo danych (KRYTYCZNE)

To jest najważniejsza część — od niej zależy prywatność ludzi.

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

1. **Fundament danych** — struktura `weddings/{id}` + `users/{id}`,
   zakładanie wesela, przypisanie ID. (bez ról jeszcze)
2. **Izolacja** — reguły Firestore, żeby konto widziało tylko swoje wesele.
   Przetestować że konto A nie widzi wesela konta B.
3. **Rejestracja / logowanie** — usunięcie listy maili, dowolne konto Google,
   onboarding zakładania wesela.
4. **Rola Gość + strony po ID** — wybór roli, wspólna strona gości z `?w=id`,
   QR generowane z ID wesela.
5. **Czyszczenie** — usunięcie wszystkiego „Waszego", domyślne puste dane.
6. **Premium** — plany, Google Play Billing, blokady funkcji.
7. **Formalne** — polityka prywatności, regulamin, zgody, przygotowanie
   do publikacji w Google Play.

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
