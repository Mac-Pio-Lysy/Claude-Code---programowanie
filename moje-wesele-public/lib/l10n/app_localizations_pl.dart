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
  String get common_yes => 'Tak';

  @override
  String get common_no => 'Nie';

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
  String get common_deleteConfirmTitle => 'Na pewno usunąć?';

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
  String get common_loading => 'Wczytywanie…';

  @override
  String get common_copy => 'Kopiuj';

  @override
  String get common_share => 'Udostępnij';

  @override
  String get common_open => 'Otwórz';

  @override
  String get common_select => 'Wybierz';

  @override
  String get common_all => 'Wszyscy';

  @override
  String get common_optional => 'opcjonalnie';

  @override
  String get common_deleteConfirmBody => 'Tej operacji nie da się cofnąć.';

  @override
  String get common_deletedToast => 'Usunięto';

  @override
  String common_deleteErrorToast(String error) {
    return 'Błąd usuwania: $error';
  }

  @override
  String get common_copiedToast => 'Skopiowano';

  @override
  String get common_offlineToast =>
      'Brak połączenia — zmiany zapiszą się po odzyskaniu sieci.';

  @override
  String get validation_required => 'To pole jest wymagane';

  @override
  String get validation_invalidNumber => 'Podaj poprawną liczbę';

  @override
  String get validation_invalidEmail => 'Podaj poprawny adres e-mail';

  @override
  String validation_tooShort(int min) {
    return 'Za krótkie — minimum $min znaki';
  }

  @override
  String get date_notSet => 'Data do ustalenia';

  @override
  String get date_pickDate => 'Wybierz datę';

  @override
  String get date_pickTime => 'Wybierz godzinę';

  @override
  String get date_today => 'Dzisiaj';

  @override
  String get date_tomorrow => 'Jutro';

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
  String get guests_allSeated => 'Wszyscy goście są już przypisani.';

  @override
  String get tables_defaultName => 'Stół';

  @override
  String get tables_title => 'Plan stołów';

  @override
  String get tables_addButton => 'Dodaj stół';

  @override
  String get tables_addedToast => 'Dodano stół';

  @override
  String get tables_addTitle => 'Nowy stół';

  @override
  String get tables_name => 'Nazwa stołu';

  @override
  String get tables_nameHint => 'np. Stół 1';

  @override
  String get tables_shape => 'Kształt';

  @override
  String get tables_shapeRound => 'Okrągły';

  @override
  String get tables_shapeRect => 'Prostokątny';

  @override
  String get tables_seats => 'Liczba miejsc';

  @override
  String get tables_honorSwitch => '⭐ Stół Pary Młodej (honorowy)';

  @override
  String get tables_honorHint => 'Używa układu prostokątnego';

  @override
  String get tables_childSwitch => '🧒 Stół dla dzieci';

  @override
  String get tables_childHint => 'Osobny stół dla najmłodszych gości';

  @override
  String get tables_deleteTitle => 'Usunąć stół?';

  @override
  String get tables_deleteBody =>
      'Goście przypisani do tego stołu wrócą na listę nieprzypisanych.';

  @override
  String get tables_deletedToast => 'Usunięto stół';

  @override
  String get tables_full => 'Stół jest pełny!';

  @override
  String tables_seatsUsed(int used, int total) {
    return '$used/$total miejsc';
  }

  @override
  String get tables_assignGuest => 'Posadź gościa';

  @override
  String get tables_unassign => 'Zwolnij miejsce';

  @override
  String get tables_emptyState => 'Nie masz jeszcze stołów. Dodaj pierwszy.';

  @override
  String get tables_statTables => 'Stoły';

  @override
  String get tables_statSeats => 'Miejsca';

  @override
  String get tables_statFree => 'Wolne';

  @override
  String get tables_hintAdultAtChildTable =>
      'Przy stole dla dzieci posadzono osobę dorosłą — jeśli to opiekun, wszystko gra.';

  @override
  String get tables_hintChildAtRegularTable =>
      'Dziecko przy zwykłym stole — jest też stół dla dzieci.';

  @override
  String get roomplan_title => 'Plan sali';

  @override
  String get roomplan_editMode => 'Tryb edycji';

  @override
  String get roomplan_gridOn => 'Siatka';

  @override
  String get roomplan_fullscreen => 'Pełny ekran';

  @override
  String get roomplan_addTable => 'Dodaj stół';

  @override
  String get roomplan_addElement => 'Dodaj element';

  @override
  String get roomplan_unassignedGuests => 'Nieprzypisani goście';

  @override
  String get roomplan_roomSize => 'Wymiary sali';

  @override
  String get roomplan_widthMeters => 'Szerokość (m)';

  @override
  String get roomplan_lengthMeters => 'Długość (m)';

  @override
  String get roomplan_savedToast => 'Zapisano plan sali';

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
  String tables_seatsShort(int used, int total) {
    return '$used/$total';
  }

  @override
  String get tables_guestPickerTitle => 'Wybierz gościa';

  @override
  String get tables_tapSeatToAssign => 'Dotknij miejsca, aby posadzić gościa';

  @override
  String get tables_honorBadge => '⭐ Honorowy';

  @override
  String get tables_childBadge => '🧒 Dla dzieci';

  @override
  String get tables_seatFree => 'Wolne';

  @override
  String get tables_addFirst => 'Dodaj pierwszy stół';

  @override
  String tables_summary(int tables) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables stołów',
      few: '$tables stoły',
      one: '1 stół',
    );
    return '$_temp0';
  }

  @override
  String tables_seatsSummary(int seats) {
    String _temp0 = intl.Intl.pluralLogic(
      seats,
      locale: localeName,
      other: '$seats miejsc',
      few: '$seats miejsca',
      one: '1 miejsce',
    );
    return '$_temp0';
  }

  @override
  String get roomplan_elementTable => 'Stół';

  @override
  String get roomplan_elementStage => 'Scena';

  @override
  String get roomplan_elementBar => 'Bar';

  @override
  String get roomplan_elementDanceFloor => 'Parkiet';

  @override
  String get roomplan_elementEntrance => 'Wejście';

  @override
  String get roomplan_elementOther => 'Inne';

  @override
  String get roomplan_deleteElement => 'Usunąć element?';

  @override
  String get roomplan_elementName => 'Nazwa elementu';

  @override
  String get roomplan_staff => 'Obsługa';

  @override
  String get roomplan_persons => 'Liczba osób';

  @override
  String get roomplan_includeInCost => 'Wliczaj do kosztów';

  @override
  String get roomplan_dragHint => 'Przytrzymaj i przeciągnij, aby przesunąć';

  @override
  String get roomplan_exitFullscreen => 'Zamknij pełny ekran';

  @override
  String get tables_nameHintOptional => 'np. Stół 1 (opcjonalnie)';

  @override
  String get tables_shapeRoundIcon => '⚪ Okrągły';

  @override
  String get tables_shapeRectIcon => '▭ Prostokątny';

  @override
  String tables_deleteBodyNamed(String name) {
    return 'Czy na pewno usunąć stół „$name”? Przypisani goście wrócą do nieprzypisanych.';
  }

  @override
  String get tables_removeFromTable => 'Usuń ze stołu';

  @override
  String tables_unassignedHeader(int count) {
    return 'Nieprzypisani goście ($count)';
  }

  @override
  String get tables_dragHint =>
      'Przeciągnij (przytrzymaj) gościa na stół lub użyj „Przypisz”.';

  @override
  String get tables_allSeatedCheer => '🎉 Wszyscy goście mają miejsce!';

  @override
  String get tables_assignGuestAction => 'Przypisz gościa';

  @override
  String get tables_deleteTable => 'Usuń stół';

  @override
  String get tables_emptyStateHint =>
      'Brak stołów. Dodaj pierwszy stół przyciskiem powyżej.';

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
  String get roomplan_elementSize => 'Rozmiar elementu';
}
