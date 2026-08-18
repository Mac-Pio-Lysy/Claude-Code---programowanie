// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get common_add => 'Dodaj';

  @override
  String get common_cancel => 'Anuluj';

  @override
  String get common_save => 'Zapisz';

  @override
  String get common_delete => 'Usuń';

  @override
  String get common_edit => 'Edytuj';

  @override
  String get common_close => 'Zamknij';

  @override
  String get common_back => 'Wstecz';

  @override
  String get common_next => 'Dalej';

  @override
  String get common_done => 'Gotowe';

  @override
  String get common_search => 'Szukaj';

  @override
  String get common_none => '—';

  @override
  String get common_savedToast => 'Zapisano zmiany';

  @override
  String common_saveErrorToast(String error) {
    return 'Błąd zapisu: $error';
  }

  @override
  String common_guestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gości',
      few: '$count gości',
      one: '1 gość',
      zero: 'Brak gości',
    );
    return '$_temp0';
  }

  @override
  String get settings_title => 'Ustawienia';

  @override
  String get settings_configCard => 'Konfiguracja';

  @override
  String get settings_languageCard => 'Język i region';

  @override
  String get settings_language => 'Język aplikacji';

  @override
  String get settings_languageHint =>
      'Zmiana działa od razu, bez restartu aplikacji.';

  @override
  String get settings_languageSystem => 'Jak w systemie';

  @override
  String get settings_currency => 'Waluta';

  @override
  String get settings_currencyHint =>
      'Zmienia tylko symbol przy kwotach. Nie przelicza kursów — wpisane kwoty zostają takie same.';

  @override
  String get settings_notificationsCard => 'Powiadomienia';

  @override
  String get settings_helpButton => 'Pomoc';

  @override
  String get settings_tourButton => 'Uruchom przewodnik';

  @override
  String get settings_planningButton => 'Od czego zacząć?';

  @override
  String get settings_setupWizardButton => 'Poprowadź mnie za rękę';

  @override
  String get settings_logoutButton => 'Wyloguj się';

  @override
  String get language_pl => 'Polski';

  @override
  String get language_en => 'Angielski';

  @override
  String get common_confirm => 'Potwierdź';

  @override
  String get common_retry => 'Spróbuj ponownie';

  @override
  String get common_copy => 'Kopiuj';

  @override
  String get common_open => 'Otwórz';

  @override
  String get common_select => 'Wybierz';

  @override
  String get common_all => 'Wszyscy';

  @override
  String get common_deleteConfirmBody => 'Tej operacji nie da się cofnąć.';

  @override
  String common_deleteErrorToast(String error) {
    return 'Błąd usuwania: $error';
  }

  @override
  String get common_copiedToast => 'Skopiowano';

  @override
  String get date_pickDate => 'Wybierz datę';

  @override
  String get guests_categoryWitnesses => 'Świadkowie';

  @override
  String get guests_categoryParents => 'Rodzice';

  @override
  String get guests_categoryFamily => 'Rodzina';

  @override
  String get guests_categoryFriends => 'Znajomi';

  @override
  String get guests_categoryWork => 'Praca';

  @override
  String get guests_categoryOther => 'Inne';

  @override
  String get guests_genderFemale => '♀ Kobieta';

  @override
  String get guests_genderMale => '♂ Mężczyzna';

  @override
  String get guests_genderNonbinary => '⚧ Niebinarna';

  @override
  String get guests_dietStandard => 'Standardowa';

  @override
  String get guests_dietVegetarian => 'Wegetariańska';

  @override
  String get guests_dietVegan => 'Wegańska';

  @override
  String get guests_dietGlutenFree => 'Bezglutenowa';

  @override
  String get guests_dietOther => 'Inne';

  @override
  String get guests_menuMeat => 'Danie mięsne';

  @override
  String get guests_menuFish => 'Danie rybne';

  @override
  String get guests_menuVegetarian => 'Wegetariańskie';

  @override
  String get guests_menuVegan => 'Wegańskie';

  @override
  String get guests_menuChild => 'Dla dziecka';

  @override
  String get guests_filterAssigned => 'Przypisani';

  @override
  String get guests_filterUnassigned => 'Nieprzypisani';

  @override
  String get guests_filterWitnesses => '🤝 Świadkowie';

  @override
  String get guests_filterChildren => '🧒 Dzieci';

  @override
  String get guests_title => 'Goście';

  @override
  String get guests_addButton => 'Dodaj gościa';

  @override
  String guests_addedToast(String name) {
    return 'Dodano gościa: $name';
  }

  @override
  String get guests_deleteTitle => 'Usunąć gościa?';

  @override
  String guests_deleteBody(String name) {
    return 'Czy na pewno usunąć gościa „$name”? Zostanie też zwolnione jego miejsce przy stole.';
  }

  @override
  String get guests_deletedToast => 'Usunięto gościa';

  @override
  String get guests_noName => '(bez imienia)';

  @override
  String guests_countOf(int shown, int total) {
    return '$shown z $total';
  }

  @override
  String get guests_badgeNoTable => 'Bez stołu';

  @override
  String get guests_badgeChild => '🧒 Dziecko';

  @override
  String get guests_badgeAccommodation => '🏨 Nocleg';

  @override
  String guests_badgeCompanionOf(String name) {
    return '👥 z: $name';
  }

  @override
  String get guests_companionPlaceholder => 'osoba towarzysząca';

  @override
  String get guests_formEditTitle => 'Edytuj gościa';

  @override
  String get guests_formAddTitle => 'Dodaj gościa';

  @override
  String get guests_formFirstName => 'Imię *';

  @override
  String get guests_formFirstNameHint => 'np. Anna';

  @override
  String get guests_formFirstNameRequired => 'Podaj imię gościa';

  @override
  String get guests_formLastName => 'Nazwisko';

  @override
  String get guests_formLastNameHint => 'np. Kowalska';

  @override
  String get guests_formInvitedBy => 'Zaproszony przez';

  @override
  String get guests_formChoose => '— wybierz —';

  @override
  String get guests_formCategory => 'Kategoria';

  @override
  String get guests_formGender => 'Płeć';

  @override
  String get guests_formRole => 'Rola';

  @override
  String get guests_formNoRole => 'Brak roli';

  @override
  String get guests_formDiet => 'Dieta / menu';

  @override
  String get guests_formNoMenu => '— brak —';

  @override
  String get guests_formIsChild => '🧒 To dziecko';

  @override
  String get guests_formIsChildHint =>
      'Dzieci są wyłączane z przeliczeń alkoholu i mogą mieć osobne menu.';

  @override
  String get guests_formAccommodation => '🏨 Potrzebuje noclegu';

  @override
  String guests_formCoupleLimit(int max) {
    return 'Para Młoda to najwyżej $max osoby — komplet już jest na liście.';
  }

  @override
  String get guests_companionSwitch => '👥 Z osobą towarzyszącą?';

  @override
  String guests_companionForCouple(String category) {
    return 'Para Młoda nie ma osoby towarzyszącej — drugą osobę dodaj jako osobny wpis w kategorii „$category”.';
  }

  @override
  String get guests_companionRelation => 'Typ relacji';

  @override
  String get guests_companionNameUnknown => 'Imienia jeszcze nie znam';

  @override
  String get guests_companionNameUnknownHint =>
      'Zapiszemy „Osoba towarzysząca” — dane uzupełnisz później. Osoba i tak liczy się do listy gości i do cateringu.';

  @override
  String get guests_companionFirstName => 'Imię os. towarzyszącej';

  @override
  String get guests_companionLastName => 'Nazwisko os. towarzyszącej';

  @override
  String get guests_companionCategory => 'Kategoria os. towarzyszącej';

  @override
  String guests_companionInherit(String category) {
    return 'Jak zapraszający ($category)';
  }

  @override
  String get guests_companionIsChild => '🧒 Osoba towarzysząca to dziecko';

  @override
  String get guests_companionInfo =>
      'Osoba towarzysząca zostanie dodana jako osobny gość powiązany z tą osobą — dzięki temu wiadomo, kto z kim przychodzi.';

  @override
  String get guests_relationPartner => 'Para';

  @override
  String get guests_relationFamily => 'Rodzina';

  @override
  String get guests_relationUnknown => 'Nieznana';

  @override
  String guests_summaryWitnesses(int target) {
    return '🤝 Świadkowie (cel: $target)';
  }

  @override
  String get guests_summaryWitnessesTotal => 'Wyznaczeni łącznie';

  @override
  String get guests_summaryChildren => '🧒 Dzieci';

  @override
  String get guests_summaryChildrenLabel => 'Dzieci';

  @override
  String get guests_summaryAdults => 'Dorośli';

  @override
  String get guests_summaryMenu => '🍽 Menu (co je)';

  @override
  String get guests_summaryNoMenu => 'Bez wyboru menu';

  @override
  String get guests_summaryDiets => '🥗 Diety';

  @override
  String get guests_summaryTransport => '🚌 Transport';

  @override
  String get guests_summaryTransportOwn => 'Własny';

  @override
  String get guests_summaryTransportOrganized => 'Zorganizowany';

  @override
  String get guests_summaryTransportNone => 'Bez transportu';

  @override
  String get guests_summaryAccommodation => '🏨 Nocleg';

  @override
  String get guests_summaryAccommodationNeeds => 'Potrzebuje';

  @override
  String get guests_summaryAccommodationAssigned => 'Przypisani do hotelu';

  @override
  String get guests_summaryRsvp => '✉ Potwierdzenia';

  @override
  String get guests_rsvpAttending => 'Przyjdzie';

  @override
  String get guests_rsvpNotAttending => 'Nie przyjdzie';

  @override
  String get guests_rsvpNoAnswer => 'Brak odpowiedzi';

  @override
  String get guests_cardFullName => 'Imię i nazwisko';

  @override
  String get guests_cardStatus => 'Status';

  @override
  String get guests_cardWith => 'Z kim';

  @override
  String get guests_cardMenu => 'Menu';

  @override
  String get guests_cardDietAllergies => 'Dieta / alergie';

  @override
  String get guests_cardTable => 'Stolik';

  @override
  String get guests_emptyFiltered => 'Brak gości spełniających kryteria.';

  @override
  String get guests_showFilters => 'Pokaż filtry';

  @override
  String get guests_hideFilters => 'Ukryj filtry';

  @override
  String get guests_detailInvitedBy => 'Zaproszony przez';

  @override
  String get tables_defaultName => 'Stół';

  @override
  String get tables_addButton => 'Dodaj stół';

  @override
  String get tables_addedToast => 'Dodano stół';

  @override
  String get tables_addTitle => 'Nowy stół';

  @override
  String get tables_name => 'Nazwa stołu';

  @override
  String get tables_shape => 'Kształt';

  @override
  String get tables_honorSwitch => '⭐ Stół Pary Młodej (honorowy)';

  @override
  String get tables_honorHint => 'Używa układu prostokątnego';

  @override
  String get tables_childSwitch => '🧒 Stół dla dzieci';

  @override
  String get tables_childHint => 'Osobny stół dla najmłodszych gości';

  @override
  String get tables_full => 'Stół jest pełny!';

  @override
  String get tables_statTables => 'Stoły';

  @override
  String get roomplan_title => 'Plan sali';

  @override
  String get roomplan_fullscreen => 'Pełny ekran';

  @override
  String get roomplan_addElement => 'Dodaj element';

  @override
  String get roomplan_widthMeters => 'Szerokość (m)';

  @override
  String get roomplan_lengthMeters => 'Długość (m)';

  @override
  String get guests_namePendingBadge => '✎ imię do potwierdzenia';

  @override
  String get guests_companionFirstNameHint => 'Imię';

  @override
  String guests_badgeSeatedAt(String table) {
    return '✓ $table';
  }

  @override
  String guests_companionOfLine(String name) {
    return '↳ towarzyszy: $name';
  }

  @override
  String get guests_emptyAll => 'Brak gości.';

  @override
  String guests_shownOf(int shown, int total) {
    return 'Wyświetlono $shown z $total gości';
  }

  @override
  String get guests_unknownGuest => 'nieznany gość';

  @override
  String get guests_companionPending =>
      'osoba towarzysząca (imię do potwierdzenia)';

  @override
  String guests_comesWith(String name) {
    return '👥 przychodzi z: $name';
  }

  @override
  String guests_menuTimes(int count) {
    return '$count×';
  }

  @override
  String get roomplan_elementTable => 'Stół';

  @override
  String get tables_nameHintOptional => 'np. Stół 1 (opcjonalnie)';

  @override
  String get tables_shapeRoundIcon => '⚪ Okrągły';

  @override
  String get tables_shapeRectIcon => '▭ Prostokątny';

  @override
  String get tables_assignGuestAction => 'Przypisz gościa';

  @override
  String get tables_deleteTable => 'Usuń stół';

  @override
  String get tables_statGuests => 'Goście';

  @override
  String get roomplan_zoomIn => 'Przybliż';

  @override
  String get roomplan_widthShort => 'Szerokość';

  @override
  String get roomplan_lengthShort => 'Długość';

  @override
  String get roomplan_tableDiameterShort => 'Śr. stołu';

  @override
  String get roomplan_hint =>
      'Przytrzymaj i przeciągnij stół/element, aby go przesunąć. Dotknij stołu, aby przypisać gości lub zmienić rozmiar.';

  @override
  String roomplan_unassignedDrag(int count) {
    return 'Nieprzypisani ($count) — przeciągnij na stół';
  }

  @override
  String get roomplan_guest => 'Gość';

  @override
  String roomplan_addedToTable(String name) {
    return 'Dodano do stołu: $name';
  }

  @override
  String get roomplan_guestsAtTable => 'Goście przy stole';

  @override
  String get roomplan_noGuestsAtTable => 'Brak przypisanych gości.';

  @override
  String get roomplan_tableSize => 'Rozmiar stołu';

  @override
  String get roomplan_diameterMeters => 'Średnica (m)';

  @override
  String get roomplan_rotate90 => 'Obróć 90°';

  @override
  String get roomplan_allSeated => 'Wszyscy goście są przypisani.';

  @override
  String roomplan_roomDims(String width, String length) {
    return '$width m × $length m';
  }

  @override
  String get roomplan_zoomOut => 'Oddal';

  @override
  String get roomplan_fit => 'Dopasuj';

  @override
  String get roomplan_editPlan => 'Edytuj plan';

  @override
  String roomplan_addedElement(String name) {
    return 'Dodano element: $name';
  }

  @override
  String get budget_title => 'Budżet';

  @override
  String get budget_tabSummary => 'Podsumowanie';

  @override
  String get budget_tabVenue => 'Sala';

  @override
  String get budget_tabExpenses => 'Wydatki';

  @override
  String get budget_tabAlcohol => 'Alkohol';

  @override
  String get budget_tabSoft => 'Napoje bezalkoholowe';

  @override
  String get budget_tabHoneymoon => 'Podróż poślubna';

  @override
  String get budget_planned => 'Budżet planowany';

  @override
  String get budget_reserveHint =>
      'Rezerwę ustawisz w Ustawieniach → „Ustawienia budżetu”.';

  @override
  String get budget_saveButton => 'Zapisz budżet';

  @override
  String get budget_savedToast => 'Zapisano budżet';

  @override
  String get budget_invalidAmount => 'Nieprawidłowa kwota';

  @override
  String get budget_paidShort => 'opłacono';

  @override
  String budget_paidAmount(String amount) {
    return 'Opłacono: $amount';
  }

  @override
  String get budget_actual => 'Budżet rzeczywisty (koszty)';

  @override
  String get budget_ofWhichPaid => 'w tym opłacono';

  @override
  String get budget_remaining => 'Pozostało z budżetu';

  @override
  String get budget_expenseDeleteTitle => 'Usunąć wydatek?';

  @override
  String budget_expenseDeleteBody(String name) {
    return 'Czy na pewno usunąć „$name”?';
  }

  @override
  String get budget_expenseDeletedToast => 'Usunięto wydatek';

  @override
  String budget_expenseAddedToast(String name) {
    return 'Dodano pozycję: $name';
  }

  @override
  String get budget_expensesEmpty =>
      'Brak wydatków. Dodaj pierwszy przyciskiem poniżej.';

  @override
  String get budget_expensesEmptyFiltered =>
      'Brak wydatków spełniających kryteria filtrów.';

  @override
  String get budget_collapse => 'zwiń';

  @override
  String get budget_expand => 'rozwiń';

  @override
  String get budget_customItem => 'Własna pozycja';

  @override
  String get budget_customName => 'Własna nazwa';

  @override
  String get budget_paid => 'Opłacono';

  @override
  String get budget_left => 'Pozostało';

  @override
  String get budget_statusPaid => '✓ Opłacone';

  @override
  String get budget_statusPartial => '⚡ Częściowo';

  @override
  String get budget_statusUnpaid => '✗ Nieopłacone';

  @override
  String get budget_manual => 'Ręcznie';

  @override
  String budget_paidShortPrefix(String amount) {
    return 'opł. $amount';
  }

  @override
  String get budget_paymentDate => 'Data płatności';

  @override
  String get budget_split => 'Podział';

  @override
  String get budget_splitCosts => 'Podział kosztów';

  @override
  String get budget_isVendor => '🏢 To jest dostawca/usługa';

  @override
  String get budget_isVendorHint =>
      'Pokaże się też w sekcji Dostawcy jako TEN SAM rekord (kwota się nie dubluje).';

  @override
  String get budget_vendorName => 'Imię i nazwisko';

  @override
  String get budget_paymentsEmpty => 'Brak płatności w tym widoku.';

  @override
  String get budget_paymentsFilter => 'Filtruj płatności';

  @override
  String get budget_paymentsReminders => '🔔 Przypomnienia o płatnościach';

  @override
  String get budget_overdue => 'zaległa!';

  @override
  String get budget_dueSoon => 'wkrótce';

  @override
  String get budget_tripShort => '✈️ Podróż';

  @override
  String budget_paidRemaining(String paid, String remaining) {
    return 'Opłacono $paid · Pozostało $remaining';
  }

  @override
  String budget_panelRemoveTitle(String panel) {
    return 'Usuń panel: $panel';
  }

  @override
  String get budget_panelRemovedToast => 'Panel usunięty';

  @override
  String budget_panelRemovedInfo(String panel) {
    return 'Panel „$panel” jest usunięty i NIE jest wliczany do budżetu. Pozycje pozostają zapisane — możesz przywrócić panel.';
  }

  @override
  String get budget_panelRestore => 'Przywróć panel';

  @override
  String get budget_addItem => 'Dodaj pozycję';

  @override
  String get budget_addItemHint => 'Kliknij +, aby dodać pozycję.';

  @override
  String get budget_bottlesTotal => 'butelek łącznie';

  @override
  String get budget_costTotal => 'łączny koszt';

  @override
  String get budget_includeVirtual =>
      'Uwzględniaj gości wirtualnych w przeliczeniu na osobę';

  @override
  String get budget_splitHeader => '⚖ Podział kosztów';

  @override
  String get budget_splitExceeds => '⚠ Suma podziału przekracza łączny koszt.';

  @override
  String get budget_honeymoonTitle => '✈ Podróż poślubna';

  @override
  String get budget_honeymoonName => 'Nazwa / cel podróży';

  @override
  String get budget_openOffer => 'Otwórz ofertę';

  @override
  String get budget_addVariant => 'Dodaj wariant podróży';

  @override
  String get budget_variantsHint =>
      'Dodaj kilka propozycji i zaznacz, która wchodzi do budżetu.';

  @override
  String get budget_variantsHeader => '✈ Warianty podróży poślubnej';

  @override
  String get budget_includeMoreExpensive => 'Wlicz droższą wersję do budżetu';

  @override
  String get budget_includeMoreExpensiveHint =>
      'Bezpieczne planowanie — liczy najdroższy wariant.';

  @override
  String get budget_payments => 'Płatności';

  @override
  String get budget_toBudget => 'Do budżetu';

  @override
  String get budget_alreadyPaid => 'Zapłacono';

  @override
  String get budget_installments => 'Harmonogram płatności';

  @override
  String get budget_addInstallment => 'Dodaj ratę';

  @override
  String get budget_noInstallments => 'Brak rat — dodaj harmonogram płatności.';

  @override
  String get budget_linkFailed => 'Nie udało się otworzyć linku';

  @override
  String get budget_installmentPaid => '✓ Zapłacona';

  @override
  String get budget_installmentDue => '○ Do zapłaty';

  @override
  String get budget_withChildrenTitle => 'Wesele z dziećmi';

  @override
  String get budget_withChildrenSwitch => 'Czy to wesele z dziećmi?';

  @override
  String get budget_withChildrenHint =>
      'Dzieci są wyłączane z przeliczeń alkoholu. Możesz też dodać stół dla dzieci (w Planie sali) i osobne menu dziecięce.';

  @override
  String get budget_childrenAuto => 'Licz dzieci z listy gości';

  @override
  String get budget_childrenAutoOn =>
      'Liczba bierze się z gości oznaczonych jako dziecko (Goście → „🧒 To dziecko”).';

  @override
  String get budget_childrenAutoOff =>
      'Wpisujesz liczbę ręcznie. Włącz, jeśli dzieci są na liście gości.';

  @override
  String get budget_childrenFromGuests => 'Liczba dzieci (z listy gości)';

  @override
  String get budget_childrenCount => 'Liczba dzieci';

  @override
  String budget_childrenMismatch(String fromGuests, String manual) {
    return 'Na liście gości oznaczono $fromGuests, a tu wpisano $manual. Sprawdź, która liczba jest właściwa.';
  }

  @override
  String get budget_childMenuSeparate => 'Czy dla dzieci jest oddzielne menu?';

  @override
  String budget_childMenuOn(int count) {
    return 'Dzieci ($count) liczone po cenie dziecięcej.';
  }

  @override
  String get budget_childMenuOff =>
      'Dzieci liczone jak dorośli (cena za osobę).';

  @override
  String get budget_childMenuPrice => 'Cena za dziecko (menu)';

  @override
  String get budget_childMenuCost => 'Koszt menu dziecięcego';

  @override
  String get budget_cateringSeparateHint =>
      'Catering od innej firmy niż sala — liczony osobno, po cenie za osobę (te same przeliczenia liczby osób co sala).';

  @override
  String get budget_cateringPricePerPerson => 'Cena cateringu za osobę';

  @override
  String get budget_noAddons => 'Brak dodatków. Dodaj przyciskiem +.';

  @override
  String budget_perPersonShort(String currency) {
    return '$currency/os.';
  }

  @override
  String get budget_peopleForCalc => 'Liczba osób do przeliczeń';

  @override
  String get budget_cateringTotal => 'Łącznie catering';

  @override
  String get budget_pricePerPerson => 'Cena za osobę';

  @override
  String get budget_venueMinGuests => 'Minimalna liczba osób (próg sali)';

  @override
  String get budget_guestsAssigned => 'Goście przypisani do stołów';

  @override
  String get budget_catVenueCatering => 'Sala i catering';

  @override
  String get budget_catDress => 'Suknia ślubna';

  @override
  String get budget_catSuit => 'Garnitur/strój';

  @override
  String get budget_catRings => 'Obrączki';

  @override
  String get budget_catPhoto => 'Fotograf';

  @override
  String get budget_catVideo => 'Kamerzysta/wideo';

  @override
  String get budget_catFlowersDecor => 'Kwiaty/dekoracje';

  @override
  String get budget_catBouquet => 'Bukiet ślubny';

  @override
  String get budget_catFlowersCouple => 'Kwiaty dla PM';

  @override
  String get budget_catChurchDecor => 'Przystrojenie kościoła';

  @override
  String get budget_catCake => 'Tort weselny';

  @override
  String get budget_catMusic => 'Muzyka/DJ/zespół';

  @override
  String get budget_catInvitations => 'Zaproszenia';

  @override
  String get budget_catBeauty => 'Uroda';

  @override
  String get budget_catHairMakeup => 'Makijaż i fryzura';

  @override
  String get budget_catTransport => 'Transport';

  @override
  String get budget_catRideReception => 'Dojazd do wesela';

  @override
  String get budget_catRideChurch => 'Dojazd do kościoła';

  @override
  String get budget_catGiftsGuests => 'Upominki dla gości';

  @override
  String get budget_catGiftsParents => 'Upominki dla rodziców';

  @override
  String get budget_catGiftsWitnesses => 'Upominki dla świadków';

  @override
  String get budget_catHoneymoon => 'Podróż poślubna';

  @override
  String get budget_catAlcohol => 'Alkohol';

  @override
  String get budget_catOther => 'Inne';

  @override
  String get budget_expenseFallbackName => 'Wydatek';

  @override
  String get budget_guestsUnassigned => 'Goście nieprzypisani';

  @override
  String get budget_guestsBilledTotal => 'Razem gości liczonych';

  @override
  String get budget_guestsCost => 'Koszt gości';

  @override
  String get budget_countUnassigned => 'Licz gości nieprzypisanych do stołów';

  @override
  String budget_countUnassignedOn(int count) {
    return 'Nieprzypisani ($count) są wliczani do kosztu.';
  }

  @override
  String budget_countUnassignedOff(int count) {
    return 'Nieprzypisani ($count) NIE są wliczani.';
  }

  @override
  String get budget_virtualGuests => 'Goście wirtualni (do progu sali)';

  @override
  String get budget_virtualGuestsCost => 'Koszt gości wirtualnych';

  @override
  String get budget_includeVirtualCalc =>
      'Uwzględnij gości wirtualnych w obliczeniach';

  @override
  String get budget_cateringSeparateNote =>
      'Catering (osobna firma) liczony w osobnej karcie poniżej.';

  @override
  String get budget_cateringIncluded =>
      'Catering wliczony w cenę sali za osobę.';

  @override
  String get budget_staff => 'Obsługa';

  @override
  String get budget_staffHint =>
      'Kelnerzy, fotograf, DJ, kamerzysta — osoby, które jedzą, ale nie są gośćmi. Liczone osobno.';

  @override
  String get budget_staffEmpty => 'Brak obsługi. Dodaj przyciskiem +.';

  @override
  String get budget_staffRate => 'Stawka obsługi za osobę (puste = jak goście)';

  @override
  String get budget_staffInclude => 'Doliczaj obsługę do kosztu sali';

  @override
  String get budget_staffIncludeHint =>
      'Liczona jest obsługa oznaczona „w kosztach”.';

  @override
  String get budget_staffCountTotal => 'Osób obsługi łącznie';

  @override
  String get budget_staffRateShort => 'Stawka obsługi / os.';

  @override
  String get budget_staffCost => 'Koszt obsługi';

  @override
  String get budget_menuAddonsTotal => 'Łącznie dodatki do menu';

  @override
  String get budget_tableDecor => 'Dekoracje stołów (per stolik)';

  @override
  String get budget_honorTable => '⭐ Stół Pary Młodej';

  @override
  String get budget_honorTableEmpty => 'Brak dekoracji stołu Pary Młodej.';

  @override
  String budget_regularTables(int count) {
    return 'Pozostałe stoły (×$count)';
  }

  @override
  String get budget_regularTablesEmpty => 'Brak dekoracji pozostałych stołów.';

  @override
  String budget_perTableShort(String currency) {
    return '$currency/stół';
  }

  @override
  String get budget_honorTableDecor => 'Dekoracje stołu Pary Młodej';

  @override
  String get budget_regularTablesDecor => 'Dekoracje pozostałych stołów';

  @override
  String get budget_decorTotal => 'Łącznie dekoracje';

  @override
  String get budget_venueSummary => 'Podsumowanie kosztów sali';

  @override
  String budget_guestsCostCount(int count) {
    return 'Koszt gości ($count os.)';
  }

  @override
  String budget_virtualCostCount(int count) {
    return 'Goście wirtualni ($count os.)';
  }

  @override
  String budget_staffCostCount(int count) {
    return 'Obsługa ($count os.)';
  }

  @override
  String budget_staffCostCountExcluded(int count) {
    return 'Obsługa ($count os., nieliczona)';
  }

  @override
  String get budget_cateringSeparateCard => 'Catering (oddzielny)';

  @override
  String get budget_childrenSuffix => 'dzieci';

  @override
  String get budget_tableDecorTotal => 'Dekoracje stołów';

  @override
  String budget_variantBudgeted(String name) {
    return 'Do budżetu: $name';
  }

  @override
  String get budget_variantNone => 'brak wyboru';

  @override
  String get budget_expensesQuickAdd =>
      'Kliknij, aby dodać gotowy wydatek — listę zmienisz w Ustawieniach.';

  @override
  String get budget_statusPaidShort => 'Opłacone';

  @override
  String get schedule_title => '📅 Harmonogram dnia ślubu';

  @override
  String get schedule_qrForGuests => 'Kod QR dla gości';

  @override
  String get schedule_forGuests => 'Dla gości';

  @override
  String get schedule_eventNameHint => 'np. Ceremonia ślubna';

  @override
  String get schedule_nameRequired => 'Podaj nazwę';

  @override
  String get schedule_detailsHint => 'Szczegóły…';

  @override
  String get schedule_private => '🔒 Prywatne (ukryte przed gośćmi)';

  @override
  String get schedule_showLink => '👁 Pokaż link gościom';

  @override
  String get schedule_deleteTitle => 'Usunąć wydarzenie?';

  @override
  String schedule_deleteBody(String name) {
    return 'Czy na pewno usunąć „$name”?';
  }

  @override
  String get schedule_deletedToast => 'Usunięto wydarzenie';

  @override
  String get schedule_empty => 'Brak wydarzeń. Dodaj pierwsze poniżej.';

  @override
  String get schedule_openLocation => 'Otwórz lokalizację';

  @override
  String schedule_guestPreview(int count) {
    return 'Podgląd dla gości ($count)';
  }

  @override
  String get schedule_noneVisible =>
      'Żadne wydarzenie nie jest oznaczone jako widoczne dla gości.';

  @override
  String get schedule_guestPreviewHint =>
      'Tak goście widzą harmonogram na stronie /harmonogram:';

  @override
  String get schedule_visibility => 'Widoczność wydarzeń';

  @override
  String get schedule_emptyAddInPlan =>
      'Brak wydarzeń. Dodaj je w zakładce „Plan dnia”.';

  @override
  String get schedule_visibilityHint =>
      'Zaznacz, które wydarzenia widzą goście.';

  @override
  String get schedule_visibleToGuests => 'Widoczne dla gości';

  @override
  String get checklist_addHint => 'Co zrobić…';

  @override
  String checklist_progress(int done, int total, int percent) {
    return '$done/$total ukończonych ($percent%)';
  }

  @override
  String get checklist_addItem => 'Dodaj pozycję';

  @override
  String get tasks_deleteTitle => 'Usunąć zadanie?';

  @override
  String tasks_deleteBody(String name) {
    return 'Czy na pewno usunąć „$name”?';
  }

  @override
  String get tasks_deletedToast => 'Usunięto zadanie';

  @override
  String get tasks_goalReached => '🎯 Cel osiągnięty';

  @override
  String tasks_goalReachedBody(String goal) {
    return '„$goal” zostało oznaczone jako zrealizowane.\n\nCzy utworzyć z tego pozycję w budżecie?';
  }

  @override
  String get tasks_goalCreateYes => 'Tak, utwórz';

  @override
  String get tasks_budgetItemCreated => 'Utworzono pozycję w budżecie';

  @override
  String get tasks_newBudgetItem => '💰 Nowa pozycja w budżecie';

  @override
  String tasks_estimatedCost(String currency) {
    return 'Szacowany koszt ($currency)';
  }

  @override
  String get tasks_budgetCategory => 'Kategoria budżetowa';

  @override
  String get tasks_create => 'Utwórz';

  @override
  String tasks_progress(int done, int total, int percent) {
    return '$done/$total ukończonych ($percent%)';
  }

  @override
  String get tasks_allLinks => 'Wszystkie powiązania';

  @override
  String get tasks_linkBudget => '💰 Budżet';

  @override
  String get tasks_linkVendor => '👨‍🍳 Dostawca';

  @override
  String get tasks_noLink => 'Bez powiązania';

  @override
  String get tasks_dragHere => 'Przeciągnij tutaj';

  @override
  String get tasks_deleteAction => '🗑 Usuń';

  @override
  String get tasks_nameHint => 'np. Zarezerwować salę';

  @override
  String get tasks_nameRequired => 'Podaj nazwę zadania';

  @override
  String get tasks_customGoal => '➕ Inny cel (wpisz własny)';

  @override
  String get tasks_goalDone => '🎯 Cel osiągnięty';

  @override
  String get tasks_goalDoneHint =>
      'np. „DJ znaleziony” — zaznacz, gdy cel jest już zrealizowany.';

  @override
  String get tasks_showMore => 'Pokaż więcej opcji';

  @override
  String get tasks_customPerson => 'Własna osoba (opcjonalnie)';

  @override
  String get tasks_customPersonHint => 'Imię — nadpisuje powyższy wybór';

  @override
  String get tasks_startDate => 'Data rozpoczęcia';

  @override
  String get tasks_endDate => 'Data zakończenia';

  @override
  String get tasks_linkBudgetSwitch => '💰 Powiąż z budżetem';

  @override
  String get tasks_linkBudgetHint =>
      'Tworzy/aktualizuje powiązany wpis w budżecie (referencja).';

  @override
  String get tasks_links => '🔗 Powiązania';

  @override
  String get tasks_linksHint =>
      'Powiąż zadanie z Dostawcą, Transportem, Noclegiem lub Muzyką. Możesz utworzyć nowy element — powstanie jako referencja (ten sam rekord widoczny w obu sekcjach), bez duplikowania danych.';

  @override
  String get tasks_createVendor => '➕ Utwórz nowego dostawcę';

  @override
  String get tasks_createTransport => '➕ Utwórz wpis transportu';

  @override
  String get tasks_createAccommodation => '➕ Utwórz wpis noclegu';

  @override
  String get tasks_createSong => '➕ Utwórz utwór';

  @override
  String get tasks_song => 'Utwór';

  @override
  String tasks_costWithCurrency(String amount, String currency) {
    return '💰 $amount $currency';
  }

  @override
  String get schedule_tabDayPlan => 'Plan dnia';

  @override
  String get schedule_tabChecklist => 'Checklista';

  @override
  String get vendors_catVenue => 'Sala';

  @override
  String get vendors_catOutfit => 'Strój';

  @override
  String get vendors_catDocs => 'Dokumenty';

  @override
  String get vendors_catDecor => 'Dekoracje';

  @override
  String get vendors_catOther => 'Inne';

  @override
  String get tasks_title => 'Zadania';

  @override
  String get tasks_addButton => 'Dodaj zadanie';

  @override
  String get tasks_addedToast => 'Dodano zadanie';

  @override
  String get tasks_notNow => 'Nie teraz';

  @override
  String get tasks_editAction => '✏ Edytuj';

  @override
  String get budget_expenseAddedShort => 'Dodano wydatek';

  @override
  String get budget_addExpense => 'Dodaj wydatek';

  @override
  String get budget_quickItems => '⚡ Szybkie pozycje';

  @override
  String get budget_filtersSort => 'Filtry i sortowanie';

  @override
  String get budget_allCategories => 'Wszystkie kategorie';

  @override
  String get budget_offerLink => 'Link do oferty';

  @override
  String get budget_roughAmount => 'Kwota orientacyjna';

  @override
  String get budget_addVariantShort => 'Dodaj wariant';

  @override
  String get budget_cateringAddons => 'Dodatki cateringu (per osoba)';

  @override
  String get budget_cateringSeparateAsk => 'Czy catering jest oddzielny?';

  @override
  String get budget_menuAddons => 'Dodatki do menu (per osoba)';

  @override
  String get budget_includeInVenueCost => 'Wliczaj w koszt sali';

  @override
  String checklist_newItem(String category) {
    return 'Nowa pozycja — $category';
  }

  @override
  String checklist_addedToast(String text) {
    return 'Dodano: $text';
  }

  @override
  String get checklist_empty => 'Brak pozycji.';

  @override
  String get schedule_addEvent => 'Dodaj wydarzenie';

  @override
  String get roomplan_roomDimsLabel => 'Wymiary sali (m)';

  @override
  String get roomplan_addElementSheet => 'Dodaj element sali';

  @override
  String get roomplan_autoSizeHint =>
      '0 = rozmiar automatyczny wg liczby miejsc.';

  @override
  String tables_assignTo(String table) {
    return 'Przypisz do: $table';
  }

  @override
  String get vendors_title => 'Dostawcy';

  @override
  String get vendors_addButton => 'Dodaj dostawcę';

  @override
  String get vendors_addedToast => 'Dodano dostawcę';

  @override
  String get vendors_deleteTitle => 'Usunąć dostawcę?';

  @override
  String get vendors_deleteKeepEntry => 'Usuń, zostaw wpis';

  @override
  String get vendors_deletedToast => 'Usunięto dostawcę';

  @override
  String get vendors_empty => 'Brak dostawców.';

  @override
  String vendors_contact(String name) {
    return '👤 $name';
  }

  @override
  String vendors_price(String amount) {
    return 'Cena: $amount';
  }

  @override
  String get vendors_installments => '💵 Raty / płatności';

  @override
  String get vendors_noInstallments => 'Brak rat.';

  @override
  String get vendors_toPay => 'Do zapłaty';

  @override
  String get vendors_paid => 'Zapłacona';

  @override
  String get vendors_linkBudget => '💰 Powiąż z budżetem';

  @override
  String get vendors_linkBudgetHint =>
      'Tworzy/aktualizuje powiązany wpis w budżecie (referencja).';

  @override
  String get transport_title => 'Transport';

  @override
  String get transport_addVehicle => 'Dodaj pojazd';

  @override
  String get transport_vehicleAdded => 'Dodano pojazd';

  @override
  String get transport_noGuestsAvailable => 'Brak dostępnych gości';

  @override
  String get transport_showOwn => 'Pokaż transport własny';

  @override
  String transport_seatsOf(int used, int total) {
    return '$used/$total miejsc';
  }

  @override
  String get transport_ownHeader => '🚶 Transport własny';

  @override
  String get transport_ownEmpty => 'Brak gości z własnym dojazdem.';

  @override
  String get transport_addGuest => 'Dodaj gościa';

  @override
  String transport_unassignedHeader(int count) {
    return '❓ Bez przydziału ($count)';
  }

  @override
  String get transport_allAssigned => 'Wszyscy goście mają transport.';

  @override
  String get transport_internalHeader => '🚕 Transport wewnętrzny';

  @override
  String get transport_internalEmpty => 'Brak. Dodaj Bolt / Taxi / inny.';

  @override
  String get transport_showInSchedule => 'Pokaż gościom w harmonogramie';

  @override
  String get accommodation_title => 'Noclegi';

  @override
  String get accommodation_deleteHotelTitle => 'Usunąć hotel?';

  @override
  String get accommodation_guestsNeeding => 'Goście potrzebujący noclegu';

  @override
  String get accommodation_hotels => 'Hotele i miejsca noclegowe';

  @override
  String get accommodation_addHotel => 'Dodaj hotel';

  @override
  String get accommodation_noHotel => 'Brak hotelu';

  @override
  String get accommodation_onSite => '🏰 W kompleksie';

  @override
  String get accommodation_onSiteSwitch => '🏰 Hotel w kompleksie wesela';

  @override
  String vendors_paidRemainingTotal(
    String paid,
    String remaining,
    String total,
  ) {
    return 'Zapłacono: $paid · Pozostało: $remaining · Suma: $total';
  }

  @override
  String get analytics_title => 'Analityka';

  @override
  String get analytics_empty => 'Brak danych do analizy';

  @override
  String get analytics_emptyHint =>
      'Dodaj gości i wydatki, żeby zobaczyć analitykę — potwierdzenia obecności, rozkład kosztów, postęp płatności, menu i diety.';

  @override
  String get analytics_budgetForecast => 'Prognoza końcowego budżetu';

  @override
  String get analytics_costPerGuest => 'Koszt per gość';

  @override
  String get dashboard_availableTiles => 'Dostępne kafelki';

  @override
  String get rsvp_title => 'Potwierdzenia';

  @override
  String get rsvp_allTitle => 'Wszystkie RSVP';

  @override
  String get rsvp_allHint =>
      'Lista wszystkich odpowiedzi oraz kody QR i linki dla gości.';

  @override
  String rsvp_qrError(String error) {
    return 'Błąd generowania QR: $error';
  }

  @override
  String rsvp_quotedMessage(String message) {
    return '„$message”';
  }

  @override
  String get rsvp_deleteEntry => 'Usuń wpis';

  @override
  String get rsvp_deleteEntryTitle => 'Usunąć wpis RSVP?';

  @override
  String get rsvp_clearAll => 'Wyczyść wszystkie';

  @override
  String get rsvp_clear => 'Wyczyść';

  @override
  String get rsvp_clearAllTitle => 'Wyczyścić wszystkie potwierdzenia?';

  @override
  String rsvp_unmatched(int count) {
    return 'Nierozpoznane potwierdzenia ($count)';
  }

  @override
  String rsvp_guestsCount(int count) {
    return 'Goście ($count)';
  }

  @override
  String get rsvp_noGuestsInCategory => 'Brak gości w tej kategorii.';

  @override
  String get rsvp_assignToGuest => 'Przypisz do gościa…';

  @override
  String get games_title => 'Ślubne gry';

  @override
  String get games_activeForGuests => 'Gra aktywna dla gości';

  @override
  String get games_quizActiveForGuests => 'Quiz aktywny dla gości';

  @override
  String get games_ranking => '🏆 Ranking gości';

  @override
  String get games_addAnswer => 'Dodaj odpowiedź';

  @override
  String games_scoreOf(int score, int total) {
    return '$score/$total';
  }

  @override
  String get games_bingo => 'Ślubne Bingo';

  @override
  String get games_quiz => 'Quiz o Parze Młodej';

  @override
  String get games_trueFalse => 'Prawda czy Fałsz';

  @override
  String get games_photoGuess => 'Zgadnij zdjęcie';

  @override
  String get games_wheel => 'Koło fortuny';

  @override
  String get games_photoChallenge => 'Foto-wyzwania';

  @override
  String get quiz_addQuestion => 'Dodaj pytanie';

  @override
  String get quiz_empty => 'Brak pytań';

  @override
  String get quiz_emptyHint =>
      'Dodaj własne pytania lub zacznij od gotowych przykładów.';

  @override
  String get quiz_examplesAdded => 'Dodano przykładowe pytania';

  @override
  String get quiz_addExamples => 'Dodaj przykładowe pytania';

  @override
  String get quiz_saved => 'Zapisano pytanie';

  @override
  String get quiz_added => 'Dodano pytanie';

  @override
  String get quiz_deleteTitle => 'Usunąć pytanie?';

  @override
  String quiz_deleteBody(String text) {
    return 'Czy na pewno usunąć „$text”?';
  }

  @override
  String get quiz_deleted => 'Usunięto pytanie';

  @override
  String get quiz_hardest => '📊 Najtrudniejsze pytania';

  @override
  String quiz_numbered(int index, String text) {
    return '$index. $text';
  }

  @override
  String get tf_addStatement => 'Dodaj stwierdzenie';

  @override
  String get tf_empty => 'Brak stwierdzeń';

  @override
  String get tf_emptyHint =>
      'Dodaj własne stwierdzenia lub zacznij od gotowych przykładów.';

  @override
  String get tf_examplesAdded => 'Dodano przykładowe stwierdzenia';

  @override
  String get tf_addExamples => 'Dodaj przykładowe';

  @override
  String get tf_saved => 'Zapisano stwierdzenie';

  @override
  String get tf_added => 'Dodano stwierdzenie';

  @override
  String get tf_deleteTitle => 'Usunąć stwierdzenie?';

  @override
  String get tf_deleted => 'Usunięto stwierdzenie';

  @override
  String get photoGuess_add => 'Dodaj zdjęcie z pytaniem';

  @override
  String get photoGuess_empty => 'Brak zdjęć';

  @override
  String get photoGuess_saved => 'Zapisano zdjęcie';

  @override
  String get photoGuess_added => 'Dodano zdjęcie';

  @override
  String get photoGuess_deleteTitle => 'Usunąć zdjęcie?';

  @override
  String photoGuess_deleteBody(String text) {
    return 'Czy na pewno usunąć pytanie „$text”?';
  }

  @override
  String get photoGuess_deleted => 'Usunięto zdjęcie';

  @override
  String get photoGuess_hardest => '📊 Najtrudniejsze zdjęcia';

  @override
  String get photoGuess_noPhoto => 'Brak zdjęcia';

  @override
  String get photoGuess_fromGallery => 'Z galerii';

  @override
  String get photoChallenge_add => 'Dodaj wyzwanie';

  @override
  String get photoChallenge_empty => 'Brak wyzwań';

  @override
  String get photoChallenge_emptyHint =>
      'Dodaj własne wyzwania lub zacznij od gotowych przykładów.';

  @override
  String get photoChallenge_examplesAdded => 'Dodano przykładowe wyzwania';

  @override
  String get photoChallenge_addExamples => 'Dodaj przykładowe';

  @override
  String get photoChallenge_saved => 'Zapisano wyzwanie';

  @override
  String get photoChallenge_added => 'Dodano wyzwanie';

  @override
  String get photoChallenge_deleteTitle => 'Usunąć wyzwanie?';

  @override
  String get photoChallenge_deleted => 'Usunięto wyzwanie';

  @override
  String photoChallenge_points(int points) {
    return '⭐ $points pkt';
  }

  @override
  String get photoChallenge_photoDeleted => 'Usunięto zdjęcie';

  @override
  String get photoChallenge_text => 'Treść wyzwania';

  @override
  String get photoChallenge_textHint => 'np. Zrób selfie z Parą Młodą';

  @override
  String get photoChallenge_textRequired => 'Wpisz treść wyzwania';

  @override
  String get common_filtersSort => 'Filtry i sortowanie';

  @override
  String common_pdfError(String error) {
    return 'Błąd generowania PDF: $error';
  }

  @override
  String get common_exportPdf => 'Eksport PDF';

  @override
  String get common_sortBy => 'Sortuj:';

  @override
  String get common_view => 'Widok:';

  @override
  String get gallery_title => 'Galeria & QR';

  @override
  String gallery_readError(String error) {
    return 'Błąd odczytu galerii: $error';
  }

  @override
  String gallery_usage(String used) {
    return 'Wykorzystano: $used / 25 GB';
  }

  @override
  String get gallery_empty => 'Brak plików w galerii.';

  @override
  String get gallery_video => '▶ film';

  @override
  String gallery_uploadedBy(String name) {
    return '📷 $name';
  }

  @override
  String get gallery_format => 'Format:';

  @override
  String gallery_pdfError(String error) {
    return 'Błąd PDF: $error';
  }

  @override
  String get gallery_deleteTitle => 'Usunąć plik z galerii?';

  @override
  String get gallery_deleteBody =>
      'Zniknie z galerii gości. Oryginał pozostaje w Cloudinary.';

  @override
  String get gallery_deleted => 'Usunięto plik';

  @override
  String get gifts_thanked => 'Podziękowano';

  @override
  String get gifts_empty => 'Brak upominków.';

  @override
  String get gifts_addPerson => '+ Dodaj osobę…';

  @override
  String get gifts_wishlistHint =>
      'Lista życzeń od Pary Młodej. Zaznaczone propozycje są widoczne dla gości na stronie harmonogramu.';

  @override
  String get gifts_showToGuests => 'Pokaż gościom na stronie harmonogramu';

  @override
  String get keepsakes_title => 'Ślubne pamiątki';

  @override
  String get keepsakes_guestbook => 'Księga gości';

  @override
  String get keepsakes_advices => 'Rady dla Pary Młodej';

  @override
  String get keepsakes_timeCapsule => 'Kapsuła czasu';

  @override
  String get keepsakes_guestMap => 'Mapa gości';

  @override
  String get advices_filterByCategory => 'Filtruj po kategorii';

  @override
  String get advices_slideshow => 'Pokaz slajdów';

  @override
  String advices_labelCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get advices_delete => 'Usuń radę';

  @override
  String get advices_deleteTitle => 'Usunąć radę?';

  @override
  String get advices_deleted => 'Usunięto radę';

  @override
  String get advices_header => '💌 Rady dla Pary Młodej';

  @override
  String advices_position(int index, int total) {
    return '$index / $total';
  }

  @override
  String advices_quoted(String message) {
    return '„$message”';
  }

  @override
  String get guestbook_deleteEntry => 'Usuń wpis';

  @override
  String get guestbook_deleteTitle => 'Usunąć wpis?';

  @override
  String get guestbook_deleted => 'Usunięto wpis';

  @override
  String get capsule_exportOpen => 'Eksport otwartych do PDF';

  @override
  String capsule_sealedUntil(String date) {
    return '🔒 Zapieczętowane do $date';
  }

  @override
  String get capsule_hasPhoto => '📷 zawiera zdjęcie';

  @override
  String get capsule_deleteMessage => 'Usuń wiadomość';

  @override
  String get capsule_openAllTitle => 'Otworzyć wszystko teraz?';

  @override
  String get capsule_openAll => 'Otwórz wszystko';

  @override
  String get capsule_deleteTitle => 'Usunąć wiadomość?';

  @override
  String get capsule_deleted => 'Usunięto wiadomość';

  @override
  String get guestMap_addManually => 'Dodaj gościa ręcznie';

  @override
  String guestMap_kmFromVenue(int km) {
    return '$km km od miejsca wesela';
  }

  @override
  String get guestMap_notLocated =>
      '⚠ Niezlokalizowany — uzupełnij miejscowość';

  @override
  String get guestMap_deleteTitle => 'Usunąć wpis?';

  @override
  String get guestMap_deleted => 'Usunięto wpis';

  @override
  String get guestMap_name => 'Imię';

  @override
  String get guestMap_city => 'Miejscowość';

  @override
  String get guestMap_cityHint => 'np. Kraków';

  @override
  String get guestMap_greeting => 'Pozdrowienie (opcjonalnie)';

  @override
  String get music_title => 'Muzyka';

  @override
  String get music_added => 'Dodano utwór';

  @override
  String get music_qrForGuests => 'Kod QR dla gości';

  @override
  String music_unmatched(int count) {
    return '⚠ Niedopasowane / do weryfikacji ($count)';
  }

  @override
  String music_list(int count) {
    return 'Lista utworów ($count)';
  }

  @override
  String get music_emptyFiltered => 'Brak utworów spełniających kryteria.';

  @override
  String get music_searchDeezer => 'Szukaj utworu (Deezer)…';

  @override
  String get music_addManually => 'Dodaj ręcznie';

  @override
  String get music_deezerError =>
      'Nie udało się połączyć z Deezer (sprawdź internet/CORS).';

  @override
  String get music_deezerEmpty => 'Nie znaleziono w Deezer.';

  @override
  String music_addedTitle(String title) {
    return 'Dodano: $title';
  }

  @override
  String get music_addedUnmatched => 'Dodano jako niedopasowany';

  @override
  String music_addToVerify(String query) {
    return 'Dodaj „$query” do weryfikacji';
  }

  @override
  String get music_allMoments => 'Wszystkie momenty';

  @override
  String get music_fromGuest => '👤 od gościa';

  @override
  String get music_addOwnMoment => 'Dodaj własny moment';

  @override
  String get music_outsideList => 'spoza listy';

  @override
  String get music_removeMoment => 'Usuń moment z listy';

  @override
  String get music_noSongAssigned => 'Brak utworu — dodaj lub przypisz.';

  @override
  String get music_addNew => 'Dodaj nowy';

  @override
  String get music_assignmentRemoved => 'Usunięto przypisanie';

  @override
  String get music_removeAssignment => 'Usuń przypisanie';

  @override
  String get music_newMoment => 'Nowy moment';

  @override
  String get music_momentName => 'Nazwa momentu';

  @override
  String get music_momentNameHint => 'np. Poprawiny';

  @override
  String get music_momentExists => 'Taki moment już istnieje';

  @override
  String music_momentAdded(String name) {
    return 'Dodano moment: $name';
  }

  @override
  String get music_removeMomentTitle => 'Usunąć moment z listy?';

  @override
  String music_removeMomentBody(String label) {
    return 'Moment „$label\" zniknie z listy. Przypisane utwory NIE zostaną usunięte — pokażą się jako „spoza listy\", możesz je przypisać ponownie lub odłączyć.';
  }

  @override
  String get music_emptyAddFirst =>
      'Brak utworów na liście. Dodaj najpierw utwór.';

  @override
  String music_assignTo(String label) {
    return 'Przypisz do: $label';
  }

  @override
  String music_assignedTo(String label) {
    return 'Przypisano utwór do: $label';
  }

  @override
  String get music_nothingToExport => 'Brak utworów do eksportu';

  @override
  String get music_exportCsv => 'Eksport CSV';

  @override
  String get music_exportText => 'Eksport tekstowy';

  @override
  String get music_copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get music_import => 'Import utworów';

  @override
  String get music_pasteHere => 'Wklej tutaj…';

  @override
  String get music_nothingRecognized => 'Nie rozpoznano utworów';

  @override
  String music_imported(int count) {
    return 'Zaimportowano $count utworów';
  }

  @override
  String get music_addSongManually => 'Dodaj utwór ręcznie';

  @override
  String get music_songTitle => 'Tytuł';

  @override
  String get music_searchInDeezer => 'Szukaj w Deezer…';

  @override
  String get music_nothingFound =>
      'Nic nie znaleziono (możesz dodać ręcznie poniżej).';

  @override
  String get music_orAddManually => '…lub dodaj ręcznie';

  @override
  String get guestMap_txt1 =>
      'Strona, na której goście zaznaczają, skąd przyjeżdżają. Pokaż im kod QR lub wyślij link.';

  @override
  String get guestMap_txt2 =>
      'Brak wpisów. Udostępnij gościom kod QR z zakładki „Strona dla gości\".';

  @override
  String get guestMap_txt3 =>
      'Brak zlokalizowanych gości. Pinezki pojawią się po wpisach gości lub ręcznym dodaniu z miejscowością.';

  @override
  String get guestMap_txt4 =>
      'Aby policzyć dystans najdalszego gościa, ustaw „Miejsce wesela\" w Konfiguracji (sekcja Ustawienia).';

  @override
  String get capsule_txt1 =>
      'Strona, na której goście zostawią wiadomości do otwarcia w przyszłości (np. w rocznicę). Pokaż im kod QR lub wyślij link.';

  @override
  String get capsule_txt2 =>
      'Brak wiadomości. Udostępnij gościom kod QR z zakładki „Strona dla gości\".';

  @override
  String get capsule_txt3 =>
      'Zobaczysz treść także zapieczętowanych wiadomości, zanim nadejdzie ich data. To tylko podgląd dla Ciebie — nie zmienia dat otwarcia ani tego, co widzą inni. Najwięcej radości daje jednak czekanie 💙';

  @override
  String get guestbook_txt1 =>
      'Strona, na której goście zostawią życzenia i wiadomości dla Pary Młodej (z opcjonalnym zdjęciem). Pokaż im kod QR lub wyślij link.';

  @override
  String get guestbook_txt2 =>
      'Brak wpisów. Udostępnij gościom kod QR z zakładki „Strona dla gości\", aby zaczęli się wpisywać.';

  @override
  String get advices_txt1 =>
      'Strona, na której goście zostawią rady i złote myśli o małżeństwie. Pokaż im kod QR lub wyślij link.';

  @override
  String get advices_txt2 =>
      'Brak rad. Udostępnij gościom kod QR z zakładki „Strona dla gości\".';

  @override
  String get music_txt1 =>
      'Strona, na której goście proponują utwory do zagrania. Pokaż im kod QR lub wyślij link.';

  @override
  String get music_txt2 =>
      'Utwory do kluczowych momentów wesela. Przeciągnij, by ustawić chronologię. Przy każdym momencie dodaj nowy utwór lub przypisz istniejący z listy.';

  @override
  String get rsvp_txt1 =>
      'Brak wpisów RSVP. Pojawią się tutaj, gdy goście wypełnią formularz /rsvp lub gdy ustawisz status ręcznie w sekcji „Potwierdzenia\".';

  @override
  String get rsvp_txt2 =>
      'Wszystkie kody QR i linki do stron dla gości w jednym miejscu. Każdy kod możesz skopiować, otworzyć albo pobrać/udostępnić (PDF do druku lub wysłania).';

  @override
  String get rsvpMain_txt1 =>
      'Brak potwierdzeń. Udostępnij gościom kod QR (na dole tej sekcji) lub link do strony /rsvp, aby zbierać potwierdzenia. Możesz też ręcznie ustawić status każdego gościa poniżej.';

  @override
  String get rsvpMain_txt2 =>
      'Udostępnij gościom stronę potwierdzeń obecności (RSVP). Pokaż kod QR lub wyślij link.';

  @override
  String get gallery_txt1 =>
      'Strona dla gości: wspólna galeria zdjęć i filmów oraz możliwość zaproponowania muzyki. Pokaż kod QR lub wyślij link.';

  @override
  String get photoChallenge_txt1 =>
      'Strona, na której goście wykonują wyzwania fotograficzne i przesyłają zdjęcia. Włącz grę w zakładce „Wyzwania\", pokaż kod QR lub wyślij link.';

  @override
  String get photoChallenge_txt2 =>
      'Brak zdjęć. Gdy goście wykonają wyzwania, pojawią się tutaj — pogrupowane po wyzwaniach.';

  @override
  String get photoGuess_txt1 =>
      'Strona, na której goście oglądają stare zdjęcia i zgadują odpowiedzi. Włącz grę w zakładce „Zdjęcia\", pokaż kod QR lub wyślij link.';

  @override
  String get photoGuess_txt2 =>
      'Dodaj stare zdjęcia (np. z dzieciństwa) i pytania, które goście będą zgadywać.';

  @override
  String get tf_txt1 =>
      'Strona, na której goście zgadują, czy stwierdzenia o Parze Młodej są prawdą czy fałszem. Włącz grę w zakładce „Stwierdzenia\", pokaż kod QR lub wyślij link.';

  @override
  String get quiz_txt1 =>
      'Strona, na której goście odpowiadają na pytania o Parę Młodą i poznają swój wynik. Włącz quiz w zakładce „Pytania\", pokaż kod QR lub wyślij link.';

  @override
  String guestbook_deleteBodyNamed(String name) {
    return 'Czy na pewno usunąć wpis od „$name”? Tej operacji nie można cofnąć.';
  }

  @override
  String capsule_deleteBodyNamed(String name) {
    return 'Czy na pewno usunąć wiadomość od „$name”? Tej operacji nie można cofnąć.';
  }

  @override
  String get guestSection_rsvp => 'RSVP (Potwierdzenia)';

  @override
  String get guestSection_gallery => 'Galeria';

  @override
  String get guestSection_schedule => 'Harmonogram';

  @override
  String get guestSection_music => 'Muzyka';

  @override
  String get guestSection_guestbook => 'Księga gości';

  @override
  String get guestSection_advice => 'Rady';

  @override
  String get guestSection_timeCapsule => 'Kapsuła czasu';

  @override
  String get guestSection_guestMap => 'Mapa gości';

  @override
  String get guestSection_quiz => 'Quiz';

  @override
  String get guestSection_trueFalse => 'Prawda/Fałsz';

  @override
  String get guestSection_photoGuess => 'Zgadnij zdjęcie';

  @override
  String get guestSection_photoChallenge => 'Foto-wyzwania';

  @override
  String get guestSection_bingo => 'Ślubne Bingo';

  @override
  String get gw_appTitle => 'Wesele — strefa gości';

  @override
  String get gw_language => 'Język';

  @override
  String get gw_help => 'Pomoc';

  @override
  String get gw_connecting => 'Łączę…';

  @override
  String get gw_invalidLink => 'Nieprawidłowy lub nieaktywny link';

  @override
  String get gw_invalidLinkBody =>
      'Poproś Parę Młodą o aktualny link lub kod QR do strony gości.';

  @override
  String get gw_guestZone => 'Strefa gości';

  @override
  String get gw_unavailable =>
      'Strona gości jest chwilowo niedostępna. Zajrzyj później.';

  @override
  String get gw_ourWedding => 'Nasze Wesele';

  @override
  String get gw_emptyInfo =>
      'Sekcje dla gości pojawią się tutaj, gdy Para Młoda je udostępni.';

  @override
  String gw_availableFrom(String date) {
    return 'Dostępne od $date';
  }

  @override
  String get gw_noLongerAvailable => 'Już niedostępne';

  @override
  String get gw_unavailableShort => 'Niedostępne';

  @override
  String get gw_comingSoon => 'Ta sekcja będzie dostępna wkrótce';

  @override
  String get gw_yourName => 'Twoje imię';

  @override
  String get gw_guest => 'Gość';

  @override
  String get gw_sending => 'Wysyłanie…';

  @override
  String get gw_thanks => 'Dziękujemy ✓';

  @override
  String get gw_updated => 'Zaktualizowano ✓';

  @override
  String get gw_saveChanges => 'Zapisz zmiany';

  @override
  String gw_sendError(String error) {
    return 'Nie udało się wysłać: $error';
  }

  @override
  String get gw_sessionError =>
      'Nie udało się przygotować sesji gościa. Odśwież stronę i spróbuj ponownie.';

  @override
  String get gw_nameFirst => 'Najpierw podaj swoje imię.';

  @override
  String get gw_scheduleSoon => 'Harmonogram pojawi się wkrótce.';

  @override
  String get gw_scheduleItem => 'Punkt programu';

  @override
  String get gw_guestbookHint => 'Twój wpis dla Pary Młodej…';

  @override
  String get gw_guestbookCta => 'Dodaj wpis';

  @override
  String get gw_guestbookEmpty => 'Bądź pierwszy — zostaw wpis!';

  @override
  String get gw_adviceHint => 'Twoja rada dla Pary Młodej…';

  @override
  String get gw_adviceCta => 'Dodaj radę';

  @override
  String get gw_adviceEmpty => 'Podziel się pierwszą radą!';

  @override
  String get gw_needNameAndMessage => 'Podaj imię i treść.';

  @override
  String get gw_needNameAndCity => 'Podaj imię i miasto.';

  @override
  String get gw_fromWhereCity => 'Skąd przyjeżdżasz (miasto)';

  @override
  String get gw_greetingOptional => 'Pozdrowienie (opcjonalnie)';

  @override
  String get gw_addToMap => 'Dodaj na mapę';

  @override
  String get gw_mapEmpty => 'Bądź pierwszy na mapie gości!';

  @override
  String get gw_needNameAndText => 'Podaj imię i wiadomość.';

  @override
  String get gw_capsuleSealed => 'Wiadomość zapieczętowana!';

  @override
  String get gw_capsuleSealedBody =>
      'Para Młoda otworzy Twoją wiadomość w wybranym czasie. Dziękujemy!';

  @override
  String get gw_capsuleIntro =>
      'Zostaw wiadomość, którą Para Młoda otworzy w przyszłości. Inni goście jej nie zobaczą.';

  @override
  String get gw_capsuleHint => 'Twoja wiadomość do kapsuły czasu…';

  @override
  String get gw_capsuleSeal => 'Zapieczętuj wiadomość';

  @override
  String get gw_needFullName => 'Podaj imię i nazwisko.';

  @override
  String get gw_rsvpSeeYou => 'Do zobaczenia na weselu! 🎉';

  @override
  String get gw_rsvpThanks => 'Dziękujemy za odpowiedź';

  @override
  String get gw_rsvpSent => 'Twoje potwierdzenie trafiło do Pary Młodej.';

  @override
  String get gw_rsvpEdit => 'Popraw odpowiedź';

  @override
  String get gw_rsvpExistingHint =>
      'To Twoje wcześniejsze potwierdzenie. Możesz je poprawić — zapiszemy nową wersję zamiast dodawać kolejną.';

  @override
  String get gw_rsvpNewHint =>
      'Wystarczy jedno potwierdzenie. Jeśli plany się zmienią, wróć tutaj i popraw odpowiedź.';

  @override
  String get gw_fullName => 'Imię i nazwisko';

  @override
  String get gw_rsvpQuestion => 'Czy będziesz na weselu?';

  @override
  String get gw_rsvpYes => 'Będę';

  @override
  String get gw_rsvpNo => 'Nie dam rady';

  @override
  String get gw_companions => 'Liczba osób towarzyszących';

  @override
  String get gw_dietOptional => 'Dieta / alergie (opcjonalnie)';

  @override
  String get gw_messageOptional => 'Wiadomość dla Pary Młodej (opcjonalnie)';

  @override
  String get gw_rsvpSend => 'Wyślij potwierdzenie';

  @override
  String get gw_photoCaption => 'Podpis zdjęcia (opcjonalnie)';

  @override
  String get gw_photoThanks => 'Dziękujemy za zdjęcie ✓';

  @override
  String gw_photoError(String error) {
    return 'Nie udało się dodać zdjęcia: $error';
  }

  @override
  String get gw_galleryError => 'Nie udało się wczytać galerii.';

  @override
  String get gw_galleryEmpty => 'Bądź pierwszy — dodaj zdjęcie!';

  @override
  String get gw_photoUploading => 'Wysyłanie zdjęcia…';

  @override
  String get gw_camera => 'Aparat';

  @override
  String get gw_pickPhoto => 'Wybierz zdjęcie';

  @override
  String get gw_searchUnavailable =>
      'Wyszukiwarka niedostępna — wpisz tytuł i wykonawcę ręcznie.';

  @override
  String get gw_needSongTitle => 'Podaj tytuł utworu.';

  @override
  String get gw_proposalSent => 'Propozycja wysłana ✓';

  @override
  String get gw_musicIntro =>
      'Zaproponuj utwór, który chcesz usłyszeć na weselu. Propozycje trafiają do Pary Młodej.';

  @override
  String get gw_musicSearch => 'Szukaj utworu lub wykonawcy';

  @override
  String get gw_noResults => 'Brak wyników — spróbuj innej frazy.';

  @override
  String get gw_addManually => 'Dodaj ręcznie';

  @override
  String get gw_songTitle => 'Tytuł utworu';

  @override
  String get gw_artistOptional => 'Wykonawca (opcjonalnie)';

  @override
  String get gw_sendProposal => 'Wyślij propozycję';

  @override
  String get gw_yourProposals => 'Twoje propozycje';

  @override
  String get gw_gameInactive => 'Ta gra nie jest w tej chwili aktywna.';

  @override
  String get gw_questionsSoon => 'Pytania pojawią się wkrótce.';

  @override
  String get gw_statementsSoon => 'Stwierdzenia pojawią się wkrótce.';

  @override
  String get gw_answerAllQuestions => 'Odpowiedz na wszystkie pytania.';

  @override
  String get gw_answerAllStatements => 'Odpowiedz na wszystkie stwierdzenia.';

  @override
  String get gw_finishAndSend => 'Zakończ i wyślij wynik';

  @override
  String gw_scoreError(String error) {
    return 'Nie udało się wysłać wyniku: $error';
  }

  @override
  String get gw_scorePrivate =>
      'Wynik zobaczy Para Młoda. Nie ma publicznego rankingu.';

  @override
  String get gw_true => 'Prawda';

  @override
  String get gw_false => 'Fałsz';

  @override
  String gw_yourScore(int score, int total) {
    return 'Twój wynik: $score / $total';
  }

  @override
  String get gw_scoreEarlier =>
      'To Twój wcześniejszy wynik. Możesz spróbować ponownie — nowy wynik zastąpi poprzedni.';

  @override
  String get gw_scoreThanks =>
      'Dziękujemy za zabawę! Wynik trafił do Pary Młodej.';

  @override
  String get gw_playAgain => 'Zagraj ponownie';

  @override
  String get gw_challengesInactive =>
      'Foto-wyzwania nie są w tej chwili aktywne.';

  @override
  String get gw_challengesSoon => 'Wyzwania pojawią się wkrótce.';

  @override
  String get gw_challengeHint =>
      'Jedno zdjęcie na wyzwanie — kolejne zastąpi poprzednie.';

  @override
  String get gw_guestPhotos => 'Zdjęcia gości';

  @override
  String get gw_photosError => 'Nie udało się wczytać zdjęć.';

  @override
  String get gw_photosEmpty =>
      'Jeszcze nikt nie przesłał zdjęcia — zacznij Ty!';

  @override
  String gw_points(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pkt',
      one: '1 pkt',
    );
    return '$_temp0';
  }

  @override
  String get gw_sendPhoto => 'Wyślij zdjęcie';

  @override
  String get gw_photoSent => 'Zdjęcie wysłane ✓';

  @override
  String get gw_bingoSoon => 'Plansza bingo pojawi się wkrótce.';

  @override
  String get gw_bingoIntro =>
      'Skreślaj pola, gdy zobaczysz je na weselu. Skreślenia są tylko na Twoim telefonie — wyślij zgłoszenie, gdy uzbierasz komplet.';

  @override
  String gw_bingoMarked(int marked, int total) {
    return 'Skreślone: $marked / $total';
  }

  @override
  String get gw_bingoDone => 'Mam bingo!';

  @override
  String get gw_bingoFree => 'GRATIS';

  @override
  String get settings_configSaved => 'Konfiguracja zapisana ✓';

  @override
  String get settings_syncCard => 'Status synchronizacji';

  @override
  String get settings_syncOk => 'Zsynchronizowano z Firestore';

  @override
  String get settings_syncConnecting => 'Łączenie…';

  @override
  String get settings_guideCard => 'Przewodnik i pomoc';

  @override
  String get settings_guideHint =>
      'Wróć do interaktywnego przewodnika po aplikacji lub do listy kroków organizacji wesela.';

  @override
  String get settings_helpOpen => 'Pomoc — opisy funkcji';

  @override
  String get settings_legacyCard => 'Dane starych sekcji (legacy)';

  @override
  String get settings_legacyHint =>
      'Wpisy z czasów jednego wesela (galeria, księga gości, rady, mapa, kapsuła czasu, wyniki gier) nie mają przypisanego wesela. Migracja przypisuje je do TEGO wesela — bez niej znikną z panelu po wdrożeniu nowych reguł bezpieczeństwa.';

  @override
  String get settings_legacyBefore => 'Uruchom PRZED wdrożeniem nowych reguł.';

  @override
  String get settings_legacyCheck => 'Sprawdź';

  @override
  String get settings_legacyMigrate => 'Migruj';

  @override
  String settings_legacyError(String collection, String error) {
    return '$collection: BŁĄD — $error';
  }

  @override
  String settings_legacyToDo(String collection, int stamped, int skipped) {
    return '$collection: do migracji $stamped, już przypisane $skipped';
  }

  @override
  String settings_legacyDone(String collection, int stamped, int skipped) {
    return '$collection: przypisano $stamped, pominięto $skipped';
  }

  @override
  String settings_legacyCheckFailed(String error) {
    return 'Nie udało się sprawdzić: $error';
  }

  @override
  String get settings_legacyConfirmTitle =>
      'Przypisać stare wpisy do tego wesela?';

  @override
  String get settings_legacyConfirmBody =>
      'Wszystkie wpisy bez przypisanego wesela (galeria, księga gości, rady, mapa, kapsuła czasu, wyniki gier) zostaną przypisane do AKTYWNEGO wesela. Wpisy, które już mają wesele, nie zostaną ruszone. Operacji nie da się cofnąć jednym kliknięciem.';

  @override
  String get settings_legacyAssign => 'Przypisz';

  @override
  String get settings_legacyFinished => 'Migracja zakończona ✓';

  @override
  String settings_legacyFailed(String error) {
    return 'Migracja nieudana: $error';
  }

  @override
  String settings_currencyToast(String code) {
    return 'Waluta: $code';
  }

  @override
  String get settings_displayModeCard => 'Tryb wyświetlania';

  @override
  String get settings_displayModeHint =>
      'Domyślnie układ dobiera się do szerokości ekranu. Możesz go wymusić — przyda się na małym tablecie albo gdy wolisz układ telefonowy na dużym ekranie.';

  @override
  String get settings_interactionsCard => 'Interakcje gości (moderacja)';

  @override
  String get settings_interactionsHint =>
      'Zobacz i moderuj to, co goście przesłali przez stronę web: potwierdzenia RSVP, wpisy księgi, rady, mapę gości i kapsułę czasu.';

  @override
  String get settings_interactionsOpen => 'Zobacz interakcje gości';

  @override
  String get settings_loading => 'Ładowanie…';

  @override
  String get settings_guestLinkCard => 'Link i QR dla gości (strona web)';

  @override
  String get settings_guestLinkHint =>
      'Udostępnij gościom ten link lub kod QR. Otworzą stronę gości BEZ logowania — zobaczą tylko sekcje dla gości (z Twoimi ustawieniami widoczności).';

  @override
  String get settings_guestLinkCopied => 'Skopiowano link dla gości';

  @override
  String get settings_copyLink => 'Kopiuj link';

  @override
  String get settings_qrCode => 'Kod QR';

  @override
  String get settings_peopleCard => 'Osoby i dostęp';

  @override
  String get settings_peopleHint =>
      'Zarządzaj osobami z dostępem do wesela: dodawaj współorganizatorów i planerów, ustawiaj datę ważności, blokuj i usuwaj dostęp.';

  @override
  String get settings_peopleOpen => 'Zarządzaj osobami';

  @override
  String get settings_inviteCard =>
      'Zaproszenie dla gości (dołączenie na konto)';

  @override
  String get settings_inviteHint =>
      'Przekaż gościom kod QR albo trzy dane z tej karty. Gość poda je w aplikacji („Dołącz do wesela\") i zobaczy wesele na swoim koncie. To inna droga niż link do strony gości niżej — ten działa bez logowania.';

  @override
  String settings_codeCopied(String code) {
    return 'Skopiowano kod: $code';
  }

  @override
  String get settings_copyCode => 'Kopiuj kod';

  @override
  String get settings_qrScanHint => 'skanuje się w aplikacji';

  @override
  String get settings_inviteCopied => 'Skopiowano gotowe zaproszenie';

  @override
  String get settings_copyInvite => 'Kopiuj gotowe zaproszenie';

  @override
  String get settings_inviteDataTitle => 'Co gość musi podać';

  @override
  String get settings_weddingCode => 'Kod wesela';

  @override
  String get settings_weddingDate => 'Data ślubu';

  @override
  String get settings_notSet => 'nie ustawiono';

  @override
  String get settings_coupleSurname => 'Nazwisko Państwa Młodych';

  @override
  String settings_copiedValue(String value) {
    return 'Skopiowano: $value';
  }

  @override
  String get settings_surnameMissing =>
      'Uzupełnij pole „Nazwisko / nazwiska Pary Młodej\" w Konfiguracji — bez niego gość nie ma czego wpisać i nie dołączy.';

  @override
  String get settings_surnameFallback =>
      'Gość poda tu na razie „Osoby\". Wpisz w Konfiguracji pole „Nazwisko / nazwiska Pary Młodej\", jeśli wolisz, żeby podawał nazwisko.';

  @override
  String get settings_inviteTextHeader =>
      'Zapraszamy! Dołącz do naszego wesela w aplikacji Moje Wesele:';

  @override
  String get settings_inviteTextStep1 =>
      '1. Zainstaluj aplikację i załóż konto.';

  @override
  String get settings_inviteTextStep2 => '2. Wybierz „Dołącz do wesela\".';

  @override
  String get settings_inviteTextStep3 => '3. Podaj poniższe dane:';

  @override
  String settings_inviteTextCode(String code) {
    return '   • Kod wesela: $code';
  }

  @override
  String settings_inviteTextDate(String date) {
    return '   • Data ślubu: $date';
  }

  @override
  String settings_inviteTextSurname(String surname) {
    return '   • Nazwisko Państwa Młodych: $surname';
  }

  @override
  String get settings_inviteTextQr =>
      'Możesz też zeskanować nasz kod QR — wypełni kod za Ciebie.';

  @override
  String get settings_joinStepsTitle => 'Jak gość dołącza — krok po kroku';

  @override
  String get settings_joinStep1 =>
      'Gość instaluje aplikację i zakłada konto (albo loguje się na swoje).';

  @override
  String get settings_joinStep2 =>
      'Na liście wesel wybiera „Dołącz do wesela\".';

  @override
  String get settings_joinStep3 =>
      'Wpisuje kod wesela — albo klika „Skanuj\" i skanuje Twój kod QR, co wypełnia to pole automatycznie.';

  @override
  String get settings_joinStep4 => 'Wybiera datę ślubu z kalendarza.';

  @override
  String get settings_joinStep5 =>
      'Wpisuje nazwisko Państwa Młodych (to z tej karty).';

  @override
  String get settings_joinStep6 =>
      'Gotowe — wesele pojawia się na jego liście.';

  @override
  String get settings_visibilityCard => 'Widoczność dla gości';

  @override
  String get settings_visibilityHint =>
      'Ustal, które sekcje i w jakim czasie widzą goście na stronach publicznych (np. RSVP do tygodnia przed, galeria od dnia wesela).';

  @override
  String get settings_visibilityOpen => 'Ustaw widoczność sekcji';

  @override
  String get settings_notificationsHint =>
      'Wybierz, o czym chcesz wiedzieć na telefonie. Dzwoneczek w aplikacji działa zawsze, niezależnie od tych ustawień.';

  @override
  String get settings_notificationsOpen => 'Ustawienia powiadomień';

  @override
  String get settings_securityCard => 'Logowanie';

  @override
  String get settings_securityHint =>
      'Biometria (odcisk palca), PIN lub wzór do odblokowywania aplikacji przy kolejnych otwarciach.';

  @override
  String get settings_securityOpen => 'Logowanie i zabezpieczenia';

  @override
  String get settings_configOwnerHint =>
      'Zmianę daty ślubu i nazwisk musi zapisać właściciel wesela — inaczej dane dołączania gości pozostaną nieaktualne.';

  @override
  String get settings_coupleType => 'Typ uroczystości';

  @override
  String settings_coupleTypeHint(String hint) {
    return '$hint. Możesz to zmienić w każdej chwili — zmieniają się tylko etykiety, dane gości zostają nietknięte.';
  }

  @override
  String get settings_eventName => 'Nazwa wydarzenia';

  @override
  String get settings_persons => 'Osoby';

  @override
  String get settings_verificationSurnames => 'Nazwisko / nazwiska Pary Młodej';

  @override
  String get settings_verificationHint =>
      'Używane tylko do weryfikacji gościa przy dołączaniu kodem — nie jest nigdzie wyświetlane. Jeśli nazwiska są różne, wpisz oba (np. „Kowalska Nowak\").';

  @override
  String get settings_time => 'Godzina';

  @override
  String get settings_ceremonyPlace => 'Miejsce ceremonii';

  @override
  String get settings_receptionPlace => 'Miejsce wesela';

  @override
  String get settings_person1 => 'Osoba 1 (podział kosztów)';

  @override
  String get settings_person2 => 'Osoba 2';

  @override
  String get settings_witnesses => 'Liczba świadków';

  @override
  String get settings_witnessesHint =>
      'Domyślnie 2. Dla nietradycyjnych ślubów możesz ustawić więcej.';

  @override
  String get settings_children => 'Dzieci na weselu';

  @override
  String get settings_childrenHint =>
      'Możesz oznaczać gości jako dzieci, dodać stół dla dzieci i osobne menu. Ceny ustawisz w Budżet → Sala.';

  @override
  String get settings_childrenSwitch => 'Włącz, jeśli na weselu będą dzieci.';

  @override
  String get settings_menuDict => 'Słownik menu (po jednym w linii)';

  @override
  String get settings_expenseCategories =>
      'Kategorie wydatków (po jednym w linii)';

  @override
  String get settings_saveConfig => 'Zapisz konfigurację';

  @override
  String get settings_budgetCard => 'Ustawienia budżetu';

  @override
  String get settings_budgetHint =>
      'Budżet planowany to kwota założona na start. Rezerwa to opcjonalny bufor na nieprzewidziane wydatki — doliczany do planowanego jako bezpiecznik.';

  @override
  String settings_budgetPlanned(String currency) {
    return 'Budżet planowany ($currency)';
  }

  @override
  String settings_budgetReserve(String currency) {
    return 'Rezerwa ($currency)';
  }

  @override
  String get settings_budgetSave => 'Zapisz ustawienia budżetu';

  @override
  String get settings_budgetSaved => 'Zapisano ustawienia budżetu ✓';

  @override
  String get settings_accessCard => 'Dostęp';

  @override
  String get settings_accessHint =>
      'Rejestracja otwarta — każde konto Google może się zalogować i założyć własne wesele. Dostęp do tego wesela mają osoby z nim powiązane (właściciel i zaproszeni).';

  @override
  String get settings_devCard => 'Ustawienia programistyczne';

  @override
  String get settings_exportData => 'Eksport danych';

  @override
  String get settings_importData => 'Import danych';

  @override
  String get settings_backupCreate => 'Utwórz kopię';

  @override
  String get settings_backupsCard => 'Kopie zapasowe';

  @override
  String get settings_backupsHint =>
      'Kopie zapasowe (3 ostatnie) przechowywane lokalnie na urządzeniu.';

  @override
  String get settings_exportTitle => 'Eksport danych (JSON)';

  @override
  String get settings_importWarning =>
      '⚠ Import ZASTĄPI wszystkie obecne dane. Wklej poprawny JSON.';

  @override
  String get settings_importHint => 'Wklej JSON…';

  @override
  String get settings_importButton => 'Importuj (zastąp)';

  @override
  String get settings_importBadFormat => 'Nieprawidłowy format JSON';

  @override
  String get settings_importDone => 'Zaimportowano dane';

  @override
  String settings_importFailed(String error) {
    return 'Błąd importu: $error';
  }

  @override
  String get settings_backupCreated => 'Utworzono kopię zapasową';

  @override
  String get settings_backupsEmpty => 'Brak kopii zapasowych.';

  @override
  String get settings_backupRestore => 'Przywróć';

  @override
  String get settings_backupRestoreTitle => 'Przywrócić kopię?';

  @override
  String settings_backupRestoreBody(String date) {
    return 'Dane z $date zastąpią obecne dane.';
  }

  @override
  String get settings_backupRestored => 'Przywrócono kopię';

  @override
  String settings_backupRestoreFailed(String error) {
    return 'Błąd przywracania: $error';
  }

  @override
  String get role_planner => 'Planer';

  @override
  String get role_collaborator => 'Współorganizator';

  @override
  String get role_guest => 'Gość';

  @override
  String get status_active => 'Aktywny';

  @override
  String get status_blocked => 'Zablokowany';

  @override
  String get status_pending => 'Oczekuje';

  @override
  String get status_expired => 'Wygasł';

  @override
  String get vis_saved => 'Zapisano ustawienia widoczności ✓';

  @override
  String get vis_title => 'Widoczność dla gości';

  @override
  String get vis_sectionsHeader => 'SEKCJE DLA GOŚCI';

  @override
  String get vis_saving => 'Zapisywanie…';

  @override
  String get vis_save => 'Zapisz ustawienia';

  @override
  String get vis_intro =>
      'Ustal, kiedy goście widzą poszczególne sekcje na stronach publicznych. Możesz podać datę OD, DO, obie lub żadną. Daty liczone są wg czasu polskiego (Europe/Warsaw).';

  @override
  String get vis_masterTitle => 'Strona dla gości';

  @override
  String get vis_masterOn => 'Włączona — obowiązują ustawienia sekcji poniżej';

  @override
  String get vis_masterOff => 'Wyłączona — goście nie widzą żadnej sekcji';

  @override
  String get vis_from => 'Widoczne od';

  @override
  String get vis_to => 'Widoczne do';

  @override
  String get vis_outOfRange => 'Gdy niedostępne dla gościa:';

  @override
  String get vis_showMessage => 'Pokaż komunikat';

  @override
  String get vis_hideSection => 'Ukryj sekcję';

  @override
  String get vis_stateVisible => 'Widoczna dla gości teraz';

  @override
  String vis_stateFrom(String date) {
    return 'Będzie widoczna od $date';
  }

  @override
  String vis_stateTo(String date) {
    return 'Już niedostępna (do $date)';
  }

  @override
  String get vis_stateOff => 'Wyłączona dla gości';

  @override
  String get vis_stateMasterOff => 'Cała strona dla gości wyłączona';

  @override
  String get notif_pushWhen => 'Wyślij mi push, gdy:';

  @override
  String get notif_soonTitle => 'Powiadomienia na telefon — wkrótce';

  @override
  String get notif_soonBody =>
      'Push jeszcze nie działa — wymaga włączenia powiadomień systemowych i uruchomienia usługi po naszej stronie. Twój wybór zapisujemy już teraz, więc po włączeniu push wszystko zadziała bez ponownego ustawiania.';

  @override
  String get notif_bellTitle => 'Dzwoneczek w aplikacji działa zawsze';

  @override
  String get notif_bellBody =>
      'Centrum powiadomień w prawym górnym rogu pokazuje zmiany niezależnie od poniższych ustawień. Te przełączniki dotyczą wyłącznie powiadomień wysyłanych na telefon, gdy nie korzystasz z aplikacji.';

  @override
  String get notif_allOff =>
      'Wszystko wyłączone — po uruchomieniu push nie dostaniesz żadnego powiadomienia na telefon. Dzwoneczek w aplikacji nadal będzie działał.';

  @override
  String get sec_enabled => 'Zabezpieczenia włączone ✓';

  @override
  String get sec_disableTitle => 'Wyłączyć zabezpieczenia?';

  @override
  String get sec_disableBody =>
      'Aplikacja przestanie wymagać odcisku palca / PIN-u przy otwieraniu. Zapisany PIN/wzór zostanie usunięty z tego urządzenia.';

  @override
  String get sec_disable => 'Wyłącz';

  @override
  String get sec_disabled => 'Zabezpieczenia wyłączone';

  @override
  String get sec_confirmBiometric =>
      'Potwierdź odcisk palca, aby włączyć szybkie logowanie';

  @override
  String get sec_biometricFailed => 'Nie potwierdzono biometrii';

  @override
  String get sec_biometricOn => 'Logowanie odciskiem palca włączone';

  @override
  String get sec_biometricOff => 'Logowanie odciskiem palca wyłączone';

  @override
  String get sec_backupChanged => 'Zmieniono zabezpieczenie zapasowe ✓';

  @override
  String get sec_title => 'Logowanie';

  @override
  String get sec_statusCard => 'Status zabezpieczeń';

  @override
  String get sec_lockOn => 'Blokada aplikacji jest aktywna';

  @override
  String get sec_lockOff => 'Blokada aplikacji wyłączona';

  @override
  String get sec_biometricStatusOn => 'Logowanie odciskiem palca: włączone';

  @override
  String get sec_biometricStatusOff => 'Logowanie odciskiem palca: wyłączone';

  @override
  String sec_backupStatus(String type) {
    return 'Zabezpieczenie zapasowe: $type';
  }

  @override
  String get sec_noReader =>
      'To urządzenie nie ma czytnika biometrycznego — dostępny tylko PIN/wzór.';

  @override
  String get sec_lockCard => 'Blokada aplikacji';

  @override
  String get sec_requireBiometric => 'Wymagaj odcisku palca lub PIN-u';

  @override
  String get sec_requirePin => 'Wymagaj PIN-u lub wzoru';

  @override
  String get sec_onNextOpen => 'Przy kolejnych otwarciach aplikacji.';

  @override
  String get sec_fingerprint => 'Odcisk palca';

  @override
  String get sec_fastLogin => 'Szybkie logowanie odciskiem palca';

  @override
  String get sec_pinStaysBackup => 'PIN/wzór pozostaje jako metoda zapasowa.';

  @override
  String get sec_noReaderLong =>
      'Brak czytnika biometrycznego na tym urządzeniu. Odblokowujesz aplikację PIN-em lub wzorem.';

  @override
  String get sec_backupCard => 'Zabezpieczenie zapasowe';

  @override
  String sec_backupCurrent(String type) {
    return 'Aktualnie: $type. Możesz zmienić bez wyłączania całej blokady.';
  }

  @override
  String get sec_changePin => 'Zmień PIN / wzór';

  @override
  String people_addConfirm(String email, String role) {
    return 'Czy na pewno dodać osobę „$email\" jako $role?';
  }

  @override
  String people_codeConfirm(String role) {
    return 'Wygenerować kod zaproszenia dla roli $role?';
  }

  @override
  String people_added(String role) {
    return 'Dodano osobę jako $role ✓';
  }

  @override
  String people_noAccount(String email) {
    return 'Nie znaleziono konta „$email\". Osoba musi najpierw założyć konto w aplikacji.';
  }

  @override
  String get people_alreadyMember => 'Ta osoba już ma dostęp do wesela.';

  @override
  String get people_error => 'Błąd. Spróbuj ponownie.';

  @override
  String people_inviteCodeTitle(String role) {
    return 'Kod zaproszenia — $role';
  }

  @override
  String get people_inviteCodeBody =>
      'Przekaż ten kod osobie. Po zalogowaniu wejdzie w „Mam kod zaproszenia\" na ekranie „Twoje wesela\" i odbierze dostęp.';

  @override
  String people_codeCopied(String code) {
    return 'Skopiowano kod: $code';
  }

  @override
  String get people_blockTitle => 'Zablokować dostęp?';

  @override
  String get people_unblockTitle => 'Przywrócić dostęp?';

  @override
  String people_blockBody(String who) {
    return 'Osoba „$who\" straci dostęp do wesela, dopóki go nie przywrócisz.';
  }

  @override
  String people_unblockBody(String who) {
    return 'Osoba „$who\" znów będzie miała dostęp do wesela.';
  }

  @override
  String get people_blocked => 'Zablokowano dostęp';

  @override
  String get people_unblocked => 'Przywrócono dostęp';

  @override
  String get people_removeTitle => 'Usunąć osobę?';

  @override
  String people_removeBody(String who) {
    return 'Osoba „$who\" zostanie całkowicie usunięta z wesela. Możesz ją później dodać ponownie.';
  }

  @override
  String get people_removed => 'Usunięto osobę';

  @override
  String get people_expiryTitle => 'Data ważności dostępu planera';

  @override
  String get people_expiryUpdated => 'Zaktualizowano datę ważności';

  @override
  String get people_title => 'Osoby i dostęp';

  @override
  String get people_add => 'Dodaj osobę';

  @override
  String get people_intro =>
      'Zarządzaj osobami z dostępem do wesela. Współorganizator ma pełny panel bez ograniczeń czasu; planer ma pełny panel z datą ważności. Ty (Para Młoda) zawsze zostajesz właścicielem.';

  @override
  String get people_you => ' (Ty)';

  @override
  String people_validUntil(String date) {
    return 'ważny do $date';
  }

  @override
  String people_code(String code) {
    return 'kod: $code';
  }

  @override
  String get people_actions => 'Akcje';

  @override
  String get people_changeExpiry => 'Zmień datę ważności';

  @override
  String get people_block => 'Zablokuj dostęp';

  @override
  String get people_unblock => 'Przywróć dostęp';

  @override
  String get people_remove => 'Usuń osobę';

  @override
  String get people_pendingInvite => 'Zaproszenie (oczekuje)';

  @override
  String get people_person => 'Osoba';

  @override
  String get people_setExpiry => 'Ustaw datę ważności dla planera.';

  @override
  String get people_role => 'Rola';

  @override
  String get people_plannerHint =>
      'Pełny panel z datą ważności dostępu (odcinany po dacie).';

  @override
  String get people_collaboratorHint =>
      'Pełny panel bez ograniczeń czasowych (świadek, mama…).';

  @override
  String get people_expiry => 'Data ważności';

  @override
  String get people_pickDate => 'Wybierz datę';

  @override
  String get people_howToAdd => 'Sposób dodania';

  @override
  String get people_byEmail => 'Przez e-mail';

  @override
  String get people_byCode => 'Kod zaproszenia';

  @override
  String get people_email => 'E-mail osoby (musi mieć konto)';

  @override
  String get people_emailHint => 'np. jan.kowalski@gmail.com';

  @override
  String get people_codeHint =>
      'Wygenerujemy kod, który przekażesz osobie. Odbierze go w „Mam kod zaproszenia\" na swoim ekranie „Twoje wesela\".';

  @override
  String get gi_title => 'Interakcje gości';

  @override
  String get gi_tabGuestbook => 'Księga';

  @override
  String get gi_tabAdvice => 'Rady';

  @override
  String get gi_tabMap => 'Mapa';

  @override
  String get gi_tabCapsule => 'Kapsuła';

  @override
  String get gi_tabGallery => 'Galeria';

  @override
  String get gi_tabChallenges => 'Foto-wyzwania';

  @override
  String get gi_tabMusic => 'Muzyka';

  @override
  String get gi_tabQuiz => 'Quiz';

  @override
  String get gi_tabTrueFalse => 'Prawda/Fałsz';

  @override
  String get gi_tabPhotoGuess => 'Zgadnij zdjęcie';

  @override
  String get gi_tabBingo => 'Bingo';

  @override
  String get gi_deleteTitle => 'Usunąć wpis?';

  @override
  String get gi_deletePhotoBody =>
      'Zdjęcie zniknie ze strony gości. Oryginał zostaje w Cloudinary.';

  @override
  String get gi_deleteEntryBody => 'Wpis gościa zostanie trwale usunięty.';

  @override
  String gi_loadError(String error) {
    return 'Nie udało się wczytać: $error';
  }

  @override
  String get gi_empty => 'Brak wpisów.';

  @override
  String get gi_musicNew => 'Nowa';

  @override
  String get gi_musicAccepted => 'Zagramy';

  @override
  String get gi_musicRejected => 'Odrzucona';

  @override
  String gi_score(String name, int score, int total) {
    return '$name — $score/$total pkt';
  }

  @override
  String gi_bingoMarked(String name, int marked, int total) {
    return '$name — skreślone $marked/$total';
  }

  @override
  String gi_proposedBy(String name) {
    return 'Zaproponował(a): $name';
  }

  @override
  String gi_challengeNo(String id) {
    return 'Wyzwanie #$id';
  }

  @override
  String gi_diet(String diet) {
    return 'Dieta: $diet';
  }

  @override
  String get gi_willAttend => 'Będzie';

  @override
  String get gi_willNotAttend => 'Nie będzie';

  @override
  String get cw_title => 'Nowe wesele';

  @override
  String get cw_intro =>
      'Podaj podstawowe informacje — resztę uzupełnisz później w Ustawieniach.';

  @override
  String get cw_name => 'Nazwa wesela';

  @override
  String get cw_nameHint => 'np. Nasze Wesele';

  @override
  String get cw_defaultName => 'Nasze Wesele';

  @override
  String cw_coupleTypeHint(String hint) {
    return '$hint. Możesz to zmienić później w Ustawieniach → Konfiguracja.';
  }

  @override
  String get cw_names => 'Imiona Pary Młodej (opcjonalnie)';

  @override
  String cw_namesHint(String category) {
    return 'Podane imiona od razu trafią na listę gości jako „$category\". Puste pola pomiń — dodasz je kiedy indziej.';
  }

  @override
  String get cw_personsHint => 'np. Ania i Piotr';

  @override
  String get cw_dateOptional => 'Data ślubu (opcjonalnie)';

  @override
  String get cw_pickDateLater => 'Wybierz datę (możesz później)';

  @override
  String get cw_children => 'Będą dzieci na weselu';

  @override
  String get cw_childrenHint =>
      'Możesz to zmienić później w Ustawieniach → Konfiguracja. Ceny menu dziecięcego ustawisz w Budżecie.';

  @override
  String get cw_childrenCount => 'Ile dzieci (orientacyjnie, opcjonalnie)';

  @override
  String get cw_childrenCountHint => 'np. 8';

  @override
  String get cw_childrenAuto =>
      'Zostaw puste, a liczba dzieci będzie liczona z listy gości — wystarczy oznaczać ich jako dzieci.';

  @override
  String get cw_childrenManual =>
      'Podana liczba będzie użyta w wyliczeniach. Gdy wpiszesz dzieci na listę gości, przełącz liczenie na automatyczne w Budżecie.';

  @override
  String get cw_create => 'Utwórz wesele';

  @override
  String get cw_firstName => 'Imię';

  @override
  String get jw_fillAll => 'Uzupełnij wszystkie pola: kod, datę i nazwisko.';

  @override
  String get jw_joined => 'Dołączono do wesela jako gość ✓';

  @override
  String get jw_alreadyMember => 'Już należysz do tego wesela.';

  @override
  String get jw_badData =>
      'Nieprawidłowe dane wesela. Sprawdź kod, datę ślubu i nazwisko Państwa Młodych.';

  @override
  String get jw_connectionError => 'Błąd połączenia. Spróbuj ponownie.';

  @override
  String get jw_title => 'Dołącz do wesela';

  @override
  String get jw_codeHint => 'np. ABCD-EFGH-JKMN';

  @override
  String get jw_scan => 'Skanuj';

  @override
  String get jw_surnameHint => 'np. Kowalscy / Ania i Piotr';

  @override
  String get jw_checking => 'Sprawdzanie…';

  @override
  String get jw_intro =>
      'Aby potwierdzić, że jesteś zaproszonym gościem, podaj trzy dane z zaproszenia: kod wesela, datę ślubu i nazwisko Państwa Młodych. Wszystkie muszą się zgadzać.';

  @override
  String get jw_scanTitle => 'Zeskanuj kod QR';

  @override
  String get jw_scanHint => 'Skieruj aparat na kod QR z zaproszenia';

  @override
  String wl_createFailed(String error) {
    return 'Nie udało się utworzyć wesela: $error';
  }

  @override
  String get wl_create => 'Załóż wesele';

  @override
  String get wl_haveCodeLong =>
      'Mam kod zaproszenia (współorganizator / planer)';

  @override
  String get wl_haveCode => 'Mam kod zaproszenia';

  @override
  String get wl_haveCodeBody =>
      'Wpisz kod otrzymany od Pary Młodej, aby odebrać dostęp jako współorganizator lub planer.';

  @override
  String get wl_redeem => 'Odbierz';

  @override
  String get wl_redeemed => 'Dostęp odebrany ✓';

  @override
  String get wl_alreadyAccess => 'Już masz dostęp do tego wesela.';

  @override
  String get wl_badCode => 'Nieprawidłowy lub wykorzystany kod zaproszenia.';

  @override
  String get wl_error => 'Błąd. Spróbuj ponownie.';

  @override
  String get wl_preparing => 'Przygotowuję strefę gości…';

  @override
  String wl_failed(String error) {
    return 'Nie udało się: $error';
  }

  @override
  String get wl_nothingToPrepare => 'Brak wesel do przygotowania';

  @override
  String wl_prepareResult(int ok, int total) {
    return 'Gotowe: $ok z $total';
  }

  @override
  String get wl_noFullAccess =>
      'Nie masz wesel z pełnym dostępem. Wesela, w których jesteś tylko gościem, przygotowuje ich organizator.';

  @override
  String get wl_itemOk => 'gotowe ✓';

  @override
  String wl_itemError(String error) {
    return 'BŁĄD: $error';
  }

  @override
  String get wl_title => 'Twoje wesela';

  @override
  String get wl_subtitle => 'Wybierz wesele lub utwórz nowe';

  @override
  String get wl_more => 'Więcej';

  @override
  String get wl_prepareGuestZone => 'Przygotuj strefę gości';

  @override
  String get wl_prepareForAll => 'Dla wszystkich Twoich wesel';

  @override
  String get wl_empty => 'Nie masz jeszcze żadnego wesela';

  @override
  String get wl_emptyBody =>
      'Załóż pierwsze wesele, aby rozpocząć organizację. Możesz też dołączyć do wesela, do którego ktoś Cię zaprosi.';

  @override
  String get wl_createFirst => 'Załóż pierwsze wesele';

  @override
  String get wl_loadError => 'Nie udało się wczytać wesel';

  @override
  String get wl_dateTbd => 'Data do ustalenia';

  @override
  String setup_todo(int count) {
    return 'Do uzupełnienia ($count)';
  }

  @override
  String get setup_basic => 'Podstawowa';

  @override
  String get setup_advanced => 'Zaawansowana';

  @override
  String setup_progress(int done, int total) {
    return '$done/$total gotowe';
  }

  @override
  String get setup_allDone => 'Wszystko uzupełnione ✓';

  @override
  String setup_partial(int done, int total, int left) {
    return 'Uzupełniono $done z $total — zostało $left';
  }

  @override
  String get setup_basicDone =>
      'Podstawy gotowe. Zajrzyj do zaawansowanej, żeby dopracować budżet, stoły i strefę gości.';

  @override
  String get setup_complete => 'Komplet — wszystkie dane wesela uzupełnione.';

  @override
  String setup_done(int count) {
    return 'Gotowe ($count)';
  }

  @override
  String setup_goTo(String section) {
    return '→ $section';
  }

  @override
  String get setup_fix => 'Popraw';

  @override
  String get setup_go => 'Przejdź';

  @override
  String get plan_newStep => 'Nowy krok';

  @override
  String get plan_resetTitle => 'Przywrócić domyślną listę?';

  @override
  String get plan_resetBody =>
      'Lista kroków „Od czego zacząć?\" wróci do domyślnej. Wprowadzone zmiany zostaną utracone.';

  @override
  String get plan_reset => 'Przywróć';

  @override
  String get plan_orderTitle => 'Sugerowana kolejność planowania wesela';

  @override
  String get plan_orderHint =>
      'Odhaczaj ukończone kroki — pasek pokaże postęp.';

  @override
  String plan_progress(int done, int total, int pct) {
    return '$done z $total ukończonych · $pct%';
  }

  @override
  String get plan_deleteStep => 'Usuń krok';

  @override
  String get plan_addStep => 'Dodaj krok';

  @override
  String get plan_resetDefaults => 'Przywróć domyślne';

  @override
  String people_codeConfirmUntil(String role, String date) {
    return 'Wygenerować kod zaproszenia dla roli $role (ważny do $date)?';
  }

  @override
  String get gh_title => 'Wesele';

  @override
  String get gh_loadError => 'Nie udało się wczytać strefy gości.';

  @override
  String get gh_loadErrorHint =>
      'Sprawdź połączenie z internetem i spróbuj ponownie.';

  @override
  String get gh_notReady => 'Strefa gości nie jest jeszcze gotowa';

  @override
  String get gh_notReadyBody =>
      'Para Młoda jeszcze jej nie przygotowała. Zajrzyj później albo poproś ją o udostępnienie sekcji dla gości.';

  @override
  String get gh_account => 'Konto';

  @override
  String get gh_guide => 'Przewodnik';

  @override
  String get gh_switchWedding => 'Zmień wesele';

  @override
  String get sec_backupPin => 'PIN';

  @override
  String get sec_backupPattern => 'wzór';

  @override
  String get bio_reason => 'Potwierdź tożsamość, aby odblokować aplikację';

  @override
  String get bio_signInTitle => 'Logowanie biometryczne';

  @override
  String get bio_hint => 'Zweryfikuj tożsamość';

  @override
  String get bio_notRecognized => 'Nie rozpoznano — spróbuj ponownie';

  @override
  String get bio_success => 'Rozpoznano';

  @override
  String get bio_settings => 'Ustawienia';

  @override
  String get bio_settingsHint =>
      'Skonfiguruj biometrię w ustawieniach urządzenia.';

  @override
  String get help_start_title => 'Start';

  @override
  String get help_start_1Title => 'Pulpit';

  @override
  String get help_start_1Body =>
      'Licznik dni do ślubu, skróty do sekcji i najważniejsze statystyki. Układ kafelków ustawiasz sam — możesz ukryć te, których nie używasz.';

  @override
  String get help_start_2Title => 'Od czego zacząć?';

  @override
  String get help_start_2Body =>
      'Sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki, a pasek pokaże postęp. Otworzysz ją z Ustawień w dowolnym momencie — lista jest wspólna dla wszystkich organizatorów wesela.';

  @override
  String get help_start_3Title => 'Przewodnik a Pomoc';

  @override
  String get help_start_3Body =>
      'Przewodnik prowadzi po aplikacji krok po kroku i podświetla elementy na ekranie. Pomoc (ten ekran) to encyklopedia funkcji do czytania wtedy, gdy szukasz konkretnej odpowiedzi.';

  @override
  String get help_guests_title => 'Goście';

  @override
  String get help_guests_1Title => 'Lista gości';

  @override
  String get help_guests_1Body =>
      'Dodawaj zaproszonych i zarządzaj ich danymi. Każdy gość może mieć osobę towarzyszącą — dodaj ją przy wpisie, a nie jako osobnego gościa, dzięki czemu liczby w podsumowaniu się zgadzają.';

  @override
  String get help_guests_2Title => 'Kartoteka';

  @override
  String get help_guests_2Body =>
      'Szczegóły przydatne przy organizacji: dieta, alergie, wiek, potrzeba noclegu i transportu, uwagi. Te dane napędzają też kalkulacje w Budżecie i przypisania w Noclegach.';

  @override
  String get help_guests_3Title => 'Podsumowanie gości';

  @override
  String get help_guests_3Body =>
      'Zbiorcze liczby: zaproszeni, potwierdzeni, dzieci, diety. Sprawdź je przed rozmową z salą — to na ich podstawie ustala się catering.';

  @override
  String get help_guests_4Title => 'Potwierdzenia obecności (RSVP)';

  @override
  String get help_guests_4Body =>
      'Masz dwa źródła: wpisy, które sam dodasz w panelu, oraz potwierdzenia przysłane przez gości ze strefy gości. Te drugie znajdziesz w Ustawieniach → Interakcje gości → RSVP. Każdy gość może wysłać jedno potwierdzenie i sam je poprawić, jeśli plany się zmienią.';

  @override
  String get help_budget_title => 'Budżet';

  @override
  String get help_budget_1Title => 'Jedno źródło danych — najważniejsza zasada';

  @override
  String get help_budget_1Body =>
      'Pozycja dodana w Dostawcach, Prezentach czy Podróży poślubnej pojawia się w Budżecie automatycznie, z etykietą „dodano w…\". Edytuj ją tam, gdzie powstała — dzięki temu nic nie liczy się podwójnie i nie musisz pilnować dwóch list.';

  @override
  String get help_budget_2Title => 'Podsumowanie budżetu';

  @override
  String get help_budget_2Body =>
      'Limit kontra wydatki, ile zostało do rozdysponowania oraz zestawienie wszystkich płatności i terminów w jednym miejscu.';

  @override
  String get help_budget_3Title => 'Sala i catering';

  @override
  String get help_budget_3Body =>
      'Stawkę podajesz za osobę, a aplikacja przelicza koszt z liczby gości. Możesz osobno wliczyć obsługę (fotograf, zespół), dzieci po innej stawce i gości jeszcze nieprzypisanych do stołów. Ustaw też minimum gwarantowane przez salę, jeśli umowa je przewiduje.';

  @override
  String get help_budget_4Title => 'Wydatki';

  @override
  String get help_budget_4Body =>
      'Pozostałe koszty pogrupowane w kategorie. Kategorie edytujesz w Ustawieniach → Konfiguracja.';

  @override
  String get help_budget_5Title => 'Alkohol i napoje';

  @override
  String get help_budget_5Body =>
      'Rodzaje, ilości i ceny — osobno alkohol, osobno napoje bezalkoholowe. Przydaje się przy ustalaniu, co bierzecie własne, a co z sali.';

  @override
  String get help_budget_6Title => 'Podróż poślubna';

  @override
  String get help_budget_6Body =>
      'Liczona osobno od kosztów wesela, żeby nie zaburzała budżetu przyjęcia — ale jej płatności widać w Podsumowaniu razem z pozostałymi.';

  @override
  String get help_budget_7Title => 'Raty i terminy płatności';

  @override
  String get help_budget_7Body =>
      'Przy dostawcy lub wydatku rozpisz raty z datami. Nadchodzące terminy zobaczysz w Podsumowaniu budżetu i na pulpicie.';

  @override
  String get help_room_title => 'Plan sali';

  @override
  String get help_room_1Title => 'Układanie sali';

  @override
  String get help_room_1Body =>
      'Włącz „Edytuj plan\", aby przeciągać stoły i elementy oraz zmieniać ich rozmiar. Poza trybem edycji plan służy do przeglądania i przypisywania gości — trudniej wtedy coś przypadkiem przesunąć.';

  @override
  String get help_room_2Title => 'Przypisywanie gości do stołów';

  @override
  String get help_room_2Body =>
      'Przeciągnij gościa na miejsce przy stole. Goście nieprzypisani są widoczni osobno — pamiętaj o nich, bo mogą wliczać się do kosztu cateringu, zależnie od ustawień w Budżecie.';

  @override
  String get help_room_3Title => 'Stoły obsługi';

  @override
  String get help_room_3Body =>
      'Stoliki dla fotografa, zespołu czy obsługi oznacz osobno — mają własną stawkę cateringową i nie mieszają się z listą gości.';

  @override
  String get help_schedule_title => 'Harmonogram i zadania';

  @override
  String get help_schedule_1Title => 'Plan dnia';

  @override
  String get help_schedule_1Body =>
      'Punkty programu z godzinami, kategorią i miejscem. To najważniejszy dokument dnia ślubu — przyda się fotografowi, zespołowi i obsłudze sali.';

  @override
  String get help_schedule_2Title => 'Punkt prywatny';

  @override
  String get help_schedule_2Body =>
      'Punkt oznaczony jako prywatny NIE trafia do strefy gości. Używaj go do spraw organizacyjnych: „przyjazd florystki\", „rozliczenie z salą\".';

  @override
  String get help_schedule_3Title => 'Link do miejsca dla gości';

  @override
  String get help_schedule_3Body =>
      'Przy punkcie możesz podać link do mapy i osobno zdecydować, czy pokazać go gościom. Bez zaznaczenia tej opcji link zostaje tylko dla Was.';

  @override
  String get help_schedule_4Title => 'Checklista';

  @override
  String get help_schedule_4Body =>
      'Lista rzeczy do odhaczenia przed weselem i w jego trakcie — osobna od Zadań, bo służy do szybkiego „zrobione / niezrobione\".';

  @override
  String get help_schedule_5Title => 'Zadania i powiązania';

  @override
  String get help_schedule_5Body =>
      'Zadaniu możesz przypisać osobę odpowiedzialną i powiązać je z wydatkiem, dostawcą lub prezentem. Dzięki temu z jednego miejsca widzisz, co zostało do zrobienia i ile to kosztuje.';

  @override
  String get help_vendors_title => 'Dostawcy, transport, noclegi';

  @override
  String get help_vendors_1Title => 'Dostawcy';

  @override
  String get help_vendors_1Body =>
      'Kontakty, kwoty umów, statusy płatności i raty. Kwota dostawcy trafia do Budżetu automatycznie — nie dodawaj jej drugi raz jako wydatku.';

  @override
  String get help_vendors_2Title => 'Transport';

  @override
  String get help_vendors_2Body =>
      'Trasy, pojazdy i przypisanie pasażerów. Informacja „potrzebuje transportu\" pochodzi z kartoteki gościa.';

  @override
  String get help_vendors_3Title => 'Noclegi';

  @override
  String get help_vendors_3Body =>
      'Obiekty, pokoje i rezerwacje dla gości. Podobnie jak transport — korzysta z oznaczeń w kartotece.';

  @override
  String get help_guestZone_title => 'Strefa gości';

  @override
  String get help_guestZone_1Title => 'Link i kod QR dla gości';

  @override
  String get help_guestZone_1Body =>
      'Ustawienia → „Link i QR dla gości\". Gość otwiera stronę bez logowania i bez instalowania aplikacji. Ten kod drukujesz na zaproszeniach albo kładziesz na stołach.';

  @override
  String get help_guestZone_2Title => 'Kod dołączenia (konto gościa)';

  @override
  String get help_guestZone_2Body =>
      'Sześcioznakowy kod dla gościa, który chce mieć wesele na własnym koncie. Weryfikacja jest potrójna: kod, data ślubu i nazwisko — sam kod nie wystarczy, bo bywa jawny na stołach.';

  @override
  String get help_guestZone_3Title => 'Widoczność sekcji dla gości';

  @override
  String get help_guestZone_3Body =>
      'Decydujesz, które sekcje widzą goście i w jakim okresie (daty OD/DO). Wybierasz też, co się dzieje poza zakresem: komunikat „dostępne od…\" albo całkowite ukrycie kafelka. Typowo: RSVP włącz od razu, galerię dopiero w dniu wesela.';

  @override
  String get help_guestZone_4Title => 'Interakcje gości i moderacja';

  @override
  String get help_guestZone_4Body =>
      'Ustawienia → „Interakcje gości\". W jednym miejscu zbierają się potwierdzenia, wpisy księgi, rady, zdjęcia, propozycje muzyki i wyniki gier. Każdy wpis możesz usunąć jednym kliknięciem.';

  @override
  String get help_guestZone_5Title => 'Czego gość nie widzi';

  @override
  String get help_guestZone_5Body =>
      'Budżet, pełna lista gości, dostawcy, plan sali i zadania są dla gościa niedostępne — i nie chodzi o ukrycie w interfejsie, tylko o techniczny brak dostępu do tych danych.';

  @override
  String get help_media_title => 'Zdjęcia i muzyka';

  @override
  String get help_media_1Title => 'Galeria';

  @override
  String get help_media_1Body =>
      'Wspólny album: goście wrzucają zdjęcia ze swoich telefonów, Wy widzicie wszystko w panelu i możecie usuwać niechciane wpisy.';

  @override
  String get help_media_2Title => 'Muzyka i propozycje gości';

  @override
  String get help_media_2Body =>
      'Budujesz playlistę wesela, a goście przysyłają propozycje utworów. Propozycje widzicie tylko Wy — nie ma publicznej listy ani głosowania. Każdą oznaczysz jako „Zagramy\" lub „Odrzucona\".';

  @override
  String get help_games_title => 'Gry i pamiątki';

  @override
  String get help_games_1Title => 'Quiz, Prawda/Fałsz, Zgadnij zdjęcie';

  @override
  String get help_games_1Body =>
      'Dodaj pytania i włącz grę przełącznikiem „aktywna\". Gość gra na swoim telefonie, a wynik trafia do Was. Publicznego rankingu nie ma — nikt nie porównuje się z innymi.';

  @override
  String get help_games_2Title => 'Foto-wyzwania';

  @override
  String get help_games_2Body =>
      'Lista zadań fotograficznych z punktami. Gość wysyła po jednym zdjęciu do każdego wyzwania; kolejne zastępuje poprzednie.';

  @override
  String get help_games_3Title => 'Ślubne Bingo';

  @override
  String get help_games_3Body =>
      'Pola bingo możesz wpisać ręcznie lub wygenerować z punktów harmonogramu. Plansze drukujesz do PDF, a goście mogą też grać na telefonie.';

  @override
  String get help_games_4Title => 'Pamiątki';

  @override
  String get help_games_4Body =>
      'Księga gości, rady dla Pary Młodej, kapsuła czasu i mapa gości. Kapsuła jest prywatna — czytacie ją tylko Wy.';

  @override
  String get help_roles_title => 'Role i dostęp';

  @override
  String get help_roles_1Title => 'Właściciel ma władzę nadrzędną';

  @override
  String get help_roles_1Body =>
      'Konto Pary Młodej jest najważniejsze. Tylko właściciel dodaje osoby, wystawia zaproszenia i może każdemu odebrać dostęp — także planerowi.';

  @override
  String get help_roles_2Title => 'Współorganizator';

  @override
  String get help_roles_2Body =>
      'Świadek, mama, przyjaciółka — pełny panel bez daty ważności. Nie może jednak dodawać kolejnych osób; to zostaje przy właścicielu.';

  @override
  String get help_roles_3Title => 'Planer i data ważności';

  @override
  String get help_roles_3Body =>
      'Planerowi możesz nadać dostęp z datą wygaśnięcia. Po tej dacie wesele znika z jego listy. Dostęp da się w każdej chwili zablokować i przywrócić — wielokrotnie.';

  @override
  String get help_roles_4Title =>
      'Jak dodać planera lub współorganizatora — krok po kroku';

  @override
  String get help_roles_4Body =>
      'Ustawienia → „Osoby i dostęp\" → „Dodaj osobę\". Wybierz rolę (Współorganizator albo Planer), a przy planerze ustaw datę ważności dostępu. Potem masz dwie drogi: podać adres e-mail osoby (musi już mieć konto w aplikacji) albo wygenerować kod zaproszenia i przekazać go dowolnym kanałem. Zaproszenie dodaje osobę tylko do TEGO wesela — przy kilku weselach każde wymaga osobnego zaproszenia.';

  @override
  String get help_roles_5Title => 'Jak działa kod zaproszenia';

  @override
  String get help_roles_5Body =>
      'Kod jest jednorazowy i przypisany do konkretnego wesela oraz roli. Osoba, która go dostanie, zakłada konto (albo loguje się na istniejące), a następnie na liście wesel wybiera „Mam kod zaproszenia (współorganizator / planer)\" i wpisuje go. Po wykorzystaniu kod przestaje działać — dla kolejnej osoby wygeneruj nowy. To inna ścieżka niż kod dla gości, którym goście dołączają do strefy gościa.';

  @override
  String get help_roles_6Title => 'Data ważności dostępu planera';

  @override
  String get help_roles_6Body =>
      'Datę ustawiasz przy zapraszaniu i zmieniasz później na liście osób. Po jej upływie wesele znika z listy planera i traci on dostęp do danych — bez usuwania czegokolwiek u Ciebie. Datę można przesunąć, a dostęp zablokować i przywrócić wielokrotnie. Współorganizator daty ważności nie ma.';

  @override
  String get help_roles_7Title => 'Odbieranie dostępu';

  @override
  String get help_roles_7Body =>
      'Na liście „Osoby i dostęp\" przy każdej osobie znajdziesz blokadę i usunięcie. Blokada zostawia osobę na liście (można ją odblokować), usunięcie kasuje członkostwo — powrót wymaga nowego zaproszenia. Właściciela nie da się usunąć.';

  @override
  String get help_analytics_title => 'Analityka';

  @override
  String get help_analytics_1Title => 'Wykresy i statystyki';

  @override
  String get help_analytics_1Body =>
      'Postępy organizacji, struktura kosztów i frekwencja. Dobre miejsce, by sprawdzić, czy budżet nie rozjeżdża się z planem.';

  @override
  String get help_settings_title => 'Ustawienia i dane';

  @override
  String get help_settings_1Title => 'Konfiguracja wesela';

  @override
  String get help_settings_1Body =>
      'Nazwa, data, godzina, miejsca ceremonii i przyjęcia, podział kosztów oraz słowniki (menu, kategorie wydatków). Po zmianie daty lub nazwisk zapisz konfigurację — odświeża to dane dołączania gości.';

  @override
  String get help_settings_2Title => 'Synchronizacja';

  @override
  String get help_settings_2Body =>
      'Dane zapisują się w chmurze i są wspólne dla wszystkich organizatorów wesela. Kartę statusu znajdziesz na górze Ustawień.';

  @override
  String get help_settings_3Title => 'Kopie zapasowe i eksport';

  @override
  String get help_settings_3Body =>
      'Możesz utworzyć kopię zapasową oraz wyeksportować wszystkie dane do pliku JSON. Import nadpisuje dane wesela — używaj ostrożnie.';

  @override
  String get help_settings_4Title => 'Blokada aplikacji';

  @override
  String get help_settings_4Body =>
      'PIN, wzór lub biometria zabezpieczają dostęp na tym urządzeniu. Ustawienie jest lokalne — nie przenosi się na inne telefony.';

  @override
  String get help_planner_title => 'Praca z klientami';

  @override
  String get help_planner_1Title => 'Wiele wesel na jednym koncie';

  @override
  String get help_planner_1Body =>
      'Możesz prowadzić dowolnie wiele wesel. Przełączasz je w menu pod logo → „Zmień wesele\". Dane każdego wesela są w pełni oddzielone — klient A nigdy nie zobaczy wesela klienta B.';

  @override
  String get help_planner_2Title => 'Twój dostęp bywa czasowy';

  @override
  String get help_planner_2Body =>
      'Para Młoda może nadać Ci dostęp z datą ważności oraz zablokować go i przywrócić. Gdy wesele zniknie z Twojej listy, to najczęściej wygasła data, a nie awaria — poproś klienta o przedłużenie.';

  @override
  String get help_planner_3Title => 'Czego planer nie może';

  @override
  String get help_planner_3Body =>
      'Dodawanie osób i wystawianie zaproszeń jest zarezerwowane dla właściciela wesela. To celowe: klient ma zawsze kontrolę nad tym, kto ma dostęp do jego danych.';

  @override
  String get help_planner_4Title => 'Przekazanie wesela Parze';

  @override
  String get help_planner_4Body =>
      'Nie ma osobnego „przekazania\" — wesele od początku należy do Pary Młodej. Gdy kończycie współpracę, po prostu tracisz dostęp, a wszystkie dane zostają u klienta. Nic nie trzeba eksportować.';

  @override
  String get help_planner_5Title => 'Dane osobowe klientów';

  @override
  String get help_planner_5Body =>
      'Lista gości zawiera dane osobowe: nazwiska, telefony, adresy e-mail, informacje o dietach. Traktuj je poufnie i nie przenoś między weselami.';

  @override
  String get help_planner_6Title => 'Co pokazać klientowi';

  @override
  String get help_planner_6Body =>
      'Najczęściej sprawdzają się: Podsumowanie budżetu (na co idą pieniądze), plan sali (wydruk) i harmonogram dnia. Analityka daje gotowy materiał na podsumowanie postępów.';

  @override
  String get help_gStart_title => 'Na start';

  @override
  String get help_gStart_1Title => 'Czym jest ta strona';

  @override
  String get help_gStart_1Body =>
      'To strefa gości przygotowana przez Parę Młodą. Nie musisz zakładać konta ani niczego instalować — wystarczy link lub kod QR z zaproszenia.';

  @override
  String get help_gStart_2Title => 'Nie widzę jakiejś sekcji';

  @override
  String get help_gStart_2Body =>
      'Para Młoda sama decyduje, co i kiedy udostępnia. Część sekcji pojawia się dopiero bliżej wesela, a niektóre znikają po nim. Zajrzyj później.';

  @override
  String get help_gRsvp_title => 'Potwierdzenie obecności';

  @override
  String get help_gRsvp_1Title => 'Jak potwierdzić obecność';

  @override
  String get help_gRsvp_1Body =>
      'Wejdź w RSVP, wpisz imię i nazwisko, zaznacz, czy będziesz, i wyślij. Jeśli przyjeżdżasz z kimś, podaj liczbę osób towarzyszących — nie wypełniaj formularza drugi raz za tę osobę.';

  @override
  String get help_gRsvp_2Title => 'Zmiana odpowiedzi';

  @override
  String get help_gRsvp_2Body =>
      'Wystarczy jedno potwierdzenie. Gdy plany się zmienią, wróć do RSVP — formularz wypełni się Twoją poprzednią odpowiedzią, a po zapisaniu zastąpi ją nowa.';

  @override
  String get help_gRsvp_3Title => 'Dieta i alergie';

  @override
  String get help_gRsvp_3Body =>
      'Wpisz je w formularzu potwierdzenia. Ta informacja trafia prosto do Pary Młodej i pomaga ustalić menu z salą.';

  @override
  String get help_gPhotos_title => 'Zdjęcia';

  @override
  String get help_gPhotos_1Title => 'Dodawanie zdjęć';

  @override
  String get help_gPhotos_1Body =>
      'W Galerii podaj imię, wybierz zdjęcie z telefonu lub zrób je od razu aparatem. Możesz dorzucić podpis. Zdjęć możesz dodać dowolnie wiele.';

  @override
  String get help_gPhotos_2Title => 'Kto widzi moje zdjęcia';

  @override
  String get help_gPhotos_2Body =>
      'Galeria jest wspólna — widzą ją wszyscy goście z linkiem oraz Para Młoda. Para może usunąć każde zdjęcie.';

  @override
  String get help_gMusic_title => 'Muzyka';

  @override
  String get help_gMusic_1Title => 'Propozycja utworu';

  @override
  String get help_gMusic_1Body =>
      'Wyszukaj piosenkę albo wpisz tytuł i wykonawcę ręcznie, a potem wyślij propozycję. Jeśli wyszukiwarka nie działa (bywa tak w przeglądarce), skorzystaj z pól ręcznych — efekt jest taki sam.';

  @override
  String get help_gMusic_2Title => 'Kto widzi propozycje';

  @override
  String get help_gMusic_2Body =>
      'Tylko Para Młoda. Nie ma publicznej listy ani głosowania, więc nikt nie podejrzy, co zaproponowali inni.';

  @override
  String get help_gSchedule_title => 'Harmonogram';

  @override
  String get help_gSchedule_1Title => 'Plan dnia';

  @override
  String get help_gSchedule_1Body =>
      'Godzina po godzinie: ceremonia, przyjęcie, tort, pierwszy taniec. U góry zobaczysz licznik dni do wesela.';

  @override
  String get help_gGames_title => 'Gry';

  @override
  String get help_gGames_1Title => 'Quiz, Prawda/Fałsz, Zgadnij zdjęcie';

  @override
  String get help_gGames_1Body =>
      'Odpowiedz na wszystkie pytania i wyślij wynik. Możesz podejść ponownie — nowy wynik zastąpi poprzedni, więc nic nie tracisz.';

  @override
  String get help_gGames_2Title => 'Foto-wyzwania';

  @override
  String get help_gGames_2Body =>
      'Lista zadań fotograficznych. Do każdego wyzwania wysyłasz jedno zdjęcie; kolejne zastąpi poprzednie. Zdjęcia widzą wszyscy goście.';

  @override
  String get help_gGames_3Title => 'Ślubne Bingo';

  @override
  String get help_gGames_3Body =>
      'Skreślaj pola, gdy zobaczysz je na weselu. Skreślenia zostają na Twoim telefonie — wyślij zgłoszenie dopiero, gdy uzbierasz komplet.';

  @override
  String get help_gGames_4Title => 'Kto widzi wyniki';

  @override
  String get help_gGames_4Body =>
      'Wyłącznie Para Młoda. Nie ma publicznego rankingu, więc graj dla zabawy, a nie dla rywalizacji.';

  @override
  String get help_gKeepsakes_title => 'Pamiątki';

  @override
  String get help_gKeepsakes_1Title => 'Księga gości i rady';

  @override
  String get help_gKeepsakes_1Body =>
      'Zostaw życzenia albo dobrą radę dla Pary Młodej. Wpisów możesz dodać kilka, a widzą je też inni goście — to trochę wspólna kronika.';

  @override
  String get help_gKeepsakes_2Title => 'Kapsuła czasu';

  @override
  String get help_gKeepsakes_2Body =>
      'Prywatna wiadomość do Pary Młodej. Nie zobaczy jej żaden inny gość.';

  @override
  String get help_gKeepsakes_3Title => 'Mapa gości';

  @override
  String get help_gKeepsakes_3Body =>
      'Zaznacz, skąd przyjeżdżasz. Jedna pinezka na gościa — możesz ją poprawić, wracając do sekcji.';

  @override
  String get help_gPrivacy_title => 'Prywatność';

  @override
  String get help_gPrivacy_1Title => 'Co widzi Para Młoda';

  @override
  String get help_gPrivacy_1Body =>
      'Twoje potwierdzenie obecności, wpisy, zdjęcia, propozycje muzyczne i wyniki gier — zawsze z imieniem, które podasz.';

  @override
  String get help_gPrivacy_2Title => 'Czego nie widzą inni goście';

  @override
  String get help_gPrivacy_2Body =>
      'Twojego potwierdzenia obecności, wiadomości do kapsuły czasu, propozycji muzycznych ani wyników gier. Publiczne są tylko: księga gości, rady, mapa, galeria i zdjęcia z foto-wyzwań.';

  @override
  String get setupTask_eventNameLabel => 'Nazwa wesela';

  @override
  String get setupTask_eventNameHint =>
      'Np. „Wesele Ani i Piotra\" — pokazuje się w nagłówku aplikacji i na stronie dla gości.';

  @override
  String get setupTask_weddingDateLabel => 'Data i godzina ślubu';

  @override
  String get setupTask_weddingDateHint =>
      'Od daty liczy się odliczanie na pulpicie i weryfikacja gości przy dołączaniu kodem.';

  @override
  String get setupTask_coupleTypeLabel => 'Typ uroczystości';

  @override
  String get setupTask_coupleTypeHint =>
      'Decyduje o etykietach w całej aplikacji — „Panna Młoda / Pan Młody\", dwie Panny Młode, dwóch Panów Młodych albo neutralnie.';

  @override
  String get setupTask_coupleNamesLabel => 'Imiona Pary Młodej';

  @override
  String get setupTask_coupleNamesHint =>
      'Wpisz oba imiona — używa ich podział kosztów, etykiety i lista gości.';

  @override
  String get setupTask_ceremonyPlaceLabel => 'Miejsce ceremonii';

  @override
  String get setupTask_ceremonyPlaceHint =>
      'Kościół albo USC — adres zobaczą goście w harmonogramie.';

  @override
  String get setupTask_receptionPlaceLabel => 'Miejsce przyjęcia';

  @override
  String get setupTask_receptionPlaceHint =>
      'Nazwa i adres sali — też trafia do harmonogramu gości.';

  @override
  String get setupTask_verificationSurnamesLabel =>
      'Nazwisko do weryfikacji gości';

  @override
  String get setupTask_verificationSurnamesHint =>
      'Nazwisko (albo oba nazwiska), które gość poda przy dołączaniu kodem. Nigdzie się nie wyświetla — służy tylko sprawdzeniu.';

  @override
  String get setupTask_guestsLabel => 'Pierwsi goście';

  @override
  String get setupTask_guestsHint =>
      'Dodaj choć kilka osób — od listy gości zależą catering, stoły i statystyki.';

  @override
  String get setupTask_budgetTotalLabel => 'Budżet planowany';

  @override
  String get setupTask_budgetTotalHint =>
      'Kwota, w której chcecie się zmieścić. Bez niej nie ma z czym porównywać wydatków.';

  @override
  String get setupTask_pricePerPersonLabel => 'Cena za osobę (sala)';

  @override
  String get setupTask_pricePerPersonHint =>
      'Stawka od talerza — mnoży się przez liczbę gości i daje koszt cateringu.';

  @override
  String get setupTask_withChildrenLabel => 'Decyzja o dzieciach';

  @override
  String get setupTask_withChildrenHint =>
      'Ustal, czy na weselu będą dzieci. Jeśli tak, dojdzie menu dziecięce, stół dla dzieci i wyłączenie ich z przeliczeń alkoholu.';

  @override
  String get setupTask_menuOptionsLabel => 'Słownik menu';

  @override
  String get setupTask_menuOptionsHint =>
      'Warianty dania do wyboru przy gościach (mięsne, rybne, wege, dla dziecka).';

  @override
  String get setupTask_expenseCategoriesLabel => 'Kategorie wydatków';

  @override
  String get setupTask_expenseCategoriesHint =>
      'Własne kategorie kosztów — po nich grupują się wydatki i wykresy w Analityce.';

  @override
  String get setupTask_witnessesLabel => 'Świadkowie';

  @override
  String get setupTask_witnessesHint =>
      'Oznacz świadków na liście gości — pojawią się w podsumowaniu i na planie sali.';

  @override
  String get setupTask_tablesLabel => 'Stoły';

  @override
  String get setupTask_tablesHint =>
      'Dodaj stoły z liczbą miejsc — bez nich nie da się rozsadzić gości.';

  @override
  String get setupTask_seatingLabel => 'Rozsadzenie gości';

  @override
  String get setupTask_seatingHint =>
      'Przypisz gości do stołów — choćby część. Resztę dokończysz bliżej wesela.';

  @override
  String get setupTask_scheduleLabel => 'Harmonogram dnia';

  @override
  String get setupTask_scheduleHint =>
      'Punkty programu z godzinami. Ten sam harmonogram widzą goście w swojej strefie.';

  @override
  String get setupTask_guestVisibilityLabel => 'Widoczność sekcji dla gości';

  @override
  String get setupTask_guestVisibilityHint =>
      'Zdecyduj, co i od kiedy widzą goście — np. RSVP od razu, a galerię dopiero w dniu wesela.';

  @override
  String get setupLevel_basic => 'Konfiguracja podstawowa';

  @override
  String get setupLevel_advanced => 'Konfiguracja zaawansowana';

  @override
  String get setupLevel_basicIntro =>
      'Minimum, żeby ruszyć: dane wesela i pierwsi goście.';

  @override
  String get setupLevel_advancedIntro =>
      'Dopracowanie: budżet, menu, stoły, harmonogram i strefa gości. To, co masz już uzupełnione, jest odhaczone.';

  @override
  String get section_dashboard => 'Pulpit';

  @override
  String get section_guests => 'Goście';

  @override
  String get section_budget => 'Budżet';

  @override
  String get section_room => 'Plan sali';

  @override
  String get section_schedule => 'Harmonogram';

  @override
  String get section_tasks => 'Zadania';

  @override
  String get section_vendors => 'Dostawcy';

  @override
  String get section_transport => 'Transport';

  @override
  String get section_accommodation => 'Noclegi';

  @override
  String get section_music => 'Muzyka';

  @override
  String get section_gifts => 'Prezenty';

  @override
  String get section_gallery => 'Galeria & QR';

  @override
  String get section_games => 'Ślubne gry';

  @override
  String get section_keepsakes => 'Ślubne pamiątki';

  @override
  String get section_analytics => 'Analityka';

  @override
  String get section_rsvp => 'Potwierdzenia';

  @override
  String get section_rsvpAll => 'Wszystkie RSVP';

  @override
  String get section_settings => 'Ustawienia';

  @override
  String get onb_desc_dashboard =>
      'Twój pulpit — licznik dni do ślubu, skróty i najważniejsze statystyki w jednym miejscu.';

  @override
  String get onb_desc_guests =>
      'Lista zaproszonych, ich dane, statusy potwierdzeń i preferencje — w podzakładkach.';

  @override
  String get onb_desc_budget =>
      'Kontroluj wszystkie koszty wesela w jednym miejscu — podzakładki obok.';

  @override
  String get onb_desc_room =>
      'Rozmieść stoły i elementy sali na interaktywnym planie. Włącz „Edytuj plan\", aby przeciągać i zmieniać rozmiary.';

  @override
  String get onb_desc_schedule =>
      'Rozpisz przebieg dnia ślubu oraz checklistę — w podzakładkach.';

  @override
  String get onb_desc_tasks =>
      'Rozpisz zadania, przypisz osoby i powiąż je z budżetem, dostawcą lub prezentem.';

  @override
  String get onb_desc_vendors =>
      'Baza usługodawców — kontakty, umowy, raty płatności i powiązania z budżetem.';

  @override
  String get onb_desc_transport =>
      'Zorganizuj dojazd gości — trasy, pojazdy i przypisanie pasażerów.';

  @override
  String get onb_desc_accommodation =>
      'Zarządzaj noclegami dla gości — obiekty, pokoje i rezerwacje.';

  @override
  String get onb_desc_music =>
      'Twórz playlistę wesela i zbieraj propozycje utworów od gości (kod QR).';

  @override
  String get onb_desc_gifts =>
      'Ewidencja prezentów otrzymanych, upominków dla gości i listy życzeń — w podzakładkach.';

  @override
  String get onb_desc_gallery =>
      'Wspólna galeria zdjęć z wesela oraz kody QR do udostępniania gościom.';

  @override
  String get onb_desc_games =>
      'Ślubne gry — zabawy dla gości, m.in. Ślubne Bingo generowane z wydarzeń harmonogramu. Wkrótce kolejne gry.';

  @override
  String get onb_desc_keepsakes =>
      'Ślubne pamiątki — księga gości, rady dla Pary Młodej, kapsuła czasu i mapa gości. W przygotowaniu.';

  @override
  String get onb_desc_analytics =>
      'Wykresy i statystyki organizacji — postępy, koszty i frekwencja.';

  @override
  String get onb_desc_rsvp =>
      'Zarządzaj potwierdzeniami obecności (RSVP) i udostępniaj gościom formularz online.';

  @override
  String get onb_desc_settings =>
      'Tu znajdziesz konfigurację, dostęp, logowanie i narzędzia. Przewodnik wznowisz w każdej chwili z menu pod logo. To już wszystko — powodzenia!';

  @override
  String onb_desc_fallback(String section) {
    return 'Sekcja „$section\" w aplikacji.';
  }

  @override
  String get onb_sub_guests_1Title => 'Lista';

  @override
  String get onb_sub_guests_1Desc =>
      'Lista zaproszonych — dodawaj gości i zarządzaj ich danymi.';

  @override
  String get onb_sub_guests_2Title => 'Kartoteka';

  @override
  String get onb_sub_guests_2Desc =>
      'Szczegółowa kartoteka: status potwierdzenia, dieta, wiek i uwagi.';

  @override
  String get onb_sub_guests_3Title => 'Podsumowanie';

  @override
  String get onb_sub_guests_3Desc =>
      'Zbiorcze statystyki: liczba gości, potwierdzenia, dzieci i diety.';

  @override
  String get onb_sub_budget_1Title => 'Podsumowanie';

  @override
  String get onb_sub_budget_1Desc =>
      'Budżet całkowity kontra wydatki — ile już rozdysponowano.';

  @override
  String get onb_sub_budget_2Title => 'Sala';

  @override
  String get onb_sub_budget_2Desc =>
      'Koszt sali — stawka za osobę przelicza się z liczbą gości (przypisanych, nieprzypisanych i obsługi).';

  @override
  String get onb_sub_budget_3Title => 'Wydatki';

  @override
  String get onb_sub_budget_3Desc =>
      'Dodawaj pozostałe wydatki i grupuj je w kategorie.';

  @override
  String get onb_sub_budget_4Title => 'Alkohol';

  @override
  String get onb_sub_budget_4Desc =>
      'Planuj rodzaje, ilości i koszty alkoholu.';

  @override
  String get onb_sub_budget_5Title => 'Napoje bezalkoholowe';

  @override
  String get onb_sub_budget_5Desc =>
      'Woda, soki, napoje gazowane — ilości i koszty.';

  @override
  String get onb_sub_budget_6Title => 'Podróż poślubna';

  @override
  String get onb_sub_budget_6Desc =>
      'Budżet miesiąca miodowego osobno od kosztów wesela. W „Podsumowaniu\" znajdziesz też wszystkie płatności i terminy.';

  @override
  String get onb_sub_schedule_1Title => 'Plan dnia';

  @override
  String get onb_sub_schedule_1Desc =>
      'Punkty programu z godzinami — od ceremonii po ostatni taniec.';

  @override
  String get onb_sub_schedule_2Title => 'Checklista';

  @override
  String get onb_sub_schedule_2Desc =>
      'Lista rzeczy do odhaczenia przed weselem i w jego trakcie.';

  @override
  String get onb_sub_gifts_1Title => 'Otrzymane';

  @override
  String get onb_sub_gifts_1Desc =>
      'Zapisuj, co i od kogo dostaliście — przyda się przy podziękowaniach.';

  @override
  String get onb_sub_gifts_2Title => 'Dla gości';

  @override
  String get onb_sub_gifts_2Desc =>
      'Planuj podziękowania i upominki dla gości.';

  @override
  String get onb_sub_gifts_3Title => 'Propozycje';

  @override
  String get onb_sub_gifts_3Desc =>
      'Wasza lista życzeń — podpowiedzcie gościom, co sprawi Wam radość.';

  @override
  String get onb_set_1Title => 'Ustawienia · Status synchronizacji';

  @override
  String get onb_set_1Desc =>
      'Sprawdź, czy dane są zsynchronizowane z chmurą (Firestore).';

  @override
  String get onb_set_2Title => 'Ustawienia · Widoczność dla gości';

  @override
  String get onb_set_2Desc =>
      'Decydujesz, które sekcje widzą goście i od kiedy do kiedy. Np. RSVP włącz od razu, a galerię dopiero w dniu wesela.';

  @override
  String get onb_set_3Title => 'Ustawienia · Kod dołączenia dla gości';

  @override
  String get onb_set_3Desc =>
      'Sześcioznakowy kod, którym gość dołącza do wesela na własnym koncie. Weryfikacja jest potrójna: kod, data ślubu i nazwisko.';

  @override
  String get onb_set_4Title => 'Ustawienia · Link i QR dla gości';

  @override
  String get onb_set_4Desc =>
      'Link i kod QR do strefy gości — działa bez logowania i bez instalowania aplikacji. To go drukujesz na zaproszeniach albo kładziesz na stołach.';

  @override
  String get onb_set_5Title => 'Ustawienia · Interakcje gości';

  @override
  String get onb_set_5Desc =>
      'Wszystko, co przysłali goście: RSVP, wpisy księgi, rady, zdjęcia, propozycje muzyki i wyniki gier. Tu też moderujesz — kasujesz nieodpowiednie wpisy jednym kliknięciem.';

  @override
  String get onb_set_6Title => 'Ustawienia · Osoby i dostęp';

  @override
  String get onb_set_6Desc =>
      'Tu dodajesz współorganizatora (świadek, mama) i planera. „Dodaj osobę\" → wybierz rolę → podaj e-mail osoby z kontem albo wygeneruj jednorazowy kod zaproszenia i prześlij go jej. Zaproszona osoba wpisuje kod na liście wesel („Mam kod zaproszenia\"). Planerowi ustawisz datę ważności — po niej wesele znika z jego listy. Dostęp blokujesz i przywracasz w każdej chwili. Tylko właściciel wesela może tu cokolwiek zmienić — to zabezpieczenie, nie ograniczenie.';

  @override
  String get onb_set_7Title => 'Ustawienia · Konfiguracja';

  @override
  String get onb_set_7Desc =>
      'Nazwa imprezy, data, miejsca, podział kosztów i słowniki.';

  @override
  String get onb_set_8Title => 'Ustawienia · Logowanie';

  @override
  String get onb_set_8Desc =>
      'Biometria, PIN/wzór i status zabezpieczeń urządzenia.';

  @override
  String get onb_set_9Title => 'Ustawienia · Programistyczne';

  @override
  String get onb_set_9Desc => 'Eksport/import danych i kopie zapasowe.';

  @override
  String get onb_plannerDesc_dashboard =>
      'Pulpit wesela KLIENTA — licznik dni, postępy i statystyki. Każde wesele w Twoim koncie ma własny pulpit; przełączasz je w „Zmień wesele\".';

  @override
  String get onb_plannerDesc_guests =>
      'Lista gości klienta wraz z potwierdzeniami i preferencjami. To dane osobowe Waszych klientów — traktuj je poufnie.';

  @override
  String get onb_plannerDesc_budget =>
      'Budżet wesela klienta. Tu najczęściej pokazujesz Parze, na co idą pieniądze i gdzie są oszczędności — podzakładki obok.';

  @override
  String get onb_plannerDesc_room =>
      'Plan sali do ustalenia z klientem i salą. Wydrukowany układ stołów to jeden z najczęściej zamawianych elementów Twojej usługi.';

  @override
  String get onb_plannerDesc_schedule =>
      'Harmonogram dnia — Twój najważniejszy dokument roboczy. To on trafia do obsługi, fotografa i zespołu muzycznego.';

  @override
  String get onb_plannerDesc_tasks =>
      'Zadania z przypisaniem osób. Możesz tu rozdzielić obowiązki między siebie, Parę i podwykonawców.';

  @override
  String get onb_plannerDesc_vendors =>
      'Baza usługodawców z umowami i ratami. Prowadząc kilka wesel, budujesz tu swoją prywatną bazę sprawdzonych kontaktów.';

  @override
  String get onb_plannerDesc_analytics =>
      'Wykresy i statystyki — gotowy materiał na podsumowanie postępów dla klienta.';

  @override
  String get onb_plannerDesc_settings =>
      'Konfiguracja wesela, dostęp osób i widoczność sekcji dla gości. Pamiętaj: właścicielem wesela pozostaje Para Młoda — to ona nadaje i odbiera dostępy. Przewodnik wznowisz z menu pod logo.';

  @override
  String get onb_planner_1Title => 'Wiele wesel na jednym koncie';

  @override
  String get onb_planner_1Desc =>
      'Jako planer możesz prowadzić dowolnie wiele wesel. Przełączasz je w menu pod logo → „Zmień wesele\". Dane każdego wesela są w pełni oddzielone — klient A nigdy nie zobaczy wesela klienta B.';

  @override
  String get onb_planner_2Title => 'Twój dostęp może mieć datę ważności';

  @override
  String get onb_planner_2Desc =>
      'Para Młoda nadaje planerowi dostęp, może ustawić mu datę ważności i w każdej chwili go zablokować lub przywrócić. Po wygaśnięciu wesele znika z Twojej listy — to normalne, nie awaria.';

  @override
  String get onb_planner_3Title => 'Przekazanie wesela Parze Młodej';

  @override
  String get onb_planner_3Desc =>
      'Konto Pary Młodej jest nadrzędne: tylko ona dodaje osoby i wystawia zaproszenia. Gdy kończysz współpracę, to Para przejmuje pełną kontrolę — nic nie trzeba przenosić ani eksportować.';

  @override
  String get onb_guest_1Title => 'Witaj w strefie gości';

  @override
  String get onb_guest_1Desc =>
      'To Twoje miejsce na weselu Pary Młodej. Znajdziesz tu wszystko, czego potrzebujesz jako gość — bez zakładania konta i bez instalowania czegokolwiek.';

  @override
  String get onb_guest_2Title => 'Potwierdzenie obecności (RSVP)';

  @override
  String get onb_guest_2Desc =>
      'Daj znać, czy będziesz i z iloma osobami. Podaj dietę lub alergie, jeśli je masz. Wystarczy jedno potwierdzenie — gdy plany się zmienią, wróć tutaj i popraw odpowiedź.';

  @override
  String get onb_guest_3Title => 'Harmonogram dnia';

  @override
  String get onb_guest_3Desc =>
      'Godzina po godzinie: ceremonia, przyjęcie, tort, pierwszy taniec. Zobaczysz też licznik dni do wesela.';

  @override
  String get onb_guest_4Title => 'Galeria — dodaj swoje zdjęcia';

  @override
  String get onb_guest_4Desc =>
      'Wrzuć zdjęcia prosto z telefonu i oglądaj te dodane przez innych gości. Para Młoda dostaje w ten sposób ujęcia, których nie ma żaden fotograf.';

  @override
  String get onb_guest_5Title => 'Muzyka — zaproponuj utwór';

  @override
  String get onb_guest_5Desc =>
      'Wyszukaj piosenkę i wyślij propozycję do Pary Młodej. Propozycje trafiają tylko do nich — nie ma publicznej listy ani głosowania.';

  @override
  String get onb_guest_6Title => 'Ślubne gry';

  @override
  String get onb_guest_6Desc =>
      'Quiz o Parze Młodej, Prawda/Fałsz, Zgadnij zdjęcie, foto-wyzwania i Ślubne Bingo. Wyniki widzi tylko Para Młoda — nie ma publicznego rankingu, więc graj dla zabawy.';

  @override
  String get onb_guest_7Title => 'Gry — jak to działa';

  @override
  String get onb_guest_7Desc =>
      'Quiz, Prawda/Fałsz i Zgadnij zdjęcie liczą wynik od razu na Twoim telefonie. Możesz podejść ponownie — nowy wynik zastąpi poprzedni. W foto-wyzwaniach wysyłasz po jednym zdjęciu do każdego zadania.';

  @override
  String get onb_guest_8Title => 'Ślubne pamiątki';

  @override
  String get onb_guest_8Desc =>
      'Zostaw ślad po sobie: wpis w księdze gości, rada dla Pary Młodej, wiadomość do kapsuły czasu i pinezka na mapie gości.';

  @override
  String get onb_guest_9Title => 'Księga gości i rady';

  @override
  String get onb_guest_9Desc =>
      'Wpisów możesz zostawić kilka — życzenia, wspomnienie, dobra rada. Widzą je inni goście, więc to trochę jak wspólna kronika.';

  @override
  String get onb_guest_10Title => 'Kapsuła czasu i mapa gości';

  @override
  String get onb_guest_10Desc =>
      'Kapsuła to prywatna wiadomość — przeczyta ją wyłącznie Para Młoda. Na mapie zaznaczasz, skąd przyjeżdżasz; jedna pinezka na gościa, można ją poprawić.';

  @override
  String get onb_guest_11Title => 'To wszystko!';

  @override
  String get onb_guest_11Desc =>
      'Sekcje pojawiają się i znikają zgodnie z tym, co udostępniła Para Młoda — jeśli czegoś nie widzisz, być może będzie dostępne bliżej wesela. Bawcie się dobrze!';

  @override
  String get onb_planningTitle => 'Od czego zacząć?';

  @override
  String get onb_planningDesc =>
      'Sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki, a pasek pokaże postęp. Otworzysz ją w każdej chwili z Ustawień.';

  @override
  String get onb_qrTitle => 'Kody QR dla gości';

  @override
  String get onb_qrDesc =>
      'Udostępnij gościom kody QR prowadzące do galerii, muzyki, harmonogramu i potwierdzeń.';

  @override
  String onb_subTitle(String section, String tab) {
    return '$section › $tab';
  }

  @override
  String onb_moreSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…i jeszcze $count kroków na liście',
      few: '…i jeszcze $count kroki na liście',
      one: '…i jeszcze 1 krok na liście',
    );
    return '$_temp0';
  }

  @override
  String onb_stepHeader(String title) {
    return '🧭  $title';
  }

  @override
  String onb_stepCounter(int index, int total) {
    return 'Krok $index z $total';
  }

  @override
  String get onb_skip => 'Pomiń';

  @override
  String get onb_finish => 'Zakończ';

  @override
  String get onb_guestTitle => 'Przewodnik dla gościa';

  @override
  String get onb_guestIntro =>
      'Pokażemy Ci, co możesz zrobić na stronie przygotowanej przez Parę Młodą. Zajmie to chwilę.';

  @override
  String get onb_plannerTitle => 'Przewodnik dla planera';

  @override
  String get onb_plannerIntro =>
      'Pokażemy Ci panel wesela klienta i to, czym różni się praca planera od konta Pary Młodej. Wznowisz go z Ustawień.';

  @override
  String get onb_plannerShort => 'Główne sekcje panelu i zasady pracy planera';

  @override
  String get onb_plannerFull => 'Wszystkie sekcje, podzakładki i ustawienia';

  @override
  String get onb_ownerTitle => 'Przewodnik po aplikacji';

  @override
  String get onb_ownerIntro =>
      'Pokażemy Ci najważniejsze miejsca w aplikacji. Wybierz tempo — przewodnik wznowisz w każdej chwili z Ustawień (pod logo).';

  @override
  String get onb_ownerShort => 'Tylko główne sekcje — szybki przegląd';

  @override
  String get onb_ownerFull => 'Wszystkie sekcje i podzakładki';

  @override
  String get onb_guestPreviewNote =>
      'To podgląd dla Ciebie. Goście oglądają swoją strefę na osobnej stronie o zupełnie innym wyglądzie — tutaj pokazujemy wyłącznie treść ich przewodnika.';

  @override
  String get onb_guestPreview => 'Zobacz przewodnik gościa';

  @override
  String get onb_start => 'Rozpocznij';

  @override
  String get onb_guestFull => 'Wszystkie sekcje strefy gości';

  @override
  String get onb_short => 'Skrócony';

  @override
  String get onb_full => 'Rozszerzony';

  @override
  String get onb_guestPreviewHint => 'Sprawdź, co widzą Wasi goście';

  @override
  String get onb_setupWizardHint =>
      'Krok po kroku przez uzupełnianie danych wesela';

  @override
  String get onb_skipTour => 'Pomiń przewodnik';

  @override
  String get help_guestTitle => 'Pomoc dla gości';

  @override
  String get help_backToOwn => 'Wróć do swojej pomocy';

  @override
  String get help_seeGuest => 'Zobacz pomoc dla gości';

  @override
  String get help_guestPreviewNote =>
      'Oglądasz pomoc, którą widzą Wasi goście.';

  @override
  String get help_searchHint => 'Szukaj funkcji, np. „budżet\", „QR\", „RSVP\"';

  @override
  String get help_tourHint =>
      'Szukasz czegoś innego? Przewodnik pokaże Ci aplikację krok po kroku — uruchomisz go z Ustawień.';

  @override
  String help_topicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count haseł',
      few: '$count hasła',
      one: '1 hasło',
    );
    return '$_temp0';
  }

  @override
  String help_found(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znaleziono $count haseł',
      few: 'Znaleziono $count hasła',
      one: 'Znaleziono 1 hasło',
    );
    return '$_temp0';
  }

  @override
  String help_nothingFound(String query) {
    return 'Nic nie znaleziono dla „$query\".\nSpróbuj innego słowa — np. „gość\", „stół\", „płatność\".';
  }

  @override
  String get coupleType_mixed => 'Kobieta i mężczyzna';

  @override
  String get coupleType_women => 'Dwie kobiety';

  @override
  String get coupleType_men => 'Dwóch mężczyzn';

  @override
  String get coupleType_neutral => 'Niebinarne / inne';

  @override
  String get coupleType_mixedHint => 'Panna Młoda i Pan Młody';

  @override
  String get coupleType_womenHint => 'Obie osoby jako Panny Młode';

  @override
  String get coupleType_menHint => 'Obie osoby jako Panowie Młodzi';

  @override
  String get coupleType_neutralHint => 'Neutralne etykiety: Osoba 1 i Osoba 2';

  @override
  String get couple_bride => 'Panna Młoda';

  @override
  String get couple_groom => 'Pan Młody';

  @override
  String get couple_brideEmoji => '👰 Panna Młoda';

  @override
  String get couple_groomEmoji => '🤵 Pan Młody';

  @override
  String couple_personNumbered(int index) {
    return 'Osoba $index';
  }

  @override
  String couple_brideNumbered(int index) {
    return 'Panna Młoda $index';
  }

  @override
  String couple_groomNumbered(int index) {
    return 'Pan Młody $index';
  }

  @override
  String couple_withEmoji(String emoji, String name) {
    return '$emoji $name';
  }

  @override
  String get couple_fromBride => 'Od Panny Młodej';

  @override
  String get couple_fromGroom => 'Od Pana Młodego';

  @override
  String couple_fromNamed(String person) {
    return 'Od: $person';
  }

  @override
  String get couple_witnessBride => 'Świadkowa';

  @override
  String get couple_witnessGroom => 'Świadek';

  @override
  String couple_witnessNamed(String person) {
    return 'Świadek/Świadkowa ($person)';
  }

  @override
  String get couple_witnessNone => 'Brak roli';

  @override
  String couple_personShort(int index) {
    return 'osoba $index';
  }

  @override
  String get couple_categoryMixed => 'Państwo Młodzi';

  @override
  String get couple_categoryWomen => 'Panny Młode';

  @override
  String get couple_categoryMen => 'Panowie Młodzi';

  @override
  String get couple_categoryNeutral => 'Para Młoda';

  @override
  String couple_joinNames(String first, String second) {
    return '$first i $second';
  }

  @override
  String get vehicle_rented => 'Auto wynajęte';

  @override
  String get vehicle_own => 'Auto własne';

  @override
  String get vehicle_parentsBride => 'Auto rodziców Panny Młodej';

  @override
  String get vehicle_parentsGroom => 'Auto rodziców Pana Młodego';

  @override
  String vehicle_parentsNamed(String person) {
    return 'Auto rodziców ($person)';
  }

  @override
  String get vehicle_bus => 'Bus';

  @override
  String get vehicle_taxi => 'Taxi/Uber';

  @override
  String get vehicle_other => 'Inne';

  @override
  String get quiz_favouriteFilmGroom => 'Ulubiony film Pana Młodego?';

  @override
  String quiz_favouriteFilmNamed(String person) {
    return 'Ulubiony film ($person)?';
  }

  @override
  String get musicMoment_firstDance => 'Pierwszy taniec';

  @override
  String get musicMoment_entrance => 'Wejście';

  @override
  String get musicMoment_games => 'Oczepiny';

  @override
  String get musicMoment_slow => 'Wolne';

  @override
  String get musicMoment_party => 'Imprezowe';

  @override
  String get musicMoment_other => 'Inne';

  @override
  String get specialMoment_firstDance => 'Pierwszy taniec';

  @override
  String get specialMoment_firstSong => 'Pierwszy utwór';

  @override
  String get specialMoment_coupleEntrance => 'Wejście Pary Młodej';

  @override
  String get specialMoment_cake => 'Tort';

  @override
  String get specialMoment_games => 'Oczepiny';

  @override
  String get specialMoment_lastDance => 'Ostatni taniec';

  @override
  String get specialMoment_toast => 'Toast';

  @override
  String get musicStatus_proposal => 'Propozycja';

  @override
  String get musicStatus_approved => 'Zatwierdzone';

  @override
  String get musicStatus_rejected => 'Odrzucone';

  @override
  String get musicStatus_dj => 'Do decyzji DJa';

  @override
  String get adviceCat_love => 'Miłość';

  @override
  String get adviceCat_daily => 'Codzienność';

  @override
  String get adviceCat_humor => 'Humor';

  @override
  String get adviceCat_wisdom => 'Mądrość życiowa';

  @override
  String get adviceCat_other => 'Inne';

  @override
  String get beverage_alcohol => 'Alkohol';

  @override
  String get beverage_soft => 'Napoje bezalkoholowe';

  @override
  String get giftCat_guests => 'Goście';

  @override
  String get giftCat_witnesses => 'Świadkowie';

  @override
  String get giftCat_parents => 'Rodzice';

  @override
  String get giftCat_distinction => 'Wyróżnienie';

  @override
  String get taskStatus_todo => 'Do zrobienia';

  @override
  String get taskStatus_inprogress => 'W trakcie';

  @override
  String get taskStatus_done => 'Zrobione';

  @override
  String get taskStatus_cancelled => 'Anulowane';

  @override
  String get taskPriority_low => 'Niski';

  @override
  String get taskPriority_med => 'Średni';

  @override
  String get taskPriority_high => 'Wysoki';

  @override
  String get taskPerson_both => 'Oboje';

  @override
  String get push_rsvp => 'Potwierdzenia gości (RSVP)';

  @override
  String get push_tasks => 'Nowe zadania';

  @override
  String get push_schedule => 'Zmiany w harmonogramie';

  @override
  String get push_memberJoined => 'Nowa osoba w weselu';

  @override
  String get push_deadlines => 'Zbliżające się terminy';

  @override
  String get push_rsvpHint =>
      'Gdy gość potwierdzi obecność albo zmieni decyzję.';

  @override
  String get push_tasksHint => 'Gdy ktoś doda zadanie do listy.';

  @override
  String get push_scheduleHint =>
      'Gdy pojawi się nowy punkt programu albo zmieni się godzina.';

  @override
  String get push_memberJoinedHint =>
      'Gdy do wesela dołączy planer, współorganizator albo gość.';

  @override
  String get push_deadlinesHint =>
      'Przypomnienie o płatności lub zadaniu z bliskim terminem.';

  @override
  String get gs_attending => 'Przyjdzie';

  @override
  String get gs_notAttending => 'Nie przyjdzie';

  @override
  String get gs_noAnswer => 'Brak odpowiedzi';

  @override
  String get gs_ownTransport => 'Własny';

  @override
  String get gs_organisedTransport => 'Zorganizowany';

  @override
  String get gs_roomReserved => 'Zarezerwowany';

  @override
  String get gs_roomPending => 'Do zarezerwowania';

  @override
  String get gs_roomSelf => 'Sam rezerwuje';

  @override
  String get gs_roomNeeded => 'Potrzebuje';

  @override
  String get gs_table => 'Stół';

  @override
  String get pay_sala => 'Sala';

  @override
  String get pay_expenses => 'Wydatki';

  @override
  String get pay_honeymoon => 'Podróż poślubna';

  @override
  String get pay_vendor => 'Dostawca';

  @override
  String get pay_generic => 'Płatność';

  @override
  String get pay_salaComputed => 'Koszt sali (obliczony)';

  @override
  String pay_vendorInstalment(String vendor) {
    return 'Rata do dostawcy: $vendor';
  }

  @override
  String notif_guestAdded(String name) {
    return 'Dodano gościa: $name';
  }

  @override
  String notif_guestAttending(String name) {
    return '$name potwierdził(a) obecność';
  }

  @override
  String notif_guestNotAttending(String name) {
    return '$name nie przyjdzie';
  }

  @override
  String notif_guestChanged(String name) {
    return '$name — zmiana potwierdzenia';
  }

  @override
  String get notif_taskAdded => 'Dodano zadanie';

  @override
  String notif_taskAddedNamed(String name) {
    return 'Dodano zadanie: $name';
  }

  @override
  String notif_scheduleAdded(String label, String time) {
    return 'Harmonogram: $label o $time';
  }

  @override
  String get notif_guestNoName => 'Gość bez imienia';

  @override
  String get currency_pln => 'Złoty polski';

  @override
  String get currency_eur => 'Euro';

  @override
  String get currency_usd => 'Dolar amerykański';

  @override
  String get currency_gbp => 'Funt brytyjski';

  @override
  String get currency_czk => 'Korona czeska';

  @override
  String get currency_chf => 'Frank szwajcarski';

  @override
  String get children_adultAtKidsTable =>
      'Przy stole dla dzieci posadzono osobę dorosłą — jeśli to opiekun, wszystko gra.';

  @override
  String get children_kidAtNormalTable =>
      'Dziecko przy zwykłym stole — jest też stół dla dzieci.';

  @override
  String get auth_googleUnsupported =>
      'Logowanie Google nie jest obsługiwane na tej platformie.';

  @override
  String get auth_noToken => 'Brak tokenu Google. Spróbuj ponownie.';

  @override
  String get auth_googleError => 'Błąd logowania Google.';

  @override
  String get auth_generic => 'Błąd logowania. Spróbuj ponownie.';

  @override
  String get auth_network => 'Błąd sieci — sprawdź połączenie z internetem.';

  @override
  String get auth_tooMany =>
      'Zbyt wiele prób logowania. Poczekaj chwilę i spróbuj ponownie.';

  @override
  String get auth_disabled => 'To konto Google zostało wyłączone.';

  @override
  String get auth_notEnabled =>
      'Logowanie przez Google nie jest włączone. Skontaktuj się z administratorem.';

  @override
  String get auth_popupBlocked =>
      'Okno logowania zostało zablokowane przez przeglądarkę — zezwól na wyskakujące okienka i spróbuj ponownie.';

  @override
  String auth_codeError(String code) {
    return 'Błąd logowania ($code). Spróbuj ponownie.';
  }

  @override
  String get auth_emailInUse =>
      'Konto z tym adresem e-mail już istnieje. Zaloguj się lub użyj innego adresu.';

  @override
  String get auth_weakPassword =>
      'Hasło jest zbyt słabe — użyj co najmniej 6 znaków.';

  @override
  String get auth_invalidEmail => 'Nieprawidłowy adres e-mail.';

  @override
  String get auth_userNotFound => 'Nie znaleziono konta z tym adresem e-mail.';

  @override
  String get auth_wrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get auth_invalidCredential => 'Nieprawidłowy e-mail lub hasło.';

  @override
  String get guestId_noUser => 'Logowanie anonimowe nie zwróciło użytkownika.';

  @override
  String get guestId_notConfigured =>
      'Strona gości nie jest jeszcze w pełni skonfigurowana. Przeglądanie działa, ale wysyłanie wpisów może się nie udać.';

  @override
  String get guestId_offline =>
      'Brak połączenia z internetem. Sprawdź sieć i odśwież stronę.';

  @override
  String get guestId_generic =>
      'Nie udało się przygotować sesji gościa. Możesz przeglądać stronę, ale wysyłanie wpisów może nie zadziałać.';

  @override
  String guestSvc_coupleLimit(String category, int max) {
    return 'W kategorii „$category\" mogą być najwyżej $max osoby. Zmień kategorię tego gościa albo popraw istniejący wpis Pary Młodej.';
  }

  @override
  String get guestSvc_coupleNoCompanion =>
      'Para Młoda nie ma osoby towarzyszącej — obie osoby dodaj jako osobne wpisy Pary Młodej.';

  @override
  String bingo_beAt(String name) {
    return 'Bądź obecny/a na: $name';
  }

  @override
  String get dash_countdown => 'Licznik do ślubu';

  @override
  String get dash_setDate => 'Ustaw datę w Ustawieniach';

  @override
  String get dash_today => 'To dziś!';

  @override
  String dash_daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'dni do ślubu',
      one: 'dzień do ślubu',
    );
    return '$_temp0';
  }

  @override
  String dash_guestsSub(int attending, int declined, int noRsvp) {
    return '$attending potw. · $declined odmów · $noRsvp bez odp.';
  }

  @override
  String dash_tablesSub(int assigned, int free) {
    return '$assigned przypisanych · $free wolnych miejsc';
  }

  @override
  String dash_budgetSub(String paid, String left) {
    return 'Opłacono $paid · zostało $left';
  }

  @override
  String get dash_noEvents => 'brak wydarzeń';

  @override
  String get dash_nextEvent => 'najbliższe wydarzenie';

  @override
  String dash_tasksSub(int todo, int inProgress) {
    return '$todo do zrobienia · $inProgress w trakcie';
  }

  @override
  String dash_transportSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gości bez transportu',
      few: '$count gości bez transportu',
      one: '1 gość bez transportu',
      zero: 'wszyscy mają transport',
    );
    return '$_temp0';
  }

  @override
  String dash_roomsSub(int reserved) {
    return '$reserved zarezerwowanych';
  }

  @override
  String dash_giftsSub(String value, int thanked) {
    return 'łącznie $value · $thanked z podziękowaniem';
  }

  @override
  String dash_rsvpSub(int declined, int total) {
    return '$declined odmów · $total odpowiedzi';
  }

  @override
  String dash_bottles(String count) {
    return '$count butelek';
  }

  @override
  String dash_paymentsSub(int overdue, int soon) {
    return '$overdue zaległych · $soon wkrótce';
  }

  @override
  String dash_vendorsSub(int count) {
    return '$count potwierdzonych';
  }

  @override
  String get dash_gallerySub => 'zdjęć i filmów';

  @override
  String get pdf_qrHint => 'Zeskanuj telefonem, aby otworzyć stronę dla gości.';

  @override
  String get pdf_galleryTitle => 'Galeria zdjęć z wesela';

  @override
  String get pdf_galleryHintVideo =>
      'Zeskanuj telefonem, aby dodać i obejrzeć wspólne zdjęcia i filmy.';

  @override
  String get pdf_galleryHint =>
      'Zeskanuj telefonem, aby dodać i obejrzeć wspólne zdjęcia.';

  @override
  String get pdf_scheduleTitle => 'Harmonogram dnia ślubu';

  @override
  String pdf_place(String place) {
    return 'Miejsce: $place';
  }

  @override
  String get pdf_scheduleEmpty => 'Brak wydarzeń w harmonogramie.';

  @override
  String get pdf_guestbookTitle => 'Księga Gości';

  @override
  String get pdf_guestbookSub => 'Życzenia i wiadomości od gości';

  @override
  String get pdf_guestbookEmpty => 'Brak wpisów w księdze gości.';

  @override
  String get pdf_hasPhoto => '📷 (zdjęcie dostępne online)';

  @override
  String get pdf_advicesTitle => 'Rady dla Pary Młodej';

  @override
  String get pdf_advicesSub => 'Złote myśli o małżeństwie od gości';

  @override
  String get pdf_advicesEmpty => 'Brak rad.';

  @override
  String pdf_quoted(String text) {
    return '„$text\"';
  }

  @override
  String get pdf_capsuleTitle => 'Kapsuła czasu';

  @override
  String get pdf_capsuleSub => 'Otwarte wiadomości od gości';

  @override
  String get pdf_capsuleEmpty => 'Brak otwartych wiadomości.';

  @override
  String pdf_openedOn(String date) {
    return 'otwarta $date';
  }

  @override
  String get pdf_bingoTitle => 'ŚLUBNE BINGO';

  @override
  String w_addedIn(String section) {
    return 'Dodano w: $section';
  }

  @override
  String get w_hideFilters => 'Ukryj filtry';

  @override
  String get w_showFilters => 'Pokaż filtry';

  @override
  String get w_more => 'Więcej';

  @override
  String get w_notifications => 'Powiadomienia';

  @override
  String w_notificationsUnread(int count) {
    return 'Powiadomienia ($count nieprzeczytane)';
  }

  @override
  String w_unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieprzeczytanych',
      few: '$count nieprzeczytane',
      one: '1 nieprzeczytane',
    );
    return '$_temp0';
  }

  @override
  String get w_markAll => 'Oznacz wszystkie';

  @override
  String get w_noNotifications => 'Brak nowych powiadomień';

  @override
  String get w_noNotificationsBody =>
      'Damy znać, gdy pojawią się potwierdzenia gości, nowe zadania albo zmiany w harmonogramie.';

  @override
  String w_groupSummary(String label, String summary) {
    return '$label: $summary';
  }

  @override
  String get w_goToSection => 'Przejdź do sekcji';

  @override
  String get w_markRead => 'Oznacz jako przeczytane';

  @override
  String get w_justNow => 'przed chwilą';

  @override
  String w_minutesAgo(int minutes) {
    return '$minutes min temu';
  }

  @override
  String get w_guestPage => 'Strona dla gości';

  @override
  String get w_linkCopied => 'Skopiowano link';

  @override
  String get w_download => 'Pobierz / udostępnij';

  @override
  String get w_weddingToday => 'To już dziś! 🎉';

  @override
  String get w_seeYouAtWedding => 'Do zobaczenia na weselu';

  @override
  String get w_timeToWedding => 'Do wesela zostało';

  @override
  String get nav_biometricTitle => 'Czy chcesz logować się odciskiem palca?';

  @override
  String get nav_securityTitle => 'Czy chcesz zabezpieczyć aplikację?';

  @override
  String get nav_biometricBody =>
      'Przy kolejnych otwarciach odblokujesz aplikację odciskiem palca. Ustawisz też zapasowy PIN lub wzór na wypadek, gdyby czytnik nie zadziałał. Konto Google pozostaje zalogowane.';

  @override
  String get nav_securityBody =>
      'To urządzenie nie ma czytnika biometrycznego. Możesz ustawić PIN lub wzór, aby odblokowywać aplikację przy kolejnych otwarciach.';

  @override
  String get nav_notNow => 'Nie teraz';

  @override
  String get nav_enable => 'Tak, włącz';

  @override
  String get nav_logoutTitle => 'Wylogować się?';

  @override
  String get nav_logoutBody =>
      'Czy wyłączyć też zabezpieczenia (odcisk palca / PIN) na tym urządzeniu? Przydatne, gdy z aplikacji może korzystać inna osoba.';

  @override
  String get nav_logoutKeep => 'Wyloguj, zachowaj';

  @override
  String get nav_logoutClear => 'Wyloguj i wyłącz';

  @override
  String get nav_appName => 'Moje Wesele';

  @override
  String get nav_moreSections => 'Więcej sekcji';

  @override
  String get nav_configureBar => 'Konfiguruj pasek';

  @override
  String get nav_configureBottomBar => 'Konfiguruj dolny pasek';

  @override
  String get nav_configureHint =>
      'Dashboard (środek) i „Więcej\" (skrajnie prawy) są zawsze na stałych miejscach. Wybierz liczbę pozostałych ikon, dotknij ikonę zamiany (⇄), by wybrać inną sekcję, i przeciągnij za uchwyt, by zmienić kolejność — pierwsza połowa trafi na lewo od Dashboardu, reszta na prawo.';

  @override
  String get nav_icons4 => '4 ikony';

  @override
  String get nav_icons6 => '6 ikon';

  @override
  String get nav_changeSection => 'Zmień sekcję';

  @override
  String countdown_hours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'godzin',
      few: 'godziny',
      one: 'godzina',
    );
    return '$_temp0';
  }

  @override
  String countdown_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dni',
      one: 'dzień',
    );
    return '$_temp0';
  }

  @override
  String countdown_minutesDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minut',
      few: '$count minuty',
      one: '$count minuta',
    );
    return '$_temp0';
  }

  @override
  String countdown_hoursDetail(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'i $count godzin',
      few: 'i $count godziny',
      one: 'i $count godzina',
    );
    return '$_temp0';
  }

  @override
  String wheel_poolInfo(int count, String excluded) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gości',
      few: '$count gości',
      one: '1 gość',
    );
    return 'Losowanie spośród gości z listy. W puli: $_temp0 ($excluded pominięci).';
  }

  @override
  String get gp_guestPage => 'Strona dla gości';

  @override
  String get gp_activeHint => 'Goście mogą teraz grać przez stronę / kod QR.';

  @override
  String get gp_enableHint => 'Włącz, aby goście mogli odpowiadać.';

  @override
  String get gp_loadResultsError =>
      'Nie udało się wczytać wyników. Sprawdź połączenie.';

  @override
  String get gp_noResults =>
      'Brak wyników. Udostępnij gościom kod QR, aby zagrali.';

  @override
  String get gp_participants => 'Uczestników';

  @override
  String get gp_avgScore => 'Śr. wynik';

  @override
  String gp_wrongOf(int wrong, int answered) {
    return '$wrong/$answered błędnych';
  }

  @override
  String get gp_questionText => 'Wpisz treść pytania';

  @override
  String get gp_emptyCorrect => 'Zaznaczona poprawna odpowiedź jest pusta';

  @override
  String get gp_answers => 'Odpowiedzi (zaznacz poprawną)';

  @override
  String gp_answerN(int index) {
    return 'Odpowiedź $index';
  }

  @override
  String get quiz_headerTitle => '🧠 Quiz o Parze Młodej';

  @override
  String get quiz_questions => 'Pytań';

  @override
  String get quiz_questionLabel => 'Treść pytania';

  @override
  String get quiz_questionHint => 'np. Gdzie się poznaliśmy?';

  @override
  String get tf_headerTitle => '🤔 Prawda czy Fałsz o Parze Młodej';

  @override
  String get tf_true => '✓ PRAWDA';

  @override
  String get tf_false => '✗ FAŁSZ';

  @override
  String tf_deleteConfirm(String text) {
    return 'Czy na pewno usunąć „$text\"?';
  }

  @override
  String get tf_confusing => '📊 Najbardziej mylące stwierdzenia';

  @override
  String get tf_statements => 'Stwierdzeń';

  @override
  String get tf_needText => 'Wpisz treść stwierdzenia';

  @override
  String get tf_textLabel => 'Treść stwierdzenia';

  @override
  String get tf_textHint => 'np. Para Młoda poznała się w pracy';

  @override
  String get tf_falseShort => 'Fałsz';

  @override
  String get tf_explanation => 'Wyjaśnienie (opcjonalnie)';

  @override
  String get tf_explanationHint => 'np. Poznali się przez wspólnych znajomych';

  @override
  String get pg_headerTitle => '📸 Zgadnij zdjęcie';

  @override
  String get pg_photos => 'Zdjęcia';

  @override
  String get pg_enableHint => 'Włącz, aby goście mogli zgadywać.';

  @override
  String get pg_needPhoto => 'Najpierw dodaj przynajmniej jedno zdjęcie.';

  @override
  String get pg_photosCount => 'Zdjęć';

  @override
  String pg_uploadError(String error) {
    return 'Nie udało się wgrać zdjęcia: $error';
  }

  @override
  String get pg_addPhotoFirst => 'Najpierw dodaj zdjęcie';

  @override
  String get pg_editPhoto => 'Edytuj zdjęcie';

  @override
  String get pg_addPhoto => 'Dodaj zdjęcie';

  @override
  String get pg_questionHint => 'np. Kto to z dzieciństwa?';

  @override
  String get pg_photo => 'Zdjęcie';

  @override
  String get pc_headerTitle => '📷 Foto-wyzwania';

  @override
  String get pc_activeHint =>
      'Goście mogą teraz wykonywać wyzwania przez stronę / kod QR.';

  @override
  String get pc_enableHint => 'Włącz, aby goście mogli przesyłać zdjęcia.';

  @override
  String pc_deleteConfirm(String text) {
    return 'Czy na pewno usunąć „$text\"? Przesłane zdjęcia pozostaną w galerii.';
  }

  @override
  String get pc_loadPhotosError =>
      'Nie udało się wczytać zdjęć. Sprawdź połączenie.';

  @override
  String get pc_deleted => 'Usunięte wyzwanie';

  @override
  String get pc_deletePhotoTitle => 'Usunąć zdjęcie?';

  @override
  String get pc_empty => 'Brak wykonanych wyzwań. Udostępnij gościom kod QR.';

  @override
  String get pc_photos => 'Zdjęć';

  @override
  String get pc_challenges => 'Wyzwań';

  @override
  String bingo_needPool(int count) {
    return 'Potrzeba min. 24 pól w puli (jest $count).';
  }

  @override
  String get bingo_title => 'Ślubne Bingo';

  @override
  String get bingo_headerTitle => '🎯 Ślubne Bingo';

  @override
  String get bingo_guestHint =>
      'Strona z interaktywnym bingo dla gości. Pokaż im kod QR lub wyślij link, aby grali na telefonach.';

  @override
  String bingo_pool(int count) {
    return 'Pula losowania: $count pól';
  }

  @override
  String get bingo_preview => 'Losuj podgląd';

  @override
  String get bingo_previewBoard => 'Podgląd planszy';

  @override
  String get bingo_fromSchedule => 'Dołącz pola z harmonogramu';

  @override
  String get bingo_centerField => 'Środkowe pole planszy';

  @override
  String get bingo_coupleNames => 'Imiona Pary Młodej';

  @override
  String bingo_fieldsBase(int active, int total) {
    return 'Baza pól ($active / $total aktywnych)';
  }

  @override
  String get bingo_empty => 'Brak pól. Dodaj pierwsze powyżej.';

  @override
  String get bingo_newField => 'Treść pola…';

  @override
  String wheel_fields(int count) {
    return 'Pola koła ($count)';
  }

  @override
  String get wheel_removeOnPick => 'Usuń wylosowanego z puli';

  @override
  String get wheel_removeOnPickOn =>
      'Wylosowane pola nie pojawią się ponownie (w tej sesji).';

  @override
  String get wheel_removeOnPickOff => 'Wylosowane pola zostają w puli.';

  @override
  String get wheel_fullscreen => 'Tryb prezentacji (pełny ekran)';

  @override
  String get wheel_fullscreenHint => 'Duże koło do pokazania na sali.';

  @override
  String get wheel_poolEmpty =>
      'Pula jest pusta — dodaj pola lub zresetuj pulę.';

  @override
  String get wheel_poolReset => 'Pula przywrócona';

  @override
  String get wheel_noFields => 'Brak pól w puli';

  @override
  String get wheel_spinning => 'Kręcę…';

  @override
  String get wheel_pressSpin => 'Naciśnij „Zakręć!\"';

  @override
  String get wheel_spin => 'Zakręć!';

  @override
  String get wheel_reset => 'Resetuj pulę';

  @override
  String get wheel_history => '🕘 Historia losowań';

  @override
  String get wheelMode_nextDance => 'Kto tańczy następny';

  @override
  String get wheelMode_coupleTask => 'Zadanie dla Pary Młodej';

  @override
  String get wheelMode_custom => 'Własne koło';

  @override
  String get advices_loadError =>
      'Nie udało się wczytać rad. Sprawdź połączenie.';

  @override
  String advices_deleteConfirm(String name) {
    return 'Czy na pewno usunąć radę od „$name\"? Tej operacji nie można cofnąć.';
  }

  @override
  String advices_pdfTitleNamed(String event) {
    return 'Rady dla Pary Młodej — $event';
  }

  @override
  String get guestbook_headerTitle => '💝 Księga gości';

  @override
  String get guestbook_loadError =>
      'Nie udało się wczytać wpisów. Sprawdź połączenie z internetem.';

  @override
  String guestbook_wishCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'życzeń',
      few: 'życzenia',
      one: 'życzenie',
    );
    return '$_temp0';
  }

  @override
  String guestbook_pdfTitleNamed(String event) {
    return 'Księga Gości — $event';
  }

  @override
  String get capsule_headerTitle => '⏳ Kapsuła czasu';

  @override
  String get capsule_messages => 'Wiadomości';

  @override
  String get capsule_loadError =>
      'Nie udało się wczytać wiadomości. Sprawdź połączenie.';

  @override
  String get capsule_sealed => 'Zapieczętowane';

  @override
  String get capsule_nearest => 'Najbliższe';

  @override
  String get capsule_previewOn =>
      'Podgląd wszystkich włączony (treści widoczne tylko dla Ciebie).';

  @override
  String get capsule_autoOpen =>
      'Wiadomości otworzą się automatycznie w swojej dacie.';

  @override
  String get capsule_seal => 'Zapieczętuj';

  @override
  String capsule_previewUntil(String date) {
    return '🔓 Podgląd — otworzy się $date';
  }

  @override
  String get capsule_later => 'później';

  @override
  String capsule_pdfTitleNamed(String event) {
    return 'Kapsuła czasu — $event';
  }

  @override
  String get guestMap_headerTitle => '🗺️ Mapa gości';

  @override
  String get guestMap_loadError =>
      'Nie udało się wczytać mapy. Sprawdź połączenie.';

  @override
  String get guestMap_guests => 'Gości';

  @override
  String get guestMap_cities => 'Miejscowości';

  @override
  String get guestMap_noCity => 'Brak miejscowości';

  @override
  String get guestMap_savedNoGeo =>
      'Zapisano (nie udało się zlokalizować miejscowości)';

  @override
  String get guestMap_addedNoGeo =>
      'Dodano (nie udało się zlokalizować miejscowości)';

  @override
  String get guestMap_addGuest => 'Dodaj gościa';

  @override
  String hotel_deleteConfirm(String name) {
    return 'Czy na pewno usunąć „$name\"? Przypisania gości do tego hotelu zostaną wyczyszczone.';
  }

  @override
  String get hotel_deleted => 'Usunięto hotel';

  @override
  String get hotel_noGuests =>
      'Brak gości z zaznaczonym noclegiem.\nZaznacz „Nocleg\" przy gościu w sekcji Goście.';

  @override
  String get hotel_empty => 'Brak hoteli. Dodaj pierwszy poniżej.';

  @override
  String hotel_address(String address) {
    return '📍 $address';
  }

  @override
  String hotel_phone(String phone) {
    return '📞 $phone';
  }

  @override
  String hotel_perRoom(int count) {
    return '👥 $count os./pokój';
  }

  @override
  String hotel_guestCount(int count) {
    return '🛏 gości: $count';
  }

  @override
  String get hotel_nameHint => 'np. Hotel Pod Różą';

  @override
  String get hotel_needName => 'Podaj nazwę hotelu';

  @override
  String get hotel_personsPerRoom => 'Osób w pokoju';

  @override
  String get an_budgetChart => 'Budżet: planowany / orientacyjny / opłacony';

  @override
  String get an_expensesChart => 'Rozkład wydatków (kategorie)';

  @override
  String get an_paymentsChart => 'Postęp płatności w czasie';

  @override
  String get an_rsvpChart => 'Potwierdzenia gości';

  @override
  String get an_menuChart => 'Rozkład menu';

  @override
  String get an_dietChart => 'Rozkład diet';

  @override
  String get an_costPerGuest => 'Koszt / gość';

  @override
  String get an_byBudget => 'Wg budżetu';

  @override
  String get an_guests => 'Gości';

  @override
  String get an_paid => 'Opłacony';

  @override
  String get an_noExpenses => 'Brak wydatków.';

  @override
  String get an_noPayments => 'Brak danych o płatnościach z datą.';

  @override
  String get an_noGuests => 'Brak gości.';

  @override
  String get an_willAttend => 'Przyjdą';

  @override
  String get an_willNotAttend => 'Nie przyjdą';

  @override
  String get dash_emptyTiles => 'Brak kafelków. Kliknij „Edytuj\", aby dodać.';

  @override
  String get dash_afterWedding => 'Już po ślubie!';

  @override
  String get gal_photoVideo => '📸 Galeria zdjęć i filmów';

  @override
  String get gal_musicChoice => '🎵 Wybór muzyki';

  @override
  String get gal_photos => '📷 Zdjęcia';

  @override
  String get gal_combined => 'Połączony';

  @override
  String get gifts_forGuests => 'Dla gości';

  @override
  String get gifts_count => 'Prezentów';

  @override
  String get gifts_totalValue => 'Łączna wartość';

  @override
  String get gifts_favoursCount => 'Upominków';

  @override
  String get gifts_totalCost => 'Łączny koszt';

  @override
  String gifts_totalCostFor(String count) {
    return 'Łączny koszt ($count os.)';
  }

  @override
  String get gifts_recalcToReal => 'Przelicz na gości rzeczywistych';

  @override
  String get gifts_addProposal => 'Dodaj propozycję';

  @override
  String get gifts_proposalHint => 'Tytuł propozycji…';

  @override
  String get rsvpAll_qr => '📋 Potwierdzenia (RSVP)';

  @override
  String get rsvpAll_entries => 'Wpisów';

  @override
  String get rsvpAll_manual => '✍ Ręczny';

  @override
  String get rsvp_attendingShort => '✓ Przyjdzie';

  @override
  String get rsvp_qrTitle => 'Kod QR potwierdzeń';

  @override
  String rsvp_attendingCount(int count) {
    return '✓ Przyjdą ($count)';
  }

  @override
  String rsvp_notAttendingCount(int count) {
    return '✗ Nie przyjdą ($count)';
  }

  @override
  String get music_headerTitle => '🎵 Muzyka — propozycje gości';

  @override
  String get music_needTitle => 'Podaj tytuł utworu';

  @override
  String get music_exportTitle => 'Tytuł';

  @override
  String get music_exportSpecial => 'Utwór specjalny';

  @override
  String get music_exportFromGuest => 'Od gościa';

  @override
  String get music_importHelp =>
      'Wklej listę utworów. Obsługiwane formaty:\n• CSV: Tytuł;Wykonawca;Status (separator średnik)\n• Tekst: \"- Tytuł — Wykonawca\" (po jednym w linii)\nStatus rozpoznawany ze słów: „zatwierdzone\", „odrzucone\", „dj\".';

  @override
  String get tr_ownTransport => 'transport własny';

  @override
  String get tr_unassigned => 'bez przydziału';

  @override
  String get tr_vehicles => 'pojazdów';

  @override
  String tr_route(String route) {
    return '🛣 $route';
  }

  @override
  String get tr_addToOwn => 'Dodaj do transportu własnego';

  @override
  String get tr_typeHint => 'np. Pojazd Kuby, Bus wynajęty';

  @override
  String get tr_needType => 'Podaj typ/nazwę';

  @override
  String get tr_driverName => 'Imię kierowcy';

  @override
  String get tr_routeHint => 'np. Kościół → Sala';

  @override
  String tr_cost(String currency) {
    return 'Koszt ($currency)';
  }

  @override
  String get vf_editVendor => 'Edytuj dostawcę';

  @override
  String get vf_addVendor => 'Dodaj dostawcę';

  @override
  String get vf_customCategory => 'Własna kategoria';

  @override
  String get vf_needCompany => 'Podaj nazwę firmy';

  @override
  String get vf_fullName => 'Imię i nazwisko';

  @override
  String vf_price(String currency) {
    return 'Cena ($currency)';
  }

  @override
  String get vf_paymentStatus => 'Status płatności';

  @override
  String vf_contractAmount(String currency) {
    return 'Kwota umowy / szac. koszt ($currency)';
  }

  @override
  String get vf_budgetCategory => 'Kategoria budżetowa';

  @override
  String vend_linkedBody(String vendor) {
    return 'Dostawca „$vendor\" jest powiązany z wpisem w budżecie. Co zrobić z powiązanym wpisem?';
  }

  @override
  String vend_deleteConfirm(String vendor) {
    return 'Czy na pewno usunąć „$vendor\"?';
  }

  @override
  String get vend_deleteBoth => 'Usuń oba';

  @override
  String get vend_anyStatus => 'Każdy status';

  @override
  String get vend_byName => 'Wg nazwy (A–Z)';

  @override
  String get task_transport => '🚗 Transport';

  @override
  String get task_gift => '🎁 Prezent';

  @override
  String task_goToSection(String section) {
    return '→ $section';
  }

  @override
  String sched_location(String location) {
    return '📍 $location';
  }

  @override
  String get pay_expensesTab => '📋 Wydatki';

  @override
  String pay_dueDate(String date) {
    return '📅 $date';
  }

  @override
  String get lock_unlock => 'Odblokuj, aby kontynuować';

  @override
  String get lock_touchToScan => 'Dotknij, aby zeskanować odcisk palca';

  @override
  String lock_useBackup(String type) {
    return 'Użyj $type';
  }

  @override
  String get lock_drawPattern => 'Narysuj wzór odblokowania';

  @override
  String lock_wrongBackup(String type, int left) {
    return 'Błędny $type — pozostało prób: $left';
  }

  @override
  String get lock_useFingerprint => 'Użyj odcisku palca';

  @override
  String get lock_forgot => 'Nie pamiętasz? Zaloguj przez Google';

  @override
  String get setup_confirmBiometric =>
      'Potwierdź odcisk palca, aby włączyć logowanie biometryczne';

  @override
  String get setup_biometricFailed =>
      'Nie udało się potwierdzić odcisku palca. Czy ustawić samo zabezpieczenie zapasowe (PIN lub wzór)?';

  @override
  String get setup_setPin => 'Ustaw PIN/wzór';

  @override
  String get setup_repeatPin => 'Powtórz kod PIN';

  @override
  String get setup_repeatPattern => 'Powtórz wzór, aby potwierdzić';

  @override
  String get setup_pinMismatch => 'Kody PIN się różnią — spróbuj ponownie';

  @override
  String get setup_patternMismatch => 'Wzory się różnią — spróbuj ponownie';

  @override
  String get setup_pinBackupHint =>
      'PIN/wzór posłuży, gdy odcisk palca nie zadziała (np. mokry palec).';

  @override
  String get setup_unlockHint =>
      'To zabezpieczenie odblokuje aplikację przy kolejnych otwarciach.';

  @override
  String get setup_pattern => 'Wzór graficzny';

  @override
  String get setup_connectDots => 'Połącz co najmniej 4 punkty';

  @override
  String get setup_patternTooShort =>
      'Wzór jest za krótki — połącz min. 4 punkty';

  @override
  String get login_subtitle =>
      'Zaloguj się lub załóż konto, aby zarządzać swoim weselem';

  @override
  String get login_secure => '🔒 Bezpieczne logowanie';

  @override
  String get login_google => 'Zaloguj się przez Google';

  @override
  String get login_or => 'lub';

  @override
  String get login_emailButton => 'Zaloguj się e-mailem';

  @override
  String get auth_cancelled => 'Anulowano logowanie.';

  @override
  String get wsum_owner => 'Właściciel';

  @override
  String get wsum_collab => 'Współpraca';

  @override
  String get hotel_added => 'Dodano hotel';

  @override
  String get hotel_needsRoom => 'Potrzebuje noclegu';

  @override
  String get common_noName => '(bez imienia)';

  @override
  String get hotel_edit => 'Edytuj hotel';

  @override
  String get hotel_add => 'Dodaj hotel';

  @override
  String get hotel_nameRequired => 'Nazwa hotelu *';

  @override
  String get hotel_streetCity => 'Ulica, miasto';

  @override
  String get hotel_pricePerNight => 'Cena za os./noc';

  @override
  String get hotel_bookingLink => 'Link do rezerwacji';

  @override
  String get an_byEstimate => 'Wg orientacyjnego';

  @override
  String get an_estimateShort => 'Orientac.';

  @override
  String get an_noMenu => 'Bez menu';

  @override
  String get an_noMenuData => 'Brak danych o menu.';

  @override
  String get an_noDietData => 'Brak danych o dietach.';

  @override
  String get bingo_generator => 'Generator plansz';

  @override
  String get bingo_boardCount => 'Liczba plansz:';

  @override
  String get bingo_newFieldHint => 'Nowe pole bingo…';

  @override
  String get bev_bottlesPerPerson => 'butelek / os.';

  @override
  String get bev_costPerPerson => 'koszt / os.';

  @override
  String get bev_brand => 'Marka / nazwa (opcjonalnie)';

  @override
  String get bev_pieces => 'szt.';

  @override
  String get bs_plannedPlusReserve => 'Planowany + rezerwa';

  @override
  String get bs_ofWhichVenue => 'w tym sala';

  @override
  String get bs_reserveUsed => 'Wykorzystana rezerwa';

  @override
  String get ef_edit => 'Edytuj wydatek';

  @override
  String get ef_add => 'Dodaj wydatek';

  @override
  String get ef_nameHint => 'np. Atrakcje dla dzieci';

  @override
  String get ef_estimate => 'Kwota orientacyjna';

  @override
  String get vf_companyName => 'Nazwa firmy';

  @override
  String get vf_companyHint => 'np. Studio Foto';

  @override
  String get vf_contactPerson => 'Osoba kontaktowa';

  @override
  String get vf_vendorCategory => 'Kategoria dostawcy';

  @override
  String get common_email => 'E-mail';

  @override
  String get sala_cateringBase => 'Baza cateringu';

  @override
  String get sala_cateringExtras => 'Dodatki cateringu';

  @override
  String get sala_inCosts => 'W kosztach';

  @override
  String get sala_menuExtras => 'Dodatki do menu';

  @override
  String get sala_separateCatering => 'Catering (oddzielny)';

  @override
  String get sala_venueTotal => 'Razem sala';

  @override
  String get sala_staffNameHint => 'Nazwa (np. Kelnerzy)';

  @override
  String get gal_videos => '▶ Filmy';

  @override
  String get gal_pdfPrints => 'Wydruki PDF';

  @override
  String get gal_galleryQr => 'Galeria (QR)';

  @override
  String get pc_needChallenge => 'Najpierw dodaj przynajmniej jedno wyzwanie.';

  @override
  String get pc_editChallenge => 'Edytuj wyzwanie';

  @override
  String get gp_needTwoAnswers => 'Podaj przynajmniej 2 odpowiedzi';

  @override
  String get quiz_needQuestion => 'Najpierw dodaj przynajmniej jedno pytanie.';

  @override
  String get gp_noAnswers => 'brak odpowiedzi';

  @override
  String get quiz_editQuestion => 'Edytuj pytanie';

  @override
  String get tf_needStatement =>
      'Najpierw dodaj przynajmniej jedno stwierdzenie.';

  @override
  String get tf_editStatement => 'Edytuj stwierdzenie';

  @override
  String get tf_isItTrue => 'Czy to prawda?';

  @override
  String get wheel_mode => 'Tryb losowania';

  @override
  String get wheel_addField => 'Dodaj pole';

  @override
  String get wheel_addHint => 'Dodaj pola przyciskiem +.';

  @override
  String wheel_fieldN(int index) {
    return 'Pole $index';
  }

  @override
  String get wheel_drawn => '🎉 Wylosowano';

  @override
  String wheel_inPool(int count) {
    return 'W puli: $count';
  }

  @override
  String get gifts_addGift => 'Dodaj prezent';

  @override
  String get gifts_fromWho => 'Od kogo…';

  @override
  String get gifts_giftDesc => 'Opis prezentu…';

  @override
  String get gifts_recalcAll => 'Przelicz na rzeczywistych + wirtualnych';

  @override
  String get gifts_favourHint => 'Upominek…';

  @override
  String get common_descriptionHint => 'Opis…';

  @override
  String get gc_seatHint => 'np. miejsce przy rodzinie';

  @override
  String get gc_allergyHint => 'np. orzechy, gluten';

  @override
  String get gc_extraInfo => 'Dodatkowe informacje…';

  @override
  String get advices_emptyCategory => 'Brak rad w tej kategorii.';

  @override
  String get advices_autoplay => 'Auto-pokaz';

  @override
  String get guestMap_onMap => 'Na mapie';

  @override
  String get guestMap_savedEntry => 'Zapisano wpis';

  @override
  String get guestMap_addedEntry => 'Dodano wpis';

  @override
  String get guestMap_editEntry => 'Edytuj wpis';

  @override
  String get capsule_opened => '💌 Otwarta';

  @override
  String get lock_locked => 'Aplikacja zablokowana';

  @override
  String lock_welcomeBack(String name) {
    return 'Witaj ponownie, $name';
  }

  @override
  String get lock_enterPin => 'Wpisz kod PIN';

  @override
  String get setup_biometricUnconfirmed => 'Biometria niepotwierdzona';

  @override
  String get setup_chooseBackup => 'Wybierz zabezpieczenie zapasowe';

  @override
  String get setup_setPinCode => 'Ustaw kod PIN (4 cyfry)';

  @override
  String get setup_changeBackup => 'Zmiana zabezpieczenia';

  @override
  String get setup_lockConfig => 'Konfiguracja blokady';

  @override
  String get setup_pinCode => 'Kod PIN';

  @override
  String get setup_fourDigits => '4 cyfry';

  @override
  String get login_signingIn => 'Logowanie…';

  @override
  String get music_specialFilter => '⭐ Specjalne';

  @override
  String get music_genre => 'Gatunek / gust';

  @override
  String get music_specialMoment => '⭐ Moment specjalny';

  @override
  String get music_notSpecial => '— nie jest specjalny —';

  @override
  String get music_partyMoment => 'Moment imprezy';

  @override
  String get music_exportHeader => 'LISTA PIOSENEK NA WESELE';

  @override
  String get music_exportSpecialHeader =>
      '### ⭐ UTWORY SPECJALNE — KLUCZOWE MOMENTY';

  @override
  String get music_exportAllHeader =>
      '### WSZYSTKIE UTWORY (wg momentu imprezy)';

  @override
  String get room_freeSeats => 'Wolne miejsca';

  @override
  String get rsvpAll_tabEntries => 'Wpisy RSVP';

  @override
  String get rsvpAll_tabQr => 'Kody QR i linki';

  @override
  String get rsvp_notAttendingShort => '✗ Nie przyjdzie';

  @override
  String get rsvp_noStatus => 'Brak statusu';

  @override
  String get rsvp_fromForm => '🌐 Z formularza';

  @override
  String rsvp_noReplyCount(int count) {
    return 'Brak odpowiedzi ($count)';
  }

  @override
  String get sched_editEvent => 'Edytuj wydarzenie';

  @override
  String get sched_addEvent => 'Dodaj wydarzenie';

  @override
  String get common_nameRequired => 'Nazwa *';

  @override
  String get sched_placeHint => 'np. Sala weselna';

  @override
  String get common_responsible => 'Osoba odpowiedzialna';

  @override
  String get sched_responsibleHint => 'np. Oboje';

  @override
  String get sched_mapLink => 'Link do lokalizacji';

  @override
  String get sched_eventAdded => 'Dodano wydarzenie';

  @override
  String get common_noNameNeutral => '(bez nazwy)';

  @override
  String get common_seats => 'Liczba miejsc';

  @override
  String get task_edit => 'Edytuj zadanie';

  @override
  String get task_add => 'Dodaj zadanie';

  @override
  String get task_goal => 'Cel / zdarzenie (opcjonalnie)';

  @override
  String get task_goalName => 'Nazwa celu';

  @override
  String get task_goalHint => 'np. Znalezienie fotografa';

  @override
  String get task_hideExtra => 'Ukryj dodatkowe opcje';

  @override
  String get task_accommodation => '🏨 Nocleg';

  @override
  String get task_music => '🎵 Muzyka';

  @override
  String get task_allStatuses => 'Wszystkie statusy';

  @override
  String get common_noSorting => 'Bez sortowania';

  @override
  String get task_byDue => 'Wg terminu';

  @override
  String get task_byPriority => 'Wg priorytetu';

  @override
  String get common_byStatus => 'Wg statusu';

  @override
  String get tr_inVehicles => 'w pojazdach';

  @override
  String tr_assignTo(String vehicle) {
    return 'Przypisz do: $vehicle';
  }

  @override
  String get tr_boltTaxi => 'Bolt / Taxi';

  @override
  String get tr_infoCodePhone => 'Info / kod / telefon';

  @override
  String get tr_editVehicle => 'Edytuj pojazd';

  @override
  String get tr_addVehicle => 'Dodaj pojazd';

  @override
  String get tr_typeRequired => 'Typ / nazwa pojazdu *';

  @override
  String get tr_departure => 'Godzina odjazdu';

  @override
  String get vf_customCategoryHint => 'np. Animator';

  @override
  String get vf_companyRequired => 'Nazwa firmy *';

  @override
  String get vf_mapsLink => 'Link do Google Maps';

  @override
  String get vend_vendorChip => '🏢 Dostawca';

  @override
  String get vend_instalmentHint => 'np. Zadatek';

  @override
  String get layout_forcePhone => 'Wymuś telefon';

  @override
  String get layout_forceTablet => 'Wymuś tablet';

  @override
  String get layout_autoHint => 'Układ dobiera się do szerokości ekranu';

  @override
  String get layout_phoneHint => 'Zawsze dolny pasek nawigacji';

  @override
  String get layout_tabletHint => 'Zawsze boczna nawigacja i szersze siatki';

  @override
  String get common_statusHint => 'Status…';

  @override
  String get gs_companion => 'osoba towarzysząca';

  @override
  String get gs_accompanies => 'towarzyszy gościowi';

  @override
  String get notif_programmeItem => 'punkt programu';

  @override
  String taskSvc_fromTask(String name) {
    return 'Utworzono z zadania: $name';
  }

  @override
  String vendSvc_vendor(String label) {
    return 'Dostawca: $label';
  }

  @override
  String wedSvc_weddingId(String id) {
    return 'Wesele $id';
  }

  @override
  String get vendStatus_contacted => 'Skontaktowano';

  @override
  String get vendStatus_confirmed => 'Potwierdzony';

  @override
  String get vendStatus_cancelled => 'Anulowany';

  @override
  String get quizEx_q1 => 'Gdzie się poznaliśmy?';

  @override
  String get quizEx_q1a1 => 'W pracy';

  @override
  String get quizEx_q1a2 => 'Na studiach';

  @override
  String get quizEx_q1a3 => 'Przez znajomych';

  @override
  String get quizEx_q1a4 => 'W wakacje';

  @override
  String get quizEx_q3 => 'Gdzie była nasza pierwsza randka?';

  @override
  String get quizEx_q3a1 => 'W kinie';

  @override
  String get quizEx_q3a2 => 'W restauracji';

  @override
  String get quizEx_q3a3 => 'Na spacerze';

  @override
  String get quizEx_q3a4 => 'W kawiarni';

  @override
  String get quizEx_q4 => 'Kto się pierwszy oświadczył?';

  @override
  String get tfEx_1 => 'Para Młoda poznała się w pracy';

  @override
  String get tfEx_1e => 'Poznali się przez wspólnych znajomych.';

  @override
  String get tfEx_2 => 'Pierwsza randka była w kinie';

  @override
  String get tfEx_2e => 'Pierwsza randka była w kawiarni.';

  @override
  String get tfEx_3 => 'Oświadczyny odbyły się za granicą';

  @override
  String get tfEx_3e => 'Oświadczyny odbyły się podczas wspólnego wyjazdu.';

  @override
  String get pcEx_1 => 'Zrób selfie z Parą Młodą';

  @override
  String get pcEx_2 => 'Sfotografuj najpiękniejszy toast';

  @override
  String get pcEx_3 => 'Znajdź i sfotografuj najstarszego gościa';

  @override
  String get pcEx_4 => 'Zdjęcie z parkietu';

  @override
  String get pcEx_5 => 'Grupowe zdjęcie Twojego stolika';

  @override
  String get pcEx_6 => 'Uchwyć pierwszy taniec';

  @override
  String tableSvc_defaultName(int number) {
    return 'Stół $number';
  }

  @override
  String get cfg_defaultEventName => 'Ceremonia Weselna';

  @override
  String get cfg_defaultPersons => 'Patrycji i Piotra';

  @override
  String get taskSvc_song => 'Utwór';

  @override
  String get err_noActiveWedding =>
      'Brak aktywnego wesela — nie wiadomo, komu przypisać dane. Wybierz wesele i spróbuj ponownie.';

  @override
  String get err_weddingDocMissing => 'Dokument wesela nie istnieje';

  @override
  String get err_guestViewMissing =>
      'guestView/main nie powstał — sprawdź reguły';

  @override
  String get err_guestViewTokenMismatch =>
      'Token w guestView nie zgadza się z weselem';

  @override
  String get common_optionalHint => 'Opcjonalnie…';

  @override
  String get common_phoneHint => 'np. 600 100 200';

  @override
  String get common_emailHint => 'kontakt@firma.pl';

  @override
  String get qr_schedule => '📅 Harmonogram';

  @override
  String get qr_music => '🎵 Muzyka';

  @override
  String get qr_bingo => '🎲 Ślubne Bingo';

  @override
  String get qr_guestbook => '💝 Księga gości';

  @override
  String get qr_quiz => '🧠 Quiz o Parze Młodej';

  @override
  String get qr_advices => '💌 Rady dla Pary Młodej';

  @override
  String get qr_trueFalse => '🤔 Prawda czy Fałsz';

  @override
  String get qr_photoGuess => '📸 Zgadnij zdjęcie';

  @override
  String get qr_capsule => '⏳ Kapsuła czasu';

  @override
  String get qr_guestMap => '🗺️ Mapa gości';

  @override
  String get qr_photoChallenge => '📷 Foto-wyzwania';

  @override
  String get pay_venueTab => '🏠 Sala';

  @override
  String get pay_vendorsTab => '🏢 Dostawcy';

  @override
  String get hm_variantName => 'Nazwa wariantu';

  @override
  String get hm_offerLink => 'Link do oferty (https://…)';

  @override
  String get common_linkHint => 'Link (https://…)';

  @override
  String bingo_generatePdf(int count, String format) {
    return 'Generuj PDF ($count plansz, $format)';
  }

  @override
  String get common_personsShort => 'os.';

  @override
  String get notif_oneNew => '1 nowe';

  @override
  String get wheelEx_toast => 'Kto wznosi toast';

  @override
  String get wheelEx_gamesTask => 'Zadanie na oczepiny';

  @override
  String get wheelEx_veilKiss => 'Pocałunek przez welon';

  @override
  String get wheelEx_blindDance => 'Wspólny taniec z zawiązanymi oczami';

  @override
  String get wheelEx_singSong => 'Odśpiewajcie ulubioną piosenkę';

  @override
  String get wheelEx_feedCake => 'Nakarmcie się nawzajem tortem';

  @override
  String get wheelEx_longKiss => 'Pocałunek dłuższy niż 10 sekund';

  @override
  String get wheelEx_compliment => 'Powiedzcie sobie komplement';

  @override
  String get wheelEx_bouquetToss => 'Rzut bukietem';

  @override
  String get wheelEx_tieToss => 'Rzut muszką / krawatem';

  @override
  String get wheelEx_chairDance => 'Taniec z krzesłami';

  @override
  String get wheelEx_bestDance => 'Konkurs na najlepszy taniec';

  @override
  String get wheelEx_charades => 'Kalambury weselne';

  @override
  String get wheelEx_nextCouple => 'Wybór następnej pary do ślubu';

  @override
  String get quizEx_film3 => 'Forrest Gump';

  @override
  String get quizEx_film4 => 'Skazani na Shawshank';

  @override
  String get invite_pdfLead =>
      'Cieszymy się, że będziesz z nami! Poniżej znajdziesz wszystko, czego potrzebujesz, aby dołączyć do naszego wesela w aplikacji.';

  @override
  String get invite_pdfScanHint =>
      'Zeskanuj w aplikacji: „Dołącz do wesela\" → „Skanuj\"';

  @override
  String get invite_pdfStep1 =>
      'Zainstaluj aplikację Moje Wesele i zaloguj się kontem Google.';

  @override
  String get invite_pdfStep2 =>
      'Wybierz „Dołącz do wesela\" i zeskanuj kod QR albo przepisz kod ręcznie.';

  @override
  String get invite_pdfStep3 =>
      'Uzupełnij datę ślubu i nazwisko z tej karty — gotowe.';

  @override
  String get invite_printButton => 'Wydruk dla gości (PDF)';

  @override
  String get invite_printHint =>
      'Elegancka karta z kodem QR i danymi do dołączenia — do wydrukowania i włożenia do zaproszenia.';

  @override
  String get invite_printFormat => 'Format wydruku';

  @override
  String get invite_printFileName => 'zaproszenie-kod-wesela.pdf';

  @override
  String invite_printError(String error) {
    return 'Nie udało się przygotować wydruku: $error';
  }

  @override
  String get invite_codeGroupHint =>
      'Kod pokazujemy w grupach po cztery znaki — myślniki są tylko dla czytelności, gość nie musi ich wpisywać.';

  @override
  String get settings_invitesCard => 'Zaproszenia dla gości';

  @override
  String get settings_invitesHint =>
      'Wybierz, czy goście dostają jeden wspólny link, czy każde zaproszenie ma własny kod QR. Kod per zaproszenie pozwala rozpoznać, kto co dodał.';

  @override
  String get settings_invitesOpen => 'Ustaw zaproszenia';

  @override
  String get inv_title => 'Zaproszenia dla gości';

  @override
  String get inv_modeHeader => 'TRYB ZAPRASZANIA';

  @override
  String get inv_modeShared => 'Wspólny link dla wszystkich';

  @override
  String get inv_modeSharedHint =>
      'Jeden link i kod QR dla całego wesela. Goście są anonimowi — widzisz, co dodali, ale nie kto to był.';

  @override
  String get inv_modeIndividual => 'Kod dla każdego zaproszenia';

  @override
  String get inv_modeIndividualHint =>
      'Dodatkowo każda paczka zaproszeniowa dostaje własny kod QR. Gość wybiera z listy, kim jest, więc widzisz, kto co dodał.';

  @override
  String get inv_sharedStaysTitle => 'Wspólny link działa dalej';

  @override
  String get inv_sharedStaysBody =>
      'Kod indywidualny NIE zastępuje wspólnego — dokłada się do niego. Wspólny link zostaje na stołach i dla gości, którzy zgubili zaproszenie.';

  @override
  String get inv_notProofTitle => 'To rozpoznanie, nie weryfikacja tożsamości';

  @override
  String get inv_notProofBody =>
      'Kod jest wydrukowany na zaproszeniu, więc każdy, kto go zobaczy, może wybrać dowolną osobę z tej paczki. Traktuj wynik jako „prawdopodobnie Anna\", a nie dowód. Do niczego wiążącego się nie nadaje.';

  @override
  String get inv_saved => 'Zapisano tryb zaproszeń';

  @override
  String get inv_packagesHeader => 'PACZKI ZAPROSZENIOWE';

  @override
  String get inv_statPackages => 'Zaproszeń';

  @override
  String get inv_statPeople => 'Osób';

  @override
  String get inv_statMulti => 'Wieloosobowych';

  @override
  String get inv_statPending => 'Bez imienia';

  @override
  String get inv_previewHint =>
      'Tak podzielą się zaproszenia. Paczkę tworzy gość wraz ze swoimi osobami towarzyszącymi — zmienisz ją, zmieniając powiązania na liście gości.';

  @override
  String get inv_empty =>
      'Brak gości. Dodaj pierwszych gości, a zaproszenia ułożą się same.';

  @override
  String inv_packageSize(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osób',
      few: '$count osoby',
      one: '1 osoba',
    );
    return '$_temp0';
  }

  @override
  String get inv_pendingBadge => 'imię do uzupełnienia';

  @override
  String get inv_mainBadge => 'adresat';

  @override
  String get inv_noName => '(imię nieuzupełnione)';

  @override
  String get inv_codesLater =>
      'Wydruk kodów dołożymy w kolejnym kroku — na razie sprawdź, czy podział na zaproszenia i kody się zgadzają.';

  @override
  String get inv_codesHeader => 'KODY ZAPROSZEŃ';

  @override
  String get inv_generate => 'Wygeneruj brakujące kody';

  @override
  String inv_generating(int done, int total) {
    return 'Generuję kody… $done z $total';
  }

  @override
  String inv_generated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wygenerowano $count kodów',
      few: 'Wygenerowano $count kody',
      one: 'Wygenerowano 1 kod',
      zero: 'Wszystkie paczki mają już kod',
    );
    return '$_temp0';
  }

  @override
  String get inv_noCode => 'brak kodu';

  @override
  String get inv_codeRevoked => 'unieważniony';

  @override
  String get inv_codeStale => 'skład się zmienił';

  @override
  String get inv_copyCode => 'Kopiuj kod';

  @override
  String get inv_regenerate => 'Nowy kod';

  @override
  String get inv_revoke => 'Unieważnij';

  @override
  String get inv_restore => 'Przywróć';

  @override
  String inv_codeCopied(String code) {
    return 'Skopiowano kod: $code';
  }

  @override
  String get inv_regenerateTitle => 'Wystawić nowy kod?';

  @override
  String get inv_regenerateBody =>
      'Dotychczasowy kod tej paczki przestanie działać. Jeśli zaproszenie jest już wydrukowane, kod QR na nim stanie się bezużyteczny — trzeba będzie przekazać nowy.';

  @override
  String get inv_regenerated => 'Wystawiono nowy kod';

  @override
  String get inv_revokeTitle => 'Unieważnić kod?';

  @override
  String get inv_revokeBody =>
      'Gość skanujący to zaproszenie zobaczy komunikat, że kod jest nieaktualny. Możesz go później przywrócić.';

  @override
  String get inv_revoked => 'Kod unieważniony';

  @override
  String get inv_restored => 'Kod przywrócony';

  @override
  String inv_staleTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kody nieaktualne dla $count paczek',
      few: 'Kody nieaktualne dla $count paczek',
      one: 'Kod nieaktualny dla 1 paczki',
    );
    return '$_temp0';
  }

  @override
  String get inv_staleBody =>
      'Skład tych zaproszeń zmienił się po wygenerowaniu kodu. Odświeżamy go automatycznie, więc gość zobaczy aktualne imiona — ale jeśli zaproszenie jest już wydrukowane, skład na papierze się nie zgadza.';

  @override
  String inv_synced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odświeżono skład $count paczek',
      few: 'Odświeżono skład $count paczek',
      one: 'Odświeżono skład 1 paczki',
    );
    return '$_temp0';
  }

  @override
  String inv_syncFailed(int count) {
    return 'Nie udało się odświeżyć $count paczek. Sprawdź połączenie i uprawnienia.';
  }

  @override
  String get inv_rulesNeededTitle => 'Kody wymagają wdrożenia reguł';

  @override
  String get inv_rulesNeededBody =>
      'Zapis kodów zaproszeń działa dopiero po wdrożeniu reguły „inviteCodes\". Do tego czasu generowanie zakończy się błędem uprawnień.';

  @override
  String inv_error(String error) {
    return 'Nie udało się: $error';
  }

  @override
  String get id_title => 'Kim jesteś?';

  @override
  String get id_lead =>
      'Rozpoznaliśmy Twoje zaproszenie. Wybierz siebie z listy — dzięki temu Para Młoda będzie wiedziała, od kogo są Twoje wpisy.';

  @override
  String get id_leadSingle =>
      'Rozpoznaliśmy Twoje zaproszenie. Potwierdź, że to Ty.';

  @override
  String get id_companion => 'Jestem osobą towarzyszącą';

  @override
  String get id_companionHint =>
      'Zaproszenie obejmuje osobę, której imienia jeszcze nie ma';

  @override
  String get id_notMine => 'To nie moje zaproszenie';

  @override
  String get id_notMineHint =>
      'Wejdź jako gość bez przypisania — Para Młoda to uzupełni';

  @override
  String get id_yourName => 'Twoje imię';

  @override
  String get id_yourNameHint => 'Jak mamy Cię podpisywać?';

  @override
  String get id_lastNameOptional => 'Nazwisko lub pseudonim (opcjonalnie)';

  @override
  String get id_needName => 'Podaj imię, żebyśmy wiedzieli, kto to.';

  @override
  String get id_enter => 'Wejdź do strefy gości';

  @override
  String get id_privacy =>
      'Twoje imię widzi Para Młoda. Inni goście zobaczą tylko to, czym sam się podpiszesz przy wpisach.';

  @override
  String get id_notMeMenu => 'To nie ja — zmień osobę';

  @override
  String get id_invalidTitle => 'Nieprawidłowe zaproszenie';

  @override
  String get id_invalidBody =>
      'Ten kod nie należy do żadnego wesela. Sprawdź, czy link jest kompletny, albo poproś Parę Młodą o nowy.';

  @override
  String get id_revokedTitle => 'To zaproszenie jest już nieaktualne';

  @override
  String get id_revokedBody =>
      'Para Młoda unieważniła ten kod. Poproś ją o nowe zaproszenie — albo skorzystaj ze wspólnego linku do strony gości, jeśli go masz.';

  @override
  String get id_notReadyTitle => 'Strona gości nie jest jeszcze gotowa';

  @override
  String get id_notReadyBody =>
      'Zaproszenie jest prawidłowe, ale Para Młoda nie przygotowała jeszcze strony dla gości. Zajrzyj później.';

  @override
  String get id_claimFailed =>
      'Nie udało się zapisać wyboru — wchodzisz dalej, ale Para Młoda może nie powiązać Twoich wpisów z zaproszeniem.';

  @override
  String get emailAuth_titleSignIn => 'Zaloguj się';

  @override
  String get emailAuth_titleRegister => 'Załóż konto';

  @override
  String get emailAuth_titleReset => 'Resetuj hasło';

  @override
  String get emailAuth_emailLabel => 'Adres e-mail';

  @override
  String get emailAuth_emailHint => 'np. jan@przyklad.pl';

  @override
  String get emailAuth_passwordLabel => 'Hasło';

  @override
  String get emailAuth_confirmPasswordLabel => 'Powtórz hasło';

  @override
  String get emailAuth_submitSignIn => 'Zaloguj się';

  @override
  String get emailAuth_submitRegister => 'Załóż konto';

  @override
  String get emailAuth_submitReset => 'Wyślij link resetujący';

  @override
  String get emailAuth_switchToRegister => 'Nie masz konta? Załóż je';

  @override
  String get emailAuth_switchToSignIn => 'Masz już konto? Zaloguj się';

  @override
  String get emailAuth_forgotPassword => 'Zapomniałeś hasła?';

  @override
  String get emailAuth_backToSignIn => 'Wróć do logowania';

  @override
  String get emailAuth_resetIntro =>
      'Podaj adres e-mail, na który wyślemy link do zresetowania hasła.';

  @override
  String get emailAuth_resetSentMessage =>
      'Wysłaliśmy link resetujący hasło na podany adres e-mail.';

  @override
  String get emailAuth_verificationNote =>
      'Po założeniu konta wyślemy e-mail weryfikacyjny na podany adres.';

  @override
  String get emailAuth_errorEmailRequired => 'Podaj adres e-mail.';

  @override
  String get emailAuth_errorEmailInvalid => 'Podaj poprawny adres e-mail.';

  @override
  String get emailAuth_errorPasswordRequired => 'Podaj hasło.';

  @override
  String get emailAuth_errorPasswordTooShort =>
      'Hasło musi mieć co najmniej 6 znaków.';

  @override
  String get emailAuth_errorPasswordMismatch => 'Hasła nie są takie same.';

  @override
  String get emailAuth_showPassword => 'Pokaż hasło';

  @override
  String get emailAuth_hidePassword => 'Ukryj hasło';

  @override
  String get emailAuth_backButton => 'Wstecz';

  @override
  String get unassigned_title => 'Do przypisania';

  @override
  String get unassigned_hint =>
      'Poniżej goście, którzy weszli kodem paczki, ale nie udało się ich jednoznacznie dopasować do listy gości. Przypisz do istniejącej osoby, utwórz nową, albo odrzuć zgłoszenie.';

  @override
  String get unassigned_empty =>
      'Brak zgłoszeń czekających na przypisanie. Tu trafiają goście, którzy kliknęli „to nie moje zaproszenie” albo wpisali imię, którego nie było na liście oczekujących.';

  @override
  String unassigned_badge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tożsamości do przypisania',
      few: '$count tożsamości do przypisania',
      one: '1 tożsamość do przypisania',
    );
    return '$_temp0';
  }

  @override
  String unassigned_fromCode(String code) {
    return 'Z zaproszenia: $code';
  }

  @override
  String get unassigned_sourcePicked => 'wybrał(a) z listy';

  @override
  String get unassigned_sourceTyped => 'wpisał(a) inne imię';

  @override
  String get unassigned_hasRsvpYes => '✓ Potwierdził(a) obecność';

  @override
  String get unassigned_hasRsvpNo => '✗ Odwołał(a) obecność';

  @override
  String get unassigned_hasMapEntry => '📍 Wpisał(a) się na mapę gości';

  @override
  String unassigned_assignTo(String name) {
    return 'To $name';
  }

  @override
  String get unassigned_createGuest => 'Nowy gość';

  @override
  String get unassigned_reject => 'Odrzuć';

  @override
  String get unassigned_rejectTitle => 'Odrzucić zgłoszenie?';

  @override
  String get unassigned_rejectBody =>
      'Wpis zniknie z listy „Do przypisania”. Jeśli ta sama przeglądarka wejdzie ponownie tym samym kodem, może pojawić się jeszcze raz.';

  @override
  String get unassigned_assigned => 'Przypisano do gościa.';

  @override
  String get unassigned_created => 'Utworzono nowego gościa i przypisano.';

  @override
  String get unassigned_rejected => 'Odrzucono.';

  @override
  String unassigned_error(String error) {
    return 'Błąd: $error';
  }

  @override
  String get unassigned_inviterMissing =>
      'Nie znaleziono gościa głównego tej paczki.';

  @override
  String get common_and => 'i';

  @override
  String get notif_companionGroup => 'Osoba towarzysząca';

  @override
  String get notif_companionReminderGeneric =>
      'Jesteś zaproszony/a z osobą towarzyszącą. Pamiętaj o tym przy potwierdzaniu obecności.';

  @override
  String notif_companionReminder(String names) {
    return 'Jesteś zaproszony/a z osobą towarzyszącą ($names). Pamiętaj o tym przy potwierdzaniu obecności.';
  }

  @override
  String get vis_showAuthorNames => 'Pokazuj imiona autorów';

  @override
  String get inv_printHeader => 'WYDRUK ZAPROSZEŃ';

  @override
  String get inv_printRangeLabel => 'Zakres';

  @override
  String get inv_printRangeAll => 'Wszystkie';

  @override
  String inv_printRangeSelected(int count) {
    return 'Zaznaczone ($count)';
  }

  @override
  String inv_printRangeMissing(int count) {
    return 'Bez kodu ($count)';
  }

  @override
  String get inv_printFormatLabel => 'Format';

  @override
  String get inv_printPerPageLabel => 'Kart na arkuszu';

  @override
  String get inv_printPerPageOne => 'cała strona';

  @override
  String get inv_printPerPageTwo => '2 na arkuszu';

  @override
  String get inv_printPerPageFour => '4 na arkuszu';

  @override
  String get inv_printGenerate => 'Generuj PDF';

  @override
  String get inv_printNothingSelected =>
      'Nie wybrano żadnej paczki do wydruku.';

  @override
  String get inv_printNoCodes =>
      'Żadna z wybranych paczek nie ma jeszcze kodu — najpierw go wygeneruj.';

  @override
  String inv_printSkipped(int count) {
    return 'Pominięto $count paczek bez kodu — wygeneruj im kody i wydrukuj ponownie.';
  }

  @override
  String get inv_printFileName => 'zaproszenia-indywidualne';

  @override
  String pdf_individualFor(String names) {
    return 'Zaproszenie dla: $names';
  }

  @override
  String get pdf_individualScanHint =>
      'Zeskanuj kod QR telefonem, żeby wejść do swojej strefy gościa';
}
