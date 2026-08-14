import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// Przycisk dodawania nowego elementu (gość, zadanie, wydatek).
  ///
  /// In pl, this message translates to:
  /// **'Dodaj'**
  String get common_add;

  /// Przycisk zamykający formularz bez zapisu.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get common_cancel;

  /// Przycisk zapisujący formularz.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get common_save;

  /// Przycisk usuwania — zwykle po potwierdzeniu.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get common_delete;

  /// Przycisk przechodzący w tryb edycji.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj'**
  String get common_edit;

  /// No description provided for @common_close.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij'**
  String get common_close;

  /// No description provided for @common_back.
  ///
  /// In pl, this message translates to:
  /// **'Wstecz'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe'**
  String get common_done;

  /// No description provided for @common_yes.
  ///
  /// In pl, this message translates to:
  /// **'Tak'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In pl, this message translates to:
  /// **'Nie'**
  String get common_no;

  /// No description provided for @common_search.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj'**
  String get common_search;

  /// Wartość pusta w tabelach i na kartach (myślnik).
  ///
  /// In pl, this message translates to:
  /// **'—'**
  String get common_none;

  /// Komunikat po udanym zapisie.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano zmiany'**
  String get common_savedToast;

  /// Komunikat błędu zapisu; {error} to treść wyjątku.
  ///
  /// In pl, this message translates to:
  /// **'Błąd zapisu: {error}'**
  String common_saveErrorToast(String error);

  /// No description provided for @common_deleteConfirmTitle.
  ///
  /// In pl, this message translates to:
  /// **'Na pewno usunąć?'**
  String get common_deleteConfirmTitle;

  /// Licznik gości z polską odmianą. ICU plural obsługuje formy 1 / 2-4 / 5+ w każdym języku, bez ręcznych funkcji odmiany.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =0{Brak gości} =1{1 gość} few{{count} gości} other{{count} gości}}'**
  String common_guestCount(int count);

  /// No description provided for @settings_title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get settings_title;

  /// No description provided for @settings_configCard.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja'**
  String get settings_configCard;

  /// Nagłówek karty z wyborem języka i waluty.
  ///
  /// In pl, this message translates to:
  /// **'Język i region'**
  String get settings_languageCard;

  /// No description provided for @settings_language.
  ///
  /// In pl, this message translates to:
  /// **'Język aplikacji'**
  String get settings_language;

  /// No description provided for @settings_languageHint.
  ///
  /// In pl, this message translates to:
  /// **'Zmiana działa od razu, bez restartu aplikacji.'**
  String get settings_languageHint;

  /// Opcja wyboru języka: użyj ustawień urządzenia.
  ///
  /// In pl, this message translates to:
  /// **'Jak w systemie'**
  String get settings_languageSystem;

  /// No description provided for @settings_currency.
  ///
  /// In pl, this message translates to:
  /// **'Waluta'**
  String get settings_currency;

  /// Kluczowe zastrzeżenie: waluta to etykieta, nie przelicznik.
  ///
  /// In pl, this message translates to:
  /// **'Zmienia tylko symbol przy kwotach. Nie przelicza kursów — wpisane kwoty zostają takie same.'**
  String get settings_currencyHint;

  /// No description provided for @settings_notificationsCard.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia'**
  String get settings_notificationsCard;

  /// No description provided for @settings_helpButton.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc'**
  String get settings_helpButton;

  /// No description provided for @settings_tourButton.
  ///
  /// In pl, this message translates to:
  /// **'Uruchom przewodnik'**
  String get settings_tourButton;

  /// No description provided for @settings_planningButton.
  ///
  /// In pl, this message translates to:
  /// **'Od czego zacząć?'**
  String get settings_planningButton;

  /// No description provided for @settings_setupWizardButton.
  ///
  /// In pl, this message translates to:
  /// **'Poprowadź mnie za rękę'**
  String get settings_setupWizardButton;

  /// No description provided for @settings_logoutButton.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj się'**
  String get settings_logoutButton;

  /// No description provided for @language_pl.
  ///
  /// In pl, this message translates to:
  /// **'Polski'**
  String get language_pl;

  /// Nazwa języka pokazywana na liście wyboru — w języku interfejsu.
  ///
  /// In pl, this message translates to:
  /// **'Angielski'**
  String get language_en;

  /// No description provided for @common_confirm.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź'**
  String get common_confirm;

  /// No description provided for @common_retry.
  ///
  /// In pl, this message translates to:
  /// **'Spróbuj ponownie'**
  String get common_retry;

  /// No description provided for @common_loading.
  ///
  /// In pl, this message translates to:
  /// **'Wczytywanie…'**
  String get common_loading;

  /// No description provided for @common_copy.
  ///
  /// In pl, this message translates to:
  /// **'Kopiuj'**
  String get common_copy;

  /// No description provided for @common_share.
  ///
  /// In pl, this message translates to:
  /// **'Udostępnij'**
  String get common_share;

  /// No description provided for @common_open.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz'**
  String get common_open;

  /// No description provided for @common_select.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz'**
  String get common_select;

  /// No description provided for @common_all.
  ///
  /// In pl, this message translates to:
  /// **'Wszyscy'**
  String get common_all;

  /// Dopisek przy etykiecie pola nieobowiązkowego.
  ///
  /// In pl, this message translates to:
  /// **'opcjonalnie'**
  String get common_optional;

  /// No description provided for @common_deleteConfirmBody.
  ///
  /// In pl, this message translates to:
  /// **'Tej operacji nie da się cofnąć.'**
  String get common_deleteConfirmBody;

  /// No description provided for @common_deletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto'**
  String get common_deletedToast;

  /// Komunikat błędu usuwania.
  ///
  /// In pl, this message translates to:
  /// **'Błąd usuwania: {error}'**
  String common_deleteErrorToast(String error);

  /// No description provided for @common_copiedToast.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano'**
  String get common_copiedToast;

  /// No description provided for @common_offlineToast.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia — zmiany zapiszą się po odzyskaniu sieci.'**
  String get common_offlineToast;

  /// No description provided for @validation_required.
  ///
  /// In pl, this message translates to:
  /// **'To pole jest wymagane'**
  String get validation_required;

  /// No description provided for @validation_invalidNumber.
  ///
  /// In pl, this message translates to:
  /// **'Podaj poprawną liczbę'**
  String get validation_invalidNumber;

  /// No description provided for @validation_invalidEmail.
  ///
  /// In pl, this message translates to:
  /// **'Podaj poprawny adres e-mail'**
  String get validation_invalidEmail;

  /// Walidacja długości; {min} to minimalna liczba znaków.
  ///
  /// In pl, this message translates to:
  /// **'Za krótkie — minimum {min} znaki'**
  String validation_tooShort(int min);

  /// No description provided for @date_notSet.
  ///
  /// In pl, this message translates to:
  /// **'Data do ustalenia'**
  String get date_notSet;

  /// No description provided for @date_pickDate.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz datę'**
  String get date_pickDate;

  /// No description provided for @date_pickTime.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz godzinę'**
  String get date_pickTime;

  /// No description provided for @date_today.
  ///
  /// In pl, this message translates to:
  /// **'Dzisiaj'**
  String get date_today;

  /// No description provided for @date_tomorrow.
  ///
  /// In pl, this message translates to:
  /// **'Jutro'**
  String get date_tomorrow;

  /// No description provided for @guests_categoryWitnesses.
  ///
  /// In pl, this message translates to:
  /// **'Świadkowie'**
  String get guests_categoryWitnesses;

  /// No description provided for @guests_categoryParents.
  ///
  /// In pl, this message translates to:
  /// **'Rodzice'**
  String get guests_categoryParents;

  /// ETYKIETA kategorii. Wartosc w bazie zostaje polska - patrz GuestOptions.categoryLabel.
  ///
  /// In pl, this message translates to:
  /// **'Rodzina'**
  String get guests_categoryFamily;

  /// No description provided for @guests_categoryFriends.
  ///
  /// In pl, this message translates to:
  /// **'Znajomi'**
  String get guests_categoryFriends;

  /// No description provided for @guests_categoryWork.
  ///
  /// In pl, this message translates to:
  /// **'Praca'**
  String get guests_categoryWork;

  /// No description provided for @guests_categoryOther.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get guests_categoryOther;

  /// No description provided for @guests_genderFemale.
  ///
  /// In pl, this message translates to:
  /// **'♀ Kobieta'**
  String get guests_genderFemale;

  /// No description provided for @guests_genderMale.
  ///
  /// In pl, this message translates to:
  /// **'♂ Mężczyzna'**
  String get guests_genderMale;

  /// No description provided for @guests_genderNonbinary.
  ///
  /// In pl, this message translates to:
  /// **'⚧ Niebinarna'**
  String get guests_genderNonbinary;

  /// No description provided for @guests_dietStandard.
  ///
  /// In pl, this message translates to:
  /// **'Standardowa'**
  String get guests_dietStandard;

  /// No description provided for @guests_dietVegetarian.
  ///
  /// In pl, this message translates to:
  /// **'Wegetariańska'**
  String get guests_dietVegetarian;

  /// No description provided for @guests_dietVegan.
  ///
  /// In pl, this message translates to:
  /// **'Wegańska'**
  String get guests_dietVegan;

  /// No description provided for @guests_dietGlutenFree.
  ///
  /// In pl, this message translates to:
  /// **'Bezglutenowa'**
  String get guests_dietGlutenFree;

  /// No description provided for @guests_dietOther.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get guests_dietOther;

  /// No description provided for @guests_menuMeat.
  ///
  /// In pl, this message translates to:
  /// **'Danie mięsne'**
  String get guests_menuMeat;

  /// No description provided for @guests_menuFish.
  ///
  /// In pl, this message translates to:
  /// **'Danie rybne'**
  String get guests_menuFish;

  /// No description provided for @guests_menuVegetarian.
  ///
  /// In pl, this message translates to:
  /// **'Wegetariańskie'**
  String get guests_menuVegetarian;

  /// No description provided for @guests_menuVegan.
  ///
  /// In pl, this message translates to:
  /// **'Wegańskie'**
  String get guests_menuVegan;

  /// No description provided for @guests_menuChild.
  ///
  /// In pl, this message translates to:
  /// **'Dla dziecka'**
  String get guests_menuChild;

  /// No description provided for @guests_filterAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Przypisani'**
  String get guests_filterAssigned;

  /// No description provided for @guests_filterUnassigned.
  ///
  /// In pl, this message translates to:
  /// **'Nieprzypisani'**
  String get guests_filterUnassigned;

  /// No description provided for @guests_filterWitnesses.
  ///
  /// In pl, this message translates to:
  /// **'🤝 Świadkowie'**
  String get guests_filterWitnesses;

  /// No description provided for @guests_filterChildren.
  ///
  /// In pl, this message translates to:
  /// **'🧒 Dzieci'**
  String get guests_filterChildren;

  /// No description provided for @guests_title.
  ///
  /// In pl, this message translates to:
  /// **'Goście'**
  String get guests_title;

  /// No description provided for @guests_addButton.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj gościa'**
  String get guests_addButton;

  /// No description provided for @guests_addedToast.
  ///
  /// In pl, this message translates to:
  /// **'Dodano gościa: {name}'**
  String guests_addedToast(String name);

  /// No description provided for @guests_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć gościa?'**
  String get guests_deleteTitle;

  /// No description provided for @guests_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć gościa „{name}”? Zostanie też zwolnione jego miejsce przy stole.'**
  String guests_deleteBody(String name);

  /// No description provided for @guests_deletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto gościa'**
  String get guests_deletedToast;

  /// No description provided for @guests_noName.
  ///
  /// In pl, this message translates to:
  /// **'(bez imienia)'**
  String get guests_noName;

  /// No description provided for @guests_countOf.
  ///
  /// In pl, this message translates to:
  /// **'{shown} z {total}'**
  String guests_countOf(int shown, int total);

  /// No description provided for @guests_badgeNoTable.
  ///
  /// In pl, this message translates to:
  /// **'Bez stołu'**
  String get guests_badgeNoTable;

  /// No description provided for @guests_badgeChild.
  ///
  /// In pl, this message translates to:
  /// **'🧒 Dziecko'**
  String get guests_badgeChild;

  /// No description provided for @guests_badgeAccommodation.
  ///
  /// In pl, this message translates to:
  /// **'🏨 Nocleg'**
  String get guests_badgeAccommodation;

  /// No description provided for @guests_badgeCompanionOf.
  ///
  /// In pl, this message translates to:
  /// **'👥 z: {name}'**
  String guests_badgeCompanionOf(String name);

  /// No description provided for @guests_companionPlaceholder.
  ///
  /// In pl, this message translates to:
  /// **'osoba towarzysząca'**
  String get guests_companionPlaceholder;

  /// No description provided for @guests_formEditTitle.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj gościa'**
  String get guests_formEditTitle;

  /// No description provided for @guests_formAddTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj gościa'**
  String get guests_formAddTitle;

  /// No description provided for @guests_formFirstName.
  ///
  /// In pl, this message translates to:
  /// **'Imię *'**
  String get guests_formFirstName;

  /// No description provided for @guests_formFirstNameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Anna'**
  String get guests_formFirstNameHint;

  /// No description provided for @guests_formFirstNameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Podaj imię gościa'**
  String get guests_formFirstNameRequired;

  /// No description provided for @guests_formLastName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko'**
  String get guests_formLastName;

  /// No description provided for @guests_formLastNameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Kowalska'**
  String get guests_formLastNameHint;

  /// No description provided for @guests_formInvitedBy.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszony przez'**
  String get guests_formInvitedBy;

  /// No description provided for @guests_formChoose.
  ///
  /// In pl, this message translates to:
  /// **'— wybierz —'**
  String get guests_formChoose;

  /// No description provided for @guests_formCategory.
  ///
  /// In pl, this message translates to:
  /// **'Kategoria'**
  String get guests_formCategory;

  /// No description provided for @guests_formGender.
  ///
  /// In pl, this message translates to:
  /// **'Płeć'**
  String get guests_formGender;

  /// No description provided for @guests_formRole.
  ///
  /// In pl, this message translates to:
  /// **'Rola'**
  String get guests_formRole;

  /// No description provided for @guests_formNoRole.
  ///
  /// In pl, this message translates to:
  /// **'Brak roli'**
  String get guests_formNoRole;

  /// No description provided for @guests_formDiet.
  ///
  /// In pl, this message translates to:
  /// **'Dieta / menu'**
  String get guests_formDiet;

  /// No description provided for @guests_formNoMenu.
  ///
  /// In pl, this message translates to:
  /// **'— brak —'**
  String get guests_formNoMenu;

  /// No description provided for @guests_formIsChild.
  ///
  /// In pl, this message translates to:
  /// **'🧒 To dziecko'**
  String get guests_formIsChild;

  /// No description provided for @guests_formIsChildHint.
  ///
  /// In pl, this message translates to:
  /// **'Dzieci są wyłączane z przeliczeń alkoholu i mogą mieć osobne menu.'**
  String get guests_formIsChildHint;

  /// No description provided for @guests_formAccommodation.
  ///
  /// In pl, this message translates to:
  /// **'🏨 Potrzebuje noclegu'**
  String get guests_formAccommodation;

  /// No description provided for @guests_formCoupleLimit.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda to najwyżej {max} osoby — komplet już jest na liście.'**
  String guests_formCoupleLimit(int max);

  /// No description provided for @guests_companionSwitch.
  ///
  /// In pl, this message translates to:
  /// **'👥 Z osobą towarzyszącą?'**
  String get guests_companionSwitch;

  /// No description provided for @guests_companionForCouple.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda nie ma osoby towarzyszącej — drugą osobę dodaj jako osobny wpis w kategorii „{category}”.'**
  String guests_companionForCouple(String category);

  /// No description provided for @guests_companionRelation.
  ///
  /// In pl, this message translates to:
  /// **'Typ relacji'**
  String get guests_companionRelation;

  /// No description provided for @guests_companionNameUnknown.
  ///
  /// In pl, this message translates to:
  /// **'Imienia jeszcze nie znam'**
  String get guests_companionNameUnknown;

  /// No description provided for @guests_companionNameUnknownHint.
  ///
  /// In pl, this message translates to:
  /// **'Zapiszemy „Osoba towarzysząca” — dane uzupełnisz później. Osoba i tak liczy się do listy gości i do cateringu.'**
  String get guests_companionNameUnknownHint;

  /// No description provided for @guests_companionFirstName.
  ///
  /// In pl, this message translates to:
  /// **'Imię os. towarzyszącej'**
  String get guests_companionFirstName;

  /// No description provided for @guests_companionLastName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko os. towarzyszącej'**
  String get guests_companionLastName;

  /// No description provided for @guests_companionCategory.
  ///
  /// In pl, this message translates to:
  /// **'Kategoria os. towarzyszącej'**
  String get guests_companionCategory;

  /// No description provided for @guests_companionInherit.
  ///
  /// In pl, this message translates to:
  /// **'Jak zapraszający ({category})'**
  String guests_companionInherit(String category);

  /// No description provided for @guests_companionIsChild.
  ///
  /// In pl, this message translates to:
  /// **'🧒 Osoba towarzysząca to dziecko'**
  String get guests_companionIsChild;

  /// No description provided for @guests_companionInfo.
  ///
  /// In pl, this message translates to:
  /// **'Osoba towarzysząca zostanie dodana jako osobny gość powiązany z tą osobą — dzięki temu wiadomo, kto z kim przychodzi.'**
  String get guests_companionInfo;

  /// No description provided for @guests_relationPartner.
  ///
  /// In pl, this message translates to:
  /// **'Para'**
  String get guests_relationPartner;

  /// No description provided for @guests_relationFamily.
  ///
  /// In pl, this message translates to:
  /// **'Rodzina'**
  String get guests_relationFamily;

  /// No description provided for @guests_relationUnknown.
  ///
  /// In pl, this message translates to:
  /// **'Nieznana'**
  String get guests_relationUnknown;

  /// No description provided for @guests_summaryWitnesses.
  ///
  /// In pl, this message translates to:
  /// **'🤝 Świadkowie (cel: {target})'**
  String guests_summaryWitnesses(int target);

  /// No description provided for @guests_summaryWitnessesTotal.
  ///
  /// In pl, this message translates to:
  /// **'Wyznaczeni łącznie'**
  String get guests_summaryWitnessesTotal;

  /// No description provided for @guests_summaryChildren.
  ///
  /// In pl, this message translates to:
  /// **'🧒 Dzieci'**
  String get guests_summaryChildren;

  /// No description provided for @guests_summaryChildrenLabel.
  ///
  /// In pl, this message translates to:
  /// **'Dzieci'**
  String get guests_summaryChildrenLabel;

  /// No description provided for @guests_summaryAdults.
  ///
  /// In pl, this message translates to:
  /// **'Dorośli'**
  String get guests_summaryAdults;

  /// No description provided for @guests_summaryMenu.
  ///
  /// In pl, this message translates to:
  /// **'🍽 Menu (co je)'**
  String get guests_summaryMenu;

  /// No description provided for @guests_summaryNoMenu.
  ///
  /// In pl, this message translates to:
  /// **'Bez wyboru menu'**
  String get guests_summaryNoMenu;

  /// No description provided for @guests_summaryDiets.
  ///
  /// In pl, this message translates to:
  /// **'🥗 Diety'**
  String get guests_summaryDiets;

  /// No description provided for @guests_summaryTransport.
  ///
  /// In pl, this message translates to:
  /// **'🚌 Transport'**
  String get guests_summaryTransport;

  /// No description provided for @guests_summaryTransportOwn.
  ///
  /// In pl, this message translates to:
  /// **'Własny'**
  String get guests_summaryTransportOwn;

  /// No description provided for @guests_summaryTransportOrganized.
  ///
  /// In pl, this message translates to:
  /// **'Zorganizowany'**
  String get guests_summaryTransportOrganized;

  /// No description provided for @guests_summaryTransportNone.
  ///
  /// In pl, this message translates to:
  /// **'Bez transportu'**
  String get guests_summaryTransportNone;

  /// No description provided for @guests_summaryAccommodation.
  ///
  /// In pl, this message translates to:
  /// **'🏨 Nocleg'**
  String get guests_summaryAccommodation;

  /// No description provided for @guests_summaryAccommodationNeeds.
  ///
  /// In pl, this message translates to:
  /// **'Potrzebuje'**
  String get guests_summaryAccommodationNeeds;

  /// No description provided for @guests_summaryAccommodationAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Przypisani do hotelu'**
  String get guests_summaryAccommodationAssigned;

  /// No description provided for @guests_summaryRsvp.
  ///
  /// In pl, this message translates to:
  /// **'✉ Potwierdzenia'**
  String get guests_summaryRsvp;

  /// No description provided for @guests_rsvpAttending.
  ///
  /// In pl, this message translates to:
  /// **'Przyjdzie'**
  String get guests_rsvpAttending;

  /// No description provided for @guests_rsvpNotAttending.
  ///
  /// In pl, this message translates to:
  /// **'Nie przyjdzie'**
  String get guests_rsvpNotAttending;

  /// No description provided for @guests_rsvpNoAnswer.
  ///
  /// In pl, this message translates to:
  /// **'Brak odpowiedzi'**
  String get guests_rsvpNoAnswer;

  /// No description provided for @guests_cardFullName.
  ///
  /// In pl, this message translates to:
  /// **'Imię i nazwisko'**
  String get guests_cardFullName;

  /// No description provided for @guests_cardStatus.
  ///
  /// In pl, this message translates to:
  /// **'Status'**
  String get guests_cardStatus;

  /// No description provided for @guests_cardWith.
  ///
  /// In pl, this message translates to:
  /// **'Z kim'**
  String get guests_cardWith;

  /// No description provided for @guests_cardMenu.
  ///
  /// In pl, this message translates to:
  /// **'Menu'**
  String get guests_cardMenu;

  /// No description provided for @guests_cardDietAllergies.
  ///
  /// In pl, this message translates to:
  /// **'Dieta / alergie'**
  String get guests_cardDietAllergies;

  /// No description provided for @guests_cardTable.
  ///
  /// In pl, this message translates to:
  /// **'Stolik'**
  String get guests_cardTable;

  /// No description provided for @guests_emptyFiltered.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości spełniających kryteria.'**
  String get guests_emptyFiltered;

  /// No description provided for @guests_showFilters.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż filtry'**
  String get guests_showFilters;

  /// No description provided for @guests_hideFilters.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj filtry'**
  String get guests_hideFilters;

  /// No description provided for @guests_detailInvitedBy.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszony przez'**
  String get guests_detailInvitedBy;

  /// No description provided for @guests_allSeated.
  ///
  /// In pl, this message translates to:
  /// **'Wszyscy goście są już przypisani.'**
  String get guests_allSeated;

  /// Nazwa zastepcza stolu bez nazwy. UWAGA: nowe stoly dostaja nazwe zapisywana w bazie - to tylko etykieta zapasowa przy odczycie.
  ///
  /// In pl, this message translates to:
  /// **'Stół'**
  String get tables_defaultName;

  /// No description provided for @tables_title.
  ///
  /// In pl, this message translates to:
  /// **'Plan stołów'**
  String get tables_title;

  /// No description provided for @tables_addButton.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj stół'**
  String get tables_addButton;

  /// No description provided for @tables_addedToast.
  ///
  /// In pl, this message translates to:
  /// **'Dodano stół'**
  String get tables_addedToast;

  /// No description provided for @tables_addTitle.
  ///
  /// In pl, this message translates to:
  /// **'Nowy stół'**
  String get tables_addTitle;

  /// No description provided for @tables_name.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa stołu'**
  String get tables_name;

  /// No description provided for @tables_nameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Stół 1'**
  String get tables_nameHint;

  /// No description provided for @tables_shape.
  ///
  /// In pl, this message translates to:
  /// **'Kształt'**
  String get tables_shape;

  /// No description provided for @tables_shapeRound.
  ///
  /// In pl, this message translates to:
  /// **'Okrągły'**
  String get tables_shapeRound;

  /// No description provided for @tables_shapeRect.
  ///
  /// In pl, this message translates to:
  /// **'Prostokątny'**
  String get tables_shapeRect;

  /// No description provided for @tables_seats.
  ///
  /// In pl, this message translates to:
  /// **'Liczba miejsc'**
  String get tables_seats;

  /// No description provided for @tables_honorSwitch.
  ///
  /// In pl, this message translates to:
  /// **'⭐ Stół Pary Młodej (honorowy)'**
  String get tables_honorSwitch;

  /// No description provided for @tables_honorHint.
  ///
  /// In pl, this message translates to:
  /// **'Używa układu prostokątnego'**
  String get tables_honorHint;

  /// No description provided for @tables_childSwitch.
  ///
  /// In pl, this message translates to:
  /// **'🧒 Stół dla dzieci'**
  String get tables_childSwitch;

  /// No description provided for @tables_childHint.
  ///
  /// In pl, this message translates to:
  /// **'Osobny stół dla najmłodszych gości'**
  String get tables_childHint;

  /// No description provided for @tables_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć stół?'**
  String get tables_deleteTitle;

  /// No description provided for @tables_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Goście przypisani do tego stołu wrócą na listę nieprzypisanych.'**
  String get tables_deleteBody;

  /// No description provided for @tables_deletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto stół'**
  String get tables_deletedToast;

  /// No description provided for @tables_full.
  ///
  /// In pl, this message translates to:
  /// **'Stół jest pełny!'**
  String get tables_full;

  /// No description provided for @tables_seatsUsed.
  ///
  /// In pl, this message translates to:
  /// **'{used}/{total} miejsc'**
  String tables_seatsUsed(int used, int total);

  /// No description provided for @tables_assignGuest.
  ///
  /// In pl, this message translates to:
  /// **'Posadź gościa'**
  String get tables_assignGuest;

  /// No description provided for @tables_unassign.
  ///
  /// In pl, this message translates to:
  /// **'Zwolnij miejsce'**
  String get tables_unassign;

  /// No description provided for @tables_emptyState.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz jeszcze stołów. Dodaj pierwszy.'**
  String get tables_emptyState;

  /// No description provided for @tables_statTables.
  ///
  /// In pl, this message translates to:
  /// **'Stoły'**
  String get tables_statTables;

  /// No description provided for @tables_statSeats.
  ///
  /// In pl, this message translates to:
  /// **'Miejsca'**
  String get tables_statSeats;

  /// No description provided for @tables_statFree.
  ///
  /// In pl, this message translates to:
  /// **'Wolne'**
  String get tables_statFree;

  /// No description provided for @tables_hintAdultAtChildTable.
  ///
  /// In pl, this message translates to:
  /// **'Przy stole dla dzieci posadzono osobę dorosłą — jeśli to opiekun, wszystko gra.'**
  String get tables_hintAdultAtChildTable;

  /// No description provided for @tables_hintChildAtRegularTable.
  ///
  /// In pl, this message translates to:
  /// **'Dziecko przy zwykłym stole — jest też stół dla dzieci.'**
  String get tables_hintChildAtRegularTable;

  /// No description provided for @roomplan_title.
  ///
  /// In pl, this message translates to:
  /// **'Plan sali'**
  String get roomplan_title;

  /// No description provided for @roomplan_editMode.
  ///
  /// In pl, this message translates to:
  /// **'Tryb edycji'**
  String get roomplan_editMode;

  /// No description provided for @roomplan_gridOn.
  ///
  /// In pl, this message translates to:
  /// **'Siatka'**
  String get roomplan_gridOn;

  /// No description provided for @roomplan_fullscreen.
  ///
  /// In pl, this message translates to:
  /// **'Pełny ekran'**
  String get roomplan_fullscreen;

  /// No description provided for @roomplan_addTable.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj stół'**
  String get roomplan_addTable;

  /// No description provided for @roomplan_addElement.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj element'**
  String get roomplan_addElement;

  /// No description provided for @roomplan_unassignedGuests.
  ///
  /// In pl, this message translates to:
  /// **'Nieprzypisani goście'**
  String get roomplan_unassignedGuests;

  /// No description provided for @roomplan_roomSize.
  ///
  /// In pl, this message translates to:
  /// **'Wymiary sali'**
  String get roomplan_roomSize;

  /// No description provided for @roomplan_widthMeters.
  ///
  /// In pl, this message translates to:
  /// **'Szerokość (m)'**
  String get roomplan_widthMeters;

  /// No description provided for @roomplan_lengthMeters.
  ///
  /// In pl, this message translates to:
  /// **'Długość (m)'**
  String get roomplan_lengthMeters;

  /// No description provided for @roomplan_savedToast.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano plan sali'**
  String get roomplan_savedToast;

  /// No description provided for @guests_namePendingBadge.
  ///
  /// In pl, this message translates to:
  /// **'✎ imię do potwierdzenia'**
  String get guests_namePendingBadge;

  /// No description provided for @guests_companionFirstNameHint.
  ///
  /// In pl, this message translates to:
  /// **'Imię'**
  String get guests_companionFirstNameHint;

  /// No description provided for @guests_badgeSeatedAt.
  ///
  /// In pl, this message translates to:
  /// **'✓ {table}'**
  String guests_badgeSeatedAt(String table);

  /// No description provided for @guests_companionOfLine.
  ///
  /// In pl, this message translates to:
  /// **'↳ towarzyszy: {name}'**
  String guests_companionOfLine(String name);

  /// No description provided for @guests_emptyAll.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości.'**
  String get guests_emptyAll;

  /// No description provided for @guests_shownOf.
  ///
  /// In pl, this message translates to:
  /// **'Wyświetlono {shown} z {total} gości'**
  String guests_shownOf(int shown, int total);

  /// No description provided for @guests_unknownGuest.
  ///
  /// In pl, this message translates to:
  /// **'nieznany gość'**
  String get guests_unknownGuest;

  /// No description provided for @guests_companionPending.
  ///
  /// In pl, this message translates to:
  /// **'osoba towarzysząca (imię do potwierdzenia)'**
  String get guests_companionPending;

  /// No description provided for @guests_comesWith.
  ///
  /// In pl, this message translates to:
  /// **'👥 przychodzi z: {name}'**
  String guests_comesWith(String name);

  /// No description provided for @guests_menuTimes.
  ///
  /// In pl, this message translates to:
  /// **'{count}×'**
  String guests_menuTimes(int count);

  /// No description provided for @tables_seatsShort.
  ///
  /// In pl, this message translates to:
  /// **'{used}/{total}'**
  String tables_seatsShort(int used, int total);

  /// No description provided for @tables_guestPickerTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz gościa'**
  String get tables_guestPickerTitle;

  /// No description provided for @tables_tapSeatToAssign.
  ///
  /// In pl, this message translates to:
  /// **'Dotknij miejsca, aby posadzić gościa'**
  String get tables_tapSeatToAssign;

  /// No description provided for @tables_honorBadge.
  ///
  /// In pl, this message translates to:
  /// **'⭐ Honorowy'**
  String get tables_honorBadge;

  /// No description provided for @tables_childBadge.
  ///
  /// In pl, this message translates to:
  /// **'🧒 Dla dzieci'**
  String get tables_childBadge;

  /// No description provided for @tables_seatFree.
  ///
  /// In pl, this message translates to:
  /// **'Wolne'**
  String get tables_seatFree;

  /// No description provided for @tables_addFirst.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pierwszy stół'**
  String get tables_addFirst;

  /// Licznik stolow z odmiana ICU.
  ///
  /// In pl, this message translates to:
  /// **'{tables, plural, =1{1 stół} few{{tables} stoły} other{{tables} stołów}}'**
  String tables_summary(int tables);

  /// Licznik miejsc z odmiana ICU.
  ///
  /// In pl, this message translates to:
  /// **'{seats, plural, =1{1 miejsce} few{{seats} miejsca} other{{seats} miejsc}}'**
  String tables_seatsSummary(int seats);

  /// No description provided for @roomplan_elementTable.
  ///
  /// In pl, this message translates to:
  /// **'Stół'**
  String get roomplan_elementTable;

  /// No description provided for @roomplan_elementStage.
  ///
  /// In pl, this message translates to:
  /// **'Scena'**
  String get roomplan_elementStage;

  /// No description provided for @roomplan_elementBar.
  ///
  /// In pl, this message translates to:
  /// **'Bar'**
  String get roomplan_elementBar;

  /// No description provided for @roomplan_elementDanceFloor.
  ///
  /// In pl, this message translates to:
  /// **'Parkiet'**
  String get roomplan_elementDanceFloor;

  /// No description provided for @roomplan_elementEntrance.
  ///
  /// In pl, this message translates to:
  /// **'Wejście'**
  String get roomplan_elementEntrance;

  /// No description provided for @roomplan_elementOther.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get roomplan_elementOther;

  /// No description provided for @roomplan_deleteElement.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć element?'**
  String get roomplan_deleteElement;

  /// No description provided for @roomplan_elementName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa elementu'**
  String get roomplan_elementName;

  /// No description provided for @roomplan_staff.
  ///
  /// In pl, this message translates to:
  /// **'Obsługa'**
  String get roomplan_staff;

  /// No description provided for @roomplan_persons.
  ///
  /// In pl, this message translates to:
  /// **'Liczba osób'**
  String get roomplan_persons;

  /// No description provided for @roomplan_includeInCost.
  ///
  /// In pl, this message translates to:
  /// **'Wliczaj do kosztów'**
  String get roomplan_includeInCost;

  /// No description provided for @roomplan_dragHint.
  ///
  /// In pl, this message translates to:
  /// **'Przytrzymaj i przeciągnij, aby przesunąć'**
  String get roomplan_dragHint;

  /// No description provided for @roomplan_exitFullscreen.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij pełny ekran'**
  String get roomplan_exitFullscreen;

  /// No description provided for @tables_nameHintOptional.
  ///
  /// In pl, this message translates to:
  /// **'np. Stół 1 (opcjonalnie)'**
  String get tables_nameHintOptional;

  /// No description provided for @tables_shapeRoundIcon.
  ///
  /// In pl, this message translates to:
  /// **'⚪ Okrągły'**
  String get tables_shapeRoundIcon;

  /// No description provided for @tables_shapeRectIcon.
  ///
  /// In pl, this message translates to:
  /// **'▭ Prostokątny'**
  String get tables_shapeRectIcon;

  /// No description provided for @tables_deleteBodyNamed.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć stół „{name}”? Przypisani goście wrócą do nieprzypisanych.'**
  String tables_deleteBodyNamed(String name);

  /// No description provided for @tables_removeFromTable.
  ///
  /// In pl, this message translates to:
  /// **'Usuń ze stołu'**
  String get tables_removeFromTable;

  /// No description provided for @tables_unassignedHeader.
  ///
  /// In pl, this message translates to:
  /// **'Nieprzypisani goście ({count})'**
  String tables_unassignedHeader(int count);

  /// No description provided for @tables_dragHint.
  ///
  /// In pl, this message translates to:
  /// **'Przeciągnij (przytrzymaj) gościa na stół lub użyj „Przypisz”.'**
  String get tables_dragHint;

  /// No description provided for @tables_allSeatedCheer.
  ///
  /// In pl, this message translates to:
  /// **'🎉 Wszyscy goście mają miejsce!'**
  String get tables_allSeatedCheer;

  /// No description provided for @tables_assignGuestAction.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz gościa'**
  String get tables_assignGuestAction;

  /// No description provided for @tables_deleteTable.
  ///
  /// In pl, this message translates to:
  /// **'Usuń stół'**
  String get tables_deleteTable;

  /// No description provided for @tables_emptyStateHint.
  ///
  /// In pl, this message translates to:
  /// **'Brak stołów. Dodaj pierwszy stół przyciskiem powyżej.'**
  String get tables_emptyStateHint;

  /// No description provided for @tables_statGuests.
  ///
  /// In pl, this message translates to:
  /// **'Goście'**
  String get tables_statGuests;

  /// No description provided for @roomplan_zoomIn.
  ///
  /// In pl, this message translates to:
  /// **'Przybliż'**
  String get roomplan_zoomIn;

  /// No description provided for @roomplan_widthShort.
  ///
  /// In pl, this message translates to:
  /// **'Szerokość'**
  String get roomplan_widthShort;

  /// No description provided for @roomplan_lengthShort.
  ///
  /// In pl, this message translates to:
  /// **'Długość'**
  String get roomplan_lengthShort;

  /// No description provided for @roomplan_tableDiameterShort.
  ///
  /// In pl, this message translates to:
  /// **'Śr. stołu'**
  String get roomplan_tableDiameterShort;

  /// No description provided for @roomplan_hint.
  ///
  /// In pl, this message translates to:
  /// **'Przytrzymaj i przeciągnij stół/element, aby go przesunąć. Dotknij stołu, aby przypisać gości lub zmienić rozmiar.'**
  String get roomplan_hint;

  /// No description provided for @roomplan_unassignedDrag.
  ///
  /// In pl, this message translates to:
  /// **'Nieprzypisani ({count}) — przeciągnij na stół'**
  String roomplan_unassignedDrag(int count);

  /// No description provided for @roomplan_guest.
  ///
  /// In pl, this message translates to:
  /// **'Gość'**
  String get roomplan_guest;

  /// No description provided for @roomplan_addedToTable.
  ///
  /// In pl, this message translates to:
  /// **'Dodano do stołu: {name}'**
  String roomplan_addedToTable(String name);

  /// No description provided for @roomplan_guestsAtTable.
  ///
  /// In pl, this message translates to:
  /// **'Goście przy stole'**
  String get roomplan_guestsAtTable;

  /// No description provided for @roomplan_noGuestsAtTable.
  ///
  /// In pl, this message translates to:
  /// **'Brak przypisanych gości.'**
  String get roomplan_noGuestsAtTable;

  /// No description provided for @roomplan_tableSize.
  ///
  /// In pl, this message translates to:
  /// **'Rozmiar stołu'**
  String get roomplan_tableSize;

  /// No description provided for @roomplan_diameterMeters.
  ///
  /// In pl, this message translates to:
  /// **'Średnica (m)'**
  String get roomplan_diameterMeters;

  /// No description provided for @roomplan_rotate90.
  ///
  /// In pl, this message translates to:
  /// **'Obróć 90°'**
  String get roomplan_rotate90;

  /// No description provided for @roomplan_allSeated.
  ///
  /// In pl, this message translates to:
  /// **'Wszyscy goście są przypisani.'**
  String get roomplan_allSeated;

  /// No description provided for @roomplan_roomDims.
  ///
  /// In pl, this message translates to:
  /// **'{width} m × {length} m'**
  String roomplan_roomDims(String width, String length);

  /// No description provided for @roomplan_zoomOut.
  ///
  /// In pl, this message translates to:
  /// **'Oddal'**
  String get roomplan_zoomOut;

  /// No description provided for @roomplan_fit.
  ///
  /// In pl, this message translates to:
  /// **'Dopasuj'**
  String get roomplan_fit;

  /// No description provided for @roomplan_editPlan.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj plan'**
  String get roomplan_editPlan;

  /// No description provided for @roomplan_addedElement.
  ///
  /// In pl, this message translates to:
  /// **'Dodano element: {name}'**
  String roomplan_addedElement(String name);

  /// No description provided for @roomplan_elementSize.
  ///
  /// In pl, this message translates to:
  /// **'Rozmiar elementu'**
  String get roomplan_elementSize;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
