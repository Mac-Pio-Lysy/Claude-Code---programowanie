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

  /// No description provided for @settings_tabWedding.
  ///
  /// In pl, this message translates to:
  /// **'Wesele'**
  String get settings_tabWedding;

  /// No description provided for @settings_tabGuests.
  ///
  /// In pl, this message translates to:
  /// **'Goście'**
  String get settings_tabGuests;

  /// No description provided for @settings_tabAccount.
  ///
  /// In pl, this message translates to:
  /// **'Konto i dostęp'**
  String get settings_tabAccount;

  /// No description provided for @settings_tabApp.
  ///
  /// In pl, this message translates to:
  /// **'Aplikacja'**
  String get settings_tabApp;

  /// No description provided for @settings_tabHelp.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc i zaawansowane'**
  String get settings_tabHelp;

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

  /// No description provided for @common_copy.
  ///
  /// In pl, this message translates to:
  /// **'Kopiuj'**
  String get common_copy;

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

  /// No description provided for @common_deleteConfirmBody.
  ///
  /// In pl, this message translates to:
  /// **'Tej operacji nie da się cofnąć.'**
  String get common_deleteConfirmBody;

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

  /// No description provided for @date_pickDate.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz datę'**
  String get date_pickDate;

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

  /// Nazwa zastepcza stolu bez nazwy. UWAGA: nowe stoly dostaja nazwe zapisywana w bazie - to tylko etykieta zapasowa przy odczycie.
  ///
  /// In pl, this message translates to:
  /// **'Stół'**
  String get tables_defaultName;

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

  /// No description provided for @tables_shape.
  ///
  /// In pl, this message translates to:
  /// **'Kształt'**
  String get tables_shape;

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

  /// No description provided for @tables_full.
  ///
  /// In pl, this message translates to:
  /// **'Stół jest pełny!'**
  String get tables_full;

  /// No description provided for @tables_statTables.
  ///
  /// In pl, this message translates to:
  /// **'Stoły'**
  String get tables_statTables;

  /// No description provided for @roomplan_title.
  ///
  /// In pl, this message translates to:
  /// **'Plan sali'**
  String get roomplan_title;

  /// No description provided for @roomplan_fullscreen.
  ///
  /// In pl, this message translates to:
  /// **'Pełny ekran'**
  String get roomplan_fullscreen;

  /// No description provided for @roomplan_addElement.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj element'**
  String get roomplan_addElement;

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

  /// No description provided for @roomplan_elementTable.
  ///
  /// In pl, this message translates to:
  /// **'Stół'**
  String get roomplan_elementTable;

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

  /// No description provided for @budget_title.
  ///
  /// In pl, this message translates to:
  /// **'Budżet'**
  String get budget_title;

  /// No description provided for @budget_tabSummary.
  ///
  /// In pl, this message translates to:
  /// **'Podsumowanie'**
  String get budget_tabSummary;

  /// No description provided for @budget_tabVenue.
  ///
  /// In pl, this message translates to:
  /// **'Sala'**
  String get budget_tabVenue;

  /// No description provided for @budget_tabExpenses.
  ///
  /// In pl, this message translates to:
  /// **'Wydatki'**
  String get budget_tabExpenses;

  /// No description provided for @budget_tabAlcohol.
  ///
  /// In pl, this message translates to:
  /// **'Alkohol'**
  String get budget_tabAlcohol;

  /// No description provided for @budget_tabSoft.
  ///
  /// In pl, this message translates to:
  /// **'Napoje bezalkoholowe'**
  String get budget_tabSoft;

  /// No description provided for @budget_tabHoneymoon.
  ///
  /// In pl, this message translates to:
  /// **'Podróż poślubna'**
  String get budget_tabHoneymoon;

  /// No description provided for @budget_planned.
  ///
  /// In pl, this message translates to:
  /// **'Budżet planowany'**
  String get budget_planned;

  /// No description provided for @budget_reserveHint.
  ///
  /// In pl, this message translates to:
  /// **'Zapas ponad budżet główny — liczony osobno, zużywany dopiero, gdy koszty go przekroczą.'**
  String get budget_reserveHint;

  /// No description provided for @budget_saveButton.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz budżet'**
  String get budget_saveButton;

  /// No description provided for @budget_savedToast.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano budżet'**
  String get budget_savedToast;

  /// No description provided for @budget_invalidAmount.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowa kwota'**
  String get budget_invalidAmount;

  /// No description provided for @budget_paidShort.
  ///
  /// In pl, this message translates to:
  /// **'opłacono'**
  String get budget_paidShort;

  /// No description provided for @budget_paidAmount.
  ///
  /// In pl, this message translates to:
  /// **'Opłacono: {amount}'**
  String budget_paidAmount(String amount);

  /// No description provided for @budget_actual.
  ///
  /// In pl, this message translates to:
  /// **'Budżet rzeczywisty (koszty)'**
  String get budget_actual;

  /// No description provided for @budget_ofWhichPaid.
  ///
  /// In pl, this message translates to:
  /// **'w tym opłacono'**
  String get budget_ofWhichPaid;

  /// No description provided for @budget_remaining.
  ///
  /// In pl, this message translates to:
  /// **'Pozostało z budżetu'**
  String get budget_remaining;

  /// No description provided for @budget_expenseDeleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wydatek?'**
  String get budget_expenseDeleteTitle;

  /// No description provided for @budget_expenseDeleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{name}”?'**
  String budget_expenseDeleteBody(String name);

  /// No description provided for @budget_expenseDeletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto wydatek'**
  String get budget_expenseDeletedToast;

  /// No description provided for @budget_expenseAddedToast.
  ///
  /// In pl, this message translates to:
  /// **'Dodano pozycję: {name}'**
  String budget_expenseAddedToast(String name);

  /// No description provided for @budget_expensesEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wydatków. Dodaj pierwszy przyciskiem poniżej.'**
  String get budget_expensesEmpty;

  /// No description provided for @budget_expensesEmptyFiltered.
  ///
  /// In pl, this message translates to:
  /// **'Brak wydatków spełniających kryteria filtrów.'**
  String get budget_expensesEmptyFiltered;

  /// No description provided for @budget_collapse.
  ///
  /// In pl, this message translates to:
  /// **'zwiń'**
  String get budget_collapse;

  /// No description provided for @budget_expand.
  ///
  /// In pl, this message translates to:
  /// **'rozwiń'**
  String get budget_expand;

  /// No description provided for @budget_customItem.
  ///
  /// In pl, this message translates to:
  /// **'Własna pozycja'**
  String get budget_customItem;

  /// No description provided for @budget_customName.
  ///
  /// In pl, this message translates to:
  /// **'Własna nazwa'**
  String get budget_customName;

  /// No description provided for @budget_paid.
  ///
  /// In pl, this message translates to:
  /// **'Opłacono'**
  String get budget_paid;

  /// No description provided for @budget_left.
  ///
  /// In pl, this message translates to:
  /// **'Pozostało'**
  String get budget_left;

  /// No description provided for @budget_statusPaid.
  ///
  /// In pl, this message translates to:
  /// **'✓ Opłacone'**
  String get budget_statusPaid;

  /// No description provided for @budget_statusPartial.
  ///
  /// In pl, this message translates to:
  /// **'⚡ Częściowo'**
  String get budget_statusPartial;

  /// No description provided for @budget_statusUnpaid.
  ///
  /// In pl, this message translates to:
  /// **'✗ Nieopłacone'**
  String get budget_statusUnpaid;

  /// No description provided for @budget_manual.
  ///
  /// In pl, this message translates to:
  /// **'Ręcznie'**
  String get budget_manual;

  /// No description provided for @budget_paidShortPrefix.
  ///
  /// In pl, this message translates to:
  /// **'opł. {amount}'**
  String budget_paidShortPrefix(String amount);

  /// No description provided for @budget_paymentDate.
  ///
  /// In pl, this message translates to:
  /// **'Data płatności'**
  String get budget_paymentDate;

  /// No description provided for @budget_split.
  ///
  /// In pl, this message translates to:
  /// **'Podział'**
  String get budget_split;

  /// No description provided for @budget_splitCosts.
  ///
  /// In pl, this message translates to:
  /// **'Podział kosztów'**
  String get budget_splitCosts;

  /// No description provided for @budget_isVendor.
  ///
  /// In pl, this message translates to:
  /// **'🏢 To jest dostawca/usługa'**
  String get budget_isVendor;

  /// No description provided for @budget_isVendorHint.
  ///
  /// In pl, this message translates to:
  /// **'Pokaże się też w sekcji Dostawcy jako TEN SAM rekord (kwota się nie dubluje).'**
  String get budget_isVendorHint;

  /// No description provided for @budget_vendorName.
  ///
  /// In pl, this message translates to:
  /// **'Imię i nazwisko'**
  String get budget_vendorName;

  /// No description provided for @budget_paymentsEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak płatności w tym widoku.'**
  String get budget_paymentsEmpty;

  /// No description provided for @budget_paymentsFilter.
  ///
  /// In pl, this message translates to:
  /// **'Filtruj płatności'**
  String get budget_paymentsFilter;

  /// No description provided for @budget_paymentsReminders.
  ///
  /// In pl, this message translates to:
  /// **'🔔 Przypomnienia o płatnościach'**
  String get budget_paymentsReminders;

  /// No description provided for @budget_overdue.
  ///
  /// In pl, this message translates to:
  /// **'zaległa!'**
  String get budget_overdue;

  /// No description provided for @budget_dueSoon.
  ///
  /// In pl, this message translates to:
  /// **'wkrótce'**
  String get budget_dueSoon;

  /// No description provided for @budget_tripShort.
  ///
  /// In pl, this message translates to:
  /// **'✈️ Podróż'**
  String get budget_tripShort;

  /// No description provided for @budget_paidRemaining.
  ///
  /// In pl, this message translates to:
  /// **'Opłacono {paid} · Pozostało {remaining}'**
  String budget_paidRemaining(String paid, String remaining);

  /// No description provided for @budget_panelRemoveTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usuń panel: {panel}'**
  String budget_panelRemoveTitle(String panel);

  /// No description provided for @budget_panelRemovedToast.
  ///
  /// In pl, this message translates to:
  /// **'Panel usunięty'**
  String get budget_panelRemovedToast;

  /// No description provided for @budget_panelRemovedInfo.
  ///
  /// In pl, this message translates to:
  /// **'Panel „{panel}” jest usunięty i NIE jest wliczany do budżetu. Pozycje pozostają zapisane — możesz przywrócić panel.'**
  String budget_panelRemovedInfo(String panel);

  /// No description provided for @budget_panelRestore.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć panel'**
  String get budget_panelRestore;

  /// No description provided for @budget_addItem.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pozycję'**
  String get budget_addItem;

  /// No description provided for @budget_addItemHint.
  ///
  /// In pl, this message translates to:
  /// **'Kliknij +, aby dodać pozycję.'**
  String get budget_addItemHint;

  /// No description provided for @budget_bottlesTotal.
  ///
  /// In pl, this message translates to:
  /// **'butelek łącznie'**
  String get budget_bottlesTotal;

  /// No description provided for @budget_costTotal.
  ///
  /// In pl, this message translates to:
  /// **'łączny koszt'**
  String get budget_costTotal;

  /// No description provided for @budget_includeVirtual.
  ///
  /// In pl, this message translates to:
  /// **'Uwzględniaj gości wirtualnych w przeliczeniu na osobę'**
  String get budget_includeVirtual;

  /// No description provided for @budget_splitHeader.
  ///
  /// In pl, this message translates to:
  /// **'⚖ Podział kosztów'**
  String get budget_splitHeader;

  /// No description provided for @budget_splitExceeds.
  ///
  /// In pl, this message translates to:
  /// **'⚠ Suma podziału przekracza łączny koszt.'**
  String get budget_splitExceeds;

  /// No description provided for @budget_honeymoonTitle.
  ///
  /// In pl, this message translates to:
  /// **'✈ Podróż poślubna'**
  String get budget_honeymoonTitle;

  /// No description provided for @budget_honeymoonName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa / cel podróży'**
  String get budget_honeymoonName;

  /// No description provided for @budget_openOffer.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz ofertę'**
  String get budget_openOffer;

  /// No description provided for @budget_addVariant.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wariant podróży'**
  String get budget_addVariant;

  /// No description provided for @budget_variantsHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj kilka propozycji i zaznacz, która wchodzi do budżetu.'**
  String get budget_variantsHint;

  /// No description provided for @budget_variantsHeader.
  ///
  /// In pl, this message translates to:
  /// **'✈ Warianty podróży poślubnej'**
  String get budget_variantsHeader;

  /// No description provided for @budget_includeMoreExpensive.
  ///
  /// In pl, this message translates to:
  /// **'Wlicz droższą wersję do budżetu'**
  String get budget_includeMoreExpensive;

  /// No description provided for @budget_includeMoreExpensiveHint.
  ///
  /// In pl, this message translates to:
  /// **'Bezpieczne planowanie — liczy najdroższy wariant.'**
  String get budget_includeMoreExpensiveHint;

  /// No description provided for @budget_payments.
  ///
  /// In pl, this message translates to:
  /// **'Płatności'**
  String get budget_payments;

  /// No description provided for @budget_toBudget.
  ///
  /// In pl, this message translates to:
  /// **'Do budżetu'**
  String get budget_toBudget;

  /// No description provided for @budget_alreadyPaid.
  ///
  /// In pl, this message translates to:
  /// **'Zapłacono'**
  String get budget_alreadyPaid;

  /// No description provided for @budget_installments.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram płatności'**
  String get budget_installments;

  /// No description provided for @budget_addInstallment.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj ratę'**
  String get budget_addInstallment;

  /// No description provided for @budget_noInstallments.
  ///
  /// In pl, this message translates to:
  /// **'Brak rat — dodaj harmonogram płatności.'**
  String get budget_noInstallments;

  /// No description provided for @budget_linkFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się otworzyć linku'**
  String get budget_linkFailed;

  /// No description provided for @budget_installmentPaid.
  ///
  /// In pl, this message translates to:
  /// **'✓ Zapłacona'**
  String get budget_installmentPaid;

  /// No description provided for @budget_installmentDue.
  ///
  /// In pl, this message translates to:
  /// **'○ Do zapłaty'**
  String get budget_installmentDue;

  /// No description provided for @budget_withChildrenTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wesele z dziećmi'**
  String get budget_withChildrenTitle;

  /// No description provided for @budget_withChildrenSwitch.
  ///
  /// In pl, this message translates to:
  /// **'Czy to wesele z dziećmi?'**
  String get budget_withChildrenSwitch;

  /// No description provided for @budget_withChildrenHint.
  ///
  /// In pl, this message translates to:
  /// **'Dzieci są wyłączane z przeliczeń alkoholu. Możesz też dodać stół dla dzieci (w Planie sali) i osobne menu dziecięce.'**
  String get budget_withChildrenHint;

  /// No description provided for @budget_childrenAuto.
  ///
  /// In pl, this message translates to:
  /// **'Licz dzieci z listy gości'**
  String get budget_childrenAuto;

  /// No description provided for @budget_childrenAutoOn.
  ///
  /// In pl, this message translates to:
  /// **'Liczba bierze się z gości oznaczonych jako dziecko (Goście → „🧒 To dziecko”).'**
  String get budget_childrenAutoOn;

  /// No description provided for @budget_childrenAutoOff.
  ///
  /// In pl, this message translates to:
  /// **'Wpisujesz liczbę ręcznie. Włącz, jeśli dzieci są na liście gości.'**
  String get budget_childrenAutoOff;

  /// No description provided for @budget_childrenFromGuests.
  ///
  /// In pl, this message translates to:
  /// **'Liczba dzieci (z listy gości)'**
  String get budget_childrenFromGuests;

  /// No description provided for @budget_childrenCount.
  ///
  /// In pl, this message translates to:
  /// **'Liczba dzieci'**
  String get budget_childrenCount;

  /// No description provided for @budget_childrenMismatch.
  ///
  /// In pl, this message translates to:
  /// **'Na liście gości oznaczono {fromGuests}, a tu wpisano {manual}. Sprawdź, która liczba jest właściwa.'**
  String budget_childrenMismatch(String fromGuests, String manual);

  /// No description provided for @budget_childrenHiddenInfo.
  ///
  /// In pl, this message translates to:
  /// **'Dane dzieci są zachowane ({count} oznaczonych na liście gości), tylko nie liczą się teraz do budżetu. Włącz przełącznik, żeby wróciły do wyliczeń.'**
  String budget_childrenHiddenInfo(String count);

  /// No description provided for @budget_childrenHiddenDeleteHint.
  ///
  /// In pl, this message translates to:
  /// **'Trwałe usunięcie: Ustawienia → Wesele.'**
  String get budget_childrenHiddenDeleteHint;

  /// No description provided for @budget_childMenuSeparate.
  ///
  /// In pl, this message translates to:
  /// **'Czy dla dzieci jest oddzielne menu?'**
  String get budget_childMenuSeparate;

  /// No description provided for @budget_childMenuOn.
  ///
  /// In pl, this message translates to:
  /// **'Dzieci ({count}) liczone po cenie dziecięcej.'**
  String budget_childMenuOn(int count);

  /// No description provided for @budget_childMenuOff.
  ///
  /// In pl, this message translates to:
  /// **'Dzieci liczone jak dorośli (cena za osobę).'**
  String get budget_childMenuOff;

  /// No description provided for @budget_childMenuPrice.
  ///
  /// In pl, this message translates to:
  /// **'Cena za dziecko (menu)'**
  String get budget_childMenuPrice;

  /// No description provided for @budget_childMenuCost.
  ///
  /// In pl, this message translates to:
  /// **'Koszt menu dziecięcego'**
  String get budget_childMenuCost;

  /// No description provided for @budget_cateringSeparateHint.
  ///
  /// In pl, this message translates to:
  /// **'Catering od innej firmy niż sala — liczony osobno, po cenie za osobę (te same przeliczenia liczby osób co sala).'**
  String get budget_cateringSeparateHint;

  /// No description provided for @budget_cateringPricePerPerson.
  ///
  /// In pl, this message translates to:
  /// **'Cena cateringu za osobę'**
  String get budget_cateringPricePerPerson;

  /// No description provided for @budget_noAddons.
  ///
  /// In pl, this message translates to:
  /// **'Brak dodatków. Dodaj przyciskiem +.'**
  String get budget_noAddons;

  /// Skrot 'na osobe' przy kwocie; {currency} to symbol waluty wesela.
  ///
  /// In pl, this message translates to:
  /// **'{currency}/os.'**
  String budget_perPersonShort(String currency);

  /// No description provided for @budget_peopleForCalc.
  ///
  /// In pl, this message translates to:
  /// **'Liczba osób do przeliczeń'**
  String get budget_peopleForCalc;

  /// No description provided for @budget_cateringTotal.
  ///
  /// In pl, this message translates to:
  /// **'Łącznie catering'**
  String get budget_cateringTotal;

  /// No description provided for @budget_pricePerPerson.
  ///
  /// In pl, this message translates to:
  /// **'Cena za osobę'**
  String get budget_pricePerPerson;

  /// No description provided for @budget_venueMinGuests.
  ///
  /// In pl, this message translates to:
  /// **'Minimalna liczba osób (próg sali)'**
  String get budget_venueMinGuests;

  /// No description provided for @budget_plannedGuests.
  ///
  /// In pl, this message translates to:
  /// **'Osoby planowane'**
  String get budget_plannedGuests;

  /// No description provided for @budget_plannedGuestsHint.
  ///
  /// In pl, this message translates to:
  /// **'Szacunek, zanim znasz pełną listę gości.'**
  String get budget_plannedGuestsHint;

  /// No description provided for @budget_effectiveBreakdown.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszeni: {invited} · Minimum sali: {min} · Planowani: {planned} → liczymy dla: {effective}'**
  String budget_effectiveBreakdown(
    String invited,
    String min,
    String planned,
    String effective,
  );

  /// No description provided for @budget_moreThanPlannedInfo.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszonych jest więcej o {diff}, łącznie {total}.'**
  String budget_moreThanPlannedInfo(String diff, String total);

  /// No description provided for @budget_moreThanPlannedNote.
  ///
  /// In pl, this message translates to:
  /// **'Nie trzeba nic zmieniać — liczba aktualizuje się automatycznie.'**
  String get budget_moreThanPlannedNote;

  /// No description provided for @budget_guestsAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Goście przypisani do stołów'**
  String get budget_guestsAssigned;

  /// ETYKIETA kategorii wydatku. Wartosc w bazie zostaje polska (Sala i catering) - patrz ExpenseCategory.labelFor.
  ///
  /// In pl, this message translates to:
  /// **'Sala i catering'**
  String get budget_catVenueCatering;

  /// No description provided for @budget_catDress.
  ///
  /// In pl, this message translates to:
  /// **'Suknia ślubna'**
  String get budget_catDress;

  /// No description provided for @budget_catSuit.
  ///
  /// In pl, this message translates to:
  /// **'Garnitur/strój'**
  String get budget_catSuit;

  /// No description provided for @budget_catRings.
  ///
  /// In pl, this message translates to:
  /// **'Obrączki'**
  String get budget_catRings;

  /// No description provided for @budget_catPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Fotograf'**
  String get budget_catPhoto;

  /// No description provided for @budget_catVideo.
  ///
  /// In pl, this message translates to:
  /// **'Kamerzysta/wideo'**
  String get budget_catVideo;

  /// No description provided for @budget_catFlowersDecor.
  ///
  /// In pl, this message translates to:
  /// **'Kwiaty/dekoracje'**
  String get budget_catFlowersDecor;

  /// No description provided for @budget_catBouquet.
  ///
  /// In pl, this message translates to:
  /// **'Bukiet ślubny'**
  String get budget_catBouquet;

  /// No description provided for @budget_catFlowersCouple.
  ///
  /// In pl, this message translates to:
  /// **'Kwiaty dla PM'**
  String get budget_catFlowersCouple;

  /// No description provided for @budget_catChurchDecor.
  ///
  /// In pl, this message translates to:
  /// **'Przystrojenie kościoła'**
  String get budget_catChurchDecor;

  /// No description provided for @budget_catCake.
  ///
  /// In pl, this message translates to:
  /// **'Tort weselny'**
  String get budget_catCake;

  /// No description provided for @budget_catMusic.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka/DJ/zespół'**
  String get budget_catMusic;

  /// No description provided for @budget_catInvitations.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenia'**
  String get budget_catInvitations;

  /// No description provided for @budget_catBeauty.
  ///
  /// In pl, this message translates to:
  /// **'Uroda'**
  String get budget_catBeauty;

  /// No description provided for @budget_catHairMakeup.
  ///
  /// In pl, this message translates to:
  /// **'Makijaż i fryzura'**
  String get budget_catHairMakeup;

  /// No description provided for @budget_catTransport.
  ///
  /// In pl, this message translates to:
  /// **'Transport'**
  String get budget_catTransport;

  /// No description provided for @budget_catRideReception.
  ///
  /// In pl, this message translates to:
  /// **'Dojazd do wesela'**
  String get budget_catRideReception;

  /// No description provided for @budget_catRideChurch.
  ///
  /// In pl, this message translates to:
  /// **'Dojazd do kościoła'**
  String get budget_catRideChurch;

  /// No description provided for @budget_catGiftsGuests.
  ///
  /// In pl, this message translates to:
  /// **'Upominki dla gości'**
  String get budget_catGiftsGuests;

  /// No description provided for @budget_catGiftsParents.
  ///
  /// In pl, this message translates to:
  /// **'Upominki dla rodziców'**
  String get budget_catGiftsParents;

  /// No description provided for @budget_catGiftsWitnesses.
  ///
  /// In pl, this message translates to:
  /// **'Upominki dla świadków'**
  String get budget_catGiftsWitnesses;

  /// No description provided for @budget_catHoneymoon.
  ///
  /// In pl, this message translates to:
  /// **'Podróż poślubna'**
  String get budget_catHoneymoon;

  /// No description provided for @budget_catAlcohol.
  ///
  /// In pl, this message translates to:
  /// **'Alkohol'**
  String get budget_catAlcohol;

  /// No description provided for @budget_catOther.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get budget_catOther;

  /// No description provided for @budget_expenseFallbackName.
  ///
  /// In pl, this message translates to:
  /// **'Wydatek'**
  String get budget_expenseFallbackName;

  /// No description provided for @budget_guestsUnassigned.
  ///
  /// In pl, this message translates to:
  /// **'Goście nieprzypisani'**
  String get budget_guestsUnassigned;

  /// No description provided for @budget_guestsCost.
  ///
  /// In pl, this message translates to:
  /// **'Koszt gości'**
  String get budget_guestsCost;

  /// No description provided for @budget_virtualGuests.
  ///
  /// In pl, this message translates to:
  /// **'Goście wirtualni (do progu sali)'**
  String get budget_virtualGuests;

  /// No description provided for @budget_virtualGuestsCost.
  ///
  /// In pl, this message translates to:
  /// **'Koszt gości wirtualnych'**
  String get budget_virtualGuestsCost;

  /// No description provided for @budget_cateringSeparateNote.
  ///
  /// In pl, this message translates to:
  /// **'Catering (osobna firma) liczony w osobnej karcie poniżej.'**
  String get budget_cateringSeparateNote;

  /// No description provided for @budget_cateringIncluded.
  ///
  /// In pl, this message translates to:
  /// **'Catering wliczony w cenę sali za osobę.'**
  String get budget_cateringIncluded;

  /// Naglowek karty obslugi. UWAGA: nazwa nowej pozycji obslugi zapisywana do bazy jest osobno w budget_service.
  ///
  /// In pl, this message translates to:
  /// **'Obsługa'**
  String get budget_staff;

  /// No description provided for @budget_staffHint.
  ///
  /// In pl, this message translates to:
  /// **'Kelnerzy, fotograf, DJ, kamerzysta — osoby, które jedzą, ale nie są gośćmi. Liczone osobno.'**
  String get budget_staffHint;

  /// No description provided for @budget_staffEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak obsługi. Dodaj przyciskiem +.'**
  String get budget_staffEmpty;

  /// No description provided for @budget_staffModeHeadcount.
  ///
  /// In pl, this message translates to:
  /// **'Wg listy obsługi'**
  String get budget_staffModeHeadcount;

  /// No description provided for @budget_staffModePerGuest.
  ///
  /// In pl, this message translates to:
  /// **'Na gości'**
  String get budget_staffModePerGuest;

  /// No description provided for @budget_staffModeManual.
  ///
  /// In pl, this message translates to:
  /// **'Kwota ręczna'**
  String get budget_staffModeManual;

  /// No description provided for @budget_staffRate.
  ///
  /// In pl, this message translates to:
  /// **'Stawka obsługi za osobę'**
  String get budget_staffRate;

  /// No description provided for @budget_staffRateFallbackHint.
  ///
  /// In pl, this message translates to:
  /// **'Zostaw puste, żeby liczyć jak za gościa (ta sama stawka co catering).'**
  String get budget_staffRateFallbackHint;

  /// No description provided for @budget_staffManualAmount.
  ///
  /// In pl, this message translates to:
  /// **'Kwota za obsługę'**
  String get budget_staffManualAmount;

  /// No description provided for @budget_staffInclude.
  ///
  /// In pl, this message translates to:
  /// **'Doliczaj obsługę do kosztu sali'**
  String get budget_staffInclude;

  /// No description provided for @budget_staffIncludeHint.
  ///
  /// In pl, this message translates to:
  /// **'Liczona jest obsługa oznaczona „w kosztach”.'**
  String get budget_staffIncludeHint;

  /// No description provided for @budget_staffCountTotal.
  ///
  /// In pl, this message translates to:
  /// **'Osób obsługi łącznie'**
  String get budget_staffCountTotal;

  /// No description provided for @budget_staffRateShort.
  ///
  /// In pl, this message translates to:
  /// **'Stawka obsługi / os.'**
  String get budget_staffRateShort;

  /// No description provided for @budget_staffCost.
  ///
  /// In pl, this message translates to:
  /// **'Koszt obsługi'**
  String get budget_staffCost;

  /// No description provided for @budget_menuAddonsTotal.
  ///
  /// In pl, this message translates to:
  /// **'Łącznie dodatki do menu'**
  String get budget_menuAddonsTotal;

  /// No description provided for @budget_tableDecor.
  ///
  /// In pl, this message translates to:
  /// **'Dekoracje stołów (per stolik)'**
  String get budget_tableDecor;

  /// No description provided for @budget_honorTable.
  ///
  /// In pl, this message translates to:
  /// **'⭐ Stół Pary Młodej'**
  String get budget_honorTable;

  /// No description provided for @budget_honorTableEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak dekoracji stołu Pary Młodej.'**
  String get budget_honorTableEmpty;

  /// No description provided for @budget_regularTables.
  ///
  /// In pl, this message translates to:
  /// **'Pozostałe stoły (×{count})'**
  String budget_regularTables(int count);

  /// No description provided for @budget_regularTablesEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak dekoracji pozostałych stołów.'**
  String get budget_regularTablesEmpty;

  /// No description provided for @budget_perTableShort.
  ///
  /// In pl, this message translates to:
  /// **'{currency}/stół'**
  String budget_perTableShort(String currency);

  /// No description provided for @budget_honorTableDecor.
  ///
  /// In pl, this message translates to:
  /// **'Dekoracje stołu Pary Młodej'**
  String get budget_honorTableDecor;

  /// No description provided for @budget_regularTablesDecor.
  ///
  /// In pl, this message translates to:
  /// **'Dekoracje pozostałych stołów'**
  String get budget_regularTablesDecor;

  /// No description provided for @budget_decorTotal.
  ///
  /// In pl, this message translates to:
  /// **'Łącznie dekoracje'**
  String get budget_decorTotal;

  /// No description provided for @budget_venueSummary.
  ///
  /// In pl, this message translates to:
  /// **'Podsumowanie kosztów sali'**
  String get budget_venueSummary;

  /// No description provided for @budget_guestsCostCount.
  ///
  /// In pl, this message translates to:
  /// **'Koszt gości ({count} os.)'**
  String budget_guestsCostCount(int count);

  /// No description provided for @budget_virtualCostCount.
  ///
  /// In pl, this message translates to:
  /// **'Goście wirtualni ({count} os.)'**
  String budget_virtualCostCount(int count);

  /// No description provided for @budget_staffCostCount.
  ///
  /// In pl, this message translates to:
  /// **'Obsługa ({count} os.)'**
  String budget_staffCostCount(int count);

  /// No description provided for @budget_staffCostCountExcluded.
  ///
  /// In pl, this message translates to:
  /// **'Obsługa ({count} os., nieliczona)'**
  String budget_staffCostCountExcluded(int count);

  /// No description provided for @budget_cateringSeparateCard.
  ///
  /// In pl, this message translates to:
  /// **'Catering (oddzielny)'**
  String get budget_cateringSeparateCard;

  /// No description provided for @budget_childrenSuffix.
  ///
  /// In pl, this message translates to:
  /// **'dzieci'**
  String get budget_childrenSuffix;

  /// No description provided for @budget_tableDecorTotal.
  ///
  /// In pl, this message translates to:
  /// **'Dekoracje stołów'**
  String get budget_tableDecorTotal;

  /// No description provided for @budget_variantBudgeted.
  ///
  /// In pl, this message translates to:
  /// **'Do budżetu: {name}'**
  String budget_variantBudgeted(String name);

  /// No description provided for @budget_variantNone.
  ///
  /// In pl, this message translates to:
  /// **'brak wyboru'**
  String get budget_variantNone;

  /// No description provided for @budget_expensesQuickAdd.
  ///
  /// In pl, this message translates to:
  /// **'Kliknij, aby dodać gotowy wydatek — listę zmienisz w Ustawieniach.'**
  String get budget_expensesQuickAdd;

  /// No description provided for @budget_statusPaidShort.
  ///
  /// In pl, this message translates to:
  /// **'Opłacone'**
  String get budget_statusPaidShort;

  /// No description provided for @schedule_title.
  ///
  /// In pl, this message translates to:
  /// **'📅 Harmonogram dnia ślubu'**
  String get schedule_title;

  /// No description provided for @schedule_qrForGuests.
  ///
  /// In pl, this message translates to:
  /// **'Kod QR dla gości'**
  String get schedule_qrForGuests;

  /// No description provided for @schedule_forGuests.
  ///
  /// In pl, this message translates to:
  /// **'Dla gości'**
  String get schedule_forGuests;

  /// No description provided for @schedule_eventNameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Ceremonia ślubna'**
  String get schedule_eventNameHint;

  /// No description provided for @schedule_nameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Podaj nazwę'**
  String get schedule_nameRequired;

  /// No description provided for @schedule_detailsHint.
  ///
  /// In pl, this message translates to:
  /// **'Szczegóły…'**
  String get schedule_detailsHint;

  /// No description provided for @schedule_private.
  ///
  /// In pl, this message translates to:
  /// **'🔒 Prywatne (ukryte przed gośćmi)'**
  String get schedule_private;

  /// No description provided for @schedule_showLink.
  ///
  /// In pl, this message translates to:
  /// **'👁 Pokaż link gościom'**
  String get schedule_showLink;

  /// No description provided for @schedule_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wydarzenie?'**
  String get schedule_deleteTitle;

  /// No description provided for @schedule_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{name}”?'**
  String schedule_deleteBody(String name);

  /// No description provided for @schedule_deletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto wydarzenie'**
  String get schedule_deletedToast;

  /// No description provided for @schedule_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wydarzeń. Dodaj pierwsze poniżej.'**
  String get schedule_empty;

  /// No description provided for @schedule_openLocation.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz lokalizację'**
  String get schedule_openLocation;

  /// No description provided for @schedule_guestPreview.
  ///
  /// In pl, this message translates to:
  /// **'Podgląd dla gości ({count})'**
  String schedule_guestPreview(int count);

  /// No description provided for @schedule_noneVisible.
  ///
  /// In pl, this message translates to:
  /// **'Żadne wydarzenie nie jest oznaczone jako widoczne dla gości.'**
  String get schedule_noneVisible;

  /// No description provided for @schedule_guestPreviewHint.
  ///
  /// In pl, this message translates to:
  /// **'Tak goście widzą harmonogram na stronie /harmonogram:'**
  String get schedule_guestPreviewHint;

  /// No description provided for @schedule_visibility.
  ///
  /// In pl, this message translates to:
  /// **'Widoczność wydarzeń'**
  String get schedule_visibility;

  /// No description provided for @schedule_emptyAddInPlan.
  ///
  /// In pl, this message translates to:
  /// **'Brak wydarzeń. Dodaj je w zakładce „Plan dnia”.'**
  String get schedule_emptyAddInPlan;

  /// No description provided for @schedule_visibilityHint.
  ///
  /// In pl, this message translates to:
  /// **'Zaznacz, które wydarzenia widzą goście.'**
  String get schedule_visibilityHint;

  /// No description provided for @schedule_visibleToGuests.
  ///
  /// In pl, this message translates to:
  /// **'Widoczne dla gości'**
  String get schedule_visibleToGuests;

  /// No description provided for @checklist_addHint.
  ///
  /// In pl, this message translates to:
  /// **'Co zrobić…'**
  String get checklist_addHint;

  /// No description provided for @checklist_progress.
  ///
  /// In pl, this message translates to:
  /// **'{done}/{total} ukończonych ({percent}%)'**
  String checklist_progress(int done, int total, int percent);

  /// No description provided for @checklist_addItem.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pozycję'**
  String get checklist_addItem;

  /// No description provided for @tasks_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć zadanie?'**
  String get tasks_deleteTitle;

  /// No description provided for @tasks_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{name}”?'**
  String tasks_deleteBody(String name);

  /// No description provided for @tasks_deletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto zadanie'**
  String get tasks_deletedToast;

  /// No description provided for @tasks_goalReached.
  ///
  /// In pl, this message translates to:
  /// **'🎯 Cel osiągnięty'**
  String get tasks_goalReached;

  /// No description provided for @tasks_goalReachedBody.
  ///
  /// In pl, this message translates to:
  /// **'„{goal}” zostało oznaczone jako zrealizowane.\n\nCzy utworzyć z tego pozycję w budżecie?'**
  String tasks_goalReachedBody(String goal);

  /// No description provided for @tasks_goalCreateYes.
  ///
  /// In pl, this message translates to:
  /// **'Tak, utwórz'**
  String get tasks_goalCreateYes;

  /// No description provided for @tasks_budgetItemCreated.
  ///
  /// In pl, this message translates to:
  /// **'Utworzono pozycję w budżecie'**
  String get tasks_budgetItemCreated;

  /// No description provided for @tasks_newBudgetItem.
  ///
  /// In pl, this message translates to:
  /// **'💰 Nowa pozycja w budżecie'**
  String get tasks_newBudgetItem;

  /// No description provided for @tasks_estimatedCost.
  ///
  /// In pl, this message translates to:
  /// **'Szacowany koszt ({currency})'**
  String tasks_estimatedCost(String currency);

  /// No description provided for @tasks_budgetCategory.
  ///
  /// In pl, this message translates to:
  /// **'Kategoria budżetowa'**
  String get tasks_budgetCategory;

  /// No description provided for @tasks_create.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz'**
  String get tasks_create;

  /// No description provided for @tasks_progress.
  ///
  /// In pl, this message translates to:
  /// **'{done}/{total} ukończonych ({percent}%)'**
  String tasks_progress(int done, int total, int percent);

  /// No description provided for @tasks_allLinks.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie powiązania'**
  String get tasks_allLinks;

  /// No description provided for @tasks_linkBudget.
  ///
  /// In pl, this message translates to:
  /// **'💰 Budżet'**
  String get tasks_linkBudget;

  /// No description provided for @tasks_linkVendor.
  ///
  /// In pl, this message translates to:
  /// **'👨‍🍳 Dostawca'**
  String get tasks_linkVendor;

  /// No description provided for @tasks_noLink.
  ///
  /// In pl, this message translates to:
  /// **'Bez powiązania'**
  String get tasks_noLink;

  /// No description provided for @tasks_dragHere.
  ///
  /// In pl, this message translates to:
  /// **'Przeciągnij tutaj'**
  String get tasks_dragHere;

  /// No description provided for @tasks_deleteAction.
  ///
  /// In pl, this message translates to:
  /// **'🗑 Usuń'**
  String get tasks_deleteAction;

  /// No description provided for @tasks_nameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Zarezerwować salę'**
  String get tasks_nameHint;

  /// No description provided for @tasks_nameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Podaj nazwę zadania'**
  String get tasks_nameRequired;

  /// No description provided for @tasks_customGoal.
  ///
  /// In pl, this message translates to:
  /// **'➕ Inny cel (wpisz własny)'**
  String get tasks_customGoal;

  /// No description provided for @tasks_goalDone.
  ///
  /// In pl, this message translates to:
  /// **'🎯 Cel osiągnięty'**
  String get tasks_goalDone;

  /// No description provided for @tasks_goalDoneHint.
  ///
  /// In pl, this message translates to:
  /// **'np. „DJ znaleziony” — zaznacz, gdy cel jest już zrealizowany.'**
  String get tasks_goalDoneHint;

  /// No description provided for @tasks_showMore.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż więcej opcji'**
  String get tasks_showMore;

  /// No description provided for @tasks_customPerson.
  ///
  /// In pl, this message translates to:
  /// **'Własna osoba (opcjonalnie)'**
  String get tasks_customPerson;

  /// No description provided for @tasks_customPersonHint.
  ///
  /// In pl, this message translates to:
  /// **'Imię — nadpisuje powyższy wybór'**
  String get tasks_customPersonHint;

  /// No description provided for @tasks_startDate.
  ///
  /// In pl, this message translates to:
  /// **'Data rozpoczęcia'**
  String get tasks_startDate;

  /// No description provided for @tasks_endDate.
  ///
  /// In pl, this message translates to:
  /// **'Data zakończenia'**
  String get tasks_endDate;

  /// No description provided for @tasks_linkBudgetSwitch.
  ///
  /// In pl, this message translates to:
  /// **'💰 Powiąż z budżetem'**
  String get tasks_linkBudgetSwitch;

  /// No description provided for @tasks_linkBudgetHint.
  ///
  /// In pl, this message translates to:
  /// **'Tworzy/aktualizuje powiązany wpis w budżecie (referencja).'**
  String get tasks_linkBudgetHint;

  /// No description provided for @tasks_links.
  ///
  /// In pl, this message translates to:
  /// **'🔗 Powiązania'**
  String get tasks_links;

  /// No description provided for @tasks_linksHint.
  ///
  /// In pl, this message translates to:
  /// **'Powiąż zadanie z Dostawcą, Transportem, Noclegiem lub Muzyką. Możesz utworzyć nowy element — powstanie jako referencja (ten sam rekord widoczny w obu sekcjach), bez duplikowania danych.'**
  String get tasks_linksHint;

  /// No description provided for @tasks_createVendor.
  ///
  /// In pl, this message translates to:
  /// **'➕ Utwórz nowego dostawcę'**
  String get tasks_createVendor;

  /// No description provided for @tasks_createTransport.
  ///
  /// In pl, this message translates to:
  /// **'➕ Utwórz wpis transportu'**
  String get tasks_createTransport;

  /// No description provided for @tasks_createAccommodation.
  ///
  /// In pl, this message translates to:
  /// **'➕ Utwórz wpis noclegu'**
  String get tasks_createAccommodation;

  /// No description provided for @tasks_createSong.
  ///
  /// In pl, this message translates to:
  /// **'➕ Utwórz utwór'**
  String get tasks_createSong;

  /// No description provided for @tasks_song.
  ///
  /// In pl, this message translates to:
  /// **'Utwór'**
  String get tasks_song;

  /// No description provided for @tasks_costWithCurrency.
  ///
  /// In pl, this message translates to:
  /// **'💰 {amount} {currency}'**
  String tasks_costWithCurrency(String amount, String currency);

  /// No description provided for @schedule_tabDayPlan.
  ///
  /// In pl, this message translates to:
  /// **'Plan dnia'**
  String get schedule_tabDayPlan;

  /// No description provided for @schedule_tabChecklist.
  ///
  /// In pl, this message translates to:
  /// **'Checklista'**
  String get schedule_tabChecklist;

  /// ETYKIETA kategorii budzetowej dostawcy. Wartosc w bazie zostaje polska - patrz vendorBudgetCategoryLabel.
  ///
  /// In pl, this message translates to:
  /// **'Sala'**
  String get vendors_catVenue;

  /// No description provided for @vendors_catOutfit.
  ///
  /// In pl, this message translates to:
  /// **'Strój'**
  String get vendors_catOutfit;

  /// No description provided for @vendors_catDocs.
  ///
  /// In pl, this message translates to:
  /// **'Dokumenty'**
  String get vendors_catDocs;

  /// No description provided for @vendors_catDecor.
  ///
  /// In pl, this message translates to:
  /// **'Dekoracje'**
  String get vendors_catDecor;

  /// No description provided for @vendors_catOther.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get vendors_catOther;

  /// No description provided for @tasks_title.
  ///
  /// In pl, this message translates to:
  /// **'Zadania'**
  String get tasks_title;

  /// No description provided for @tasks_addButton.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj zadanie'**
  String get tasks_addButton;

  /// No description provided for @tasks_addedToast.
  ///
  /// In pl, this message translates to:
  /// **'Dodano zadanie'**
  String get tasks_addedToast;

  /// No description provided for @tasks_notNow.
  ///
  /// In pl, this message translates to:
  /// **'Nie teraz'**
  String get tasks_notNow;

  /// No description provided for @tasks_editAction.
  ///
  /// In pl, this message translates to:
  /// **'✏ Edytuj'**
  String get tasks_editAction;

  /// No description provided for @budget_expenseAddedShort.
  ///
  /// In pl, this message translates to:
  /// **'Dodano wydatek'**
  String get budget_expenseAddedShort;

  /// No description provided for @budget_addExpense.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wydatek'**
  String get budget_addExpense;

  /// No description provided for @budget_quickItems.
  ///
  /// In pl, this message translates to:
  /// **'⚡ Szybkie pozycje'**
  String get budget_quickItems;

  /// No description provided for @budget_filtersSort.
  ///
  /// In pl, this message translates to:
  /// **'Filtry i sortowanie'**
  String get budget_filtersSort;

  /// No description provided for @budget_allCategories.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie kategorie'**
  String get budget_allCategories;

  /// No description provided for @budget_offerLink.
  ///
  /// In pl, this message translates to:
  /// **'Link do oferty'**
  String get budget_offerLink;

  /// No description provided for @budget_roughAmount.
  ///
  /// In pl, this message translates to:
  /// **'Kwota orientacyjna'**
  String get budget_roughAmount;

  /// No description provided for @budget_addVariantShort.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wariant'**
  String get budget_addVariantShort;

  /// No description provided for @budget_cateringAddons.
  ///
  /// In pl, this message translates to:
  /// **'Dodatki cateringu (per osoba)'**
  String get budget_cateringAddons;

  /// No description provided for @budget_cateringSeparateAsk.
  ///
  /// In pl, this message translates to:
  /// **'Czy catering jest oddzielny?'**
  String get budget_cateringSeparateAsk;

  /// No description provided for @budget_menuAddons.
  ///
  /// In pl, this message translates to:
  /// **'Dodatki do menu (per osoba)'**
  String get budget_menuAddons;

  /// No description provided for @budget_menuAddonsAlcoholNote.
  ///
  /// In pl, this message translates to:
  /// **'Alkohol i napoje bezalkoholowe liczone są w osobnych sekcjach (Budżet → Alkohol / Napoje).'**
  String get budget_menuAddonsAlcoholNote;

  /// No description provided for @budget_includeInVenueCost.
  ///
  /// In pl, this message translates to:
  /// **'Wliczaj w koszt sali'**
  String get budget_includeInVenueCost;

  /// No description provided for @checklist_newItem.
  ///
  /// In pl, this message translates to:
  /// **'Nowa pozycja — {category}'**
  String checklist_newItem(String category);

  /// No description provided for @checklist_addedToast.
  ///
  /// In pl, this message translates to:
  /// **'Dodano: {text}'**
  String checklist_addedToast(String text);

  /// No description provided for @checklist_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak pozycji.'**
  String get checklist_empty;

  /// No description provided for @schedule_addEvent.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wydarzenie'**
  String get schedule_addEvent;

  /// No description provided for @roomplan_roomDimsLabel.
  ///
  /// In pl, this message translates to:
  /// **'Wymiary sali (m)'**
  String get roomplan_roomDimsLabel;

  /// No description provided for @roomplan_addElementSheet.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj element sali'**
  String get roomplan_addElementSheet;

  /// No description provided for @roomplan_autoSizeHint.
  ///
  /// In pl, this message translates to:
  /// **'0 = rozmiar automatyczny wg liczby miejsc.'**
  String get roomplan_autoSizeHint;

  /// No description provided for @tables_assignTo.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz do: {table}'**
  String tables_assignTo(String table);

  /// No description provided for @vendors_title.
  ///
  /// In pl, this message translates to:
  /// **'Dostawcy'**
  String get vendors_title;

  /// No description provided for @vendors_addButton.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj dostawcę'**
  String get vendors_addButton;

  /// No description provided for @vendors_addedToast.
  ///
  /// In pl, this message translates to:
  /// **'Dodano dostawcę'**
  String get vendors_addedToast;

  /// No description provided for @vendors_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć dostawcę?'**
  String get vendors_deleteTitle;

  /// No description provided for @vendors_deleteKeepEntry.
  ///
  /// In pl, this message translates to:
  /// **'Usuń, zostaw wpis'**
  String get vendors_deleteKeepEntry;

  /// No description provided for @vendors_deletedToast.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto dostawcę'**
  String get vendors_deletedToast;

  /// No description provided for @vendors_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak dostawców.'**
  String get vendors_empty;

  /// No description provided for @vendors_contact.
  ///
  /// In pl, this message translates to:
  /// **'👤 {name}'**
  String vendors_contact(String name);

  /// No description provided for @vendors_price.
  ///
  /// In pl, this message translates to:
  /// **'Cena: {amount}'**
  String vendors_price(String amount);

  /// No description provided for @vendors_installments.
  ///
  /// In pl, this message translates to:
  /// **'💵 Raty / płatności'**
  String get vendors_installments;

  /// No description provided for @vendors_noInstallments.
  ///
  /// In pl, this message translates to:
  /// **'Brak rat.'**
  String get vendors_noInstallments;

  /// No description provided for @vendors_toPay.
  ///
  /// In pl, this message translates to:
  /// **'Do zapłaty'**
  String get vendors_toPay;

  /// No description provided for @vendors_paid.
  ///
  /// In pl, this message translates to:
  /// **'Zapłacona'**
  String get vendors_paid;

  /// No description provided for @vendors_linkBudget.
  ///
  /// In pl, this message translates to:
  /// **'💰 Powiąż z budżetem'**
  String get vendors_linkBudget;

  /// No description provided for @vendors_linkBudgetHint.
  ///
  /// In pl, this message translates to:
  /// **'Tworzy/aktualizuje powiązany wpis w budżecie (referencja).'**
  String get vendors_linkBudgetHint;

  /// No description provided for @transport_title.
  ///
  /// In pl, this message translates to:
  /// **'Transport'**
  String get transport_title;

  /// No description provided for @transport_addVehicle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pojazd'**
  String get transport_addVehicle;

  /// No description provided for @transport_vehicleAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano pojazd'**
  String get transport_vehicleAdded;

  /// No description provided for @transport_noGuestsAvailable.
  ///
  /// In pl, this message translates to:
  /// **'Brak dostępnych gości'**
  String get transport_noGuestsAvailable;

  /// No description provided for @transport_showOwn.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż transport własny'**
  String get transport_showOwn;

  /// No description provided for @transport_seatsOf.
  ///
  /// In pl, this message translates to:
  /// **'{used}/{total} miejsc'**
  String transport_seatsOf(int used, int total);

  /// No description provided for @transport_ownHeader.
  ///
  /// In pl, this message translates to:
  /// **'🚶 Transport własny'**
  String get transport_ownHeader;

  /// No description provided for @transport_ownEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości z własnym dojazdem.'**
  String get transport_ownEmpty;

  /// No description provided for @transport_addGuest.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj gościa'**
  String get transport_addGuest;

  /// No description provided for @transport_unassignedHeader.
  ///
  /// In pl, this message translates to:
  /// **'❓ Bez przydziału ({count})'**
  String transport_unassignedHeader(int count);

  /// No description provided for @transport_allAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Wszyscy goście mają transport.'**
  String get transport_allAssigned;

  /// No description provided for @transport_internalHeader.
  ///
  /// In pl, this message translates to:
  /// **'🚕 Transport wewnętrzny'**
  String get transport_internalHeader;

  /// No description provided for @transport_internalEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak. Dodaj Bolt / Taxi / inny.'**
  String get transport_internalEmpty;

  /// No description provided for @transport_showInSchedule.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż gościom w harmonogramie'**
  String get transport_showInSchedule;

  /// No description provided for @accommodation_title.
  ///
  /// In pl, this message translates to:
  /// **'Noclegi'**
  String get accommodation_title;

  /// No description provided for @accommodation_deleteHotelTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć hotel?'**
  String get accommodation_deleteHotelTitle;

  /// No description provided for @accommodation_guestsNeeding.
  ///
  /// In pl, this message translates to:
  /// **'Goście potrzebujący noclegu'**
  String get accommodation_guestsNeeding;

  /// No description provided for @accommodation_hotels.
  ///
  /// In pl, this message translates to:
  /// **'Hotele i miejsca noclegowe'**
  String get accommodation_hotels;

  /// No description provided for @accommodation_addHotel.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj hotel'**
  String get accommodation_addHotel;

  /// No description provided for @accommodation_noHotel.
  ///
  /// In pl, this message translates to:
  /// **'Brak hotelu'**
  String get accommodation_noHotel;

  /// No description provided for @accommodation_onSite.
  ///
  /// In pl, this message translates to:
  /// **'🏰 W kompleksie'**
  String get accommodation_onSite;

  /// No description provided for @accommodation_onSiteSwitch.
  ///
  /// In pl, this message translates to:
  /// **'🏰 Hotel w kompleksie wesela'**
  String get accommodation_onSiteSwitch;

  /// No description provided for @vendors_paidRemainingTotal.
  ///
  /// In pl, this message translates to:
  /// **'Zapłacono: {paid} · Pozostało: {remaining} · Suma: {total}'**
  String vendors_paidRemainingTotal(
    String paid,
    String remaining,
    String total,
  );

  /// No description provided for @analytics_title.
  ///
  /// In pl, this message translates to:
  /// **'Analityka'**
  String get analytics_title;

  /// No description provided for @analytics_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak danych do analizy'**
  String get analytics_empty;

  /// No description provided for @analytics_emptyHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj gości i wydatki, żeby zobaczyć analitykę — potwierdzenia obecności, rozkład kosztów, postęp płatności, menu i diety.'**
  String get analytics_emptyHint;

  /// No description provided for @analytics_budgetForecast.
  ///
  /// In pl, this message translates to:
  /// **'Prognoza końcowego budżetu'**
  String get analytics_budgetForecast;

  /// No description provided for @analytics_costPerGuest.
  ///
  /// In pl, this message translates to:
  /// **'Koszt per gość'**
  String get analytics_costPerGuest;

  /// No description provided for @dashboard_availableTiles.
  ///
  /// In pl, this message translates to:
  /// **'Dostępne kafelki'**
  String get dashboard_availableTiles;

  /// No description provided for @rsvp_title.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenia'**
  String get rsvp_title;

  /// No description provided for @rsvp_allTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie RSVP'**
  String get rsvp_allTitle;

  /// No description provided for @rsvp_allHint.
  ///
  /// In pl, this message translates to:
  /// **'Lista wszystkich odpowiedzi oraz kody QR i linki dla gości.'**
  String get rsvp_allHint;

  /// No description provided for @rsvp_qrError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd generowania QR: {error}'**
  String rsvp_qrError(String error);

  /// No description provided for @rsvp_quotedMessage.
  ///
  /// In pl, this message translates to:
  /// **'„{message}”'**
  String rsvp_quotedMessage(String message);

  /// No description provided for @rsvp_deleteEntry.
  ///
  /// In pl, this message translates to:
  /// **'Usuń wpis'**
  String get rsvp_deleteEntry;

  /// No description provided for @rsvp_deleteEntryTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wpis RSVP?'**
  String get rsvp_deleteEntryTitle;

  /// No description provided for @rsvp_clearAll.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść wszystkie'**
  String get rsvp_clearAll;

  /// No description provided for @rsvp_clear.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść'**
  String get rsvp_clear;

  /// No description provided for @rsvp_clearAllTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyścić wszystkie potwierdzenia?'**
  String get rsvp_clearAllTitle;

  /// No description provided for @rsvp_unmatched.
  ///
  /// In pl, this message translates to:
  /// **'Nierozpoznane potwierdzenia ({count})'**
  String rsvp_unmatched(int count);

  /// No description provided for @rsvp_guestsCount.
  ///
  /// In pl, this message translates to:
  /// **'Goście ({count})'**
  String rsvp_guestsCount(int count);

  /// No description provided for @rsvp_noGuestsInCategory.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości w tej kategorii.'**
  String get rsvp_noGuestsInCategory;

  /// No description provided for @rsvp_assignToGuest.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz do gościa…'**
  String get rsvp_assignToGuest;

  /// No description provided for @games_title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne gry'**
  String get games_title;

  /// No description provided for @games_activeForGuests.
  ///
  /// In pl, this message translates to:
  /// **'Gra aktywna dla gości'**
  String get games_activeForGuests;

  /// No description provided for @games_quizActiveForGuests.
  ///
  /// In pl, this message translates to:
  /// **'Quiz aktywny dla gości'**
  String get games_quizActiveForGuests;

  /// No description provided for @games_ranking.
  ///
  /// In pl, this message translates to:
  /// **'🏆 Ranking gości'**
  String get games_ranking;

  /// No description provided for @games_addAnswer.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj odpowiedź'**
  String get games_addAnswer;

  /// No description provided for @games_scoreOf.
  ///
  /// In pl, this message translates to:
  /// **'{score}/{total}'**
  String games_scoreOf(int score, int total);

  /// No description provided for @games_bingo.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne Bingo'**
  String get games_bingo;

  /// No description provided for @games_quiz.
  ///
  /// In pl, this message translates to:
  /// **'Quiz o Parze Młodej'**
  String get games_quiz;

  /// No description provided for @games_trueFalse.
  ///
  /// In pl, this message translates to:
  /// **'Prawda czy Fałsz'**
  String get games_trueFalse;

  /// No description provided for @games_photoGuess.
  ///
  /// In pl, this message translates to:
  /// **'Zgadnij zdjęcie'**
  String get games_photoGuess;

  /// No description provided for @games_wheel.
  ///
  /// In pl, this message translates to:
  /// **'Koło fortuny'**
  String get games_wheel;

  /// No description provided for @games_photoChallenge.
  ///
  /// In pl, this message translates to:
  /// **'Foto-wyzwania'**
  String get games_photoChallenge;

  /// No description provided for @games_photoContest.
  ///
  /// In pl, this message translates to:
  /// **'Konkursy foto'**
  String get games_photoContest;

  /// No description provided for @contest_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak konkursów'**
  String get contest_empty;

  /// No description provided for @contest_emptyHint.
  ///
  /// In pl, this message translates to:
  /// **'Załóż pierwszy konkurs fotograficzny — goście będą zgłaszać zdjęcia i głosować.'**
  String get contest_emptyHint;

  /// No description provided for @contest_add.
  ///
  /// In pl, this message translates to:
  /// **'Nowy konkurs'**
  String get contest_add;

  /// No description provided for @contest_edit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj konkurs'**
  String get contest_edit;

  /// No description provided for @contest_name.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa konkursu'**
  String get contest_name;

  /// No description provided for @contest_subcategories.
  ///
  /// In pl, this message translates to:
  /// **'Podkategorie'**
  String get contest_subcategories;

  /// No description provided for @contest_addSubcategory.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj podkategorię'**
  String get contest_addSubcategory;

  /// No description provided for @contest_subcategoryLabel.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa podkategorii'**
  String get contest_subcategoryLabel;

  /// No description provided for @contest_subcategoriesEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj co najmniej jedną podkategorię.'**
  String get contest_subcategoriesEmpty;

  /// No description provided for @contest_rankingSize.
  ///
  /// In pl, this message translates to:
  /// **'Rozmiar rankingu'**
  String get contest_rankingSize;

  /// No description provided for @contest_revealMode.
  ///
  /// In pl, this message translates to:
  /// **'Ujawnienie wyników'**
  String get contest_revealMode;

  /// No description provided for @contest_revealManual.
  ///
  /// In pl, this message translates to:
  /// **'Ręczne'**
  String get contest_revealManual;

  /// No description provided for @contest_revealAuto.
  ///
  /// In pl, this message translates to:
  /// **'Automatyczne po dacie'**
  String get contest_revealAuto;

  /// No description provided for @contest_revealDate.
  ///
  /// In pl, this message translates to:
  /// **'Data ujawnienia'**
  String get contest_revealDate;

  /// No description provided for @contest_active.
  ///
  /// In pl, this message translates to:
  /// **'Konkurs aktywny dla gości'**
  String get contest_active;

  /// No description provided for @contest_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć konkurs?'**
  String get contest_deleteTitle;

  /// No description provided for @contest_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Konkurs, jego podkategorie oraz powiązane zgłoszenia i głosy gości znikną ze strony gości. Dane zgłoszeń w Firestore NIE są kasowane automatycznie.'**
  String get contest_deleteBody;

  /// No description provided for @contest_subcategoriesCount.
  ///
  /// In pl, this message translates to:
  /// **'{count} {count, plural, =1{podkategoria} few{podkategorie} other{podkategorii}}'**
  String contest_subcategoriesCount(int count);

  /// No description provided for @contest_results.
  ///
  /// In pl, this message translates to:
  /// **'Wyniki'**
  String get contest_results;

  /// No description provided for @contest_noGuestToken.
  ///
  /// In pl, this message translates to:
  /// **'Brak tokenu strefy gości dla tego wesela — otwórz najpierw Ustawienia → Goście.'**
  String get contest_noGuestToken;

  /// No description provided for @contest_ranking.
  ///
  /// In pl, this message translates to:
  /// **'Ranking głosów gości'**
  String get contest_ranking;

  /// No description provided for @contest_rankingHint.
  ///
  /// In pl, this message translates to:
  /// **'Policzone z {count} oddanych głosów. Punkty widzisz tylko Ty — goście zobaczą je dopiero po ujawnieniu.'**
  String contest_rankingHint(int count);

  /// No description provided for @contest_noVotesYet.
  ///
  /// In pl, this message translates to:
  /// **'Jeszcze nikt nie zagłosował.'**
  String get contest_noVotesYet;

  /// No description provided for @contest_points.
  ///
  /// In pl, this message translates to:
  /// **'{points} pkt'**
  String contest_points(int points);

  /// No description provided for @contest_coupleChoice.
  ///
  /// In pl, this message translates to:
  /// **'Wybór Pary Młodej'**
  String get contest_coupleChoice;

  /// No description provided for @contest_coupleChoiceHint.
  ///
  /// In pl, this message translates to:
  /// **'Kliknij zdjęcie, aby wskazać 1./2./3. miejsce albo wyróżnienie (max 2) — niezależnie od głosów gości.'**
  String get contest_coupleChoiceHint;

  /// No description provided for @contest_couplePickTitle.
  ///
  /// In pl, this message translates to:
  /// **'Werdykt Pary Młodej'**
  String get contest_couplePickTitle;

  /// No description provided for @contest_honorableMention.
  ///
  /// In pl, this message translates to:
  /// **'Wyróżnienie'**
  String get contest_honorableMention;

  /// No description provided for @contest_honorableFull.
  ///
  /// In pl, this message translates to:
  /// **'Masz już 2 wyróżnienia — najpierw cofnij jedno.'**
  String get contest_honorableFull;

  /// No description provided for @contest_revealNow.
  ///
  /// In pl, this message translates to:
  /// **'Ujawnij teraz'**
  String get contest_revealNow;

  /// No description provided for @contest_updateResults.
  ///
  /// In pl, this message translates to:
  /// **'Zaktualizuj wyniki'**
  String get contest_updateResults;

  /// No description provided for @contest_revealed.
  ///
  /// In pl, this message translates to:
  /// **'Wyniki ujawnione ✓'**
  String get contest_revealed;

  /// No description provided for @contest_revealedBadge.
  ///
  /// In pl, this message translates to:
  /// **'Ujawnione'**
  String get contest_revealedBadge;

  /// No description provided for @quiz_addQuestion.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pytanie'**
  String get quiz_addQuestion;

  /// No description provided for @quiz_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak pytań'**
  String get quiz_empty;

  /// No description provided for @quiz_emptyHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj własne pytania lub zacznij od gotowych przykładów.'**
  String get quiz_emptyHint;

  /// No description provided for @quiz_examplesAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano przykładowe pytania'**
  String get quiz_examplesAdded;

  /// No description provided for @quiz_addExamples.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj przykładowe pytania'**
  String get quiz_addExamples;

  /// No description provided for @quiz_saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano pytanie'**
  String get quiz_saved;

  /// No description provided for @quiz_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano pytanie'**
  String get quiz_added;

  /// No description provided for @quiz_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć pytanie?'**
  String get quiz_deleteTitle;

  /// No description provided for @quiz_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{text}”?'**
  String quiz_deleteBody(String text);

  /// No description provided for @quiz_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto pytanie'**
  String get quiz_deleted;

  /// No description provided for @quiz_hardest.
  ///
  /// In pl, this message translates to:
  /// **'📊 Najtrudniejsze pytania'**
  String get quiz_hardest;

  /// No description provided for @quiz_numbered.
  ///
  /// In pl, this message translates to:
  /// **'{index}. {text}'**
  String quiz_numbered(int index, String text);

  /// No description provided for @tf_addStatement.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj stwierdzenie'**
  String get tf_addStatement;

  /// No description provided for @tf_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak stwierdzeń'**
  String get tf_empty;

  /// No description provided for @tf_emptyHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj własne stwierdzenia lub zacznij od gotowych przykładów.'**
  String get tf_emptyHint;

  /// No description provided for @tf_examplesAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano przykładowe stwierdzenia'**
  String get tf_examplesAdded;

  /// No description provided for @tf_addExamples.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj przykładowe'**
  String get tf_addExamples;

  /// No description provided for @tf_saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano stwierdzenie'**
  String get tf_saved;

  /// No description provided for @tf_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano stwierdzenie'**
  String get tf_added;

  /// No description provided for @tf_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć stwierdzenie?'**
  String get tf_deleteTitle;

  /// No description provided for @tf_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto stwierdzenie'**
  String get tf_deleted;

  /// No description provided for @photoGuess_add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj zdjęcie z pytaniem'**
  String get photoGuess_add;

  /// No description provided for @photoGuess_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak zdjęć'**
  String get photoGuess_empty;

  /// No description provided for @photoGuess_saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano zdjęcie'**
  String get photoGuess_saved;

  /// No description provided for @photoGuess_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano zdjęcie'**
  String get photoGuess_added;

  /// No description provided for @photoGuess_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć zdjęcie?'**
  String get photoGuess_deleteTitle;

  /// No description provided for @photoGuess_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć pytanie „{text}”?'**
  String photoGuess_deleteBody(String text);

  /// No description provided for @photoGuess_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto zdjęcie'**
  String get photoGuess_deleted;

  /// No description provided for @photoGuess_hardest.
  ///
  /// In pl, this message translates to:
  /// **'📊 Najtrudniejsze zdjęcia'**
  String get photoGuess_hardest;

  /// No description provided for @photoGuess_noPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Brak zdjęcia'**
  String get photoGuess_noPhoto;

  /// No description provided for @photoGuess_fromGallery.
  ///
  /// In pl, this message translates to:
  /// **'Z galerii'**
  String get photoGuess_fromGallery;

  /// No description provided for @photoChallenge_add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wyzwanie'**
  String get photoChallenge_add;

  /// No description provided for @photoChallenge_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wyzwań'**
  String get photoChallenge_empty;

  /// No description provided for @photoChallenge_emptyHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj własne wyzwania lub zacznij od gotowych przykładów.'**
  String get photoChallenge_emptyHint;

  /// No description provided for @photoChallenge_examplesAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano przykładowe wyzwania'**
  String get photoChallenge_examplesAdded;

  /// No description provided for @photoChallenge_addExamples.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj przykładowe'**
  String get photoChallenge_addExamples;

  /// No description provided for @photoChallenge_saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano wyzwanie'**
  String get photoChallenge_saved;

  /// No description provided for @photoChallenge_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano wyzwanie'**
  String get photoChallenge_added;

  /// No description provided for @photoChallenge_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wyzwanie?'**
  String get photoChallenge_deleteTitle;

  /// No description provided for @photoChallenge_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto wyzwanie'**
  String get photoChallenge_deleted;

  /// No description provided for @photoChallenge_points.
  ///
  /// In pl, this message translates to:
  /// **'⭐ {points} pkt'**
  String photoChallenge_points(int points);

  /// No description provided for @photoChallenge_photoDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto zdjęcie'**
  String get photoChallenge_photoDeleted;

  /// No description provided for @photoChallenge_text.
  ///
  /// In pl, this message translates to:
  /// **'Treść wyzwania'**
  String get photoChallenge_text;

  /// No description provided for @photoChallenge_textHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Zrób selfie z Parą Młodą'**
  String get photoChallenge_textHint;

  /// No description provided for @photoChallenge_textRequired.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz treść wyzwania'**
  String get photoChallenge_textRequired;

  /// No description provided for @common_filtersSort.
  ///
  /// In pl, this message translates to:
  /// **'Filtry i sortowanie'**
  String get common_filtersSort;

  /// No description provided for @common_pdfError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd generowania PDF: {error}'**
  String common_pdfError(String error);

  /// No description provided for @common_exportPdf.
  ///
  /// In pl, this message translates to:
  /// **'Eksport PDF'**
  String get common_exportPdf;

  /// No description provided for @common_sortBy.
  ///
  /// In pl, this message translates to:
  /// **'Sortuj:'**
  String get common_sortBy;

  /// No description provided for @common_view.
  ///
  /// In pl, this message translates to:
  /// **'Widok:'**
  String get common_view;

  /// No description provided for @gallery_title.
  ///
  /// In pl, this message translates to:
  /// **'Galeria & QR'**
  String get gallery_title;

  /// No description provided for @gallery_readError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd odczytu galerii: {error}'**
  String gallery_readError(String error);

  /// No description provided for @gallery_usage.
  ///
  /// In pl, this message translates to:
  /// **'Wykorzystano: {used} / 25 GB'**
  String gallery_usage(String used);

  /// No description provided for @gallery_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak plików w galerii.'**
  String get gallery_empty;

  /// No description provided for @gallery_video.
  ///
  /// In pl, this message translates to:
  /// **'▶ film'**
  String get gallery_video;

  /// No description provided for @gallery_uploadedBy.
  ///
  /// In pl, this message translates to:
  /// **'📷 {name}'**
  String gallery_uploadedBy(String name);

  /// No description provided for @gallery_format.
  ///
  /// In pl, this message translates to:
  /// **'Format:'**
  String get gallery_format;

  /// No description provided for @gallery_pdfError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd PDF: {error}'**
  String gallery_pdfError(String error);

  /// No description provided for @gallery_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć plik z galerii?'**
  String get gallery_deleteTitle;

  /// No description provided for @gallery_deleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Zniknie z galerii gości. Oryginał pozostaje w Cloudinary.'**
  String get gallery_deleteBody;

  /// No description provided for @gallery_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto plik'**
  String get gallery_deleted;

  /// No description provided for @gifts_thanked.
  ///
  /// In pl, this message translates to:
  /// **'Podziękowano'**
  String get gifts_thanked;

  /// No description provided for @gifts_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak upominków.'**
  String get gifts_empty;

  /// No description provided for @gifts_addPerson.
  ///
  /// In pl, this message translates to:
  /// **'+ Dodaj osobę…'**
  String get gifts_addPerson;

  /// No description provided for @gifts_wishlistHint.
  ///
  /// In pl, this message translates to:
  /// **'Lista życzeń od Pary Młodej. Zaznaczone propozycje są widoczne dla gości na stronie harmonogramu.'**
  String get gifts_wishlistHint;

  /// No description provided for @gifts_showToGuests.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż gościom na stronie harmonogramu'**
  String get gifts_showToGuests;

  /// No description provided for @keepsakes_title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne pamiątki'**
  String get keepsakes_title;

  /// No description provided for @keepsakes_guestbook.
  ///
  /// In pl, this message translates to:
  /// **'Księga gości'**
  String get keepsakes_guestbook;

  /// No description provided for @keepsakes_advices.
  ///
  /// In pl, this message translates to:
  /// **'Rady dla Pary Młodej'**
  String get keepsakes_advices;

  /// No description provided for @keepsakes_timeCapsule.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła czasu'**
  String get keepsakes_timeCapsule;

  /// No description provided for @keepsakes_guestMap.
  ///
  /// In pl, this message translates to:
  /// **'Mapa gości'**
  String get keepsakes_guestMap;

  /// No description provided for @advices_filterByCategory.
  ///
  /// In pl, this message translates to:
  /// **'Filtruj po kategorii'**
  String get advices_filterByCategory;

  /// No description provided for @advices_slideshow.
  ///
  /// In pl, this message translates to:
  /// **'Pokaz slajdów'**
  String get advices_slideshow;

  /// No description provided for @advices_labelCount.
  ///
  /// In pl, this message translates to:
  /// **'{label} ({count})'**
  String advices_labelCount(String label, int count);

  /// No description provided for @advices_delete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń radę'**
  String get advices_delete;

  /// No description provided for @advices_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć radę?'**
  String get advices_deleteTitle;

  /// No description provided for @advices_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto radę'**
  String get advices_deleted;

  /// No description provided for @advices_header.
  ///
  /// In pl, this message translates to:
  /// **'💌 Rady dla Pary Młodej'**
  String get advices_header;

  /// No description provided for @advices_position.
  ///
  /// In pl, this message translates to:
  /// **'{index} / {total}'**
  String advices_position(int index, int total);

  /// No description provided for @advices_quoted.
  ///
  /// In pl, this message translates to:
  /// **'„{message}”'**
  String advices_quoted(String message);

  /// No description provided for @guestbook_deleteEntry.
  ///
  /// In pl, this message translates to:
  /// **'Usuń wpis'**
  String get guestbook_deleteEntry;

  /// No description provided for @guestbook_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wpis?'**
  String get guestbook_deleteTitle;

  /// No description provided for @guestbook_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto wpis'**
  String get guestbook_deleted;

  /// No description provided for @capsule_exportOpen.
  ///
  /// In pl, this message translates to:
  /// **'Eksport otwartych do PDF'**
  String get capsule_exportOpen;

  /// No description provided for @capsule_sealedUntil.
  ///
  /// In pl, this message translates to:
  /// **'🔒 Zapieczętowane do {date}'**
  String capsule_sealedUntil(String date);

  /// No description provided for @capsule_hasPhoto.
  ///
  /// In pl, this message translates to:
  /// **'📷 zawiera zdjęcie'**
  String get capsule_hasPhoto;

  /// No description provided for @capsule_deleteMessage.
  ///
  /// In pl, this message translates to:
  /// **'Usuń wiadomość'**
  String get capsule_deleteMessage;

  /// No description provided for @capsule_openAllTitle.
  ///
  /// In pl, this message translates to:
  /// **'Otworzyć wszystko teraz?'**
  String get capsule_openAllTitle;

  /// No description provided for @capsule_openAll.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz wszystko'**
  String get capsule_openAll;

  /// No description provided for @capsule_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wiadomość?'**
  String get capsule_deleteTitle;

  /// No description provided for @capsule_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto wiadomość'**
  String get capsule_deleted;

  /// No description provided for @guestMap_addManually.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj gościa ręcznie'**
  String get guestMap_addManually;

  /// No description provided for @guestMap_kmFromVenue.
  ///
  /// In pl, this message translates to:
  /// **'{km} km od miejsca wesela'**
  String guestMap_kmFromVenue(int km);

  /// No description provided for @guestMap_notLocated.
  ///
  /// In pl, this message translates to:
  /// **'⚠ Niezlokalizowany — uzupełnij miejscowość'**
  String get guestMap_notLocated;

  /// No description provided for @guestMap_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wpis?'**
  String get guestMap_deleteTitle;

  /// No description provided for @guestMap_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto wpis'**
  String get guestMap_deleted;

  /// No description provided for @guestMap_name.
  ///
  /// In pl, this message translates to:
  /// **'Imię'**
  String get guestMap_name;

  /// No description provided for @guestMap_city.
  ///
  /// In pl, this message translates to:
  /// **'Miejscowość'**
  String get guestMap_city;

  /// No description provided for @guestMap_cityHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Kraków'**
  String get guestMap_cityHint;

  /// No description provided for @guestMap_greeting.
  ///
  /// In pl, this message translates to:
  /// **'Pozdrowienie (opcjonalnie)'**
  String get guestMap_greeting;

  /// No description provided for @music_title.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka'**
  String get music_title;

  /// No description provided for @music_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano utwór'**
  String get music_added;

  /// No description provided for @music_qrForGuests.
  ///
  /// In pl, this message translates to:
  /// **'Kod QR dla gości'**
  String get music_qrForGuests;

  /// No description provided for @music_unmatched.
  ///
  /// In pl, this message translates to:
  /// **'⚠ Niedopasowane / do weryfikacji ({count})'**
  String music_unmatched(int count);

  /// No description provided for @music_list.
  ///
  /// In pl, this message translates to:
  /// **'Lista utworów ({count})'**
  String music_list(int count);

  /// No description provided for @music_emptyFiltered.
  ///
  /// In pl, this message translates to:
  /// **'Brak utworów spełniających kryteria.'**
  String get music_emptyFiltered;

  /// No description provided for @music_searchDeezer.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj utworu (Deezer)…'**
  String get music_searchDeezer;

  /// No description provided for @music_addManually.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj ręcznie'**
  String get music_addManually;

  /// No description provided for @music_deezerError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się połączyć z Deezer (sprawdź internet/CORS).'**
  String get music_deezerError;

  /// No description provided for @music_deezerEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono w Deezer.'**
  String get music_deezerEmpty;

  /// No description provided for @music_addedTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dodano: {title}'**
  String music_addedTitle(String title);

  /// No description provided for @music_addedUnmatched.
  ///
  /// In pl, this message translates to:
  /// **'Dodano jako niedopasowany'**
  String get music_addedUnmatched;

  /// No description provided for @music_addToVerify.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj „{query}” do weryfikacji'**
  String music_addToVerify(String query);

  /// No description provided for @music_allMoments.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie momenty'**
  String get music_allMoments;

  /// No description provided for @music_fromGuest.
  ///
  /// In pl, this message translates to:
  /// **'👤 od gościa'**
  String get music_fromGuest;

  /// No description provided for @music_addOwnMoment.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj własny moment'**
  String get music_addOwnMoment;

  /// No description provided for @music_outsideList.
  ///
  /// In pl, this message translates to:
  /// **'spoza listy'**
  String get music_outsideList;

  /// No description provided for @music_removeMoment.
  ///
  /// In pl, this message translates to:
  /// **'Usuń moment z listy'**
  String get music_removeMoment;

  /// No description provided for @music_noSongAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Brak utworu — dodaj lub przypisz.'**
  String get music_noSongAssigned;

  /// No description provided for @music_addNew.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj nowy'**
  String get music_addNew;

  /// No description provided for @music_assignmentRemoved.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto przypisanie'**
  String get music_assignmentRemoved;

  /// No description provided for @music_removeAssignment.
  ///
  /// In pl, this message translates to:
  /// **'Usuń przypisanie'**
  String get music_removeAssignment;

  /// No description provided for @music_newMoment.
  ///
  /// In pl, this message translates to:
  /// **'Nowy moment'**
  String get music_newMoment;

  /// No description provided for @music_momentName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa momentu'**
  String get music_momentName;

  /// No description provided for @music_momentNameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Poprawiny'**
  String get music_momentNameHint;

  /// No description provided for @music_momentExists.
  ///
  /// In pl, this message translates to:
  /// **'Taki moment już istnieje'**
  String get music_momentExists;

  /// No description provided for @music_momentAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano moment: {name}'**
  String music_momentAdded(String name);

  /// No description provided for @music_removeMomentTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć moment z listy?'**
  String get music_removeMomentTitle;

  /// No description provided for @music_removeMomentBody.
  ///
  /// In pl, this message translates to:
  /// **'Moment „{label}\" zniknie z listy. Przypisane utwory NIE zostaną usunięte — pokażą się jako „spoza listy\", możesz je przypisać ponownie lub odłączyć.'**
  String music_removeMomentBody(String label);

  /// No description provided for @music_emptyAddFirst.
  ///
  /// In pl, this message translates to:
  /// **'Brak utworów na liście. Dodaj najpierw utwór.'**
  String get music_emptyAddFirst;

  /// No description provided for @music_assignTo.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz do: {label}'**
  String music_assignTo(String label);

  /// No description provided for @music_assignedTo.
  ///
  /// In pl, this message translates to:
  /// **'Przypisano utwór do: {label}'**
  String music_assignedTo(String label);

  /// No description provided for @music_nothingToExport.
  ///
  /// In pl, this message translates to:
  /// **'Brak utworów do eksportu'**
  String get music_nothingToExport;

  /// No description provided for @music_exportCsv.
  ///
  /// In pl, this message translates to:
  /// **'Eksport CSV'**
  String get music_exportCsv;

  /// No description provided for @music_exportText.
  ///
  /// In pl, this message translates to:
  /// **'Eksport tekstowy'**
  String get music_exportText;

  /// No description provided for @music_copiedToClipboard.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano do schowka'**
  String get music_copiedToClipboard;

  /// No description provided for @music_import.
  ///
  /// In pl, this message translates to:
  /// **'Import utworów'**
  String get music_import;

  /// No description provided for @music_pasteHere.
  ///
  /// In pl, this message translates to:
  /// **'Wklej tutaj…'**
  String get music_pasteHere;

  /// No description provided for @music_nothingRecognized.
  ///
  /// In pl, this message translates to:
  /// **'Nie rozpoznano utworów'**
  String get music_nothingRecognized;

  /// No description provided for @music_imported.
  ///
  /// In pl, this message translates to:
  /// **'Zaimportowano {count} utworów'**
  String music_imported(int count);

  /// No description provided for @music_addSongManually.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj utwór ręcznie'**
  String get music_addSongManually;

  /// No description provided for @music_songTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tytuł'**
  String get music_songTitle;

  /// No description provided for @music_searchInDeezer.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj w Deezer…'**
  String get music_searchInDeezer;

  /// No description provided for @music_nothingFound.
  ///
  /// In pl, this message translates to:
  /// **'Nic nie znaleziono (możesz dodać ręcznie poniżej).'**
  String get music_nothingFound;

  /// No description provided for @music_orAddManually.
  ///
  /// In pl, this message translates to:
  /// **'…lub dodaj ręcznie'**
  String get music_orAddManually;

  /// No description provided for @guestMap_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście zaznaczają, skąd przyjeżdżają. Pokaż im kod QR lub wyślij link.'**
  String get guestMap_txt1;

  /// No description provided for @guestMap_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Brak wpisów. Udostępnij gościom kod QR z zakładki „Strona dla gości\".'**
  String get guestMap_txt2;

  /// No description provided for @guestMap_txt3.
  ///
  /// In pl, this message translates to:
  /// **'Brak zlokalizowanych gości. Pinezki pojawią się po wpisach gości lub ręcznym dodaniu z miejscowością.'**
  String get guestMap_txt3;

  /// No description provided for @guestMap_txt4.
  ///
  /// In pl, this message translates to:
  /// **'Aby policzyć dystans najdalszego gościa, ustaw „Miejsce wesela\" w Konfiguracji (sekcja Ustawienia).'**
  String get guestMap_txt4;

  /// No description provided for @capsule_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście zostawią wiadomości do otwarcia w przyszłości (np. w rocznicę). Pokaż im kod QR lub wyślij link.'**
  String get capsule_txt1;

  /// No description provided for @capsule_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Brak wiadomości. Udostępnij gościom kod QR z zakładki „Strona dla gości\".'**
  String get capsule_txt2;

  /// No description provided for @capsule_txt3.
  ///
  /// In pl, this message translates to:
  /// **'Zobaczysz treść także zapieczętowanych wiadomości, zanim nadejdzie ich data. To tylko podgląd dla Ciebie — nie zmienia dat otwarcia ani tego, co widzą inni. Najwięcej radości daje jednak czekanie 💙'**
  String get capsule_txt3;

  /// No description provided for @guestbook_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście zostawią życzenia i wiadomości dla Pary Młodej (z opcjonalnym zdjęciem). Pokaż im kod QR lub wyślij link.'**
  String get guestbook_txt1;

  /// No description provided for @guestbook_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Brak wpisów. Udostępnij gościom kod QR z zakładki „Strona dla gości\", aby zaczęli się wpisywać.'**
  String get guestbook_txt2;

  /// No description provided for @advices_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście zostawią rady i złote myśli o małżeństwie. Pokaż im kod QR lub wyślij link.'**
  String get advices_txt1;

  /// No description provided for @advices_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Brak rad. Udostępnij gościom kod QR z zakładki „Strona dla gości\".'**
  String get advices_txt2;

  /// No description provided for @music_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście proponują utwory do zagrania. Pokaż im kod QR lub wyślij link.'**
  String get music_txt1;

  /// No description provided for @music_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Utwory do kluczowych momentów wesela. Przeciągnij, by ustawić chronologię. Przy każdym momencie dodaj nowy utwór lub przypisz istniejący z listy.'**
  String get music_txt2;

  /// No description provided for @rsvp_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Brak wpisów RSVP. Pojawią się tutaj, gdy goście wypełnią formularz /rsvp lub gdy ustawisz status ręcznie w sekcji „Potwierdzenia\".'**
  String get rsvp_txt1;

  /// No description provided for @rsvp_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie kody QR i linki do stron dla gości w jednym miejscu. Każdy kod możesz skopiować, otworzyć albo pobrać/udostępnić (PDF do druku lub wysłania).'**
  String get rsvp_txt2;

  /// No description provided for @rsvpMain_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Brak potwierdzeń. Udostępnij gościom kod QR (na dole tej sekcji) lub link do strony /rsvp, aby zbierać potwierdzenia. Możesz też ręcznie ustawić status każdego gościa poniżej.'**
  String get rsvpMain_txt1;

  /// No description provided for @rsvpMain_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Udostępnij gościom stronę potwierdzeń obecności (RSVP). Pokaż kod QR lub wyślij link.'**
  String get rsvpMain_txt2;

  /// No description provided for @gallery_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona dla gości: wspólna galeria zdjęć i filmów oraz możliwość zaproponowania muzyki. Pokaż kod QR lub wyślij link.'**
  String get gallery_txt1;

  /// No description provided for @photoChallenge_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście wykonują wyzwania fotograficzne i przesyłają zdjęcia. Włącz grę w zakładce „Wyzwania\", pokaż kod QR lub wyślij link.'**
  String get photoChallenge_txt1;

  /// No description provided for @photoChallenge_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Brak zdjęć. Gdy goście wykonają wyzwania, pojawią się tutaj — pogrupowane po wyzwaniach.'**
  String get photoChallenge_txt2;

  /// No description provided for @photoGuess_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście oglądają stare zdjęcia i zgadują odpowiedzi. Włącz grę w zakładce „Zdjęcia\", pokaż kod QR lub wyślij link.'**
  String get photoGuess_txt1;

  /// No description provided for @photoGuess_txt2.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj stare zdjęcia (np. z dzieciństwa) i pytania, które goście będą zgadywać.'**
  String get photoGuess_txt2;

  /// No description provided for @tf_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście zgadują, czy stwierdzenia o Parze Młodej są prawdą czy fałszem. Włącz grę w zakładce „Stwierdzenia\", pokaż kod QR lub wyślij link.'**
  String get tf_txt1;

  /// No description provided for @quiz_txt1.
  ///
  /// In pl, this message translates to:
  /// **'Strona, na której goście odpowiadają na pytania o Parę Młodą i poznają swój wynik. Włącz quiz w zakładce „Pytania\", pokaż kod QR lub wyślij link.'**
  String get quiz_txt1;

  /// No description provided for @guestbook_deleteBodyNamed.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć wpis od „{name}”? Tej operacji nie można cofnąć.'**
  String guestbook_deleteBodyNamed(String name);

  /// No description provided for @capsule_deleteBodyNamed.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć wiadomość od „{name}”? Tej operacji nie można cofnąć.'**
  String capsule_deleteBodyNamed(String name);

  /// No description provided for @guestSection_rsvp.
  ///
  /// In pl, this message translates to:
  /// **'RSVP (Potwierdzenia)'**
  String get guestSection_rsvp;

  /// No description provided for @guestSection_gallery.
  ///
  /// In pl, this message translates to:
  /// **'Galeria'**
  String get guestSection_gallery;

  /// No description provided for @guestSection_schedule.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram'**
  String get guestSection_schedule;

  /// No description provided for @guestSection_music.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka'**
  String get guestSection_music;

  /// No description provided for @guestSection_guestbook.
  ///
  /// In pl, this message translates to:
  /// **'Księga gości'**
  String get guestSection_guestbook;

  /// No description provided for @guestSection_advice.
  ///
  /// In pl, this message translates to:
  /// **'Rady'**
  String get guestSection_advice;

  /// No description provided for @guestSection_timeCapsule.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła czasu'**
  String get guestSection_timeCapsule;

  /// No description provided for @guestSection_guestMap.
  ///
  /// In pl, this message translates to:
  /// **'Mapa gości'**
  String get guestSection_guestMap;

  /// No description provided for @guestSection_quiz.
  ///
  /// In pl, this message translates to:
  /// **'Quiz'**
  String get guestSection_quiz;

  /// No description provided for @guestSection_trueFalse.
  ///
  /// In pl, this message translates to:
  /// **'Prawda/Fałsz'**
  String get guestSection_trueFalse;

  /// No description provided for @guestSection_photoGuess.
  ///
  /// In pl, this message translates to:
  /// **'Zgadnij zdjęcie'**
  String get guestSection_photoGuess;

  /// No description provided for @guestSection_photoChallenge.
  ///
  /// In pl, this message translates to:
  /// **'Foto-wyzwania'**
  String get guestSection_photoChallenge;

  /// No description provided for @guestSection_bingo.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne Bingo'**
  String get guestSection_bingo;

  /// No description provided for @guestSection_photoContest.
  ///
  /// In pl, this message translates to:
  /// **'Konkursy fotograficzne'**
  String get guestSection_photoContest;

  /// No description provided for @gw_appTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wesele — strefa gości'**
  String get gw_appTitle;

  /// Podpowiedź przy globusie — gość przełącza język strefy gości.
  ///
  /// In pl, this message translates to:
  /// **'Język'**
  String get gw_language;

  /// No description provided for @gw_help.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc'**
  String get gw_help;

  /// No description provided for @gw_connecting.
  ///
  /// In pl, this message translates to:
  /// **'Łączę…'**
  String get gw_connecting;

  /// No description provided for @gw_invalidLink.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy lub nieaktywny link'**
  String get gw_invalidLink;

  /// No description provided for @gw_invalidLinkBody.
  ///
  /// In pl, this message translates to:
  /// **'Poproś Parę Młodą o aktualny link lub kod QR do strony gości.'**
  String get gw_invalidLinkBody;

  /// No description provided for @gw_guestZone.
  ///
  /// In pl, this message translates to:
  /// **'Strefa gości'**
  String get gw_guestZone;

  /// No description provided for @gw_unavailable.
  ///
  /// In pl, this message translates to:
  /// **'Strona gości jest chwilowo niedostępna. Zajrzyj później.'**
  String get gw_unavailable;

  /// No description provided for @gw_ourWedding.
  ///
  /// In pl, this message translates to:
  /// **'Nasze Wesele'**
  String get gw_ourWedding;

  /// No description provided for @gw_emptyInfo.
  ///
  /// In pl, this message translates to:
  /// **'Sekcje dla gości pojawią się tutaj, gdy Para Młoda je udostępni.'**
  String get gw_emptyInfo;

  /// Data, od której sekcja jest dostępna dla gościa.
  ///
  /// In pl, this message translates to:
  /// **'Dostępne od {date}'**
  String gw_availableFrom(String date);

  /// No description provided for @gw_noLongerAvailable.
  ///
  /// In pl, this message translates to:
  /// **'Już niedostępne'**
  String get gw_noLongerAvailable;

  /// No description provided for @gw_unavailableShort.
  ///
  /// In pl, this message translates to:
  /// **'Niedostępne'**
  String get gw_unavailableShort;

  /// No description provided for @gw_comingSoon.
  ///
  /// In pl, this message translates to:
  /// **'Ta sekcja będzie dostępna wkrótce'**
  String get gw_comingSoon;

  /// No description provided for @gw_yourName.
  ///
  /// In pl, this message translates to:
  /// **'Twoje imię'**
  String get gw_yourName;

  /// No description provided for @gw_guest.
  ///
  /// In pl, this message translates to:
  /// **'Gość'**
  String get gw_guest;

  /// No description provided for @gw_sending.
  ///
  /// In pl, this message translates to:
  /// **'Wysyłanie…'**
  String get gw_sending;

  /// No description provided for @gw_thanks.
  ///
  /// In pl, this message translates to:
  /// **'Dziękujemy ✓'**
  String get gw_thanks;

  /// No description provided for @gw_updated.
  ///
  /// In pl, this message translates to:
  /// **'Zaktualizowano ✓'**
  String get gw_updated;

  /// No description provided for @gw_saveChanges.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz zmiany'**
  String get gw_saveChanges;

  /// No description provided for @gw_sendError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wysłać: {error}'**
  String gw_sendError(String error);

  /// No description provided for @gw_sessionError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się przygotować sesji gościa. Odśwież stronę i spróbuj ponownie.'**
  String get gw_sessionError;

  /// No description provided for @gw_nameFirst.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw podaj swoje imię.'**
  String get gw_nameFirst;

  /// No description provided for @gw_scheduleSoon.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram pojawi się wkrótce.'**
  String get gw_scheduleSoon;

  /// No description provided for @gw_scheduleItem.
  ///
  /// In pl, this message translates to:
  /// **'Punkt programu'**
  String get gw_scheduleItem;

  /// No description provided for @gw_guestbookHint.
  ///
  /// In pl, this message translates to:
  /// **'Twój wpis dla Pary Młodej…'**
  String get gw_guestbookHint;

  /// No description provided for @gw_guestbookCta.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wpis'**
  String get gw_guestbookCta;

  /// No description provided for @gw_guestbookEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Bądź pierwszy — zostaw wpis!'**
  String get gw_guestbookEmpty;

  /// No description provided for @gw_adviceHint.
  ///
  /// In pl, this message translates to:
  /// **'Twoja rada dla Pary Młodej…'**
  String get gw_adviceHint;

  /// No description provided for @gw_adviceCta.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj radę'**
  String get gw_adviceCta;

  /// No description provided for @gw_adviceEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Podziel się pierwszą radą!'**
  String get gw_adviceEmpty;

  /// No description provided for @gw_needNameAndMessage.
  ///
  /// In pl, this message translates to:
  /// **'Podaj imię i treść.'**
  String get gw_needNameAndMessage;

  /// No description provided for @gw_needNameAndCity.
  ///
  /// In pl, this message translates to:
  /// **'Podaj imię i miasto.'**
  String get gw_needNameAndCity;

  /// No description provided for @gw_fromWhereCity.
  ///
  /// In pl, this message translates to:
  /// **'Skąd przyjeżdżasz (miasto)'**
  String get gw_fromWhereCity;

  /// No description provided for @gw_greetingOptional.
  ///
  /// In pl, this message translates to:
  /// **'Pozdrowienie (opcjonalnie)'**
  String get gw_greetingOptional;

  /// No description provided for @gw_addToMap.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj na mapę'**
  String get gw_addToMap;

  /// No description provided for @gw_mapEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Bądź pierwszy na mapie gości!'**
  String get gw_mapEmpty;

  /// No description provided for @gw_needNameAndText.
  ///
  /// In pl, this message translates to:
  /// **'Podaj imię i wiadomość.'**
  String get gw_needNameAndText;

  /// No description provided for @gw_capsuleSealed.
  ///
  /// In pl, this message translates to:
  /// **'Wiadomość zapieczętowana!'**
  String get gw_capsuleSealed;

  /// No description provided for @gw_capsuleSealedBody.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda otworzy Twoją wiadomość w wybranym czasie. Dziękujemy!'**
  String get gw_capsuleSealedBody;

  /// No description provided for @gw_capsuleIntro.
  ///
  /// In pl, this message translates to:
  /// **'Zostaw wiadomość, którą Para Młoda otworzy w przyszłości. Inni goście jej nie zobaczą.'**
  String get gw_capsuleIntro;

  /// No description provided for @gw_capsuleHint.
  ///
  /// In pl, this message translates to:
  /// **'Twoja wiadomość do kapsuły czasu…'**
  String get gw_capsuleHint;

  /// No description provided for @gw_capsuleSeal.
  ///
  /// In pl, this message translates to:
  /// **'Zapieczętuj wiadomość'**
  String get gw_capsuleSeal;

  /// No description provided for @gw_needFullName.
  ///
  /// In pl, this message translates to:
  /// **'Podaj imię i nazwisko.'**
  String get gw_needFullName;

  /// No description provided for @gw_rsvpSeeYou.
  ///
  /// In pl, this message translates to:
  /// **'Do zobaczenia na weselu! 🎉'**
  String get gw_rsvpSeeYou;

  /// No description provided for @gw_rsvpThanks.
  ///
  /// In pl, this message translates to:
  /// **'Dziękujemy za odpowiedź'**
  String get gw_rsvpThanks;

  /// No description provided for @gw_rsvpSent.
  ///
  /// In pl, this message translates to:
  /// **'Twoje potwierdzenie trafiło do Pary Młodej.'**
  String get gw_rsvpSent;

  /// No description provided for @gw_rsvpEdit.
  ///
  /// In pl, this message translates to:
  /// **'Popraw odpowiedź'**
  String get gw_rsvpEdit;

  /// No description provided for @gw_rsvpExistingHint.
  ///
  /// In pl, this message translates to:
  /// **'To Twoje wcześniejsze potwierdzenie. Możesz je poprawić — zapiszemy nową wersję zamiast dodawać kolejną.'**
  String get gw_rsvpExistingHint;

  /// No description provided for @gw_rsvpNewHint.
  ///
  /// In pl, this message translates to:
  /// **'Wystarczy jedno potwierdzenie. Jeśli plany się zmienią, wróć tutaj i popraw odpowiedź.'**
  String get gw_rsvpNewHint;

  /// No description provided for @gw_fullName.
  ///
  /// In pl, this message translates to:
  /// **'Imię i nazwisko'**
  String get gw_fullName;

  /// No description provided for @gw_rsvpQuestion.
  ///
  /// In pl, this message translates to:
  /// **'Czy będziesz na weselu?'**
  String get gw_rsvpQuestion;

  /// No description provided for @gw_rsvpYes.
  ///
  /// In pl, this message translates to:
  /// **'Będę'**
  String get gw_rsvpYes;

  /// No description provided for @gw_rsvpNo.
  ///
  /// In pl, this message translates to:
  /// **'Nie dam rady'**
  String get gw_rsvpNo;

  /// No description provided for @gw_companions.
  ///
  /// In pl, this message translates to:
  /// **'Liczba osób towarzyszących'**
  String get gw_companions;

  /// No description provided for @gw_dietOptional.
  ///
  /// In pl, this message translates to:
  /// **'Dieta / alergie (opcjonalnie)'**
  String get gw_dietOptional;

  /// No description provided for @gw_messageOptional.
  ///
  /// In pl, this message translates to:
  /// **'Wiadomość dla Pary Młodej (opcjonalnie)'**
  String get gw_messageOptional;

  /// No description provided for @gw_rsvpSend.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij potwierdzenie'**
  String get gw_rsvpSend;

  /// No description provided for @gw_photoCaption.
  ///
  /// In pl, this message translates to:
  /// **'Podpis zdjęcia (opcjonalnie)'**
  String get gw_photoCaption;

  /// No description provided for @gw_photoThanks.
  ///
  /// In pl, this message translates to:
  /// **'Dziękujemy za zdjęcie ✓'**
  String get gw_photoThanks;

  /// No description provided for @gw_photoError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się dodać zdjęcia: {error}'**
  String gw_photoError(String error);

  /// No description provided for @gw_galleryError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać galerii.'**
  String get gw_galleryError;

  /// No description provided for @gw_galleryEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Bądź pierwszy — dodaj zdjęcie!'**
  String get gw_galleryEmpty;

  /// No description provided for @gw_photoUploading.
  ///
  /// In pl, this message translates to:
  /// **'Wysyłanie zdjęcia…'**
  String get gw_photoUploading;

  /// No description provided for @gw_camera.
  ///
  /// In pl, this message translates to:
  /// **'Aparat'**
  String get gw_camera;

  /// No description provided for @gw_pickPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz zdjęcie'**
  String get gw_pickPhoto;

  /// No description provided for @gw_searchUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Wyszukiwarka niedostępna — wpisz tytuł i wykonawcę ręcznie.'**
  String get gw_searchUnavailable;

  /// No description provided for @gw_needSongTitle.
  ///
  /// In pl, this message translates to:
  /// **'Podaj tytuł utworu.'**
  String get gw_needSongTitle;

  /// No description provided for @gw_proposalSent.
  ///
  /// In pl, this message translates to:
  /// **'Propozycja wysłana ✓'**
  String get gw_proposalSent;

  /// No description provided for @gw_musicIntro.
  ///
  /// In pl, this message translates to:
  /// **'Zaproponuj utwór, który chcesz usłyszeć na weselu. Propozycje trafiają do Pary Młodej.'**
  String get gw_musicIntro;

  /// No description provided for @gw_musicSearch.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj utworu lub wykonawcy'**
  String get gw_musicSearch;

  /// No description provided for @gw_noResults.
  ///
  /// In pl, this message translates to:
  /// **'Brak wyników — spróbuj innej frazy.'**
  String get gw_noResults;

  /// No description provided for @gw_addManually.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj ręcznie'**
  String get gw_addManually;

  /// No description provided for @gw_songTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tytuł utworu'**
  String get gw_songTitle;

  /// No description provided for @gw_artistOptional.
  ///
  /// In pl, this message translates to:
  /// **'Wykonawca (opcjonalnie)'**
  String get gw_artistOptional;

  /// No description provided for @gw_sendProposal.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij propozycję'**
  String get gw_sendProposal;

  /// No description provided for @gw_yourProposals.
  ///
  /// In pl, this message translates to:
  /// **'Twoje propozycje'**
  String get gw_yourProposals;

  /// No description provided for @gw_gameInactive.
  ///
  /// In pl, this message translates to:
  /// **'Ta gra nie jest w tej chwili aktywna.'**
  String get gw_gameInactive;

  /// No description provided for @gw_questionsSoon.
  ///
  /// In pl, this message translates to:
  /// **'Pytania pojawią się wkrótce.'**
  String get gw_questionsSoon;

  /// No description provided for @gw_statementsSoon.
  ///
  /// In pl, this message translates to:
  /// **'Stwierdzenia pojawią się wkrótce.'**
  String get gw_statementsSoon;

  /// No description provided for @gw_answerAllQuestions.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedz na wszystkie pytania.'**
  String get gw_answerAllQuestions;

  /// No description provided for @gw_answerAllStatements.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedz na wszystkie stwierdzenia.'**
  String get gw_answerAllStatements;

  /// No description provided for @gw_finishAndSend.
  ///
  /// In pl, this message translates to:
  /// **'Zakończ i wyślij wynik'**
  String get gw_finishAndSend;

  /// No description provided for @gw_scoreError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wysłać wyniku: {error}'**
  String gw_scoreError(String error);

  /// No description provided for @gw_scorePrivate.
  ///
  /// In pl, this message translates to:
  /// **'Wynik zobaczy Para Młoda. Nie ma publicznego rankingu.'**
  String get gw_scorePrivate;

  /// No description provided for @gw_true.
  ///
  /// In pl, this message translates to:
  /// **'Prawda'**
  String get gw_true;

  /// No description provided for @gw_false.
  ///
  /// In pl, this message translates to:
  /// **'Fałsz'**
  String get gw_false;

  /// No description provided for @gw_yourScore.
  ///
  /// In pl, this message translates to:
  /// **'Twój wynik: {score} / {total}'**
  String gw_yourScore(int score, int total);

  /// No description provided for @gw_scoreEarlier.
  ///
  /// In pl, this message translates to:
  /// **'To Twój wcześniejszy wynik. Możesz spróbować ponownie — nowy wynik zastąpi poprzedni.'**
  String get gw_scoreEarlier;

  /// No description provided for @gw_scoreThanks.
  ///
  /// In pl, this message translates to:
  /// **'Dziękujemy za zabawę! Wynik trafił do Pary Młodej.'**
  String get gw_scoreThanks;

  /// No description provided for @gw_playAgain.
  ///
  /// In pl, this message translates to:
  /// **'Zagraj ponownie'**
  String get gw_playAgain;

  /// No description provided for @gw_challengesInactive.
  ///
  /// In pl, this message translates to:
  /// **'Foto-wyzwania nie są w tej chwili aktywne.'**
  String get gw_challengesInactive;

  /// No description provided for @gw_challengesSoon.
  ///
  /// In pl, this message translates to:
  /// **'Wyzwania pojawią się wkrótce.'**
  String get gw_challengesSoon;

  /// No description provided for @gw_challengeHint.
  ///
  /// In pl, this message translates to:
  /// **'Jedno zdjęcie na wyzwanie — kolejne zastąpi poprzednie.'**
  String get gw_challengeHint;

  /// No description provided for @gw_guestPhotos.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcia gości'**
  String get gw_guestPhotos;

  /// No description provided for @gw_photosError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać zdjęć.'**
  String get gw_photosError;

  /// No description provided for @gw_photosEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Jeszcze nikt nie przesłał zdjęcia — zacznij Ty!'**
  String get gw_photosEmpty;

  /// Punkty za foto-wyzwanie.
  ///
  /// In pl, this message translates to:
  /// **'{points, plural, =1{1 pkt} other{{points} pkt}}'**
  String gw_points(int points);

  /// No description provided for @gw_sendPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij zdjęcie'**
  String get gw_sendPhoto;

  /// No description provided for @gw_photoSent.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcie wysłane ✓'**
  String get gw_photoSent;

  /// No description provided for @gw_contestsSoon.
  ///
  /// In pl, this message translates to:
  /// **'Konkursy fotograficzne pojawią się wkrótce.'**
  String get gw_contestsSoon;

  /// No description provided for @gw_contestPickCategory.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz podkategorię'**
  String get gw_contestPickCategory;

  /// No description provided for @gw_contestSubmitHint.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcie trafi też do ogólnej galerii wesela.'**
  String get gw_contestSubmitHint;

  /// No description provided for @gw_contestSubmissions.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszenia'**
  String get gw_contestSubmissions;

  /// No description provided for @gw_contestSubmitted.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcie zgłoszone do konkursu ✓'**
  String get gw_contestSubmitted;

  /// No description provided for @gw_contestBack.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz konkurs'**
  String get gw_contestBack;

  /// No description provided for @gw_contestVoteHint.
  ///
  /// In pl, this message translates to:
  /// **'Kliknij zdjęcie, aby przyznać mu 1., 2. lub 3. miejsce. Nie możesz głosować na własne zdjęcia.'**
  String get gw_contestVoteHint;

  /// No description provided for @gw_contestPickPlace.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz miejsce'**
  String get gw_contestPickPlace;

  /// No description provided for @gw_contestPlaceN.
  ///
  /// In pl, this message translates to:
  /// **'{n}. miejsce'**
  String gw_contestPlaceN(int n);

  /// No description provided for @gw_contestUndo.
  ///
  /// In pl, this message translates to:
  /// **'Cofnij to miejsce'**
  String get gw_contestUndo;

  /// No description provided for @gw_contestVoteSaved.
  ///
  /// In pl, this message translates to:
  /// **'Głos zapisany ✓'**
  String get gw_contestVoteSaved;

  /// No description provided for @gw_contestVotePending.
  ///
  /// In pl, this message translates to:
  /// **'Brakuje wyborów do zapisania głosu: {count}/3'**
  String gw_contestVotePending(int count);

  /// No description provided for @gw_contestOwnPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Twoje zdjęcie'**
  String get gw_contestOwnPhoto;

  /// No description provided for @gw_contestResultsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wyniki'**
  String get gw_contestResultsTitle;

  /// No description provided for @gw_contestResultsPendingManual.
  ///
  /// In pl, this message translates to:
  /// **'Wyniki pojawią się, gdy ujawni je Para Młoda.'**
  String get gw_contestResultsPendingManual;

  /// No description provided for @gw_contestResultsPendingAuto.
  ///
  /// In pl, this message translates to:
  /// **'Wyniki pojawią się {date}.'**
  String gw_contestResultsPendingAuto(String date);

  /// No description provided for @gw_bingoSoon.
  ///
  /// In pl, this message translates to:
  /// **'Plansza bingo pojawi się wkrótce.'**
  String get gw_bingoSoon;

  /// No description provided for @gw_bingoIntro.
  ///
  /// In pl, this message translates to:
  /// **'Skreślaj pola, gdy zobaczysz je na weselu. Skreślenia są tylko na Twoim telefonie — wyślij zgłoszenie, gdy uzbierasz komplet.'**
  String get gw_bingoIntro;

  /// No description provided for @gw_bingoMarked.
  ///
  /// In pl, this message translates to:
  /// **'Skreślone: {marked} / {total}'**
  String gw_bingoMarked(int marked, int total);

  /// No description provided for @gw_bingoDone.
  ///
  /// In pl, this message translates to:
  /// **'Mam bingo!'**
  String get gw_bingoDone;

  /// Darmowe pole na środku planszy bingo (gdy para nie ustawiła własnego).
  ///
  /// In pl, this message translates to:
  /// **'GRATIS'**
  String get gw_bingoFree;

  /// No description provided for @settings_configSaved.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja zapisana ✓'**
  String get settings_configSaved;

  /// No description provided for @settings_syncCard.
  ///
  /// In pl, this message translates to:
  /// **'Status synchronizacji'**
  String get settings_syncCard;

  /// No description provided for @settings_syncOk.
  ///
  /// In pl, this message translates to:
  /// **'Zsynchronizowano z Firestore'**
  String get settings_syncOk;

  /// No description provided for @settings_syncConnecting.
  ///
  /// In pl, this message translates to:
  /// **'Łączenie…'**
  String get settings_syncConnecting;

  /// No description provided for @settings_guideCard.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik i pomoc'**
  String get settings_guideCard;

  /// No description provided for @settings_guideHint.
  ///
  /// In pl, this message translates to:
  /// **'Wróć do interaktywnego przewodnika po aplikacji lub do listy kroków organizacji wesela.'**
  String get settings_guideHint;

  /// No description provided for @settings_helpOpen.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc — opisy funkcji'**
  String get settings_helpOpen;

  /// No description provided for @settings_legacyCard.
  ///
  /// In pl, this message translates to:
  /// **'Dane starych sekcji (legacy)'**
  String get settings_legacyCard;

  /// No description provided for @settings_legacyHint.
  ///
  /// In pl, this message translates to:
  /// **'Wpisy z czasów jednego wesela (galeria, księga gości, rady, mapa, kapsuła czasu, wyniki gier) nie mają przypisanego wesela. Migracja przypisuje je do TEGO wesela — bez niej znikną z panelu po wdrożeniu nowych reguł bezpieczeństwa.'**
  String get settings_legacyHint;

  /// No description provided for @settings_legacyBefore.
  ///
  /// In pl, this message translates to:
  /// **'Uruchom PRZED wdrożeniem nowych reguł.'**
  String get settings_legacyBefore;

  /// No description provided for @settings_legacyCheck.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź'**
  String get settings_legacyCheck;

  /// No description provided for @settings_legacyMigrate.
  ///
  /// In pl, this message translates to:
  /// **'Migruj'**
  String get settings_legacyMigrate;

  /// No description provided for @settings_legacyError.
  ///
  /// In pl, this message translates to:
  /// **'{collection}: BŁĄD — {error}'**
  String settings_legacyError(String collection, String error);

  /// No description provided for @settings_legacyToDo.
  ///
  /// In pl, this message translates to:
  /// **'{collection}: do migracji {stamped}, już przypisane {skipped}'**
  String settings_legacyToDo(String collection, int stamped, int skipped);

  /// No description provided for @settings_legacyDone.
  ///
  /// In pl, this message translates to:
  /// **'{collection}: przypisano {stamped}, pominięto {skipped}'**
  String settings_legacyDone(String collection, int stamped, int skipped);

  /// No description provided for @settings_legacyCheckFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się sprawdzić: {error}'**
  String settings_legacyCheckFailed(String error);

  /// No description provided for @settings_legacyConfirmTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przypisać stare wpisy do tego wesela?'**
  String get settings_legacyConfirmTitle;

  /// No description provided for @settings_legacyConfirmBody.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie wpisy bez przypisanego wesela (galeria, księga gości, rady, mapa, kapsuła czasu, wyniki gier) zostaną przypisane do AKTYWNEGO wesela. Wpisy, które już mają wesele, nie zostaną ruszone. Operacji nie da się cofnąć jednym kliknięciem.'**
  String get settings_legacyConfirmBody;

  /// No description provided for @settings_legacyAssign.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz'**
  String get settings_legacyAssign;

  /// No description provided for @settings_legacyFinished.
  ///
  /// In pl, this message translates to:
  /// **'Migracja zakończona ✓'**
  String get settings_legacyFinished;

  /// No description provided for @settings_legacyFailed.
  ///
  /// In pl, this message translates to:
  /// **'Migracja nieudana: {error}'**
  String settings_legacyFailed(String error);

  /// No description provided for @settings_currencyToast.
  ///
  /// In pl, this message translates to:
  /// **'Waluta: {code}'**
  String settings_currencyToast(String code);

  /// No description provided for @settings_displayModeCard.
  ///
  /// In pl, this message translates to:
  /// **'Tryb wyświetlania'**
  String get settings_displayModeCard;

  /// No description provided for @settings_displayModeHint.
  ///
  /// In pl, this message translates to:
  /// **'Domyślnie układ dobiera się do szerokości ekranu. Możesz go wymusić — przyda się na małym tablecie albo gdy wolisz układ telefonowy na dużym ekranie.'**
  String get settings_displayModeHint;

  /// No description provided for @settings_interactionsCard.
  ///
  /// In pl, this message translates to:
  /// **'Interakcje gości (moderacja)'**
  String get settings_interactionsCard;

  /// No description provided for @settings_interactionsHint.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz i moderuj to, co goście przesłali przez stronę web: potwierdzenia RSVP, wpisy księgi, rady, mapę gości i kapsułę czasu.'**
  String get settings_interactionsHint;

  /// No description provided for @settings_interactionsOpen.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz interakcje gości'**
  String get settings_interactionsOpen;

  /// No description provided for @settings_loading.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie…'**
  String get settings_loading;

  /// No description provided for @settings_guestLinkCard.
  ///
  /// In pl, this message translates to:
  /// **'Link i QR dla gości (strona web)'**
  String get settings_guestLinkCard;

  /// No description provided for @settings_guestLinkHint.
  ///
  /// In pl, this message translates to:
  /// **'Udostępnij gościom ten link lub kod QR. Otworzą stronę gości BEZ logowania — zobaczą tylko sekcje dla gości (z Twoimi ustawieniami widoczności).'**
  String get settings_guestLinkHint;

  /// No description provided for @settings_guestLinkCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano link dla gości'**
  String get settings_guestLinkCopied;

  /// No description provided for @settings_copyLink.
  ///
  /// In pl, this message translates to:
  /// **'Kopiuj link'**
  String get settings_copyLink;

  /// No description provided for @settings_qrCode.
  ///
  /// In pl, this message translates to:
  /// **'Kod QR'**
  String get settings_qrCode;

  /// No description provided for @settings_peopleCard.
  ///
  /// In pl, this message translates to:
  /// **'Osoby i dostęp'**
  String get settings_peopleCard;

  /// No description provided for @settings_peopleHint.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj osobami z dostępem do wesela: dodawaj współorganizatorów i planerów, ustawiaj datę ważności, blokuj i usuwaj dostęp.'**
  String get settings_peopleHint;

  /// No description provided for @settings_peopleOpen.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj osobami'**
  String get settings_peopleOpen;

  /// No description provided for @settings_inviteCard.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenie dla gości (dołączenie na konto)'**
  String get settings_inviteCard;

  /// No description provided for @settings_inviteHint.
  ///
  /// In pl, this message translates to:
  /// **'Przekaż gościom kod QR albo trzy dane z tej karty. Gość poda je w aplikacji („Dołącz do wesela\") i zobaczy wesele na swoim koncie. To inna droga niż link do strony gości niżej — ten działa bez logowania.'**
  String get settings_inviteHint;

  /// No description provided for @settings_codeCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano kod: {code}'**
  String settings_codeCopied(String code);

  /// No description provided for @settings_copyCode.
  ///
  /// In pl, this message translates to:
  /// **'Kopiuj kod'**
  String get settings_copyCode;

  /// No description provided for @settings_qrScanHint.
  ///
  /// In pl, this message translates to:
  /// **'skanuje się w aplikacji'**
  String get settings_qrScanHint;

  /// No description provided for @settings_inviteCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano gotowe zaproszenie'**
  String get settings_inviteCopied;

  /// No description provided for @settings_copyInvite.
  ///
  /// In pl, this message translates to:
  /// **'Kopiuj gotowe zaproszenie'**
  String get settings_copyInvite;

  /// No description provided for @settings_inviteDataTitle.
  ///
  /// In pl, this message translates to:
  /// **'Co gość musi podać'**
  String get settings_inviteDataTitle;

  /// No description provided for @settings_weddingCode.
  ///
  /// In pl, this message translates to:
  /// **'Kod wesela'**
  String get settings_weddingCode;

  /// No description provided for @settings_weddingDate.
  ///
  /// In pl, this message translates to:
  /// **'Data ślubu'**
  String get settings_weddingDate;

  /// No description provided for @settings_notSet.
  ///
  /// In pl, this message translates to:
  /// **'nie ustawiono'**
  String get settings_notSet;

  /// No description provided for @settings_coupleSurname.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko Państwa Młodych'**
  String get settings_coupleSurname;

  /// No description provided for @settings_copiedValue.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano: {value}'**
  String settings_copiedValue(String value);

  /// No description provided for @settings_surnameMissing.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełnij pole „Nazwisko / nazwiska Pary Młodej\" w Konfiguracji — bez niego gość nie ma czego wpisać i nie dołączy.'**
  String get settings_surnameMissing;

  /// No description provided for @settings_surnameFallback.
  ///
  /// In pl, this message translates to:
  /// **'Gość poda tu na razie „Osoby\". Wpisz w Konfiguracji pole „Nazwisko / nazwiska Pary Młodej\", jeśli wolisz, żeby podawał nazwisko.'**
  String get settings_surnameFallback;

  /// No description provided for @settings_inviteTextHeader.
  ///
  /// In pl, this message translates to:
  /// **'Zapraszamy! Dołącz do naszego wesela w aplikacji Moje Wesele:'**
  String get settings_inviteTextHeader;

  /// No description provided for @settings_inviteTextStep1.
  ///
  /// In pl, this message translates to:
  /// **'1. Zainstaluj aplikację i załóż konto.'**
  String get settings_inviteTextStep1;

  /// No description provided for @settings_inviteTextStep2.
  ///
  /// In pl, this message translates to:
  /// **'2. Wybierz „Dołącz do wesela\".'**
  String get settings_inviteTextStep2;

  /// No description provided for @settings_inviteTextStep3.
  ///
  /// In pl, this message translates to:
  /// **'3. Podaj poniższe dane:'**
  String get settings_inviteTextStep3;

  /// No description provided for @settings_inviteTextCode.
  ///
  /// In pl, this message translates to:
  /// **'   • Kod wesela: {code}'**
  String settings_inviteTextCode(String code);

  /// No description provided for @settings_inviteTextDate.
  ///
  /// In pl, this message translates to:
  /// **'   • Data ślubu: {date}'**
  String settings_inviteTextDate(String date);

  /// No description provided for @settings_inviteTextSurname.
  ///
  /// In pl, this message translates to:
  /// **'   • Nazwisko Państwa Młodych: {surname}'**
  String settings_inviteTextSurname(String surname);

  /// No description provided for @settings_inviteTextQr.
  ///
  /// In pl, this message translates to:
  /// **'Możesz też zeskanować nasz kod QR — wypełni kod za Ciebie.'**
  String get settings_inviteTextQr;

  /// No description provided for @settings_joinStepsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Jak gość dołącza — krok po kroku'**
  String get settings_joinStepsTitle;

  /// No description provided for @settings_joinStep1.
  ///
  /// In pl, this message translates to:
  /// **'Gość instaluje aplikację i zakłada konto (albo loguje się na swoje).'**
  String get settings_joinStep1;

  /// No description provided for @settings_joinStep2.
  ///
  /// In pl, this message translates to:
  /// **'Na liście wesel wybiera „Dołącz do wesela\".'**
  String get settings_joinStep2;

  /// No description provided for @settings_joinStep3.
  ///
  /// In pl, this message translates to:
  /// **'Wpisuje kod wesela — albo klika „Skanuj\" i skanuje Twój kod QR, co wypełnia to pole automatycznie.'**
  String get settings_joinStep3;

  /// No description provided for @settings_joinStep4.
  ///
  /// In pl, this message translates to:
  /// **'Wybiera datę ślubu z kalendarza.'**
  String get settings_joinStep4;

  /// No description provided for @settings_joinStep5.
  ///
  /// In pl, this message translates to:
  /// **'Wpisuje nazwisko Państwa Młodych (to z tej karty).'**
  String get settings_joinStep5;

  /// No description provided for @settings_joinStep6.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe — wesele pojawia się na jego liście.'**
  String get settings_joinStep6;

  /// No description provided for @settings_visibilityCard.
  ///
  /// In pl, this message translates to:
  /// **'Widoczność dla gości'**
  String get settings_visibilityCard;

  /// No description provided for @settings_visibilityHint.
  ///
  /// In pl, this message translates to:
  /// **'Ustal, które sekcje i w jakim czasie widzą goście na stronach publicznych (np. RSVP do tygodnia przed, galeria od dnia wesela).'**
  String get settings_visibilityHint;

  /// No description provided for @settings_visibilityOpen.
  ///
  /// In pl, this message translates to:
  /// **'Ustaw widoczność sekcji'**
  String get settings_visibilityOpen;

  /// No description provided for @settings_notificationsHint.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz, o czym chcesz wiedzieć na telefonie. Dzwoneczek w aplikacji działa zawsze, niezależnie od tych ustawień.'**
  String get settings_notificationsHint;

  /// No description provided for @settings_notificationsOpen.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia powiadomień'**
  String get settings_notificationsOpen;

  /// No description provided for @settings_securityCard.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie'**
  String get settings_securityCard;

  /// No description provided for @settings_securityHint.
  ///
  /// In pl, this message translates to:
  /// **'Biometria (odcisk palca), PIN lub wzór do odblokowywania aplikacji przy kolejnych otwarciach.'**
  String get settings_securityHint;

  /// No description provided for @settings_securityOpen.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie i zabezpieczenia'**
  String get settings_securityOpen;

  /// No description provided for @settings_configOwnerHint.
  ///
  /// In pl, this message translates to:
  /// **'Zmianę daty ślubu i nazwisk musi zapisać właściciel wesela — inaczej dane dołączania gości pozostaną nieaktualne.'**
  String get settings_configOwnerHint;

  /// No description provided for @settings_coupleType.
  ///
  /// In pl, this message translates to:
  /// **'Typ uroczystości'**
  String get settings_coupleType;

  /// {hint} to podpowiedź typu uroczystości z CoupleType.
  ///
  /// In pl, this message translates to:
  /// **'{hint}. Możesz to zmienić w każdej chwili — zmieniają się tylko etykiety, dane gości zostają nietknięte.'**
  String settings_coupleTypeHint(String hint);

  /// No description provided for @settings_eventName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa wydarzenia'**
  String get settings_eventName;

  /// No description provided for @settings_persons.
  ///
  /// In pl, this message translates to:
  /// **'Osoby'**
  String get settings_persons;

  /// No description provided for @settings_verificationSurnames.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko / nazwiska Pary Młodej'**
  String get settings_verificationSurnames;

  /// No description provided for @settings_verificationHint.
  ///
  /// In pl, this message translates to:
  /// **'Używane tylko do weryfikacji gościa przy dołączaniu kodem — nie jest nigdzie wyświetlane. Jeśli nazwiska są różne, wpisz oba (np. „Kowalska Nowak\").'**
  String get settings_verificationHint;

  /// No description provided for @settings_time.
  ///
  /// In pl, this message translates to:
  /// **'Godzina'**
  String get settings_time;

  /// No description provided for @settings_ceremonyPlace.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce ceremonii'**
  String get settings_ceremonyPlace;

  /// No description provided for @settings_receptionPlace.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce wesela'**
  String get settings_receptionPlace;

  /// No description provided for @settings_person1.
  ///
  /// In pl, this message translates to:
  /// **'Osoba 1 (podział kosztów)'**
  String get settings_person1;

  /// No description provided for @settings_person2.
  ///
  /// In pl, this message translates to:
  /// **'Osoba 2'**
  String get settings_person2;

  /// No description provided for @settings_witnesses.
  ///
  /// In pl, this message translates to:
  /// **'Liczba świadków'**
  String get settings_witnesses;

  /// No description provided for @settings_witnessesHint.
  ///
  /// In pl, this message translates to:
  /// **'Domyślnie 2. Dla nietradycyjnych ślubów możesz ustawić więcej.'**
  String get settings_witnessesHint;

  /// No description provided for @settings_children.
  ///
  /// In pl, this message translates to:
  /// **'Dzieci na weselu'**
  String get settings_children;

  /// No description provided for @settings_childrenHint.
  ///
  /// In pl, this message translates to:
  /// **'Możesz oznaczać gości jako dzieci, dodać stół dla dzieci i osobne menu. Ceny ustawisz w Budżet → Sala.'**
  String get settings_childrenHint;

  /// No description provided for @settings_childrenSwitch.
  ///
  /// In pl, this message translates to:
  /// **'Włącz, jeśli na weselu będą dzieci.'**
  String get settings_childrenSwitch;

  /// No description provided for @settings_menuDict.
  ///
  /// In pl, this message translates to:
  /// **'Słownik menu (po jednym w linii)'**
  String get settings_menuDict;

  /// No description provided for @settings_expenseCategories.
  ///
  /// In pl, this message translates to:
  /// **'Kategorie wydatków (po jednym w linii)'**
  String get settings_expenseCategories;

  /// No description provided for @settings_saveConfig.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz konfigurację'**
  String get settings_saveConfig;

  /// No description provided for @settings_budgetCard.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia budżetu'**
  String get settings_budgetCard;

  /// No description provided for @settings_childrenDataCard.
  ///
  /// In pl, this message translates to:
  /// **'Dane o dzieciach'**
  String get settings_childrenDataCard;

  /// No description provided for @settings_childrenDataHint.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączenie „wesele z dziećmi” w budżecie tylko ukrywa dane — nic nie usuwa. Tu możesz je skasować na trwałe.'**
  String get settings_childrenDataHint;

  /// No description provided for @settings_childrenDataCount.
  ///
  /// In pl, this message translates to:
  /// **'{count} gości oznaczonych jako dziecko.'**
  String settings_childrenDataCount(String count);

  /// No description provided for @settings_childrenDataButton.
  ///
  /// In pl, this message translates to:
  /// **'Usuń dane o dzieciach'**
  String get settings_childrenDataButton;

  /// No description provided for @settings_childrenDataConfirmTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć dane o dzieciach?'**
  String get settings_childrenDataConfirmTitle;

  /// No description provided for @settings_childrenDataConfirmBody.
  ///
  /// In pl, this message translates to:
  /// **'To usunie oznaczenie „dziecko” u wszystkich gości oraz liczbę i ustawienia dzieci w budżecie. Tej operacji NIE MOŻNA cofnąć.'**
  String get settings_childrenDataConfirmBody;

  /// No description provided for @settings_childrenDataConfirmButton.
  ///
  /// In pl, this message translates to:
  /// **'Usuń trwale'**
  String get settings_childrenDataConfirmButton;

  /// No description provided for @settings_childrenDataDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Dane o dzieciach usunięte.'**
  String get settings_childrenDataDeleted;

  /// No description provided for @settings_budgetHint.
  ///
  /// In pl, this message translates to:
  /// **'Budżet planowany to kwota założona na start. Rezerwa to opcjonalny bufor na nieprzewidziane wydatki — doliczany do planowanego jako bezpiecznik.'**
  String get settings_budgetHint;

  /// {currency} to symbol waluty wesela (zł, €, …).
  ///
  /// In pl, this message translates to:
  /// **'Budżet planowany ({currency})'**
  String settings_budgetPlanned(String currency);

  /// No description provided for @settings_budgetReserve.
  ///
  /// In pl, this message translates to:
  /// **'Rezerwa ({currency})'**
  String settings_budgetReserve(String currency);

  /// No description provided for @settings_budgetSave.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz ustawienia budżetu'**
  String get settings_budgetSave;

  /// No description provided for @settings_budgetSaved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano ustawienia budżetu ✓'**
  String get settings_budgetSaved;

  /// No description provided for @settings_accessCard.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp'**
  String get settings_accessCard;

  /// No description provided for @settings_accessHint.
  ///
  /// In pl, this message translates to:
  /// **'Rejestracja otwarta — każde konto Google może się zalogować i założyć własne wesele. Dostęp do tego wesela mają osoby z nim powiązane (właściciel i zaproszeni).'**
  String get settings_accessHint;

  /// No description provided for @settings_devCard.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia programistyczne'**
  String get settings_devCard;

  /// No description provided for @settings_exportData.
  ///
  /// In pl, this message translates to:
  /// **'Eksport danych'**
  String get settings_exportData;

  /// No description provided for @settings_importData.
  ///
  /// In pl, this message translates to:
  /// **'Import danych'**
  String get settings_importData;

  /// No description provided for @settings_backupCreate.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz kopię'**
  String get settings_backupCreate;

  /// No description provided for @settings_backupsCard.
  ///
  /// In pl, this message translates to:
  /// **'Kopie zapasowe'**
  String get settings_backupsCard;

  /// No description provided for @settings_backupsHint.
  ///
  /// In pl, this message translates to:
  /// **'Kopie zapasowe (3 ostatnie) przechowywane lokalnie na urządzeniu.'**
  String get settings_backupsHint;

  /// No description provided for @settings_exportTitle.
  ///
  /// In pl, this message translates to:
  /// **'Eksport danych (JSON)'**
  String get settings_exportTitle;

  /// No description provided for @settings_importWarning.
  ///
  /// In pl, this message translates to:
  /// **'⚠ Import ZASTĄPI wszystkie obecne dane. Wklej poprawny JSON.'**
  String get settings_importWarning;

  /// No description provided for @settings_importHint.
  ///
  /// In pl, this message translates to:
  /// **'Wklej JSON…'**
  String get settings_importHint;

  /// No description provided for @settings_importButton.
  ///
  /// In pl, this message translates to:
  /// **'Importuj (zastąp)'**
  String get settings_importButton;

  /// No description provided for @settings_importBadFormat.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy format JSON'**
  String get settings_importBadFormat;

  /// No description provided for @settings_importDone.
  ///
  /// In pl, this message translates to:
  /// **'Zaimportowano dane'**
  String get settings_importDone;

  /// No description provided for @settings_importFailed.
  ///
  /// In pl, this message translates to:
  /// **'Błąd importu: {error}'**
  String settings_importFailed(String error);

  /// No description provided for @settings_backupCreated.
  ///
  /// In pl, this message translates to:
  /// **'Utworzono kopię zapasową'**
  String get settings_backupCreated;

  /// No description provided for @settings_backupsEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak kopii zapasowych.'**
  String get settings_backupsEmpty;

  /// No description provided for @settings_backupRestore.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć'**
  String get settings_backupRestore;

  /// No description provided for @settings_backupRestoreTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przywrócić kopię?'**
  String get settings_backupRestoreTitle;

  /// No description provided for @settings_backupRestoreBody.
  ///
  /// In pl, this message translates to:
  /// **'Dane z {date} zastąpią obecne dane.'**
  String settings_backupRestoreBody(String date);

  /// No description provided for @settings_backupRestored.
  ///
  /// In pl, this message translates to:
  /// **'Przywrócono kopię'**
  String get settings_backupRestored;

  /// No description provided for @settings_backupRestoreFailed.
  ///
  /// In pl, this message translates to:
  /// **'Błąd przywracania: {error}'**
  String settings_backupRestoreFailed(String error);

  /// No description provided for @role_planner.
  ///
  /// In pl, this message translates to:
  /// **'Planer'**
  String get role_planner;

  /// No description provided for @role_collaborator.
  ///
  /// In pl, this message translates to:
  /// **'Współorganizator'**
  String get role_collaborator;

  /// No description provided for @role_guest.
  ///
  /// In pl, this message translates to:
  /// **'Gość'**
  String get role_guest;

  /// No description provided for @status_active.
  ///
  /// In pl, this message translates to:
  /// **'Aktywny'**
  String get status_active;

  /// No description provided for @status_blocked.
  ///
  /// In pl, this message translates to:
  /// **'Zablokowany'**
  String get status_blocked;

  /// No description provided for @status_pending.
  ///
  /// In pl, this message translates to:
  /// **'Oczekuje'**
  String get status_pending;

  /// No description provided for @status_expired.
  ///
  /// In pl, this message translates to:
  /// **'Wygasł'**
  String get status_expired;

  /// No description provided for @vis_saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano ustawienia widoczności ✓'**
  String get vis_saved;

  /// No description provided for @vis_title.
  ///
  /// In pl, this message translates to:
  /// **'Widoczność dla gości'**
  String get vis_title;

  /// No description provided for @vis_sectionsHeader.
  ///
  /// In pl, this message translates to:
  /// **'SEKCJE DLA GOŚCI'**
  String get vis_sectionsHeader;

  /// No description provided for @vis_saving.
  ///
  /// In pl, this message translates to:
  /// **'Zapisywanie…'**
  String get vis_saving;

  /// No description provided for @vis_save.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz ustawienia'**
  String get vis_save;

  /// No description provided for @vis_intro.
  ///
  /// In pl, this message translates to:
  /// **'Ustal, kiedy goście widzą poszczególne sekcje na stronach publicznych. Możesz podać datę OD, DO, obie lub żadną. Daty liczone są wg czasu polskiego (Europe/Warsaw).'**
  String get vis_intro;

  /// No description provided for @vis_masterTitle.
  ///
  /// In pl, this message translates to:
  /// **'Strona dla gości'**
  String get vis_masterTitle;

  /// No description provided for @vis_masterOn.
  ///
  /// In pl, this message translates to:
  /// **'Włączona — obowiązują ustawienia sekcji poniżej'**
  String get vis_masterOn;

  /// No description provided for @vis_masterOff.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączona — goście nie widzą żadnej sekcji'**
  String get vis_masterOff;

  /// No description provided for @vis_from.
  ///
  /// In pl, this message translates to:
  /// **'Widoczne od'**
  String get vis_from;

  /// No description provided for @vis_to.
  ///
  /// In pl, this message translates to:
  /// **'Widoczne do'**
  String get vis_to;

  /// No description provided for @vis_outOfRange.
  ///
  /// In pl, this message translates to:
  /// **'Gdy niedostępne dla gościa:'**
  String get vis_outOfRange;

  /// No description provided for @vis_showMessage.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż komunikat'**
  String get vis_showMessage;

  /// No description provided for @vis_hideSection.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj sekcję'**
  String get vis_hideSection;

  /// No description provided for @vis_stateVisible.
  ///
  /// In pl, this message translates to:
  /// **'Widoczna dla gości teraz'**
  String get vis_stateVisible;

  /// No description provided for @vis_stateFrom.
  ///
  /// In pl, this message translates to:
  /// **'Będzie widoczna od {date}'**
  String vis_stateFrom(String date);

  /// No description provided for @vis_stateTo.
  ///
  /// In pl, this message translates to:
  /// **'Już niedostępna (do {date})'**
  String vis_stateTo(String date);

  /// No description provided for @vis_stateOff.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączona dla gości'**
  String get vis_stateOff;

  /// No description provided for @vis_stateMasterOff.
  ///
  /// In pl, this message translates to:
  /// **'Cała strona dla gości wyłączona'**
  String get vis_stateMasterOff;

  /// No description provided for @notif_pushWhen.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij mi push, gdy:'**
  String get notif_pushWhen;

  /// No description provided for @notif_soonTitle.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia na telefon — wkrótce'**
  String get notif_soonTitle;

  /// No description provided for @notif_soonBody.
  ///
  /// In pl, this message translates to:
  /// **'Push jeszcze nie działa — wymaga włączenia powiadomień systemowych i uruchomienia usługi po naszej stronie. Twój wybór zapisujemy już teraz, więc po włączeniu push wszystko zadziała bez ponownego ustawiania.'**
  String get notif_soonBody;

  /// No description provided for @notif_bellTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dzwoneczek w aplikacji działa zawsze'**
  String get notif_bellTitle;

  /// No description provided for @notif_bellBody.
  ///
  /// In pl, this message translates to:
  /// **'Centrum powiadomień w prawym górnym rogu pokazuje zmiany niezależnie od poniższych ustawień. Te przełączniki dotyczą wyłącznie powiadomień wysyłanych na telefon, gdy nie korzystasz z aplikacji.'**
  String get notif_bellBody;

  /// No description provided for @notif_allOff.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko wyłączone — po uruchomieniu push nie dostaniesz żadnego powiadomienia na telefon. Dzwoneczek w aplikacji nadal będzie działał.'**
  String get notif_allOff;

  /// No description provided for @sec_enabled.
  ///
  /// In pl, this message translates to:
  /// **'Zabezpieczenia włączone ✓'**
  String get sec_enabled;

  /// No description provided for @sec_disableTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączyć zabezpieczenia?'**
  String get sec_disableTitle;

  /// No description provided for @sec_disableBody.
  ///
  /// In pl, this message translates to:
  /// **'Aplikacja przestanie wymagać odcisku palca / PIN-u przy otwieraniu. Zapisany PIN/wzór zostanie usunięty z tego urządzenia.'**
  String get sec_disableBody;

  /// No description provided for @sec_disable.
  ///
  /// In pl, this message translates to:
  /// **'Wyłącz'**
  String get sec_disable;

  /// No description provided for @sec_disabled.
  ///
  /// In pl, this message translates to:
  /// **'Zabezpieczenia wyłączone'**
  String get sec_disabled;

  /// No description provided for @sec_confirmBiometric.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź odcisk palca, aby włączyć szybkie logowanie'**
  String get sec_confirmBiometric;

  /// No description provided for @sec_biometricFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie potwierdzono biometrii'**
  String get sec_biometricFailed;

  /// No description provided for @sec_biometricOn.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie odciskiem palca włączone'**
  String get sec_biometricOn;

  /// No description provided for @sec_biometricOff.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie odciskiem palca wyłączone'**
  String get sec_biometricOff;

  /// No description provided for @sec_backupChanged.
  ///
  /// In pl, this message translates to:
  /// **'Zmieniono zabezpieczenie zapasowe ✓'**
  String get sec_backupChanged;

  /// No description provided for @sec_title.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie'**
  String get sec_title;

  /// No description provided for @sec_statusCard.
  ///
  /// In pl, this message translates to:
  /// **'Status zabezpieczeń'**
  String get sec_statusCard;

  /// No description provided for @sec_lockOn.
  ///
  /// In pl, this message translates to:
  /// **'Blokada aplikacji jest aktywna'**
  String get sec_lockOn;

  /// No description provided for @sec_lockOff.
  ///
  /// In pl, this message translates to:
  /// **'Blokada aplikacji wyłączona'**
  String get sec_lockOff;

  /// No description provided for @sec_biometricStatusOn.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie odciskiem palca: włączone'**
  String get sec_biometricStatusOn;

  /// No description provided for @sec_biometricStatusOff.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie odciskiem palca: wyłączone'**
  String get sec_biometricStatusOff;

  /// No description provided for @sec_backupStatus.
  ///
  /// In pl, this message translates to:
  /// **'Zabezpieczenie zapasowe: {type}'**
  String sec_backupStatus(String type);

  /// No description provided for @sec_noReader.
  ///
  /// In pl, this message translates to:
  /// **'To urządzenie nie ma czytnika biometrycznego — dostępny tylko PIN/wzór.'**
  String get sec_noReader;

  /// No description provided for @sec_lockCard.
  ///
  /// In pl, this message translates to:
  /// **'Blokada aplikacji'**
  String get sec_lockCard;

  /// No description provided for @sec_requireBiometric.
  ///
  /// In pl, this message translates to:
  /// **'Wymagaj odcisku palca lub PIN-u'**
  String get sec_requireBiometric;

  /// No description provided for @sec_requirePin.
  ///
  /// In pl, this message translates to:
  /// **'Wymagaj PIN-u lub wzoru'**
  String get sec_requirePin;

  /// No description provided for @sec_onNextOpen.
  ///
  /// In pl, this message translates to:
  /// **'Przy kolejnych otwarciach aplikacji.'**
  String get sec_onNextOpen;

  /// No description provided for @sec_fingerprint.
  ///
  /// In pl, this message translates to:
  /// **'Odcisk palca'**
  String get sec_fingerprint;

  /// No description provided for @sec_fastLogin.
  ///
  /// In pl, this message translates to:
  /// **'Szybkie logowanie odciskiem palca'**
  String get sec_fastLogin;

  /// No description provided for @sec_pinStaysBackup.
  ///
  /// In pl, this message translates to:
  /// **'PIN/wzór pozostaje jako metoda zapasowa.'**
  String get sec_pinStaysBackup;

  /// No description provided for @sec_noReaderLong.
  ///
  /// In pl, this message translates to:
  /// **'Brak czytnika biometrycznego na tym urządzeniu. Odblokowujesz aplikację PIN-em lub wzorem.'**
  String get sec_noReaderLong;

  /// No description provided for @sec_backupCard.
  ///
  /// In pl, this message translates to:
  /// **'Zabezpieczenie zapasowe'**
  String get sec_backupCard;

  /// No description provided for @sec_backupCurrent.
  ///
  /// In pl, this message translates to:
  /// **'Aktualnie: {type}. Możesz zmienić bez wyłączania całej blokady.'**
  String sec_backupCurrent(String type);

  /// No description provided for @sec_changePin.
  ///
  /// In pl, this message translates to:
  /// **'Zmień PIN / wzór'**
  String get sec_changePin;

  /// No description provided for @people_addConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno dodać osobę „{email}\" jako {role}?'**
  String people_addConfirm(String email, String role);

  /// No description provided for @people_codeConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Wygenerować kod zaproszenia dla roli {role}?'**
  String people_codeConfirm(String role);

  /// No description provided for @people_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano osobę jako {role} ✓'**
  String people_added(String role);

  /// No description provided for @people_noAccount.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono konta „{email}\". Osoba musi najpierw założyć konto w aplikacji.'**
  String people_noAccount(String email);

  /// No description provided for @people_alreadyMember.
  ///
  /// In pl, this message translates to:
  /// **'Ta osoba już ma dostęp do wesela.'**
  String get people_alreadyMember;

  /// No description provided for @people_error.
  ///
  /// In pl, this message translates to:
  /// **'Błąd. Spróbuj ponownie.'**
  String get people_error;

  /// No description provided for @people_inviteCodeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Kod zaproszenia — {role}'**
  String people_inviteCodeTitle(String role);

  /// No description provided for @people_inviteCodeBody.
  ///
  /// In pl, this message translates to:
  /// **'Przekaż ten kod osobie. Po zalogowaniu wejdzie w „Mam kod zaproszenia\" na ekranie „Twoje wesela\" i odbierze dostęp.'**
  String get people_inviteCodeBody;

  /// No description provided for @people_codeCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano kod: {code}'**
  String people_codeCopied(String code);

  /// No description provided for @people_blockTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zablokować dostęp?'**
  String get people_blockTitle;

  /// No description provided for @people_unblockTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przywrócić dostęp?'**
  String get people_unblockTitle;

  /// No description provided for @people_blockBody.
  ///
  /// In pl, this message translates to:
  /// **'Osoba „{who}\" straci dostęp do wesela, dopóki go nie przywrócisz.'**
  String people_blockBody(String who);

  /// No description provided for @people_unblockBody.
  ///
  /// In pl, this message translates to:
  /// **'Osoba „{who}\" znów będzie miała dostęp do wesela.'**
  String people_unblockBody(String who);

  /// No description provided for @people_blocked.
  ///
  /// In pl, this message translates to:
  /// **'Zablokowano dostęp'**
  String get people_blocked;

  /// No description provided for @people_unblocked.
  ///
  /// In pl, this message translates to:
  /// **'Przywrócono dostęp'**
  String get people_unblocked;

  /// No description provided for @people_removeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć osobę?'**
  String get people_removeTitle;

  /// No description provided for @people_removeBody.
  ///
  /// In pl, this message translates to:
  /// **'Osoba „{who}\" zostanie całkowicie usunięta z wesela. Możesz ją później dodać ponownie.'**
  String people_removeBody(String who);

  /// No description provided for @people_removed.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto osobę'**
  String get people_removed;

  /// No description provided for @people_expiryTitle.
  ///
  /// In pl, this message translates to:
  /// **'Data ważności dostępu planera'**
  String get people_expiryTitle;

  /// No description provided for @people_expiryUpdated.
  ///
  /// In pl, this message translates to:
  /// **'Zaktualizowano datę ważności'**
  String get people_expiryUpdated;

  /// No description provided for @people_title.
  ///
  /// In pl, this message translates to:
  /// **'Osoby i dostęp'**
  String get people_title;

  /// No description provided for @people_add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj osobę'**
  String get people_add;

  /// No description provided for @people_intro.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj osobami z dostępem do wesela. Współorganizator ma pełny panel bez ograniczeń czasu; planer ma pełny panel z datą ważności. Ty (Para Młoda) zawsze zostajesz właścicielem.'**
  String get people_intro;

  /// No description provided for @people_you.
  ///
  /// In pl, this message translates to:
  /// **' (Ty)'**
  String get people_you;

  /// No description provided for @people_validUntil.
  ///
  /// In pl, this message translates to:
  /// **'ważny do {date}'**
  String people_validUntil(String date);

  /// No description provided for @people_code.
  ///
  /// In pl, this message translates to:
  /// **'kod: {code}'**
  String people_code(String code);

  /// No description provided for @people_actions.
  ///
  /// In pl, this message translates to:
  /// **'Akcje'**
  String get people_actions;

  /// No description provided for @people_changeExpiry.
  ///
  /// In pl, this message translates to:
  /// **'Zmień datę ważności'**
  String get people_changeExpiry;

  /// No description provided for @people_block.
  ///
  /// In pl, this message translates to:
  /// **'Zablokuj dostęp'**
  String get people_block;

  /// No description provided for @people_unblock.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć dostęp'**
  String get people_unblock;

  /// No description provided for @people_remove.
  ///
  /// In pl, this message translates to:
  /// **'Usuń osobę'**
  String get people_remove;

  /// No description provided for @people_pendingInvite.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenie (oczekuje)'**
  String get people_pendingInvite;

  /// No description provided for @people_person.
  ///
  /// In pl, this message translates to:
  /// **'Osoba'**
  String get people_person;

  /// No description provided for @people_setExpiry.
  ///
  /// In pl, this message translates to:
  /// **'Ustaw datę ważności dla planera.'**
  String get people_setExpiry;

  /// No description provided for @people_role.
  ///
  /// In pl, this message translates to:
  /// **'Rola'**
  String get people_role;

  /// No description provided for @people_plannerHint.
  ///
  /// In pl, this message translates to:
  /// **'Pełny panel z datą ważności dostępu (odcinany po dacie).'**
  String get people_plannerHint;

  /// No description provided for @people_collaboratorHint.
  ///
  /// In pl, this message translates to:
  /// **'Pełny panel bez ograniczeń czasowych (świadek, mama…).'**
  String get people_collaboratorHint;

  /// No description provided for @people_expiry.
  ///
  /// In pl, this message translates to:
  /// **'Data ważności'**
  String get people_expiry;

  /// No description provided for @people_pickDate.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz datę'**
  String get people_pickDate;

  /// No description provided for @people_howToAdd.
  ///
  /// In pl, this message translates to:
  /// **'Sposób dodania'**
  String get people_howToAdd;

  /// No description provided for @people_byEmail.
  ///
  /// In pl, this message translates to:
  /// **'Przez e-mail'**
  String get people_byEmail;

  /// No description provided for @people_byCode.
  ///
  /// In pl, this message translates to:
  /// **'Kod zaproszenia'**
  String get people_byCode;

  /// No description provided for @people_email.
  ///
  /// In pl, this message translates to:
  /// **'E-mail osoby (musi mieć konto)'**
  String get people_email;

  /// No description provided for @people_emailHint.
  ///
  /// In pl, this message translates to:
  /// **'np. jan.kowalski@gmail.com'**
  String get people_emailHint;

  /// No description provided for @people_codeHint.
  ///
  /// In pl, this message translates to:
  /// **'Wygenerujemy kod, który przekażesz osobie. Odbierze go w „Mam kod zaproszenia\" na swoim ekranie „Twoje wesela\".'**
  String get people_codeHint;

  /// No description provided for @gi_title.
  ///
  /// In pl, this message translates to:
  /// **'Interakcje gości'**
  String get gi_title;

  /// No description provided for @gi_tabGuestbook.
  ///
  /// In pl, this message translates to:
  /// **'Księga'**
  String get gi_tabGuestbook;

  /// No description provided for @gi_tabAdvice.
  ///
  /// In pl, this message translates to:
  /// **'Rady'**
  String get gi_tabAdvice;

  /// No description provided for @gi_tabMap.
  ///
  /// In pl, this message translates to:
  /// **'Mapa'**
  String get gi_tabMap;

  /// No description provided for @gi_tabCapsule.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła'**
  String get gi_tabCapsule;

  /// No description provided for @gi_tabGallery.
  ///
  /// In pl, this message translates to:
  /// **'Galeria'**
  String get gi_tabGallery;

  /// No description provided for @gi_tabChallenges.
  ///
  /// In pl, this message translates to:
  /// **'Foto-wyzwania'**
  String get gi_tabChallenges;

  /// No description provided for @gi_tabMusic.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka'**
  String get gi_tabMusic;

  /// No description provided for @gi_tabQuiz.
  ///
  /// In pl, this message translates to:
  /// **'Quiz'**
  String get gi_tabQuiz;

  /// No description provided for @gi_tabTrueFalse.
  ///
  /// In pl, this message translates to:
  /// **'Prawda/Fałsz'**
  String get gi_tabTrueFalse;

  /// No description provided for @gi_tabPhotoGuess.
  ///
  /// In pl, this message translates to:
  /// **'Zgadnij zdjęcie'**
  String get gi_tabPhotoGuess;

  /// No description provided for @gi_tabBingo.
  ///
  /// In pl, this message translates to:
  /// **'Bingo'**
  String get gi_tabBingo;

  /// No description provided for @gi_deleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wpis?'**
  String get gi_deleteTitle;

  /// No description provided for @gi_deletePhotoBody.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcie zniknie ze strony gości. Oryginał zostaje w Cloudinary.'**
  String get gi_deletePhotoBody;

  /// No description provided for @gi_deleteEntryBody.
  ///
  /// In pl, this message translates to:
  /// **'Wpis gościa zostanie trwale usunięty.'**
  String get gi_deleteEntryBody;

  /// No description provided for @gi_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać: {error}'**
  String gi_loadError(String error);

  /// No description provided for @gi_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wpisów.'**
  String get gi_empty;

  /// No description provided for @gi_authorMatched.
  ///
  /// In pl, this message translates to:
  /// **'✓ {displayName}'**
  String gi_authorMatched(String displayName);

  /// No description provided for @gi_authorUnassigned.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszona tożsamość: {displayName} (nieprzypisana)'**
  String gi_authorUnassigned(String displayName);

  /// No description provided for @gi_authorOutsidePackage.
  ///
  /// In pl, this message translates to:
  /// **'Gość spoza indywidualnych zaproszeń (wspólny link)'**
  String get gi_authorOutsidePackage;

  /// No description provided for @gi_musicNew.
  ///
  /// In pl, this message translates to:
  /// **'Nowa'**
  String get gi_musicNew;

  /// No description provided for @gi_musicAccepted.
  ///
  /// In pl, this message translates to:
  /// **'Zagramy'**
  String get gi_musicAccepted;

  /// No description provided for @gi_musicRejected.
  ///
  /// In pl, this message translates to:
  /// **'Odrzucona'**
  String get gi_musicRejected;

  /// No description provided for @gi_score.
  ///
  /// In pl, this message translates to:
  /// **'{name} — {score}/{total} pkt'**
  String gi_score(String name, int score, int total);

  /// No description provided for @gi_bingoMarked.
  ///
  /// In pl, this message translates to:
  /// **'{name} — skreślone {marked}/{total}'**
  String gi_bingoMarked(String name, int marked, int total);

  /// No description provided for @gi_proposedBy.
  ///
  /// In pl, this message translates to:
  /// **'Zaproponował(a): {name}'**
  String gi_proposedBy(String name);

  /// No description provided for @gi_challengeNo.
  ///
  /// In pl, this message translates to:
  /// **'Wyzwanie #{id}'**
  String gi_challengeNo(String id);

  /// No description provided for @gi_diet.
  ///
  /// In pl, this message translates to:
  /// **'Dieta: {diet}'**
  String gi_diet(String diet);

  /// No description provided for @gi_willAttend.
  ///
  /// In pl, this message translates to:
  /// **'Będzie'**
  String get gi_willAttend;

  /// No description provided for @gi_willNotAttend.
  ///
  /// In pl, this message translates to:
  /// **'Nie będzie'**
  String get gi_willNotAttend;

  /// No description provided for @cw_title.
  ///
  /// In pl, this message translates to:
  /// **'Nowe wesele'**
  String get cw_title;

  /// No description provided for @cw_intro.
  ///
  /// In pl, this message translates to:
  /// **'Podaj podstawowe informacje — resztę uzupełnisz później w Ustawieniach.'**
  String get cw_intro;

  /// No description provided for @cw_name.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa wesela'**
  String get cw_name;

  /// No description provided for @cw_nameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Nasze Wesele'**
  String get cw_nameHint;

  /// No description provided for @cw_defaultName.
  ///
  /// In pl, this message translates to:
  /// **'Nasze Wesele'**
  String get cw_defaultName;

  /// No description provided for @cw_coupleTypeHint.
  ///
  /// In pl, this message translates to:
  /// **'{hint}. Możesz to zmienić później w Ustawieniach → Konfiguracja.'**
  String cw_coupleTypeHint(String hint);

  /// No description provided for @cw_names.
  ///
  /// In pl, this message translates to:
  /// **'Imiona Pary Młodej (opcjonalnie)'**
  String get cw_names;

  /// {category} to etykieta kategorii Pary Młodej na liście gości.
  ///
  /// In pl, this message translates to:
  /// **'Podane imiona od razu trafią na listę gości jako „{category}\". Puste pola pomiń — dodasz je kiedy indziej.'**
  String cw_namesHint(String category);

  /// No description provided for @cw_personsHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Ania i Piotr'**
  String get cw_personsHint;

  /// No description provided for @cw_dateOptional.
  ///
  /// In pl, this message translates to:
  /// **'Data ślubu (opcjonalnie)'**
  String get cw_dateOptional;

  /// No description provided for @cw_pickDateLater.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz datę (możesz później)'**
  String get cw_pickDateLater;

  /// No description provided for @cw_children.
  ///
  /// In pl, this message translates to:
  /// **'Będą dzieci na weselu'**
  String get cw_children;

  /// No description provided for @cw_childrenHint.
  ///
  /// In pl, this message translates to:
  /// **'Możesz to zmienić później w Ustawieniach → Konfiguracja. Ceny menu dziecięcego ustawisz w Budżecie.'**
  String get cw_childrenHint;

  /// No description provided for @cw_childrenCount.
  ///
  /// In pl, this message translates to:
  /// **'Ile dzieci (orientacyjnie, opcjonalnie)'**
  String get cw_childrenCount;

  /// No description provided for @cw_childrenCountHint.
  ///
  /// In pl, this message translates to:
  /// **'np. 8'**
  String get cw_childrenCountHint;

  /// No description provided for @cw_childrenAuto.
  ///
  /// In pl, this message translates to:
  /// **'Zostaw puste, a liczba dzieci będzie liczona z listy gości — wystarczy oznaczać ich jako dzieci.'**
  String get cw_childrenAuto;

  /// No description provided for @cw_childrenManual.
  ///
  /// In pl, this message translates to:
  /// **'Podana liczba będzie użyta w wyliczeniach. Gdy wpiszesz dzieci na listę gości, przełącz liczenie na automatyczne w Budżecie.'**
  String get cw_childrenManual;

  /// No description provided for @cw_create.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz wesele'**
  String get cw_create;

  /// No description provided for @cw_firstName.
  ///
  /// In pl, this message translates to:
  /// **'Imię'**
  String get cw_firstName;

  /// No description provided for @jw_fillAll.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełnij wszystkie pola: kod, datę i nazwisko.'**
  String get jw_fillAll;

  /// No description provided for @jw_joined.
  ///
  /// In pl, this message translates to:
  /// **'Dołączono do wesela jako gość ✓'**
  String get jw_joined;

  /// No description provided for @jw_alreadyMember.
  ///
  /// In pl, this message translates to:
  /// **'Już należysz do tego wesela.'**
  String get jw_alreadyMember;

  /// No description provided for @jw_badData.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowe dane wesela. Sprawdź kod, datę ślubu i nazwisko Państwa Młodych.'**
  String get jw_badData;

  /// No description provided for @jw_connectionError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd połączenia. Spróbuj ponownie.'**
  String get jw_connectionError;

  /// No description provided for @jw_title.
  ///
  /// In pl, this message translates to:
  /// **'Dołącz do wesela'**
  String get jw_title;

  /// No description provided for @jw_codeHint.
  ///
  /// In pl, this message translates to:
  /// **'np. ABCD-EFGH-JKMN'**
  String get jw_codeHint;

  /// No description provided for @jw_scan.
  ///
  /// In pl, this message translates to:
  /// **'Skanuj'**
  String get jw_scan;

  /// No description provided for @jw_surnameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Kowalscy / Ania i Piotr'**
  String get jw_surnameHint;

  /// No description provided for @jw_checking.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdzanie…'**
  String get jw_checking;

  /// No description provided for @jw_intro.
  ///
  /// In pl, this message translates to:
  /// **'Aby potwierdzić, że jesteś zaproszonym gościem, podaj trzy dane z zaproszenia: kod wesela, datę ślubu i nazwisko Państwa Młodych. Wszystkie muszą się zgadzać.'**
  String get jw_intro;

  /// No description provided for @jw_scanTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj kod QR'**
  String get jw_scanTitle;

  /// No description provided for @jw_scanHint.
  ///
  /// In pl, this message translates to:
  /// **'Skieruj aparat na kod QR z zaproszenia'**
  String get jw_scanHint;

  /// No description provided for @wl_createFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się utworzyć wesela: {error}'**
  String wl_createFailed(String error);

  /// No description provided for @wl_create.
  ///
  /// In pl, this message translates to:
  /// **'Załóż wesele'**
  String get wl_create;

  /// No description provided for @wl_haveCodeLong.
  ///
  /// In pl, this message translates to:
  /// **'Mam kod zaproszenia (współorganizator / planer)'**
  String get wl_haveCodeLong;

  /// No description provided for @wl_haveCode.
  ///
  /// In pl, this message translates to:
  /// **'Mam kod zaproszenia'**
  String get wl_haveCode;

  /// No description provided for @wl_haveCodeBody.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz kod otrzymany od Pary Młodej, aby odebrać dostęp jako współorganizator lub planer.'**
  String get wl_haveCodeBody;

  /// No description provided for @wl_redeem.
  ///
  /// In pl, this message translates to:
  /// **'Odbierz'**
  String get wl_redeem;

  /// No description provided for @wl_redeemed.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp odebrany ✓'**
  String get wl_redeemed;

  /// No description provided for @wl_alreadyAccess.
  ///
  /// In pl, this message translates to:
  /// **'Już masz dostęp do tego wesela.'**
  String get wl_alreadyAccess;

  /// No description provided for @wl_badCode.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy lub wykorzystany kod zaproszenia.'**
  String get wl_badCode;

  /// No description provided for @wl_error.
  ///
  /// In pl, this message translates to:
  /// **'Błąd. Spróbuj ponownie.'**
  String get wl_error;

  /// No description provided for @wl_preparing.
  ///
  /// In pl, this message translates to:
  /// **'Przygotowuję strefę gości…'**
  String get wl_preparing;

  /// No description provided for @wl_failed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się: {error}'**
  String wl_failed(String error);

  /// No description provided for @wl_nothingToPrepare.
  ///
  /// In pl, this message translates to:
  /// **'Brak wesel do przygotowania'**
  String get wl_nothingToPrepare;

  /// No description provided for @wl_prepareResult.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe: {ok} z {total}'**
  String wl_prepareResult(int ok, int total);

  /// No description provided for @wl_noFullAccess.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz wesel z pełnym dostępem. Wesela, w których jesteś tylko gościem, przygotowuje ich organizator.'**
  String get wl_noFullAccess;

  /// No description provided for @wl_itemOk.
  ///
  /// In pl, this message translates to:
  /// **'gotowe ✓'**
  String get wl_itemOk;

  /// No description provided for @wl_itemError.
  ///
  /// In pl, this message translates to:
  /// **'BŁĄD: {error}'**
  String wl_itemError(String error);

  /// No description provided for @wl_title.
  ///
  /// In pl, this message translates to:
  /// **'Twoje wesela'**
  String get wl_title;

  /// No description provided for @wl_subtitle.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz wesele lub utwórz nowe'**
  String get wl_subtitle;

  /// No description provided for @wl_more.
  ///
  /// In pl, this message translates to:
  /// **'Więcej'**
  String get wl_more;

  /// No description provided for @wl_prepareGuestZone.
  ///
  /// In pl, this message translates to:
  /// **'Przygotuj strefę gości'**
  String get wl_prepareGuestZone;

  /// No description provided for @wl_prepareForAll.
  ///
  /// In pl, this message translates to:
  /// **'Dla wszystkich Twoich wesel'**
  String get wl_prepareForAll;

  /// No description provided for @wl_empty.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz jeszcze żadnego wesela'**
  String get wl_empty;

  /// No description provided for @wl_emptyBody.
  ///
  /// In pl, this message translates to:
  /// **'Załóż pierwsze wesele, aby rozpocząć organizację. Możesz też dołączyć do wesela, do którego ktoś Cię zaprosi.'**
  String get wl_emptyBody;

  /// No description provided for @wl_createFirst.
  ///
  /// In pl, this message translates to:
  /// **'Załóż pierwsze wesele'**
  String get wl_createFirst;

  /// No description provided for @wl_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać wesel'**
  String get wl_loadError;

  /// No description provided for @wl_dateTbd.
  ///
  /// In pl, this message translates to:
  /// **'Data do ustalenia'**
  String get wl_dateTbd;

  /// No description provided for @setup_todo.
  ///
  /// In pl, this message translates to:
  /// **'Do uzupełnienia ({count})'**
  String setup_todo(int count);

  /// No description provided for @setup_basic.
  ///
  /// In pl, this message translates to:
  /// **'Podstawowa'**
  String get setup_basic;

  /// No description provided for @setup_advanced.
  ///
  /// In pl, this message translates to:
  /// **'Zaawansowana'**
  String get setup_advanced;

  /// No description provided for @setup_progress.
  ///
  /// In pl, this message translates to:
  /// **'{done}/{total} gotowe'**
  String setup_progress(int done, int total);

  /// No description provided for @setup_allDone.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko uzupełnione ✓'**
  String get setup_allDone;

  /// No description provided for @setup_partial.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełniono {done} z {total} — zostało {left}'**
  String setup_partial(int done, int total, int left);

  /// No description provided for @setup_basicDone.
  ///
  /// In pl, this message translates to:
  /// **'Podstawy gotowe. Zajrzyj do zaawansowanej, żeby dopracować budżet, stoły i strefę gości.'**
  String get setup_basicDone;

  /// No description provided for @setup_complete.
  ///
  /// In pl, this message translates to:
  /// **'Komplet — wszystkie dane wesela uzupełnione.'**
  String get setup_complete;

  /// No description provided for @setup_done.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe ({count})'**
  String setup_done(int count);

  /// No description provided for @setup_goTo.
  ///
  /// In pl, this message translates to:
  /// **'→ {section}'**
  String setup_goTo(String section);

  /// No description provided for @setup_fix.
  ///
  /// In pl, this message translates to:
  /// **'Popraw'**
  String get setup_fix;

  /// No description provided for @setup_go.
  ///
  /// In pl, this message translates to:
  /// **'Przejdź'**
  String get setup_go;

  /// No description provided for @plan_newStep.
  ///
  /// In pl, this message translates to:
  /// **'Nowy krok'**
  String get plan_newStep;

  /// No description provided for @plan_resetTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przywrócić domyślną listę?'**
  String get plan_resetTitle;

  /// No description provided for @plan_resetBody.
  ///
  /// In pl, this message translates to:
  /// **'Lista kroków „Od czego zacząć?\" wróci do domyślnej. Wprowadzone zmiany zostaną utracone.'**
  String get plan_resetBody;

  /// No description provided for @plan_reset.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć'**
  String get plan_reset;

  /// No description provided for @plan_orderTitle.
  ///
  /// In pl, this message translates to:
  /// **'Sugerowana kolejność planowania wesela'**
  String get plan_orderTitle;

  /// No description provided for @plan_orderHint.
  ///
  /// In pl, this message translates to:
  /// **'Odhaczaj ukończone kroki — pasek pokaże postęp.'**
  String get plan_orderHint;

  /// No description provided for @plan_progress.
  ///
  /// In pl, this message translates to:
  /// **'{done} z {total} ukończonych · {pct}%'**
  String plan_progress(int done, int total, int pct);

  /// No description provided for @plan_deleteStep.
  ///
  /// In pl, this message translates to:
  /// **'Usuń krok'**
  String get plan_deleteStep;

  /// No description provided for @plan_addStep.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj krok'**
  String get plan_addStep;

  /// No description provided for @plan_resetDefaults.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć domyślne'**
  String get plan_resetDefaults;

  /// No description provided for @people_codeConfirmUntil.
  ///
  /// In pl, this message translates to:
  /// **'Wygenerować kod zaproszenia dla roli {role} (ważny do {date})?'**
  String people_codeConfirmUntil(String role, String date);

  /// No description provided for @gh_title.
  ///
  /// In pl, this message translates to:
  /// **'Wesele'**
  String get gh_title;

  /// No description provided for @gh_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać strefy gości.'**
  String get gh_loadError;

  /// No description provided for @gh_loadErrorHint.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź połączenie z internetem i spróbuj ponownie.'**
  String get gh_loadErrorHint;

  /// No description provided for @gh_notReady.
  ///
  /// In pl, this message translates to:
  /// **'Strefa gości nie jest jeszcze gotowa'**
  String get gh_notReady;

  /// No description provided for @gh_notReadyBody.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda jeszcze jej nie przygotowała. Zajrzyj później albo poproś ją o udostępnienie sekcji dla gości.'**
  String get gh_notReadyBody;

  /// No description provided for @gh_account.
  ///
  /// In pl, this message translates to:
  /// **'Konto'**
  String get gh_account;

  /// No description provided for @gh_guide.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik'**
  String get gh_guide;

  /// No description provided for @gh_switchWedding.
  ///
  /// In pl, this message translates to:
  /// **'Zmień wesele'**
  String get gh_switchWedding;

  /// No description provided for @sec_backupPin.
  ///
  /// In pl, this message translates to:
  /// **'PIN'**
  String get sec_backupPin;

  /// Zapasowa metoda odblokowania; użyta w zdaniu „Aktualnie: wzór.".
  ///
  /// In pl, this message translates to:
  /// **'wzór'**
  String get sec_backupPattern;

  /// Komunikat systemowego okna biometrii (Android/iOS).
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź tożsamość, aby odblokować aplikację'**
  String get bio_reason;

  /// No description provided for @bio_signInTitle.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie biometryczne'**
  String get bio_signInTitle;

  /// No description provided for @bio_hint.
  ///
  /// In pl, this message translates to:
  /// **'Zweryfikuj tożsamość'**
  String get bio_hint;

  /// No description provided for @bio_notRecognized.
  ///
  /// In pl, this message translates to:
  /// **'Nie rozpoznano — spróbuj ponownie'**
  String get bio_notRecognized;

  /// No description provided for @bio_success.
  ///
  /// In pl, this message translates to:
  /// **'Rozpoznano'**
  String get bio_success;

  /// No description provided for @bio_settings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get bio_settings;

  /// No description provided for @bio_settingsHint.
  ///
  /// In pl, this message translates to:
  /// **'Skonfiguruj biometrię w ustawieniach urządzenia.'**
  String get bio_settingsHint;

  /// Nazwa kategorii na ekranie Pomocy (rozwijana sekcja).
  ///
  /// In pl, this message translates to:
  /// **'Start'**
  String get help_start_title;

  /// No description provided for @help_start_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Pulpit'**
  String get help_start_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Licznik dni do ślubu, skróty do sekcji i najważniejsze statystyki. Układ kafelków ustawiasz sam — możesz ukryć te, których nie używasz.'**
  String get help_start_1Body;

  /// No description provided for @help_start_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Od czego zacząć?'**
  String get help_start_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki, a pasek pokaże postęp. Otworzysz ją z Ustawień w dowolnym momencie — lista jest wspólna dla wszystkich organizatorów wesela.'**
  String get help_start_2Body;

  /// No description provided for @help_start_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik a Pomoc'**
  String get help_start_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik prowadzi po aplikacji krok po kroku i podświetla elementy na ekranie. Pomoc (ten ekran) to encyklopedia funkcji do czytania wtedy, gdy szukasz konkretnej odpowiedzi.'**
  String get help_start_3Body;

  /// No description provided for @help_guests_title.
  ///
  /// In pl, this message translates to:
  /// **'Goście'**
  String get help_guests_title;

  /// No description provided for @help_guests_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Lista gości'**
  String get help_guests_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Dodawaj zaproszonych i zarządzaj ich danymi. Każdy gość może mieć osobę towarzyszącą — dodaj ją przy wpisie, a nie jako osobnego gościa, dzięki czemu liczby w podsumowaniu się zgadzają.'**
  String get help_guests_1Body;

  /// No description provided for @help_guests_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Kartoteka'**
  String get help_guests_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Szczegóły przydatne przy organizacji: dieta, alergie, wiek, potrzeba noclegu i transportu, uwagi. Te dane napędzają też kalkulacje w Budżecie i przypisania w Noclegach.'**
  String get help_guests_2Body;

  /// No description provided for @help_guests_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Podsumowanie gości'**
  String get help_guests_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Zbiorcze liczby: zaproszeni, potwierdzeni, dzieci, diety. Sprawdź je przed rozmową z salą — to na ich podstawie ustala się catering.'**
  String get help_guests_3Body;

  /// No description provided for @help_guests_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenia obecności (RSVP)'**
  String get help_guests_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Masz dwa źródła: wpisy, które sam dodasz w panelu, oraz potwierdzenia przysłane przez gości ze strefy gości. Te drugie znajdziesz w Ustawieniach → Interakcje gości → RSVP. Każdy gość może wysłać jedno potwierdzenie i sam je poprawić, jeśli plany się zmienią.'**
  String get help_guests_4Body;

  /// No description provided for @help_budget_title.
  ///
  /// In pl, this message translates to:
  /// **'Budżet'**
  String get help_budget_title;

  /// No description provided for @help_budget_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Jedno źródło danych — najważniejsza zasada'**
  String get help_budget_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Pozycja dodana w Dostawcach, Prezentach czy Podróży poślubnej pojawia się w Budżecie automatycznie, z etykietą „dodano w…\". Edytuj ją tam, gdzie powstała — dzięki temu nic nie liczy się podwójnie i nie musisz pilnować dwóch list.'**
  String get help_budget_1Body;

  /// No description provided for @help_budget_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Podsumowanie budżetu'**
  String get help_budget_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Limit kontra wydatki, ile zostało do rozdysponowania oraz zestawienie wszystkich płatności i terminów w jednym miejscu.'**
  String get help_budget_2Body;

  /// No description provided for @help_budget_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Sala i catering'**
  String get help_budget_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Stawkę podajesz za osobę, a aplikacja przelicza koszt z liczby gości. Możesz osobno wliczyć obsługę (fotograf, zespół), dzieci po innej stawce i gości jeszcze nieprzypisanych do stołów. Ustaw też minimum gwarantowane przez salę, jeśli umowa je przewiduje.'**
  String get help_budget_3Body;

  /// No description provided for @help_budget_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Wydatki'**
  String get help_budget_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Pozostałe koszty pogrupowane w kategorie. Kategorie edytujesz w Ustawieniach → Konfiguracja.'**
  String get help_budget_4Body;

  /// No description provided for @help_budget_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Alkohol i napoje'**
  String get help_budget_5Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Rodzaje, ilości i ceny — osobno alkohol, osobno napoje bezalkoholowe. Przydaje się przy ustalaniu, co bierzecie własne, a co z sali.'**
  String get help_budget_5Body;

  /// No description provided for @help_budget_6Title.
  ///
  /// In pl, this message translates to:
  /// **'Podróż poślubna'**
  String get help_budget_6Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Liczona osobno od kosztów wesela, żeby nie zaburzała budżetu przyjęcia — ale jej płatności widać w Podsumowaniu razem z pozostałymi.'**
  String get help_budget_6Body;

  /// No description provided for @help_budget_7Title.
  ///
  /// In pl, this message translates to:
  /// **'Raty i terminy płatności'**
  String get help_budget_7Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Przy dostawcy lub wydatku rozpisz raty z datami. Nadchodzące terminy zobaczysz w Podsumowaniu budżetu i na pulpicie.'**
  String get help_budget_7Body;

  /// No description provided for @help_room_title.
  ///
  /// In pl, this message translates to:
  /// **'Plan sali'**
  String get help_room_title;

  /// No description provided for @help_room_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Układanie sali'**
  String get help_room_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Włącz „Edytuj plan\", aby przeciągać stoły i elementy oraz zmieniać ich rozmiar. Poza trybem edycji plan służy do przeglądania i przypisywania gości — trudniej wtedy coś przypadkiem przesunąć.'**
  String get help_room_1Body;

  /// No description provided for @help_room_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Przypisywanie gości do stołów'**
  String get help_room_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Przeciągnij gościa na miejsce przy stole. Goście nieprzypisani są widoczni osobno — pamiętaj o nich, bo mogą wliczać się do kosztu cateringu, zależnie od ustawień w Budżecie.'**
  String get help_room_2Body;

  /// No description provided for @help_room_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Stoły obsługi'**
  String get help_room_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Stoliki dla fotografa, zespołu czy obsługi oznacz osobno — mają własną stawkę cateringową i nie mieszają się z listą gości.'**
  String get help_room_3Body;

  /// No description provided for @help_schedule_title.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram i zadania'**
  String get help_schedule_title;

  /// No description provided for @help_schedule_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Plan dnia'**
  String get help_schedule_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Punkty programu z godzinami, kategorią i miejscem. To najważniejszy dokument dnia ślubu — przyda się fotografowi, zespołowi i obsłudze sali.'**
  String get help_schedule_1Body;

  /// No description provided for @help_schedule_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Punkt prywatny'**
  String get help_schedule_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Punkt oznaczony jako prywatny NIE trafia do strefy gości. Używaj go do spraw organizacyjnych: „przyjazd florystki\", „rozliczenie z salą\".'**
  String get help_schedule_2Body;

  /// No description provided for @help_schedule_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Link do miejsca dla gości'**
  String get help_schedule_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Przy punkcie możesz podać link do mapy i osobno zdecydować, czy pokazać go gościom. Bez zaznaczenia tej opcji link zostaje tylko dla Was.'**
  String get help_schedule_3Body;

  /// No description provided for @help_schedule_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Checklista'**
  String get help_schedule_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Lista rzeczy do odhaczenia przed weselem i w jego trakcie — osobna od Zadań, bo służy do szybkiego „zrobione / niezrobione\".'**
  String get help_schedule_4Body;

  /// No description provided for @help_schedule_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Zadania i powiązania'**
  String get help_schedule_5Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Zadaniu możesz przypisać osobę odpowiedzialną i powiązać je z wydatkiem, dostawcą lub prezentem. Dzięki temu z jednego miejsca widzisz, co zostało do zrobienia i ile to kosztuje.'**
  String get help_schedule_5Body;

  /// No description provided for @help_vendors_title.
  ///
  /// In pl, this message translates to:
  /// **'Dostawcy, transport, noclegi'**
  String get help_vendors_title;

  /// No description provided for @help_vendors_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Dostawcy'**
  String get help_vendors_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Kontakty, kwoty umów, statusy płatności i raty. Kwota dostawcy trafia do Budżetu automatycznie — nie dodawaj jej drugi raz jako wydatku.'**
  String get help_vendors_1Body;

  /// No description provided for @help_vendors_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Transport'**
  String get help_vendors_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Trasy, pojazdy i przypisanie pasażerów. Informacja „potrzebuje transportu\" pochodzi z kartoteki gościa.'**
  String get help_vendors_2Body;

  /// No description provided for @help_vendors_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Noclegi'**
  String get help_vendors_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Obiekty, pokoje i rezerwacje dla gości. Podobnie jak transport — korzysta z oznaczeń w kartotece.'**
  String get help_vendors_3Body;

  /// No description provided for @help_guestZone_title.
  ///
  /// In pl, this message translates to:
  /// **'Strefa gości'**
  String get help_guestZone_title;

  /// No description provided for @help_guestZone_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Link i kod QR dla gości'**
  String get help_guestZone_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia → „Link i QR dla gości\". Gość otwiera stronę bez logowania i bez instalowania aplikacji. Ten kod drukujesz na zaproszeniach albo kładziesz na stołach.'**
  String get help_guestZone_1Body;

  /// No description provided for @help_guestZone_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Kod dołączenia (konto gościa)'**
  String get help_guestZone_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Sześcioznakowy kod dla gościa, który chce mieć wesele na własnym koncie. Weryfikacja jest potrójna: kod, data ślubu i nazwisko — sam kod nie wystarczy, bo bywa jawny na stołach.'**
  String get help_guestZone_2Body;

  /// No description provided for @help_guestZone_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Widoczność sekcji dla gości'**
  String get help_guestZone_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Decydujesz, które sekcje widzą goście i w jakim okresie (daty OD/DO). Wybierasz też, co się dzieje poza zakresem: komunikat „dostępne od…\" albo całkowite ukrycie kafelka. Typowo: RSVP włącz od razu, galerię dopiero w dniu wesela.'**
  String get help_guestZone_3Body;

  /// No description provided for @help_guestZone_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Interakcje gości i moderacja'**
  String get help_guestZone_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia → „Interakcje gości\". W jednym miejscu zbierają się potwierdzenia, wpisy księgi, rady, zdjęcia, propozycje muzyki i wyniki gier. Każdy wpis możesz usunąć jednym kliknięciem.'**
  String get help_guestZone_4Body;

  /// No description provided for @help_guestZone_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Czego gość nie widzi'**
  String get help_guestZone_5Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Budżet, pełna lista gości, dostawcy, plan sali i zadania są dla gościa niedostępne — i nie chodzi o ukrycie w interfejsie, tylko o techniczny brak dostępu do tych danych.'**
  String get help_guestZone_5Body;

  /// No description provided for @help_media_title.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcia i muzyka'**
  String get help_media_title;

  /// No description provided for @help_media_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Galeria'**
  String get help_media_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Wspólny album: goście wrzucają zdjęcia ze swoich telefonów, Wy widzicie wszystko w panelu i możecie usuwać niechciane wpisy.'**
  String get help_media_1Body;

  /// No description provided for @help_media_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka i propozycje gości'**
  String get help_media_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Budujesz playlistę wesela, a goście przysyłają propozycje utworów. Propozycje widzicie tylko Wy — nie ma publicznej listy ani głosowania. Każdą oznaczysz jako „Zagramy\" lub „Odrzucona\".'**
  String get help_media_2Body;

  /// No description provided for @help_games_title.
  ///
  /// In pl, this message translates to:
  /// **'Gry i pamiątki'**
  String get help_games_title;

  /// No description provided for @help_games_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Quiz, Prawda/Fałsz, Zgadnij zdjęcie'**
  String get help_games_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pytania i włącz grę przełącznikiem „aktywna\". Gość gra na swoim telefonie, a wynik trafia do Was. Publicznego rankingu nie ma — nikt nie porównuje się z innymi.'**
  String get help_games_1Body;

  /// No description provided for @help_games_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Foto-wyzwania'**
  String get help_games_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Lista zadań fotograficznych z punktami. Gość wysyła po jednym zdjęciu do każdego wyzwania; kolejne zastępuje poprzednie.'**
  String get help_games_2Body;

  /// No description provided for @help_games_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne Bingo'**
  String get help_games_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Pola bingo możesz wpisać ręcznie lub wygenerować z punktów harmonogramu. Plansze drukujesz do PDF, a goście mogą też grać na telefonie.'**
  String get help_games_3Body;

  /// No description provided for @help_games_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Pamiątki'**
  String get help_games_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Księga gości, rady dla Pary Młodej, kapsuła czasu i mapa gości. Kapsuła jest prywatna — czytacie ją tylko Wy.'**
  String get help_games_4Body;

  /// No description provided for @help_roles_title.
  ///
  /// In pl, this message translates to:
  /// **'Role i dostęp'**
  String get help_roles_title;

  /// No description provided for @help_roles_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Właściciel ma władzę nadrzędną'**
  String get help_roles_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Konto Pary Młodej jest najważniejsze. Tylko właściciel dodaje osoby, wystawia zaproszenia i może każdemu odebrać dostęp — także planerowi.'**
  String get help_roles_1Body;

  /// No description provided for @help_roles_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Współorganizator'**
  String get help_roles_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Świadek, mama, przyjaciółka — pełny panel bez daty ważności. Nie może jednak dodawać kolejnych osób; to zostaje przy właścicielu.'**
  String get help_roles_2Body;

  /// No description provided for @help_roles_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Planer i data ważności'**
  String get help_roles_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Planerowi możesz nadać dostęp z datą wygaśnięcia. Po tej dacie wesele znika z jego listy. Dostęp da się w każdej chwili zablokować i przywrócić — wielokrotnie.'**
  String get help_roles_3Body;

  /// No description provided for @help_roles_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Jak dodać planera lub współorganizatora — krok po kroku'**
  String get help_roles_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia → „Osoby i dostęp\" → „Dodaj osobę\". Wybierz rolę (Współorganizator albo Planer), a przy planerze ustaw datę ważności dostępu. Potem masz dwie drogi: podać adres e-mail osoby (musi już mieć konto w aplikacji) albo wygenerować kod zaproszenia i przekazać go dowolnym kanałem. Zaproszenie dodaje osobę tylko do TEGO wesela — przy kilku weselach każde wymaga osobnego zaproszenia.'**
  String get help_roles_4Body;

  /// No description provided for @help_roles_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Jak działa kod zaproszenia'**
  String get help_roles_5Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Kod jest jednorazowy i przypisany do konkretnego wesela oraz roli. Osoba, która go dostanie, zakłada konto (albo loguje się na istniejące), a następnie na liście wesel wybiera „Mam kod zaproszenia (współorganizator / planer)\" i wpisuje go. Po wykorzystaniu kod przestaje działać — dla kolejnej osoby wygeneruj nowy. To inna ścieżka niż kod dla gości, którym goście dołączają do strefy gościa.'**
  String get help_roles_5Body;

  /// No description provided for @help_roles_6Title.
  ///
  /// In pl, this message translates to:
  /// **'Data ważności dostępu planera'**
  String get help_roles_6Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Datę ustawiasz przy zapraszaniu i zmieniasz później na liście osób. Po jej upływie wesele znika z listy planera i traci on dostęp do danych — bez usuwania czegokolwiek u Ciebie. Datę można przesunąć, a dostęp zablokować i przywrócić wielokrotnie. Współorganizator daty ważności nie ma.'**
  String get help_roles_6Body;

  /// No description provided for @help_roles_7Title.
  ///
  /// In pl, this message translates to:
  /// **'Odbieranie dostępu'**
  String get help_roles_7Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Na liście „Osoby i dostęp\" przy każdej osobie znajdziesz blokadę i usunięcie. Blokada zostawia osobę na liście (można ją odblokować), usunięcie kasuje członkostwo — powrót wymaga nowego zaproszenia. Właściciela nie da się usunąć.'**
  String get help_roles_7Body;

  /// No description provided for @help_analytics_title.
  ///
  /// In pl, this message translates to:
  /// **'Analityka'**
  String get help_analytics_title;

  /// No description provided for @help_analytics_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Wykresy i statystyki'**
  String get help_analytics_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Postępy organizacji, struktura kosztów i frekwencja. Dobre miejsce, by sprawdzić, czy budżet nie rozjeżdża się z planem.'**
  String get help_analytics_1Body;

  /// No description provided for @help_settings_title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia i dane'**
  String get help_settings_title;

  /// No description provided for @help_settings_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja wesela'**
  String get help_settings_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa, data, godzina, miejsca ceremonii i przyjęcia, podział kosztów oraz słowniki (menu, kategorie wydatków). Po zmianie daty lub nazwisk zapisz konfigurację — odświeża to dane dołączania gości.'**
  String get help_settings_1Body;

  /// No description provided for @help_settings_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Synchronizacja'**
  String get help_settings_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Dane zapisują się w chmurze i są wspólne dla wszystkich organizatorów wesela. Kartę statusu znajdziesz na górze Ustawień.'**
  String get help_settings_2Body;

  /// No description provided for @help_settings_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Kopie zapasowe i eksport'**
  String get help_settings_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Możesz utworzyć kopię zapasową oraz wyeksportować wszystkie dane do pliku JSON. Import nadpisuje dane wesela — używaj ostrożnie.'**
  String get help_settings_3Body;

  /// No description provided for @help_settings_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Blokada aplikacji'**
  String get help_settings_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'PIN, wzór lub biometria zabezpieczają dostęp na tym urządzeniu. Ustawienie jest lokalne — nie przenosi się na inne telefony.'**
  String get help_settings_4Body;

  /// No description provided for @help_planner_title.
  ///
  /// In pl, this message translates to:
  /// **'Praca z klientami'**
  String get help_planner_title;

  /// No description provided for @help_planner_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Wiele wesel na jednym koncie'**
  String get help_planner_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Możesz prowadzić dowolnie wiele wesel. Przełączasz je w menu pod logo → „Zmień wesele\". Dane każdego wesela są w pełni oddzielone — klient A nigdy nie zobaczy wesela klienta B.'**
  String get help_planner_1Body;

  /// No description provided for @help_planner_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Twój dostęp bywa czasowy'**
  String get help_planner_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda może nadać Ci dostęp z datą ważności oraz zablokować go i przywrócić. Gdy wesele zniknie z Twojej listy, to najczęściej wygasła data, a nie awaria — poproś klienta o przedłużenie.'**
  String get help_planner_2Body;

  /// No description provided for @help_planner_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Czego planer nie może'**
  String get help_planner_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Dodawanie osób i wystawianie zaproszeń jest zarezerwowane dla właściciela wesela. To celowe: klient ma zawsze kontrolę nad tym, kto ma dostęp do jego danych.'**
  String get help_planner_3Body;

  /// No description provided for @help_planner_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Przekazanie wesela Parze'**
  String get help_planner_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Nie ma osobnego „przekazania\" — wesele od początku należy do Pary Młodej. Gdy kończycie współpracę, po prostu tracisz dostęp, a wszystkie dane zostają u klienta. Nic nie trzeba eksportować.'**
  String get help_planner_4Body;

  /// No description provided for @help_planner_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Dane osobowe klientów'**
  String get help_planner_5Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Lista gości zawiera dane osobowe: nazwiska, telefony, adresy e-mail, informacje o dietach. Traktuj je poufnie i nie przenoś między weselami.'**
  String get help_planner_5Body;

  /// No description provided for @help_planner_6Title.
  ///
  /// In pl, this message translates to:
  /// **'Co pokazać klientowi'**
  String get help_planner_6Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Najczęściej sprawdzają się: Podsumowanie budżetu (na co idą pieniądze), plan sali (wydruk) i harmonogram dnia. Analityka daje gotowy materiał na podsumowanie postępów.'**
  String get help_planner_6Body;

  /// No description provided for @help_gStart_title.
  ///
  /// In pl, this message translates to:
  /// **'Na start'**
  String get help_gStart_title;

  /// No description provided for @help_gStart_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Czym jest ta strona'**
  String get help_gStart_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'To strefa gości przygotowana przez Parę Młodą. Nie musisz zakładać konta ani niczego instalować — wystarczy link lub kod QR z zaproszenia.'**
  String get help_gStart_1Body;

  /// No description provided for @help_gStart_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Nie widzę jakiejś sekcji'**
  String get help_gStart_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda sama decyduje, co i kiedy udostępnia. Część sekcji pojawia się dopiero bliżej wesela, a niektóre znikają po nim. Zajrzyj później.'**
  String get help_gStart_2Body;

  /// No description provided for @help_gRsvp_title.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenie obecności'**
  String get help_gRsvp_title;

  /// No description provided for @help_gRsvp_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Jak potwierdzić obecność'**
  String get help_gRsvp_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Wejdź w RSVP, wpisz imię i nazwisko, zaznacz, czy będziesz, i wyślij. Jeśli przyjeżdżasz z kimś, podaj liczbę osób towarzyszących — nie wypełniaj formularza drugi raz za tę osobę.'**
  String get help_gRsvp_1Body;

  /// No description provided for @help_gRsvp_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Zmiana odpowiedzi'**
  String get help_gRsvp_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Wystarczy jedno potwierdzenie. Gdy plany się zmienią, wróć do RSVP — formularz wypełni się Twoją poprzednią odpowiedzią, a po zapisaniu zastąpi ją nowa.'**
  String get help_gRsvp_2Body;

  /// No description provided for @help_gRsvp_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Dieta i alergie'**
  String get help_gRsvp_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz je w formularzu potwierdzenia. Ta informacja trafia prosto do Pary Młodej i pomaga ustalić menu z salą.'**
  String get help_gRsvp_3Body;

  /// No description provided for @help_gPhotos_title.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcia'**
  String get help_gPhotos_title;

  /// No description provided for @help_gPhotos_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Dodawanie zdjęć'**
  String get help_gPhotos_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'W Galerii podaj imię, wybierz zdjęcie z telefonu lub zrób je od razu aparatem. Możesz dorzucić podpis. Zdjęć możesz dodać dowolnie wiele.'**
  String get help_gPhotos_1Body;

  /// No description provided for @help_gPhotos_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Kto widzi moje zdjęcia'**
  String get help_gPhotos_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Galeria jest wspólna — widzą ją wszyscy goście z linkiem oraz Para Młoda. Para może usunąć każde zdjęcie.'**
  String get help_gPhotos_2Body;

  /// No description provided for @help_gMusic_title.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka'**
  String get help_gMusic_title;

  /// No description provided for @help_gMusic_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Propozycja utworu'**
  String get help_gMusic_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Wyszukaj piosenkę albo wpisz tytuł i wykonawcę ręcznie, a potem wyślij propozycję. Jeśli wyszukiwarka nie działa (bywa tak w przeglądarce), skorzystaj z pól ręcznych — efekt jest taki sam.'**
  String get help_gMusic_1Body;

  /// No description provided for @help_gMusic_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Kto widzi propozycje'**
  String get help_gMusic_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Tylko Para Młoda. Nie ma publicznej listy ani głosowania, więc nikt nie podejrzy, co zaproponowali inni.'**
  String get help_gMusic_2Body;

  /// No description provided for @help_gSchedule_title.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram'**
  String get help_gSchedule_title;

  /// No description provided for @help_gSchedule_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Plan dnia'**
  String get help_gSchedule_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Godzina po godzinie: ceremonia, przyjęcie, tort, pierwszy taniec. U góry zobaczysz licznik dni do wesela.'**
  String get help_gSchedule_1Body;

  /// No description provided for @help_gGames_title.
  ///
  /// In pl, this message translates to:
  /// **'Gry'**
  String get help_gGames_title;

  /// No description provided for @help_gGames_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Quiz, Prawda/Fałsz, Zgadnij zdjęcie'**
  String get help_gGames_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedz na wszystkie pytania i wyślij wynik. Możesz podejść ponownie — nowy wynik zastąpi poprzedni, więc nic nie tracisz.'**
  String get help_gGames_1Body;

  /// No description provided for @help_gGames_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Foto-wyzwania'**
  String get help_gGames_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Lista zadań fotograficznych. Do każdego wyzwania wysyłasz jedno zdjęcie; kolejne zastąpi poprzednie. Zdjęcia widzą wszyscy goście.'**
  String get help_gGames_2Body;

  /// No description provided for @help_gGames_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne Bingo'**
  String get help_gGames_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Skreślaj pola, gdy zobaczysz je na weselu. Skreślenia zostają na Twoim telefonie — wyślij zgłoszenie dopiero, gdy uzbierasz komplet.'**
  String get help_gGames_3Body;

  /// No description provided for @help_gGames_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Kto widzi wyniki'**
  String get help_gGames_4Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Wyłącznie Para Młoda. Nie ma publicznego rankingu, więc graj dla zabawy, a nie dla rywalizacji.'**
  String get help_gGames_4Body;

  /// No description provided for @help_gKeepsakes_title.
  ///
  /// In pl, this message translates to:
  /// **'Pamiątki'**
  String get help_gKeepsakes_title;

  /// No description provided for @help_gKeepsakes_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Księga gości i rady'**
  String get help_gKeepsakes_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Zostaw życzenia albo dobrą radę dla Pary Młodej. Wpisów możesz dodać kilka, a widzą je też inni goście — to trochę wspólna kronika.'**
  String get help_gKeepsakes_1Body;

  /// No description provided for @help_gKeepsakes_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła czasu'**
  String get help_gKeepsakes_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Prywatna wiadomość do Pary Młodej. Nie zobaczy jej żaden inny gość.'**
  String get help_gKeepsakes_2Body;

  /// No description provided for @help_gKeepsakes_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Mapa gości'**
  String get help_gKeepsakes_3Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Zaznacz, skąd przyjeżdżasz. Jedna pinezka na gościa — możesz ją poprawić, wracając do sekcji.'**
  String get help_gKeepsakes_3Body;

  /// No description provided for @help_gPrivacy_title.
  ///
  /// In pl, this message translates to:
  /// **'Prywatność'**
  String get help_gPrivacy_title;

  /// No description provided for @help_gPrivacy_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Co widzi Para Młoda'**
  String get help_gPrivacy_1Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Twoje potwierdzenie obecności, wpisy, zdjęcia, propozycje muzyczne i wyniki gier — zawsze z imieniem, które podasz.'**
  String get help_gPrivacy_1Body;

  /// No description provided for @help_gPrivacy_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Czego nie widzą inni goście'**
  String get help_gPrivacy_2Title;

  /// Pomoc — treść hasła. Tekst ciągły, bez podstawień; można swobodnie dostosować długość zdań do języka.
  ///
  /// In pl, this message translates to:
  /// **'Twojego potwierdzenia obecności, wiadomości do kapsuły czasu, propozycji muzycznych ani wyników gier. Publiczne są tylko: księga gości, rady, mapa, galeria i zdjęcia z foto-wyzwań.'**
  String get help_gPrivacy_2Body;

  /// No description provided for @setupTask_eventNameLabel.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa wesela'**
  String get setupTask_eventNameLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Np. „Wesele Ani i Piotra\" — pokazuje się w nagłówku aplikacji i na stronie dla gości.'**
  String get setupTask_eventNameHint;

  /// No description provided for @setupTask_weddingDateLabel.
  ///
  /// In pl, this message translates to:
  /// **'Data i godzina ślubu'**
  String get setupTask_weddingDateLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Od daty liczy się odliczanie na pulpicie i weryfikacja gości przy dołączaniu kodem.'**
  String get setupTask_weddingDateHint;

  /// No description provided for @setupTask_coupleTypeLabel.
  ///
  /// In pl, this message translates to:
  /// **'Typ uroczystości'**
  String get setupTask_coupleTypeLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Decyduje o etykietach w całej aplikacji — „Panna Młoda / Pan Młody\", dwie Panny Młode, dwóch Panów Młodych albo neutralnie.'**
  String get setupTask_coupleTypeHint;

  /// No description provided for @setupTask_coupleNamesLabel.
  ///
  /// In pl, this message translates to:
  /// **'Imiona Pary Młodej'**
  String get setupTask_coupleNamesLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz oba imiona — używa ich podział kosztów, etykiety i lista gości.'**
  String get setupTask_coupleNamesHint;

  /// No description provided for @setupTask_ceremonyPlaceLabel.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce ceremonii'**
  String get setupTask_ceremonyPlaceLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Kościół albo USC — adres zobaczą goście w harmonogramie.'**
  String get setupTask_ceremonyPlaceHint;

  /// No description provided for @setupTask_receptionPlaceLabel.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce przyjęcia'**
  String get setupTask_receptionPlaceLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa i adres sali — też trafia do harmonogramu gości.'**
  String get setupTask_receptionPlaceHint;

  /// No description provided for @setupTask_verificationSurnamesLabel.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko do weryfikacji gości'**
  String get setupTask_verificationSurnamesLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko (albo oba nazwiska), które gość poda przy dołączaniu kodem. Nigdzie się nie wyświetla — służy tylko sprawdzeniu.'**
  String get setupTask_verificationSurnamesHint;

  /// No description provided for @setupTask_guestsLabel.
  ///
  /// In pl, this message translates to:
  /// **'Pierwsi goście'**
  String get setupTask_guestsLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj choć kilka osób — od listy gości zależą catering, stoły i statystyki.'**
  String get setupTask_guestsHint;

  /// No description provided for @setupTask_budgetTotalLabel.
  ///
  /// In pl, this message translates to:
  /// **'Budżet planowany'**
  String get setupTask_budgetTotalLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Kwota, w której chcecie się zmieścić. Bez niej nie ma z czym porównywać wydatków.'**
  String get setupTask_budgetTotalHint;

  /// No description provided for @setupTask_pricePerPersonLabel.
  ///
  /// In pl, this message translates to:
  /// **'Cena za osobę (sala)'**
  String get setupTask_pricePerPersonLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Stawka od talerza — mnoży się przez liczbę gości i daje koszt cateringu.'**
  String get setupTask_pricePerPersonHint;

  /// No description provided for @setupTask_withChildrenLabel.
  ///
  /// In pl, this message translates to:
  /// **'Decyzja o dzieciach'**
  String get setupTask_withChildrenLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Ustal, czy na weselu będą dzieci. Jeśli tak, dojdzie menu dziecięce, stół dla dzieci i wyłączenie ich z przeliczeń alkoholu.'**
  String get setupTask_withChildrenHint;

  /// No description provided for @setupTask_menuOptionsLabel.
  ///
  /// In pl, this message translates to:
  /// **'Słownik menu'**
  String get setupTask_menuOptionsLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Warianty dania do wyboru przy gościach (mięsne, rybne, wege, dla dziecka).'**
  String get setupTask_menuOptionsHint;

  /// No description provided for @setupTask_expenseCategoriesLabel.
  ///
  /// In pl, this message translates to:
  /// **'Kategorie wydatków'**
  String get setupTask_expenseCategoriesLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Własne kategorie kosztów — po nich grupują się wydatki i wykresy w Analityce.'**
  String get setupTask_expenseCategoriesHint;

  /// No description provided for @setupTask_witnessesLabel.
  ///
  /// In pl, this message translates to:
  /// **'Świadkowie'**
  String get setupTask_witnessesLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Oznacz świadków na liście gości — pojawią się w podsumowaniu i na planie sali.'**
  String get setupTask_witnessesHint;

  /// No description provided for @setupTask_tablesLabel.
  ///
  /// In pl, this message translates to:
  /// **'Stoły'**
  String get setupTask_tablesLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj stoły z liczbą miejsc — bez nich nie da się rozsadzić gości.'**
  String get setupTask_tablesHint;

  /// No description provided for @setupTask_seatingLabel.
  ///
  /// In pl, this message translates to:
  /// **'Rozsadzenie gości'**
  String get setupTask_seatingLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz gości do stołów — choćby część. Resztę dokończysz bliżej wesela.'**
  String get setupTask_seatingHint;

  /// No description provided for @setupTask_scheduleLabel.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram dnia'**
  String get setupTask_scheduleLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Punkty programu z godzinami. Ten sam harmonogram widzą goście w swojej strefie.'**
  String get setupTask_scheduleHint;

  /// No description provided for @setupTask_guestVisibilityLabel.
  ///
  /// In pl, this message translates to:
  /// **'Widoczność sekcji dla gości'**
  String get setupTask_guestVisibilityLabel;

  /// Kreator „Poprowadź mnie za rękę" — podpowiedź, CO wpisać w tym kroku.
  ///
  /// In pl, this message translates to:
  /// **'Zdecyduj, co i od kiedy widzą goście — np. RSVP od razu, a galerię dopiero w dniu wesela.'**
  String get setupTask_guestVisibilityHint;

  /// No description provided for @setupLevel_basic.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja podstawowa'**
  String get setupLevel_basic;

  /// No description provided for @setupLevel_advanced.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja zaawansowana'**
  String get setupLevel_advanced;

  /// No description provided for @setupLevel_basicIntro.
  ///
  /// In pl, this message translates to:
  /// **'Minimum, żeby ruszyć: dane wesela i pierwsi goście.'**
  String get setupLevel_basicIntro;

  /// No description provided for @setupLevel_advancedIntro.
  ///
  /// In pl, this message translates to:
  /// **'Dopracowanie: budżet, menu, stoły, harmonogram i strefa gości. To, co masz już uzupełnione, jest odhaczone.'**
  String get setupLevel_advancedIntro;

  /// Nazwa sekcji w nawigacji. W bazie zapisuje się `AppSection.name` (angielskie), więc tłumaczy się WYŁĄCZNIE etykieta.
  ///
  /// In pl, this message translates to:
  /// **'Pulpit'**
  String get section_dashboard;

  /// No description provided for @section_guests.
  ///
  /// In pl, this message translates to:
  /// **'Goście'**
  String get section_guests;

  /// No description provided for @section_budget.
  ///
  /// In pl, this message translates to:
  /// **'Budżet'**
  String get section_budget;

  /// No description provided for @section_room.
  ///
  /// In pl, this message translates to:
  /// **'Plan sali'**
  String get section_room;

  /// No description provided for @section_schedule.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram'**
  String get section_schedule;

  /// No description provided for @section_tasks.
  ///
  /// In pl, this message translates to:
  /// **'Zadania'**
  String get section_tasks;

  /// No description provided for @section_vendors.
  ///
  /// In pl, this message translates to:
  /// **'Dostawcy'**
  String get section_vendors;

  /// No description provided for @section_transport.
  ///
  /// In pl, this message translates to:
  /// **'Transport'**
  String get section_transport;

  /// No description provided for @section_accommodation.
  ///
  /// In pl, this message translates to:
  /// **'Noclegi'**
  String get section_accommodation;

  /// No description provided for @section_music.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka'**
  String get section_music;

  /// No description provided for @section_gifts.
  ///
  /// In pl, this message translates to:
  /// **'Prezenty'**
  String get section_gifts;

  /// No description provided for @section_gallery.
  ///
  /// In pl, this message translates to:
  /// **'Galeria & QR'**
  String get section_gallery;

  /// No description provided for @section_games.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne gry'**
  String get section_games;

  /// No description provided for @section_keepsakes.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne pamiątki'**
  String get section_keepsakes;

  /// No description provided for @section_analytics.
  ///
  /// In pl, this message translates to:
  /// **'Analityka'**
  String get section_analytics;

  /// No description provided for @section_rsvp.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenia'**
  String get section_rsvp;

  /// No description provided for @section_rsvpAll.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie RSVP'**
  String get section_rsvpAll;

  /// No description provided for @section_settings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get section_settings;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Twój pulpit — licznik dni do ślubu, skróty i najważniejsze statystyki w jednym miejscu.'**
  String get onb_desc_dashboard;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Lista zaproszonych, ich dane, statusy potwierdzeń i preferencje — w podzakładkach.'**
  String get onb_desc_guests;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Kontroluj wszystkie koszty wesela w jednym miejscu — podzakładki obok.'**
  String get onb_desc_budget;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Rozmieść stoły i elementy sali na interaktywnym planie. Włącz „Edytuj plan\", aby przeciągać i zmieniać rozmiary.'**
  String get onb_desc_room;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Rozpisz przebieg dnia ślubu oraz checklistę — w podzakładkach.'**
  String get onb_desc_schedule;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Rozpisz zadania, przypisz osoby i powiąż je z budżetem, dostawcą lub prezentem.'**
  String get onb_desc_tasks;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Baza usługodawców — kontakty, umowy, raty płatności i powiązania z budżetem.'**
  String get onb_desc_vendors;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zorganizuj dojazd gości — trasy, pojazdy i przypisanie pasażerów.'**
  String get onb_desc_transport;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj noclegami dla gości — obiekty, pokoje i rezerwacje.'**
  String get onb_desc_accommodation;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Twórz playlistę wesela i zbieraj propozycje utworów od gości (kod QR).'**
  String get onb_desc_music;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Ewidencja prezentów otrzymanych, upominków dla gości i listy życzeń — w podzakładkach.'**
  String get onb_desc_gifts;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wspólna galeria zdjęć z wesela oraz kody QR do udostępniania gościom.'**
  String get onb_desc_gallery;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne gry — zabawy dla gości, m.in. Ślubne Bingo generowane z wydarzeń harmonogramu. Wkrótce kolejne gry.'**
  String get onb_desc_games;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne pamiątki — księga gości, rady dla Pary Młodej, kapsuła czasu i mapa gości. W przygotowaniu.'**
  String get onb_desc_keepsakes;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wykresy i statystyki organizacji — postępy, koszty i frekwencja.'**
  String get onb_desc_analytics;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj potwierdzeniami obecności (RSVP) i udostępniaj gościom formularz online.'**
  String get onb_desc_rsvp;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Tu znajdziesz konfigurację, dostęp, logowanie i narzędzia. Przewodnik wznowisz w każdej chwili z menu pod logo. To już wszystko — powodzenia!'**
  String get onb_desc_settings;

  /// Zapasowy opis kroku dla sekcji bez własnego tekstu — {section} to nazwa sekcji.
  ///
  /// In pl, this message translates to:
  /// **'Sekcja „{section}\" w aplikacji.'**
  String onb_desc_fallback(String section);

  /// No description provided for @onb_sub_guests_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Lista'**
  String get onb_sub_guests_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Lista zaproszonych — dodawaj gości i zarządzaj ich danymi.'**
  String get onb_sub_guests_1Desc;

  /// No description provided for @onb_sub_guests_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Kartoteka'**
  String get onb_sub_guests_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Szczegółowa kartoteka: status potwierdzenia, dieta, wiek i uwagi.'**
  String get onb_sub_guests_2Desc;

  /// No description provided for @onb_sub_guests_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Podsumowanie'**
  String get onb_sub_guests_3Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zbiorcze statystyki: liczba gości, potwierdzenia, dzieci i diety.'**
  String get onb_sub_guests_3Desc;

  /// No description provided for @onb_sub_budget_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Podsumowanie'**
  String get onb_sub_budget_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Budżet całkowity kontra wydatki — ile już rozdysponowano.'**
  String get onb_sub_budget_1Desc;

  /// No description provided for @onb_sub_budget_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Sala'**
  String get onb_sub_budget_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Koszt sali — stawka za osobę przelicza się z liczbą gości (przypisanych, nieprzypisanych i obsługi).'**
  String get onb_sub_budget_2Desc;

  /// No description provided for @onb_sub_budget_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Wydatki'**
  String get onb_sub_budget_3Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Dodawaj pozostałe wydatki i grupuj je w kategorie.'**
  String get onb_sub_budget_3Desc;

  /// No description provided for @onb_sub_budget_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Alkohol'**
  String get onb_sub_budget_4Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Planuj rodzaje, ilości i koszty alkoholu.'**
  String get onb_sub_budget_4Desc;

  /// No description provided for @onb_sub_budget_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Napoje bezalkoholowe'**
  String get onb_sub_budget_5Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Woda, soki, napoje gazowane — ilości i koszty.'**
  String get onb_sub_budget_5Desc;

  /// No description provided for @onb_sub_budget_6Title.
  ///
  /// In pl, this message translates to:
  /// **'Podróż poślubna'**
  String get onb_sub_budget_6Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Budżet miesiąca miodowego osobno od kosztów wesela. W „Podsumowaniu\" znajdziesz też wszystkie płatności i terminy.'**
  String get onb_sub_budget_6Desc;

  /// No description provided for @onb_sub_schedule_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Plan dnia'**
  String get onb_sub_schedule_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Punkty programu z godzinami — od ceremonii po ostatni taniec.'**
  String get onb_sub_schedule_1Desc;

  /// No description provided for @onb_sub_schedule_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Checklista'**
  String get onb_sub_schedule_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Lista rzeczy do odhaczenia przed weselem i w jego trakcie.'**
  String get onb_sub_schedule_2Desc;

  /// No description provided for @onb_sub_gifts_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Otrzymane'**
  String get onb_sub_gifts_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zapisuj, co i od kogo dostaliście — przyda się przy podziękowaniach.'**
  String get onb_sub_gifts_1Desc;

  /// No description provided for @onb_sub_gifts_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Dla gości'**
  String get onb_sub_gifts_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Planuj podziękowania i upominki dla gości.'**
  String get onb_sub_gifts_2Desc;

  /// No description provided for @onb_sub_gifts_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Propozycje'**
  String get onb_sub_gifts_3Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wasza lista życzeń — podpowiedzcie gościom, co sprawi Wam radość.'**
  String get onb_sub_gifts_3Desc;

  /// No description provided for @onb_set_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Status synchronizacji'**
  String get onb_set_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź, czy dane są zsynchronizowane z chmurą (Firestore).'**
  String get onb_set_1Desc;

  /// No description provided for @onb_set_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Widoczność dla gości'**
  String get onb_set_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Decydujesz, które sekcje widzą goście i od kiedy do kiedy. Np. RSVP włącz od razu, a galerię dopiero w dniu wesela.'**
  String get onb_set_2Desc;

  /// No description provided for @onb_set_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Kod dołączenia dla gości'**
  String get onb_set_3Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Sześcioznakowy kod, którym gość dołącza do wesela na własnym koncie. Weryfikacja jest potrójna: kod, data ślubu i nazwisko.'**
  String get onb_set_3Desc;

  /// No description provided for @onb_set_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Link i QR dla gości'**
  String get onb_set_4Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Link i kod QR do strefy gości — działa bez logowania i bez instalowania aplikacji. To go drukujesz na zaproszeniach albo kładziesz na stołach.'**
  String get onb_set_4Desc;

  /// No description provided for @onb_set_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Interakcje gości'**
  String get onb_set_5Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko, co przysłali goście: RSVP, wpisy księgi, rady, zdjęcia, propozycje muzyki i wyniki gier. Tu też moderujesz — kasujesz nieodpowiednie wpisy jednym kliknięciem.'**
  String get onb_set_5Desc;

  /// No description provided for @onb_set_6Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Osoby i dostęp'**
  String get onb_set_6Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Tu dodajesz współorganizatora (świadek, mama) i planera. „Dodaj osobę\" → wybierz rolę → podaj e-mail osoby z kontem albo wygeneruj jednorazowy kod zaproszenia i prześlij go jej. Zaproszona osoba wpisuje kod na liście wesel („Mam kod zaproszenia\"). Planerowi ustawisz datę ważności — po niej wesele znika z jego listy. Dostęp blokujesz i przywracasz w każdej chwili. Tylko właściciel wesela może tu cokolwiek zmienić — to zabezpieczenie, nie ograniczenie.'**
  String get onb_set_6Desc;

  /// No description provided for @onb_set_7Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Konfiguracja'**
  String get onb_set_7Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa imprezy, data, miejsca, podział kosztów i słowniki.'**
  String get onb_set_7Desc;

  /// No description provided for @onb_set_8Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Logowanie'**
  String get onb_set_8Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Biometria, PIN/wzór i status zabezpieczeń urządzenia.'**
  String get onb_set_8Desc;

  /// No description provided for @onb_set_9Title.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia · Programistyczne'**
  String get onb_set_9Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Eksport/import danych i kopie zapasowe.'**
  String get onb_set_9Desc;

  /// Wariant PLANERA: ten sam ekran co u właściciela, ale opisany w kontekście pracy na weselu klienta. Zachować to rozróżnienie w tłumaczeniu.
  ///
  /// In pl, this message translates to:
  /// **'Pulpit wesela KLIENTA — licznik dni, postępy i statystyki. Każde wesele w Twoim koncie ma własny pulpit; przełączasz je w „Zmień wesele\".'**
  String get onb_plannerDesc_dashboard;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Lista gości klienta wraz z potwierdzeniami i preferencjami. To dane osobowe Waszych klientów — traktuj je poufnie.'**
  String get onb_plannerDesc_guests;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Budżet wesela klienta. Tu najczęściej pokazujesz Parze, na co idą pieniądze i gdzie są oszczędności — podzakładki obok.'**
  String get onb_plannerDesc_budget;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Plan sali do ustalenia z klientem i salą. Wydrukowany układ stołów to jeden z najczęściej zamawianych elementów Twojej usługi.'**
  String get onb_plannerDesc_room;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram dnia — Twój najważniejszy dokument roboczy. To on trafia do obsługi, fotografa i zespołu muzycznego.'**
  String get onb_plannerDesc_schedule;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zadania z przypisaniem osób. Możesz tu rozdzielić obowiązki między siebie, Parę i podwykonawców.'**
  String get onb_plannerDesc_tasks;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Baza usługodawców z umowami i ratami. Prowadząc kilka wesel, budujesz tu swoją prywatną bazę sprawdzonych kontaktów.'**
  String get onb_plannerDesc_vendors;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wykresy i statystyki — gotowy materiał na podsumowanie postępów dla klienta.'**
  String get onb_plannerDesc_analytics;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja wesela, dostęp osób i widoczność sekcji dla gości. Pamiętaj: właścicielem wesela pozostaje Para Młoda — to ona nadaje i odbiera dostępy. Przewodnik wznowisz z menu pod logo.'**
  String get onb_plannerDesc_settings;

  /// No description provided for @onb_planner_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Wiele wesel na jednym koncie'**
  String get onb_planner_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Jako planer możesz prowadzić dowolnie wiele wesel. Przełączasz je w menu pod logo → „Zmień wesele\". Dane każdego wesela są w pełni oddzielone — klient A nigdy nie zobaczy wesela klienta B.'**
  String get onb_planner_1Desc;

  /// No description provided for @onb_planner_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Twój dostęp może mieć datę ważności'**
  String get onb_planner_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda nadaje planerowi dostęp, może ustawić mu datę ważności i w każdej chwili go zablokować lub przywrócić. Po wygaśnięciu wesele znika z Twojej listy — to normalne, nie awaria.'**
  String get onb_planner_2Desc;

  /// No description provided for @onb_planner_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Przekazanie wesela Parze Młodej'**
  String get onb_planner_3Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Konto Pary Młodej jest nadrzędne: tylko ona dodaje osoby i wystawia zaproszenia. Gdy kończysz współpracę, to Para przejmuje pełną kontrolę — nic nie trzeba przenosić ani eksportować.'**
  String get onb_planner_3Desc;

  /// No description provided for @onb_guest_1Title.
  ///
  /// In pl, this message translates to:
  /// **'Witaj w strefie gości'**
  String get onb_guest_1Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'To Twoje miejsce na weselu Pary Młodej. Znajdziesz tu wszystko, czego potrzebujesz jako gość — bez zakładania konta i bez instalowania czegokolwiek.'**
  String get onb_guest_1Desc;

  /// No description provided for @onb_guest_2Title.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenie obecności (RSVP)'**
  String get onb_guest_2Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Daj znać, czy będziesz i z iloma osobami. Podaj dietę lub alergie, jeśli je masz. Wystarczy jedno potwierdzenie — gdy plany się zmienią, wróć tutaj i popraw odpowiedź.'**
  String get onb_guest_2Desc;

  /// No description provided for @onb_guest_3Title.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram dnia'**
  String get onb_guest_3Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Godzina po godzinie: ceremonia, przyjęcie, tort, pierwszy taniec. Zobaczysz też licznik dni do wesela.'**
  String get onb_guest_3Desc;

  /// No description provided for @onb_guest_4Title.
  ///
  /// In pl, this message translates to:
  /// **'Galeria — dodaj swoje zdjęcia'**
  String get onb_guest_4Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wrzuć zdjęcia prosto z telefonu i oglądaj te dodane przez innych gości. Para Młoda dostaje w ten sposób ujęcia, których nie ma żaden fotograf.'**
  String get onb_guest_4Desc;

  /// No description provided for @onb_guest_5Title.
  ///
  /// In pl, this message translates to:
  /// **'Muzyka — zaproponuj utwór'**
  String get onb_guest_5Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wyszukaj piosenkę i wyślij propozycję do Pary Młodej. Propozycje trafiają tylko do nich — nie ma publicznej listy ani głosowania.'**
  String get onb_guest_5Desc;

  /// No description provided for @onb_guest_6Title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne gry'**
  String get onb_guest_6Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Quiz o Parze Młodej, Prawda/Fałsz, Zgadnij zdjęcie, foto-wyzwania i Ślubne Bingo. Wyniki widzi tylko Para Młoda — nie ma publicznego rankingu, więc graj dla zabawy.'**
  String get onb_guest_6Desc;

  /// No description provided for @onb_guest_7Title.
  ///
  /// In pl, this message translates to:
  /// **'Gry — jak to działa'**
  String get onb_guest_7Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Quiz, Prawda/Fałsz i Zgadnij zdjęcie liczą wynik od razu na Twoim telefonie. Możesz podejść ponownie — nowy wynik zastąpi poprzedni. W foto-wyzwaniach wysyłasz po jednym zdjęciu do każdego zadania.'**
  String get onb_guest_7Desc;

  /// No description provided for @onb_guest_8Title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne pamiątki'**
  String get onb_guest_8Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Zostaw ślad po sobie: wpis w księdze gości, rada dla Pary Młodej, wiadomość do kapsuły czasu i pinezka na mapie gości.'**
  String get onb_guest_8Desc;

  /// No description provided for @onb_guest_9Title.
  ///
  /// In pl, this message translates to:
  /// **'Księga gości i rady'**
  String get onb_guest_9Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Wpisów możesz zostawić kilka — życzenia, wspomnienie, dobra rada. Widzą je inni goście, więc to trochę jak wspólna kronika.'**
  String get onb_guest_9Desc;

  /// No description provided for @onb_guest_10Title.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła czasu i mapa gości'**
  String get onb_guest_10Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła to prywatna wiadomość — przeczyta ją wyłącznie Para Młoda. Na mapie zaznaczasz, skąd przyjeżdżasz; jedna pinezka na gościa, można ją poprawić.'**
  String get onb_guest_10Desc;

  /// No description provided for @onb_guest_11Title.
  ///
  /// In pl, this message translates to:
  /// **'To wszystko!'**
  String get onb_guest_11Title;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Sekcje pojawiają się i znikają zgodnie z tym, co udostępniła Para Młoda — jeśli czegoś nie widzisz, być może będzie dostępne bliżej wesela. Bawcie się dobrze!'**
  String get onb_guest_11Desc;

  /// No description provided for @onb_planningTitle.
  ///
  /// In pl, this message translates to:
  /// **'Od czego zacząć?'**
  String get onb_planningTitle;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki, a pasek pokaże postęp. Otworzysz ją w każdej chwili z Ustawień.'**
  String get onb_planningDesc;

  /// No description provided for @onb_qrTitle.
  ///
  /// In pl, this message translates to:
  /// **'Kody QR dla gości'**
  String get onb_qrTitle;

  /// Przewodnik — opis kroku. Tekst ciągły, bez podstawień.
  ///
  /// In pl, this message translates to:
  /// **'Udostępnij gościom kody QR prowadzące do galerii, muzyki, harmonogramu i potwierdzeń.'**
  String get onb_qrDesc;

  /// Tytuł kroku dla podzakładki: nazwa sekcji › nazwa zakładki.
  ///
  /// In pl, this message translates to:
  /// **'{section} › {tab}'**
  String onb_subTitle(String section, String tab);

  /// Podgląd listy „Od czego zacząć?" — ile kroków nie zmieściło się na ekranie.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{…i jeszcze 1 krok na liście} few{…i jeszcze {count} kroki na liście} other{…i jeszcze {count} kroków na liście}}'**
  String onb_moreSteps(int count);

  /// Nagłówek dymka przewodnika; emoji kompasu zostaje.
  ///
  /// In pl, this message translates to:
  /// **'🧭  {title}'**
  String onb_stepHeader(String title);

  /// No description provided for @onb_stepCounter.
  ///
  /// In pl, this message translates to:
  /// **'Krok {index} z {total}'**
  String onb_stepCounter(int index, int total);

  /// No description provided for @onb_skip.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń'**
  String get onb_skip;

  /// No description provided for @onb_finish.
  ///
  /// In pl, this message translates to:
  /// **'Zakończ'**
  String get onb_finish;

  /// No description provided for @onb_guestTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik dla gościa'**
  String get onb_guestTitle;

  /// No description provided for @onb_guestIntro.
  ///
  /// In pl, this message translates to:
  /// **'Pokażemy Ci, co możesz zrobić na stronie przygotowanej przez Parę Młodą. Zajmie to chwilę.'**
  String get onb_guestIntro;

  /// No description provided for @onb_plannerTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik dla planera'**
  String get onb_plannerTitle;

  /// No description provided for @onb_plannerIntro.
  ///
  /// In pl, this message translates to:
  /// **'Pokażemy Ci panel wesela klienta i to, czym różni się praca planera od konta Pary Młodej. Wznowisz go z Ustawień.'**
  String get onb_plannerIntro;

  /// No description provided for @onb_plannerShort.
  ///
  /// In pl, this message translates to:
  /// **'Główne sekcje panelu i zasady pracy planera'**
  String get onb_plannerShort;

  /// No description provided for @onb_plannerFull.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie sekcje, podzakładki i ustawienia'**
  String get onb_plannerFull;

  /// No description provided for @onb_ownerTitle.
  ///
  /// In pl, this message translates to:
  /// **'Przewodnik po aplikacji'**
  String get onb_ownerTitle;

  /// No description provided for @onb_ownerIntro.
  ///
  /// In pl, this message translates to:
  /// **'Pokażemy Ci najważniejsze miejsca w aplikacji. Wybierz tempo — przewodnik wznowisz w każdej chwili z Ustawień (pod logo).'**
  String get onb_ownerIntro;

  /// No description provided for @onb_ownerShort.
  ///
  /// In pl, this message translates to:
  /// **'Tylko główne sekcje — szybki przegląd'**
  String get onb_ownerShort;

  /// No description provided for @onb_ownerFull.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie sekcje i podzakładki'**
  String get onb_ownerFull;

  /// No description provided for @onb_guestPreviewNote.
  ///
  /// In pl, this message translates to:
  /// **'To podgląd dla Ciebie. Goście oglądają swoją strefę na osobnej stronie o zupełnie innym wyglądzie — tutaj pokazujemy wyłącznie treść ich przewodnika.'**
  String get onb_guestPreviewNote;

  /// No description provided for @onb_guestPreview.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz przewodnik gościa'**
  String get onb_guestPreview;

  /// No description provided for @onb_start.
  ///
  /// In pl, this message translates to:
  /// **'Rozpocznij'**
  String get onb_start;

  /// No description provided for @onb_guestFull.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie sekcje strefy gości'**
  String get onb_guestFull;

  /// No description provided for @onb_short.
  ///
  /// In pl, this message translates to:
  /// **'Skrócony'**
  String get onb_short;

  /// No description provided for @onb_full.
  ///
  /// In pl, this message translates to:
  /// **'Rozszerzony'**
  String get onb_full;

  /// No description provided for @onb_guestPreviewHint.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź, co widzą Wasi goście'**
  String get onb_guestPreviewHint;

  /// No description provided for @onb_setupWizardHint.
  ///
  /// In pl, this message translates to:
  /// **'Krok po kroku przez uzupełnianie danych wesela'**
  String get onb_setupWizardHint;

  /// No description provided for @onb_skipTour.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń przewodnik'**
  String get onb_skipTour;

  /// No description provided for @help_guestTitle.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc dla gości'**
  String get help_guestTitle;

  /// No description provided for @help_backToOwn.
  ///
  /// In pl, this message translates to:
  /// **'Wróć do swojej pomocy'**
  String get help_backToOwn;

  /// No description provided for @help_seeGuest.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz pomoc dla gości'**
  String get help_seeGuest;

  /// No description provided for @help_guestPreviewNote.
  ///
  /// In pl, this message translates to:
  /// **'Oglądasz pomoc, którą widzą Wasi goście.'**
  String get help_guestPreviewNote;

  /// No description provided for @help_searchHint.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj funkcji, np. „budżet\", „QR\", „RSVP\"'**
  String get help_searchHint;

  /// No description provided for @help_tourHint.
  ///
  /// In pl, this message translates to:
  /// **'Szukasz czegoś innego? Przewodnik pokaże Ci aplikację krok po kroku — uruchomisz go z Ustawień.'**
  String get help_tourHint;

  /// Liczba haseł w kategorii Pomocy.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 hasło} few{{count} hasła} other{{count} haseł}}'**
  String help_topicCount(int count);

  /// No description provided for @help_found.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{Znaleziono 1 hasło} few{Znaleziono {count} hasła} other{Znaleziono {count} haseł}}'**
  String help_found(int count);

  /// Pusty wynik wyszukiwarki Pomocy; {query} to fraza wpisana przez użytkownika.
  ///  rozdziela zdania.
  ///
  /// In pl, this message translates to:
  /// **'Nic nie znaleziono dla „{query}\".\nSpróbuj innego słowa — np. „gość\", „stół\", „płatność\".'**
  String help_nothingFound(String query);

  /// No description provided for @coupleType_mixed.
  ///
  /// In pl, this message translates to:
  /// **'Kobieta i mężczyzna'**
  String get coupleType_mixed;

  /// No description provided for @coupleType_women.
  ///
  /// In pl, this message translates to:
  /// **'Dwie kobiety'**
  String get coupleType_women;

  /// No description provided for @coupleType_men.
  ///
  /// In pl, this message translates to:
  /// **'Dwóch mężczyzn'**
  String get coupleType_men;

  /// No description provided for @coupleType_neutral.
  ///
  /// In pl, this message translates to:
  /// **'Niebinarne / inne'**
  String get coupleType_neutral;

  /// No description provided for @coupleType_mixedHint.
  ///
  /// In pl, this message translates to:
  /// **'Panna Młoda i Pan Młody'**
  String get coupleType_mixedHint;

  /// No description provided for @coupleType_womenHint.
  ///
  /// In pl, this message translates to:
  /// **'Obie osoby jako Panny Młode'**
  String get coupleType_womenHint;

  /// No description provided for @coupleType_menHint.
  ///
  /// In pl, this message translates to:
  /// **'Obie osoby jako Panowie Młodzi'**
  String get coupleType_menHint;

  /// No description provided for @coupleType_neutralHint.
  ///
  /// In pl, this message translates to:
  /// **'Neutralne etykiety: Osoba 1 i Osoba 2'**
  String get coupleType_neutralHint;

  /// No description provided for @couple_bride.
  ///
  /// In pl, this message translates to:
  /// **'Panna Młoda'**
  String get couple_bride;

  /// No description provided for @couple_groom.
  ///
  /// In pl, this message translates to:
  /// **'Pan Młody'**
  String get couple_groom;

  /// No description provided for @couple_brideEmoji.
  ///
  /// In pl, this message translates to:
  /// **'👰 Panna Młoda'**
  String get couple_brideEmoji;

  /// No description provided for @couple_groomEmoji.
  ///
  /// In pl, this message translates to:
  /// **'🤵 Pan Młody'**
  String get couple_groomEmoji;

  /// Etykieta zastępcza, gdy imię nie zostało podane.
  ///
  /// In pl, this message translates to:
  /// **'Osoba {index}'**
  String couple_personNumbered(int index);

  /// No description provided for @couple_brideNumbered.
  ///
  /// In pl, this message translates to:
  /// **'Panna Młoda {index}'**
  String couple_brideNumbered(int index);

  /// No description provided for @couple_groomNumbered.
  ///
  /// In pl, this message translates to:
  /// **'Pan Młody {index}'**
  String couple_groomNumbered(int index);

  /// Sklejenie ikony z etykietą osoby. Jeśli w danym języku ikona ma stać po tekście, zmień kolejność podstawień.
  ///
  /// In pl, this message translates to:
  /// **'{emoji} {name}'**
  String couple_withEmoji(String emoji, String name);

  /// No description provided for @couple_fromBride.
  ///
  /// In pl, this message translates to:
  /// **'Od Panny Młodej'**
  String get couple_fromBride;

  /// No description provided for @couple_fromGroom.
  ///
  /// In pl, this message translates to:
  /// **'Od Pana Młodego'**
  String get couple_fromGroom;

  /// Filtr „kto zaprosił" przy parze jednopłciowej lub neutralnej — używamy dwukropka, bo imion nie odmieniamy.
  ///
  /// In pl, this message translates to:
  /// **'Od: {person}'**
  String couple_fromNamed(String person);

  /// No description provided for @couple_witnessBride.
  ///
  /// In pl, this message translates to:
  /// **'Świadkowa'**
  String get couple_witnessBride;

  /// No description provided for @couple_witnessGroom.
  ///
  /// In pl, this message translates to:
  /// **'Świadek'**
  String get couple_witnessGroom;

  /// No description provided for @couple_witnessNamed.
  ///
  /// In pl, this message translates to:
  /// **'Świadek/Świadkowa ({person})'**
  String couple_witnessNamed(String person);

  /// No description provided for @couple_witnessNone.
  ///
  /// In pl, this message translates to:
  /// **'Brak roli'**
  String get couple_witnessNone;

  /// No description provided for @couple_personShort.
  ///
  /// In pl, this message translates to:
  /// **'osoba {index}'**
  String couple_personShort(int index);

  /// No description provided for @couple_categoryMixed.
  ///
  /// In pl, this message translates to:
  /// **'Państwo Młodzi'**
  String get couple_categoryMixed;

  /// No description provided for @couple_categoryWomen.
  ///
  /// In pl, this message translates to:
  /// **'Panny Młode'**
  String get couple_categoryWomen;

  /// No description provided for @couple_categoryMen.
  ///
  /// In pl, this message translates to:
  /// **'Panowie Młodzi'**
  String get couple_categoryMen;

  /// No description provided for @couple_categoryNeutral.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda'**
  String get couple_categoryNeutral;

  /// Złączenie dwóch imion („Ania i Piotr").
  ///
  /// In pl, this message translates to:
  /// **'{first} i {second}'**
  String couple_joinNames(String first, String second);

  /// No description provided for @vehicle_rented.
  ///
  /// In pl, this message translates to:
  /// **'Auto wynajęte'**
  String get vehicle_rented;

  /// No description provided for @vehicle_own.
  ///
  /// In pl, this message translates to:
  /// **'Auto własne'**
  String get vehicle_own;

  /// Typ pojazdu. UWAGA: cała fraza w jednym kluczu — polski wymaga tu dopełniacza, więc sklejanie z przedrostka nie działa.
  ///
  /// In pl, this message translates to:
  /// **'Auto rodziców Panny Młodej'**
  String get vehicle_parentsBride;

  /// No description provided for @vehicle_parentsGroom.
  ///
  /// In pl, this message translates to:
  /// **'Auto rodziców Pana Młodego'**
  String get vehicle_parentsGroom;

  /// No description provided for @vehicle_parentsNamed.
  ///
  /// In pl, this message translates to:
  /// **'Auto rodziców ({person})'**
  String vehicle_parentsNamed(String person);

  /// No description provided for @vehicle_bus.
  ///
  /// In pl, this message translates to:
  /// **'Bus'**
  String get vehicle_bus;

  /// No description provided for @vehicle_taxi.
  ///
  /// In pl, this message translates to:
  /// **'Taxi/Uber'**
  String get vehicle_taxi;

  /// No description provided for @vehicle_other.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get vehicle_other;

  /// No description provided for @quiz_favouriteFilmGroom.
  ///
  /// In pl, this message translates to:
  /// **'Ulubiony film Pana Młodego?'**
  String get quiz_favouriteFilmGroom;

  /// Przykładowe pytanie quizu; {person} to imię drugiej osoby z pary.
  ///
  /// In pl, this message translates to:
  /// **'Ulubiony film ({person})?'**
  String quiz_favouriteFilmNamed(String person);

  /// No description provided for @musicMoment_firstDance.
  ///
  /// In pl, this message translates to:
  /// **'Pierwszy taniec'**
  String get musicMoment_firstDance;

  /// No description provided for @musicMoment_entrance.
  ///
  /// In pl, this message translates to:
  /// **'Wejście'**
  String get musicMoment_entrance;

  /// No description provided for @musicMoment_games.
  ///
  /// In pl, this message translates to:
  /// **'Oczepiny'**
  String get musicMoment_games;

  /// No description provided for @musicMoment_slow.
  ///
  /// In pl, this message translates to:
  /// **'Wolne'**
  String get musicMoment_slow;

  /// No description provided for @musicMoment_party.
  ///
  /// In pl, this message translates to:
  /// **'Imprezowe'**
  String get musicMoment_party;

  /// Wartość domyślna pola `moment` utworu.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get musicMoment_other;

  /// Kluczowy moment wesela. UWAGA: ta wartość ZAPISUJE SIĘ w bazie przy zakładaniu wesela i po niej dobierana jest ikona — dopasowanie działa we wszystkich obsługiwanych językach, więc tłumaczenie jest bezpieczne, ale nie zmieniaj go po wydaniu.
  ///
  /// In pl, this message translates to:
  /// **'Pierwszy taniec'**
  String get specialMoment_firstDance;

  /// No description provided for @specialMoment_firstSong.
  ///
  /// In pl, this message translates to:
  /// **'Pierwszy utwór'**
  String get specialMoment_firstSong;

  /// No description provided for @specialMoment_coupleEntrance.
  ///
  /// In pl, this message translates to:
  /// **'Wejście Pary Młodej'**
  String get specialMoment_coupleEntrance;

  /// No description provided for @specialMoment_cake.
  ///
  /// In pl, this message translates to:
  /// **'Tort'**
  String get specialMoment_cake;

  /// No description provided for @specialMoment_games.
  ///
  /// In pl, this message translates to:
  /// **'Oczepiny'**
  String get specialMoment_games;

  /// No description provided for @specialMoment_lastDance.
  ///
  /// In pl, this message translates to:
  /// **'Ostatni taniec'**
  String get specialMoment_lastDance;

  /// No description provided for @specialMoment_toast.
  ///
  /// In pl, this message translates to:
  /// **'Toast'**
  String get specialMoment_toast;

  /// No description provided for @musicStatus_proposal.
  ///
  /// In pl, this message translates to:
  /// **'Propozycja'**
  String get musicStatus_proposal;

  /// No description provided for @musicStatus_approved.
  ///
  /// In pl, this message translates to:
  /// **'Zatwierdzone'**
  String get musicStatus_approved;

  /// No description provided for @musicStatus_rejected.
  ///
  /// In pl, this message translates to:
  /// **'Odrzucone'**
  String get musicStatus_rejected;

  /// No description provided for @musicStatus_dj.
  ///
  /// In pl, this message translates to:
  /// **'Do decyzji DJa'**
  String get musicStatus_dj;

  /// Kategoria rady. W bazie zapisuje się identyfikator (`love`), więc tłumaczy się wyłącznie etykieta.
  ///
  /// In pl, this message translates to:
  /// **'Miłość'**
  String get adviceCat_love;

  /// No description provided for @adviceCat_daily.
  ///
  /// In pl, this message translates to:
  /// **'Codzienność'**
  String get adviceCat_daily;

  /// No description provided for @adviceCat_humor.
  ///
  /// In pl, this message translates to:
  /// **'Humor'**
  String get adviceCat_humor;

  /// No description provided for @adviceCat_wisdom.
  ///
  /// In pl, this message translates to:
  /// **'Mądrość życiowa'**
  String get adviceCat_wisdom;

  /// No description provided for @adviceCat_other.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get adviceCat_other;

  /// No description provided for @beverage_alcohol.
  ///
  /// In pl, this message translates to:
  /// **'Alkohol'**
  String get beverage_alcohol;

  /// No description provided for @beverage_soft.
  ///
  /// In pl, this message translates to:
  /// **'Napoje bezalkoholowe'**
  String get beverage_soft;

  /// No description provided for @giftCat_guests.
  ///
  /// In pl, this message translates to:
  /// **'Goście'**
  String get giftCat_guests;

  /// No description provided for @giftCat_witnesses.
  ///
  /// In pl, this message translates to:
  /// **'Świadkowie'**
  String get giftCat_witnesses;

  /// No description provided for @giftCat_parents.
  ///
  /// In pl, this message translates to:
  /// **'Rodzice'**
  String get giftCat_parents;

  /// No description provided for @giftCat_distinction.
  ///
  /// In pl, this message translates to:
  /// **'Wyróżnienie'**
  String get giftCat_distinction;

  /// Status zadania; w bazie zostaje `todo`.
  ///
  /// In pl, this message translates to:
  /// **'Do zrobienia'**
  String get taskStatus_todo;

  /// No description provided for @taskStatus_inprogress.
  ///
  /// In pl, this message translates to:
  /// **'W trakcie'**
  String get taskStatus_inprogress;

  /// No description provided for @taskStatus_done.
  ///
  /// In pl, this message translates to:
  /// **'Zrobione'**
  String get taskStatus_done;

  /// No description provided for @taskStatus_cancelled.
  ///
  /// In pl, this message translates to:
  /// **'Anulowane'**
  String get taskStatus_cancelled;

  /// No description provided for @taskPriority_low.
  ///
  /// In pl, this message translates to:
  /// **'Niski'**
  String get taskPriority_low;

  /// No description provided for @taskPriority_med.
  ///
  /// In pl, this message translates to:
  /// **'Średni'**
  String get taskPriority_med;

  /// No description provided for @taskPriority_high.
  ///
  /// In pl, this message translates to:
  /// **'Wysoki'**
  String get taskPriority_high;

  /// No description provided for @taskPerson_both.
  ///
  /// In pl, this message translates to:
  /// **'Oboje'**
  String get taskPerson_both;

  /// No description provided for @push_rsvp.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenia gości (RSVP)'**
  String get push_rsvp;

  /// No description provided for @push_tasks.
  ///
  /// In pl, this message translates to:
  /// **'Nowe zadania'**
  String get push_tasks;

  /// No description provided for @push_schedule.
  ///
  /// In pl, this message translates to:
  /// **'Zmiany w harmonogramie'**
  String get push_schedule;

  /// No description provided for @push_memberJoined.
  ///
  /// In pl, this message translates to:
  /// **'Nowa osoba w weselu'**
  String get push_memberJoined;

  /// No description provided for @push_deadlines.
  ///
  /// In pl, this message translates to:
  /// **'Zbliżające się terminy'**
  String get push_deadlines;

  /// No description provided for @push_rsvpHint.
  ///
  /// In pl, this message translates to:
  /// **'Gdy gość potwierdzi obecność albo zmieni decyzję.'**
  String get push_rsvpHint;

  /// No description provided for @push_tasksHint.
  ///
  /// In pl, this message translates to:
  /// **'Gdy ktoś doda zadanie do listy.'**
  String get push_tasksHint;

  /// No description provided for @push_scheduleHint.
  ///
  /// In pl, this message translates to:
  /// **'Gdy pojawi się nowy punkt programu albo zmieni się godzina.'**
  String get push_scheduleHint;

  /// No description provided for @push_memberJoinedHint.
  ///
  /// In pl, this message translates to:
  /// **'Gdy do wesela dołączy planer, współorganizator albo gość.'**
  String get push_memberJoinedHint;

  /// No description provided for @push_deadlinesHint.
  ///
  /// In pl, this message translates to:
  /// **'Przypomnienie o płatności lub zadaniu z bliskim terminem.'**
  String get push_deadlinesHint;

  /// No description provided for @gs_attending.
  ///
  /// In pl, this message translates to:
  /// **'Przyjdzie'**
  String get gs_attending;

  /// No description provided for @gs_notAttending.
  ///
  /// In pl, this message translates to:
  /// **'Nie przyjdzie'**
  String get gs_notAttending;

  /// No description provided for @gs_noAnswer.
  ///
  /// In pl, this message translates to:
  /// **'Brak odpowiedzi'**
  String get gs_noAnswer;

  /// No description provided for @gs_ownTransport.
  ///
  /// In pl, this message translates to:
  /// **'Własny'**
  String get gs_ownTransport;

  /// No description provided for @gs_organisedTransport.
  ///
  /// In pl, this message translates to:
  /// **'Zorganizowany'**
  String get gs_organisedTransport;

  /// No description provided for @gs_roomReserved.
  ///
  /// In pl, this message translates to:
  /// **'Zarezerwowany'**
  String get gs_roomReserved;

  /// No description provided for @gs_roomPending.
  ///
  /// In pl, this message translates to:
  /// **'Do zarezerwowania'**
  String get gs_roomPending;

  /// No description provided for @gs_roomSelf.
  ///
  /// In pl, this message translates to:
  /// **'Sam rezerwuje'**
  String get gs_roomSelf;

  /// No description provided for @gs_roomNeeded.
  ///
  /// In pl, this message translates to:
  /// **'Potrzebuje'**
  String get gs_roomNeeded;

  /// Zapasowa nazwa stołu, gdy para nie nadała własnej.
  ///
  /// In pl, this message translates to:
  /// **'Stół'**
  String get gs_table;

  /// No description provided for @pay_sala.
  ///
  /// In pl, this message translates to:
  /// **'Sala'**
  String get pay_sala;

  /// No description provided for @pay_expenses.
  ///
  /// In pl, this message translates to:
  /// **'Wydatki'**
  String get pay_expenses;

  /// No description provided for @pay_honeymoon.
  ///
  /// In pl, this message translates to:
  /// **'Podróż poślubna'**
  String get pay_honeymoon;

  /// No description provided for @pay_vendor.
  ///
  /// In pl, this message translates to:
  /// **'Dostawca'**
  String get pay_vendor;

  /// No description provided for @pay_generic.
  ///
  /// In pl, this message translates to:
  /// **'Płatność'**
  String get pay_generic;

  /// No description provided for @pay_salaComputed.
  ///
  /// In pl, this message translates to:
  /// **'Koszt sali (obliczony)'**
  String get pay_salaComputed;

  /// No description provided for @pay_vendorInstalment.
  ///
  /// In pl, this message translates to:
  /// **'Rata do dostawcy: {vendor}'**
  String pay_vendorInstalment(String vendor);

  /// No description provided for @notif_guestAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano gościa: {name}'**
  String notif_guestAdded(String name);

  /// No description provided for @notif_guestAttending.
  ///
  /// In pl, this message translates to:
  /// **'{name} potwierdził(a) obecność'**
  String notif_guestAttending(String name);

  /// No description provided for @notif_guestNotAttending.
  ///
  /// In pl, this message translates to:
  /// **'{name} nie przyjdzie'**
  String notif_guestNotAttending(String name);

  /// No description provided for @notif_guestChanged.
  ///
  /// In pl, this message translates to:
  /// **'{name} — zmiana potwierdzenia'**
  String notif_guestChanged(String name);

  /// No description provided for @notif_taskAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano zadanie'**
  String get notif_taskAdded;

  /// No description provided for @notif_taskAddedNamed.
  ///
  /// In pl, this message translates to:
  /// **'Dodano zadanie: {name}'**
  String notif_taskAddedNamed(String name);

  /// No description provided for @notif_scheduleAdded.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram: {label} o {time}'**
  String notif_scheduleAdded(String label, String time);

  /// No description provided for @notif_guestNoName.
  ///
  /// In pl, this message translates to:
  /// **'Gość bez imienia'**
  String get notif_guestNoName;

  /// No description provided for @currency_pln.
  ///
  /// In pl, this message translates to:
  /// **'Złoty polski'**
  String get currency_pln;

  /// No description provided for @currency_eur.
  ///
  /// In pl, this message translates to:
  /// **'Euro'**
  String get currency_eur;

  /// No description provided for @currency_usd.
  ///
  /// In pl, this message translates to:
  /// **'Dolar amerykański'**
  String get currency_usd;

  /// No description provided for @currency_gbp.
  ///
  /// In pl, this message translates to:
  /// **'Funt brytyjski'**
  String get currency_gbp;

  /// No description provided for @currency_czk.
  ///
  /// In pl, this message translates to:
  /// **'Korona czeska'**
  String get currency_czk;

  /// No description provided for @currency_chf.
  ///
  /// In pl, this message translates to:
  /// **'Frank szwajcarski'**
  String get currency_chf;

  /// No description provided for @children_adultAtKidsTable.
  ///
  /// In pl, this message translates to:
  /// **'Przy stole dla dzieci posadzono osobę dorosłą — jeśli to opiekun, wszystko gra.'**
  String get children_adultAtKidsTable;

  /// No description provided for @children_kidAtNormalTable.
  ///
  /// In pl, this message translates to:
  /// **'Dziecko przy zwykłym stole — jest też stół dla dzieci.'**
  String get children_kidAtNormalTable;

  /// No description provided for @auth_googleUnsupported.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie Google nie jest obsługiwane na tej platformie.'**
  String get auth_googleUnsupported;

  /// No description provided for @auth_noToken.
  ///
  /// In pl, this message translates to:
  /// **'Brak tokenu Google. Spróbuj ponownie.'**
  String get auth_noToken;

  /// No description provided for @auth_googleError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd logowania Google.'**
  String get auth_googleError;

  /// No description provided for @auth_generic.
  ///
  /// In pl, this message translates to:
  /// **'Błąd logowania. Spróbuj ponownie.'**
  String get auth_generic;

  /// No description provided for @auth_network.
  ///
  /// In pl, this message translates to:
  /// **'Błąd sieci — sprawdź połączenie z internetem.'**
  String get auth_network;

  /// No description provided for @auth_tooMany.
  ///
  /// In pl, this message translates to:
  /// **'Zbyt wiele prób logowania. Poczekaj chwilę i spróbuj ponownie.'**
  String get auth_tooMany;

  /// No description provided for @auth_disabled.
  ///
  /// In pl, this message translates to:
  /// **'To konto Google zostało wyłączone.'**
  String get auth_disabled;

  /// No description provided for @auth_notEnabled.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie przez Google nie jest włączone. Skontaktuj się z administratorem.'**
  String get auth_notEnabled;

  /// No description provided for @auth_popupBlocked.
  ///
  /// In pl, this message translates to:
  /// **'Okno logowania zostało zablokowane przez przeglądarkę — zezwól na wyskakujące okienka i spróbuj ponownie.'**
  String get auth_popupBlocked;

  /// {code} to kod błędu z Firebase — zostaje bez tłumaczenia.
  ///
  /// In pl, this message translates to:
  /// **'Błąd logowania ({code}). Spróbuj ponownie.'**
  String auth_codeError(String code);

  /// No description provided for @auth_emailInUse.
  ///
  /// In pl, this message translates to:
  /// **'Konto z tym adresem e-mail już istnieje. Zaloguj się lub użyj innego adresu.'**
  String get auth_emailInUse;

  /// No description provided for @auth_weakPassword.
  ///
  /// In pl, this message translates to:
  /// **'Hasło jest zbyt słabe — użyj co najmniej 6 znaków.'**
  String get auth_weakPassword;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy adres e-mail.'**
  String get auth_invalidEmail;

  /// No description provided for @auth_userNotFound.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono konta z tym adresem e-mail.'**
  String get auth_userNotFound;

  /// No description provided for @auth_wrongPassword.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowe hasło.'**
  String get auth_wrongPassword;

  /// No description provided for @auth_invalidCredential.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy e-mail lub hasło.'**
  String get auth_invalidCredential;

  /// No description provided for @guestId_noUser.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie anonimowe nie zwróciło użytkownika.'**
  String get guestId_noUser;

  /// No description provided for @guestId_notConfigured.
  ///
  /// In pl, this message translates to:
  /// **'Strona gości nie jest jeszcze w pełni skonfigurowana. Przeglądanie działa, ale wysyłanie wpisów może się nie udać.'**
  String get guestId_notConfigured;

  /// No description provided for @guestId_offline.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia z internetem. Sprawdź sieć i odśwież stronę.'**
  String get guestId_offline;

  /// No description provided for @guestId_generic.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się przygotować sesji gościa. Możesz przeglądać stronę, ale wysyłanie wpisów może nie zadziałać.'**
  String get guestId_generic;

  /// {category} to etykieta kategorii Pary Młodej, {max} — limit osób.
  ///
  /// In pl, this message translates to:
  /// **'W kategorii „{category}\" mogą być najwyżej {max} osoby. Zmień kategorię tego gościa albo popraw istniejący wpis Pary Młodej.'**
  String guestSvc_coupleLimit(String category, int max);

  /// No description provided for @guestSvc_coupleNoCompanion.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda nie ma osoby towarzyszącej — obie osoby dodaj jako osobne wpisy Pary Młodej.'**
  String get guestSvc_coupleNoCompanion;

  /// Pole planszy bingo generowane z punktu harmonogramu.
  ///
  /// In pl, this message translates to:
  /// **'Bądź obecny/a na: {name}'**
  String bingo_beAt(String name);

  /// No description provided for @dash_countdown.
  ///
  /// In pl, this message translates to:
  /// **'Licznik do ślubu'**
  String get dash_countdown;

  /// No description provided for @dash_setDate.
  ///
  /// In pl, this message translates to:
  /// **'Ustaw datę w Ustawieniach'**
  String get dash_setDate;

  /// No description provided for @dash_today.
  ///
  /// In pl, this message translates to:
  /// **'To dziś!'**
  String get dash_today;

  /// Podpis pod liczbą dni na kafelku licznika. Sama liczba stoi nad podpisem, dlatego w treści jej nie powtarzamy.
  ///
  /// In pl, this message translates to:
  /// **'{days, plural, =1{dzień do ślubu} other{dni do ślubu}}'**
  String dash_daysLeft(int days);

  /// No description provided for @dash_guestsSub.
  ///
  /// In pl, this message translates to:
  /// **'{attending} potw. · {declined} odmów · {noRsvp} bez odp.'**
  String dash_guestsSub(int attending, int declined, int noRsvp);

  /// No description provided for @dash_tablesSub.
  ///
  /// In pl, this message translates to:
  /// **'{assigned} przypisanych · {free} wolnych miejsc'**
  String dash_tablesSub(int assigned, int free);

  /// {paid} i {left} to gotowe kwoty z symbolem waluty.
  ///
  /// In pl, this message translates to:
  /// **'Opłacono {paid} · zostało {left}'**
  String dash_budgetSub(String paid, String left);

  /// No description provided for @dash_noEvents.
  ///
  /// In pl, this message translates to:
  /// **'brak wydarzeń'**
  String get dash_noEvents;

  /// No description provided for @dash_nextEvent.
  ///
  /// In pl, this message translates to:
  /// **'najbliższe wydarzenie'**
  String get dash_nextEvent;

  /// No description provided for @dash_tasksSub.
  ///
  /// In pl, this message translates to:
  /// **'{todo} do zrobienia · {inProgress} w trakcie'**
  String dash_tasksSub(int todo, int inProgress);

  /// No description provided for @dash_transportSub.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =0{wszyscy mają transport} =1{1 gość bez transportu} few{{count} gości bez transportu} other{{count} gości bez transportu}}'**
  String dash_transportSub(int count);

  /// No description provided for @dash_roomsSub.
  ///
  /// In pl, this message translates to:
  /// **'{reserved} zarezerwowanych'**
  String dash_roomsSub(int reserved);

  /// No description provided for @dash_giftsSub.
  ///
  /// In pl, this message translates to:
  /// **'łącznie {value} · {thanked} z podziękowaniem'**
  String dash_giftsSub(String value, int thanked);

  /// No description provided for @dash_rsvpSub.
  ///
  /// In pl, this message translates to:
  /// **'{declined} odmów · {total} odpowiedzi'**
  String dash_rsvpSub(int declined, int total);

  /// No description provided for @dash_bottles.
  ///
  /// In pl, this message translates to:
  /// **'{count} butelek'**
  String dash_bottles(String count);

  /// No description provided for @dash_paymentsSub.
  ///
  /// In pl, this message translates to:
  /// **'{overdue} zaległych · {soon} wkrótce'**
  String dash_paymentsSub(int overdue, int soon);

  /// No description provided for @dash_vendorsSub.
  ///
  /// In pl, this message translates to:
  /// **'{count} potwierdzonych'**
  String dash_vendorsSub(int count);

  /// No description provided for @dash_gallerySub.
  ///
  /// In pl, this message translates to:
  /// **'zdjęć i filmów'**
  String get dash_gallerySub;

  /// No description provided for @pdf_qrHint.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj telefonem, aby otworzyć stronę dla gości.'**
  String get pdf_qrHint;

  /// No description provided for @pdf_galleryTitle.
  ///
  /// In pl, this message translates to:
  /// **'Galeria zdjęć z wesela'**
  String get pdf_galleryTitle;

  /// No description provided for @pdf_galleryHintVideo.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj telefonem, aby dodać i obejrzeć wspólne zdjęcia i filmy.'**
  String get pdf_galleryHintVideo;

  /// No description provided for @pdf_galleryHint.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj telefonem, aby dodać i obejrzeć wspólne zdjęcia.'**
  String get pdf_galleryHint;

  /// No description provided for @pdf_scheduleTitle.
  ///
  /// In pl, this message translates to:
  /// **'Harmonogram dnia ślubu'**
  String get pdf_scheduleTitle;

  /// No description provided for @pdf_place.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce: {place}'**
  String pdf_place(String place);

  /// No description provided for @pdf_scheduleEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wydarzeń w harmonogramie.'**
  String get pdf_scheduleEmpty;

  /// No description provided for @pdf_guestbookTitle.
  ///
  /// In pl, this message translates to:
  /// **'Księga Gości'**
  String get pdf_guestbookTitle;

  /// No description provided for @pdf_guestbookSub.
  ///
  /// In pl, this message translates to:
  /// **'Życzenia i wiadomości od gości'**
  String get pdf_guestbookSub;

  /// No description provided for @pdf_guestbookEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wpisów w księdze gości.'**
  String get pdf_guestbookEmpty;

  /// No description provided for @pdf_hasPhoto.
  ///
  /// In pl, this message translates to:
  /// **'📷 (zdjęcie dostępne online)'**
  String get pdf_hasPhoto;

  /// No description provided for @pdf_advicesTitle.
  ///
  /// In pl, this message translates to:
  /// **'Rady dla Pary Młodej'**
  String get pdf_advicesTitle;

  /// No description provided for @pdf_advicesSub.
  ///
  /// In pl, this message translates to:
  /// **'Złote myśli o małżeństwie od gości'**
  String get pdf_advicesSub;

  /// No description provided for @pdf_advicesEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak rad.'**
  String get pdf_advicesEmpty;

  /// Cudzysłów wokół cytatu — użyj znaków typowych dla języka.
  ///
  /// In pl, this message translates to:
  /// **'„{text}\"'**
  String pdf_quoted(String text);

  /// No description provided for @pdf_capsuleTitle.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła czasu'**
  String get pdf_capsuleTitle;

  /// No description provided for @pdf_capsuleSub.
  ///
  /// In pl, this message translates to:
  /// **'Otwarte wiadomości od gości'**
  String get pdf_capsuleSub;

  /// No description provided for @pdf_capsuleEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak otwartych wiadomości.'**
  String get pdf_capsuleEmpty;

  /// No description provided for @pdf_openedOn.
  ///
  /// In pl, this message translates to:
  /// **'otwarta {date}'**
  String pdf_openedOn(String date);

  /// No description provided for @pdf_bingoTitle.
  ///
  /// In pl, this message translates to:
  /// **'ŚLUBNE BINGO'**
  String get pdf_bingoTitle;

  /// Plakietka przy pozycji budżetu utworzonej w innej sekcji.
  ///
  /// In pl, this message translates to:
  /// **'Dodano w: {section}'**
  String w_addedIn(String section);

  /// No description provided for @w_hideFilters.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj filtry'**
  String get w_hideFilters;

  /// No description provided for @w_showFilters.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż filtry'**
  String get w_showFilters;

  /// No description provided for @w_more.
  ///
  /// In pl, this message translates to:
  /// **'Więcej'**
  String get w_more;

  /// No description provided for @w_notifications.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia'**
  String get w_notifications;

  /// No description provided for @w_notificationsUnread.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia ({count} nieprzeczytane)'**
  String w_notificationsUnread(int count);

  /// No description provided for @w_unreadCount.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 nieprzeczytane} few{{count} nieprzeczytane} other{{count} nieprzeczytanych}}'**
  String w_unreadCount(int count);

  /// No description provided for @w_markAll.
  ///
  /// In pl, this message translates to:
  /// **'Oznacz wszystkie'**
  String get w_markAll;

  /// No description provided for @w_noNotifications.
  ///
  /// In pl, this message translates to:
  /// **'Brak nowych powiadomień'**
  String get w_noNotifications;

  /// No description provided for @w_noNotificationsBody.
  ///
  /// In pl, this message translates to:
  /// **'Damy znać, gdy pojawią się potwierdzenia gości, nowe zadania albo zmiany w harmonogramie.'**
  String get w_noNotificationsBody;

  /// No description provided for @w_groupSummary.
  ///
  /// In pl, this message translates to:
  /// **'{label}: {summary}'**
  String w_groupSummary(String label, String summary);

  /// No description provided for @w_goToSection.
  ///
  /// In pl, this message translates to:
  /// **'Przejdź do sekcji'**
  String get w_goToSection;

  /// No description provided for @w_markRead.
  ///
  /// In pl, this message translates to:
  /// **'Oznacz jako przeczytane'**
  String get w_markRead;

  /// No description provided for @w_justNow.
  ///
  /// In pl, this message translates to:
  /// **'przed chwilą'**
  String get w_justNow;

  /// No description provided for @w_minutesAgo.
  ///
  /// In pl, this message translates to:
  /// **'{minutes} min temu'**
  String w_minutesAgo(int minutes);

  /// No description provided for @w_guestPage.
  ///
  /// In pl, this message translates to:
  /// **'Strona dla gości'**
  String get w_guestPage;

  /// No description provided for @w_linkCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano link'**
  String get w_linkCopied;

  /// No description provided for @w_download.
  ///
  /// In pl, this message translates to:
  /// **'Pobierz / udostępnij'**
  String get w_download;

  /// No description provided for @w_weddingToday.
  ///
  /// In pl, this message translates to:
  /// **'To już dziś! 🎉'**
  String get w_weddingToday;

  /// No description provided for @w_seeYouAtWedding.
  ///
  /// In pl, this message translates to:
  /// **'Do zobaczenia na weselu'**
  String get w_seeYouAtWedding;

  /// No description provided for @w_timeToWedding.
  ///
  /// In pl, this message translates to:
  /// **'Do wesela zostało'**
  String get w_timeToWedding;

  /// No description provided for @nav_biometricTitle.
  ///
  /// In pl, this message translates to:
  /// **'Czy chcesz logować się odciskiem palca?'**
  String get nav_biometricTitle;

  /// No description provided for @nav_securityTitle.
  ///
  /// In pl, this message translates to:
  /// **'Czy chcesz zabezpieczyć aplikację?'**
  String get nav_securityTitle;

  /// No description provided for @nav_biometricBody.
  ///
  /// In pl, this message translates to:
  /// **'Przy kolejnych otwarciach odblokujesz aplikację odciskiem palca. Ustawisz też zapasowy PIN lub wzór na wypadek, gdyby czytnik nie zadziałał. Konto Google pozostaje zalogowane.'**
  String get nav_biometricBody;

  /// No description provided for @nav_securityBody.
  ///
  /// In pl, this message translates to:
  /// **'To urządzenie nie ma czytnika biometrycznego. Możesz ustawić PIN lub wzór, aby odblokowywać aplikację przy kolejnych otwarciach.'**
  String get nav_securityBody;

  /// No description provided for @nav_notNow.
  ///
  /// In pl, this message translates to:
  /// **'Nie teraz'**
  String get nav_notNow;

  /// No description provided for @nav_enable.
  ///
  /// In pl, this message translates to:
  /// **'Tak, włącz'**
  String get nav_enable;

  /// No description provided for @nav_logoutTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wylogować się?'**
  String get nav_logoutTitle;

  /// No description provided for @nav_logoutBody.
  ///
  /// In pl, this message translates to:
  /// **'Czy wyłączyć też zabezpieczenia (odcisk palca / PIN) na tym urządzeniu? Przydatne, gdy z aplikacji może korzystać inna osoba.'**
  String get nav_logoutBody;

  /// No description provided for @nav_logoutKeep.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj, zachowaj'**
  String get nav_logoutKeep;

  /// No description provided for @nav_logoutClear.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj i wyłącz'**
  String get nav_logoutClear;

  /// Nazwa własna produktu — NIE tłumaczyć.
  ///
  /// In pl, this message translates to:
  /// **'Moje Wesele'**
  String get nav_appName;

  /// No description provided for @nav_moreSections.
  ///
  /// In pl, this message translates to:
  /// **'Więcej sekcji'**
  String get nav_moreSections;

  /// No description provided for @nav_configureBar.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguruj pasek'**
  String get nav_configureBar;

  /// No description provided for @nav_configureBottomBar.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguruj dolny pasek'**
  String get nav_configureBottomBar;

  /// No description provided for @nav_configureHint.
  ///
  /// In pl, this message translates to:
  /// **'Dashboard (środek) i „Więcej\" (skrajnie prawy) są zawsze na stałych miejscach. Wybierz liczbę pozostałych ikon, dotknij ikonę zamiany (⇄), by wybrać inną sekcję, i przeciągnij za uchwyt, by zmienić kolejność — pierwsza połowa trafi na lewo od Dashboardu, reszta na prawo.'**
  String get nav_configureHint;

  /// No description provided for @nav_icons4.
  ///
  /// In pl, this message translates to:
  /// **'4 ikony'**
  String get nav_icons4;

  /// No description provided for @nav_icons6.
  ///
  /// In pl, this message translates to:
  /// **'6 ikon'**
  String get nav_icons6;

  /// No description provided for @nav_changeSection.
  ///
  /// In pl, this message translates to:
  /// **'Zmień sekcję'**
  String get nav_changeSection;

  /// Podpis pod liczbą na liczniku — sama liczba stoi nad podpisem, więc w treści jej nie powtarzamy.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{godzina} few{godziny} other{godzin}}'**
  String countdown_hours(int count);

  /// No description provided for @countdown_days.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{dzień} other{dni}}'**
  String countdown_days(int count);

  /// Doprecyzowanie pod licznikiem — tu liczba JEST w treści.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{{count} minuta} few{{count} minuty} other{{count} minut}}'**
  String countdown_minutesDetail(int count);

  /// No description provided for @countdown_hoursDetail.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{i {count} godzina} few{i {count} godziny} other{i {count} godzin}}'**
  String countdown_hoursDetail(int count);

  /// {excluded} to etykieta kategorii Pary Młodej (pomijanej w losowaniu).
  ///
  /// In pl, this message translates to:
  /// **'Losowanie spośród gości z listy. W puli: {count, plural, =1{1 gość} few{{count} gości} other{{count} gości}} ({excluded} pominięci).'**
  String wheel_poolInfo(int count, String excluded);

  /// No description provided for @gp_guestPage.
  ///
  /// In pl, this message translates to:
  /// **'Strona dla gości'**
  String get gp_guestPage;

  /// No description provided for @gp_activeHint.
  ///
  /// In pl, this message translates to:
  /// **'Goście mogą teraz grać przez stronę / kod QR.'**
  String get gp_activeHint;

  /// No description provided for @gp_enableHint.
  ///
  /// In pl, this message translates to:
  /// **'Włącz, aby goście mogli odpowiadać.'**
  String get gp_enableHint;

  /// No description provided for @gp_loadResultsError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać wyników. Sprawdź połączenie.'**
  String get gp_loadResultsError;

  /// No description provided for @gp_noResults.
  ///
  /// In pl, this message translates to:
  /// **'Brak wyników. Udostępnij gościom kod QR, aby zagrali.'**
  String get gp_noResults;

  /// No description provided for @gp_participants.
  ///
  /// In pl, this message translates to:
  /// **'Uczestników'**
  String get gp_participants;

  /// No description provided for @gp_avgScore.
  ///
  /// In pl, this message translates to:
  /// **'Śr. wynik'**
  String get gp_avgScore;

  /// No description provided for @gp_wrongOf.
  ///
  /// In pl, this message translates to:
  /// **'{wrong}/{answered} błędnych'**
  String gp_wrongOf(int wrong, int answered);

  /// No description provided for @gp_questionText.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz treść pytania'**
  String get gp_questionText;

  /// No description provided for @gp_emptyCorrect.
  ///
  /// In pl, this message translates to:
  /// **'Zaznaczona poprawna odpowiedź jest pusta'**
  String get gp_emptyCorrect;

  /// No description provided for @gp_answers.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedzi (zaznacz poprawną)'**
  String get gp_answers;

  /// No description provided for @gp_answerN.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedź {index}'**
  String gp_answerN(int index);

  /// No description provided for @quiz_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'🧠 Quiz o Parze Młodej'**
  String get quiz_headerTitle;

  /// No description provided for @quiz_questions.
  ///
  /// In pl, this message translates to:
  /// **'Pytań'**
  String get quiz_questions;

  /// No description provided for @quiz_questionLabel.
  ///
  /// In pl, this message translates to:
  /// **'Treść pytania'**
  String get quiz_questionLabel;

  /// No description provided for @quiz_questionHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Gdzie się poznaliśmy?'**
  String get quiz_questionHint;

  /// No description provided for @tf_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'🤔 Prawda czy Fałsz o Parze Młodej'**
  String get tf_headerTitle;

  /// No description provided for @tf_true.
  ///
  /// In pl, this message translates to:
  /// **'✓ PRAWDA'**
  String get tf_true;

  /// No description provided for @tf_false.
  ///
  /// In pl, this message translates to:
  /// **'✗ FAŁSZ'**
  String get tf_false;

  /// No description provided for @tf_deleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{text}\"?'**
  String tf_deleteConfirm(String text);

  /// No description provided for @tf_confusing.
  ///
  /// In pl, this message translates to:
  /// **'📊 Najbardziej mylące stwierdzenia'**
  String get tf_confusing;

  /// No description provided for @tf_statements.
  ///
  /// In pl, this message translates to:
  /// **'Stwierdzeń'**
  String get tf_statements;

  /// No description provided for @tf_needText.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz treść stwierdzenia'**
  String get tf_needText;

  /// No description provided for @tf_textLabel.
  ///
  /// In pl, this message translates to:
  /// **'Treść stwierdzenia'**
  String get tf_textLabel;

  /// No description provided for @tf_textHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Para Młoda poznała się w pracy'**
  String get tf_textHint;

  /// No description provided for @tf_falseShort.
  ///
  /// In pl, this message translates to:
  /// **'Fałsz'**
  String get tf_falseShort;

  /// No description provided for @tf_explanation.
  ///
  /// In pl, this message translates to:
  /// **'Wyjaśnienie (opcjonalnie)'**
  String get tf_explanation;

  /// No description provided for @tf_explanationHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Poznali się przez wspólnych znajomych'**
  String get tf_explanationHint;

  /// No description provided for @pg_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'📸 Zgadnij zdjęcie'**
  String get pg_headerTitle;

  /// No description provided for @pg_photos.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcia'**
  String get pg_photos;

  /// No description provided for @pg_enableHint.
  ///
  /// In pl, this message translates to:
  /// **'Włącz, aby goście mogli zgadywać.'**
  String get pg_enableHint;

  /// No description provided for @pg_needPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw dodaj przynajmniej jedno zdjęcie.'**
  String get pg_needPhoto;

  /// No description provided for @pg_photosCount.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęć'**
  String get pg_photosCount;

  /// No description provided for @pg_uploadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wgrać zdjęcia: {error}'**
  String pg_uploadError(String error);

  /// No description provided for @pg_addPhotoFirst.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw dodaj zdjęcie'**
  String get pg_addPhotoFirst;

  /// No description provided for @pg_editPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj zdjęcie'**
  String get pg_editPhoto;

  /// No description provided for @pg_addPhoto.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj zdjęcie'**
  String get pg_addPhoto;

  /// No description provided for @pg_questionHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Kto to z dzieciństwa?'**
  String get pg_questionHint;

  /// No description provided for @pg_photo.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcie'**
  String get pg_photo;

  /// No description provided for @pc_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'📷 Foto-wyzwania'**
  String get pc_headerTitle;

  /// No description provided for @pc_activeHint.
  ///
  /// In pl, this message translates to:
  /// **'Goście mogą teraz wykonywać wyzwania przez stronę / kod QR.'**
  String get pc_activeHint;

  /// No description provided for @pc_enableHint.
  ///
  /// In pl, this message translates to:
  /// **'Włącz, aby goście mogli przesyłać zdjęcia.'**
  String get pc_enableHint;

  /// No description provided for @pc_deleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{text}\"? Przesłane zdjęcia pozostaną w galerii.'**
  String pc_deleteConfirm(String text);

  /// No description provided for @pc_loadPhotosError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać zdjęć. Sprawdź połączenie.'**
  String get pc_loadPhotosError;

  /// No description provided for @pc_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięte wyzwanie'**
  String get pc_deleted;

  /// No description provided for @pc_deletePhotoTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć zdjęcie?'**
  String get pc_deletePhotoTitle;

  /// No description provided for @pc_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak wykonanych wyzwań. Udostępnij gościom kod QR.'**
  String get pc_empty;

  /// No description provided for @pc_photos.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęć'**
  String get pc_photos;

  /// No description provided for @pc_challenges.
  ///
  /// In pl, this message translates to:
  /// **'Wyzwań'**
  String get pc_challenges;

  /// No description provided for @bingo_needPool.
  ///
  /// In pl, this message translates to:
  /// **'Potrzeba min. 24 pól w puli (jest {count}).'**
  String bingo_needPool(int count);

  /// No description provided for @bingo_title.
  ///
  /// In pl, this message translates to:
  /// **'Ślubne Bingo'**
  String get bingo_title;

  /// No description provided for @bingo_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'🎯 Ślubne Bingo'**
  String get bingo_headerTitle;

  /// No description provided for @bingo_guestHint.
  ///
  /// In pl, this message translates to:
  /// **'Strona z interaktywnym bingo dla gości. Pokaż im kod QR lub wyślij link, aby grali na telefonach.'**
  String get bingo_guestHint;

  /// No description provided for @bingo_pool.
  ///
  /// In pl, this message translates to:
  /// **'Pula losowania: {count} pól'**
  String bingo_pool(int count);

  /// No description provided for @bingo_preview.
  ///
  /// In pl, this message translates to:
  /// **'Losuj podgląd'**
  String get bingo_preview;

  /// No description provided for @bingo_previewBoard.
  ///
  /// In pl, this message translates to:
  /// **'Podgląd planszy'**
  String get bingo_previewBoard;

  /// No description provided for @bingo_fromSchedule.
  ///
  /// In pl, this message translates to:
  /// **'Dołącz pola z harmonogramu'**
  String get bingo_fromSchedule;

  /// No description provided for @bingo_centerField.
  ///
  /// In pl, this message translates to:
  /// **'Środkowe pole planszy'**
  String get bingo_centerField;

  /// No description provided for @bingo_coupleNames.
  ///
  /// In pl, this message translates to:
  /// **'Imiona Pary Młodej'**
  String get bingo_coupleNames;

  /// No description provided for @bingo_fieldsBase.
  ///
  /// In pl, this message translates to:
  /// **'Baza pól ({active} / {total} aktywnych)'**
  String bingo_fieldsBase(int active, int total);

  /// No description provided for @bingo_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak pól. Dodaj pierwsze powyżej.'**
  String get bingo_empty;

  /// No description provided for @bingo_newField.
  ///
  /// In pl, this message translates to:
  /// **'Treść pola…'**
  String get bingo_newField;

  /// No description provided for @wheel_fields.
  ///
  /// In pl, this message translates to:
  /// **'Pola koła ({count})'**
  String wheel_fields(int count);

  /// No description provided for @wheel_removeOnPick.
  ///
  /// In pl, this message translates to:
  /// **'Usuń wylosowanego z puli'**
  String get wheel_removeOnPick;

  /// No description provided for @wheel_removeOnPickOn.
  ///
  /// In pl, this message translates to:
  /// **'Wylosowane pola nie pojawią się ponownie (w tej sesji).'**
  String get wheel_removeOnPickOn;

  /// No description provided for @wheel_removeOnPickOff.
  ///
  /// In pl, this message translates to:
  /// **'Wylosowane pola zostają w puli.'**
  String get wheel_removeOnPickOff;

  /// No description provided for @wheel_fullscreen.
  ///
  /// In pl, this message translates to:
  /// **'Tryb prezentacji (pełny ekran)'**
  String get wheel_fullscreen;

  /// No description provided for @wheel_fullscreenHint.
  ///
  /// In pl, this message translates to:
  /// **'Duże koło do pokazania na sali.'**
  String get wheel_fullscreenHint;

  /// No description provided for @wheel_poolEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Pula jest pusta — dodaj pola lub zresetuj pulę.'**
  String get wheel_poolEmpty;

  /// No description provided for @wheel_poolReset.
  ///
  /// In pl, this message translates to:
  /// **'Pula przywrócona'**
  String get wheel_poolReset;

  /// No description provided for @wheel_noFields.
  ///
  /// In pl, this message translates to:
  /// **'Brak pól w puli'**
  String get wheel_noFields;

  /// No description provided for @wheel_spinning.
  ///
  /// In pl, this message translates to:
  /// **'Kręcę…'**
  String get wheel_spinning;

  /// No description provided for @wheel_pressSpin.
  ///
  /// In pl, this message translates to:
  /// **'Naciśnij „Zakręć!\"'**
  String get wheel_pressSpin;

  /// No description provided for @wheel_spin.
  ///
  /// In pl, this message translates to:
  /// **'Zakręć!'**
  String get wheel_spin;

  /// No description provided for @wheel_reset.
  ///
  /// In pl, this message translates to:
  /// **'Resetuj pulę'**
  String get wheel_reset;

  /// No description provided for @wheel_history.
  ///
  /// In pl, this message translates to:
  /// **'🕘 Historia losowań'**
  String get wheel_history;

  /// Tryb koła fortuny; wartość zapisywana w bazie jest osobna.
  ///
  /// In pl, this message translates to:
  /// **'Kto tańczy następny'**
  String get wheelMode_nextDance;

  /// No description provided for @wheelMode_coupleTask.
  ///
  /// In pl, this message translates to:
  /// **'Zadanie dla Pary Młodej'**
  String get wheelMode_coupleTask;

  /// No description provided for @wheelMode_custom.
  ///
  /// In pl, this message translates to:
  /// **'Własne koło'**
  String get wheelMode_custom;

  /// No description provided for @advices_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać rad. Sprawdź połączenie.'**
  String get advices_loadError;

  /// No description provided for @advices_deleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć radę od „{name}\"? Tej operacji nie można cofnąć.'**
  String advices_deleteConfirm(String name);

  /// No description provided for @advices_pdfTitleNamed.
  ///
  /// In pl, this message translates to:
  /// **'Rady dla Pary Młodej — {event}'**
  String advices_pdfTitleNamed(String event);

  /// No description provided for @guestbook_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'💝 Księga gości'**
  String get guestbook_headerTitle;

  /// No description provided for @guestbook_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać wpisów. Sprawdź połączenie z internetem.'**
  String get guestbook_loadError;

  /// Podpis pod liczbą wpisów w księdze gości.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{życzenie} few{życzenia} other{życzeń}}'**
  String guestbook_wishCount(int count);

  /// No description provided for @guestbook_pdfTitleNamed.
  ///
  /// In pl, this message translates to:
  /// **'Księga Gości — {event}'**
  String guestbook_pdfTitleNamed(String event);

  /// No description provided for @capsule_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'⏳ Kapsuła czasu'**
  String get capsule_headerTitle;

  /// No description provided for @capsule_messages.
  ///
  /// In pl, this message translates to:
  /// **'Wiadomości'**
  String get capsule_messages;

  /// No description provided for @capsule_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać wiadomości. Sprawdź połączenie.'**
  String get capsule_loadError;

  /// No description provided for @capsule_sealed.
  ///
  /// In pl, this message translates to:
  /// **'Zapieczętowane'**
  String get capsule_sealed;

  /// No description provided for @capsule_nearest.
  ///
  /// In pl, this message translates to:
  /// **'Najbliższe'**
  String get capsule_nearest;

  /// No description provided for @capsule_previewOn.
  ///
  /// In pl, this message translates to:
  /// **'Podgląd wszystkich włączony (treści widoczne tylko dla Ciebie).'**
  String get capsule_previewOn;

  /// No description provided for @capsule_autoOpen.
  ///
  /// In pl, this message translates to:
  /// **'Wiadomości otworzą się automatycznie w swojej dacie.'**
  String get capsule_autoOpen;

  /// No description provided for @capsule_seal.
  ///
  /// In pl, this message translates to:
  /// **'Zapieczętuj'**
  String get capsule_seal;

  /// No description provided for @capsule_previewUntil.
  ///
  /// In pl, this message translates to:
  /// **'🔓 Podgląd — otworzy się {date}'**
  String capsule_previewUntil(String date);

  /// No description provided for @capsule_later.
  ///
  /// In pl, this message translates to:
  /// **'później'**
  String get capsule_later;

  /// No description provided for @capsule_pdfTitleNamed.
  ///
  /// In pl, this message translates to:
  /// **'Kapsuła czasu — {event}'**
  String capsule_pdfTitleNamed(String event);

  /// No description provided for @guestMap_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'🗺️ Mapa gości'**
  String get guestMap_headerTitle;

  /// No description provided for @guestMap_loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać mapy. Sprawdź połączenie.'**
  String get guestMap_loadError;

  /// No description provided for @guestMap_guests.
  ///
  /// In pl, this message translates to:
  /// **'Gości'**
  String get guestMap_guests;

  /// No description provided for @guestMap_cities.
  ///
  /// In pl, this message translates to:
  /// **'Miejscowości'**
  String get guestMap_cities;

  /// No description provided for @guestMap_noCity.
  ///
  /// In pl, this message translates to:
  /// **'Brak miejscowości'**
  String get guestMap_noCity;

  /// No description provided for @guestMap_savedNoGeo.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano (nie udało się zlokalizować miejscowości)'**
  String get guestMap_savedNoGeo;

  /// No description provided for @guestMap_addedNoGeo.
  ///
  /// In pl, this message translates to:
  /// **'Dodano (nie udało się zlokalizować miejscowości)'**
  String get guestMap_addedNoGeo;

  /// No description provided for @guestMap_addGuest.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj gościa'**
  String get guestMap_addGuest;

  /// No description provided for @hotel_deleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{name}\"? Przypisania gości do tego hotelu zostaną wyczyszczone.'**
  String hotel_deleteConfirm(String name);

  /// No description provided for @hotel_deleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto hotel'**
  String get hotel_deleted;

  /// No description provided for @hotel_noGuests.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości z zaznaczonym noclegiem.\nZaznacz „Nocleg\" przy gościu w sekcji Goście.'**
  String get hotel_noGuests;

  /// No description provided for @hotel_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak hoteli. Dodaj pierwszy poniżej.'**
  String get hotel_empty;

  /// No description provided for @hotel_address.
  ///
  /// In pl, this message translates to:
  /// **'📍 {address}'**
  String hotel_address(String address);

  /// No description provided for @hotel_phone.
  ///
  /// In pl, this message translates to:
  /// **'📞 {phone}'**
  String hotel_phone(String phone);

  /// No description provided for @hotel_perRoom.
  ///
  /// In pl, this message translates to:
  /// **'👥 {count} os./pokój'**
  String hotel_perRoom(int count);

  /// No description provided for @hotel_guestCount.
  ///
  /// In pl, this message translates to:
  /// **'🛏 gości: {count}'**
  String hotel_guestCount(int count);

  /// No description provided for @hotel_nameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Hotel Pod Różą'**
  String get hotel_nameHint;

  /// No description provided for @hotel_needName.
  ///
  /// In pl, this message translates to:
  /// **'Podaj nazwę hotelu'**
  String get hotel_needName;

  /// No description provided for @hotel_personsPerRoom.
  ///
  /// In pl, this message translates to:
  /// **'Osób w pokoju'**
  String get hotel_personsPerRoom;

  /// No description provided for @an_budgetChart.
  ///
  /// In pl, this message translates to:
  /// **'Budżet: planowany / orientacyjny / opłacony'**
  String get an_budgetChart;

  /// No description provided for @an_expensesChart.
  ///
  /// In pl, this message translates to:
  /// **'Rozkład wydatków (kategorie)'**
  String get an_expensesChart;

  /// No description provided for @an_paymentsChart.
  ///
  /// In pl, this message translates to:
  /// **'Postęp płatności w czasie'**
  String get an_paymentsChart;

  /// No description provided for @an_rsvpChart.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzenia gości'**
  String get an_rsvpChart;

  /// No description provided for @an_menuChart.
  ///
  /// In pl, this message translates to:
  /// **'Rozkład menu'**
  String get an_menuChart;

  /// No description provided for @an_dietChart.
  ///
  /// In pl, this message translates to:
  /// **'Rozkład diet'**
  String get an_dietChart;

  /// No description provided for @an_costPerGuest.
  ///
  /// In pl, this message translates to:
  /// **'Koszt / gość'**
  String get an_costPerGuest;

  /// No description provided for @an_byBudget.
  ///
  /// In pl, this message translates to:
  /// **'Wg budżetu'**
  String get an_byBudget;

  /// No description provided for @an_guests.
  ///
  /// In pl, this message translates to:
  /// **'Gości'**
  String get an_guests;

  /// No description provided for @an_paid.
  ///
  /// In pl, this message translates to:
  /// **'Opłacony'**
  String get an_paid;

  /// No description provided for @an_noExpenses.
  ///
  /// In pl, this message translates to:
  /// **'Brak wydatków.'**
  String get an_noExpenses;

  /// No description provided for @an_noPayments.
  ///
  /// In pl, this message translates to:
  /// **'Brak danych o płatnościach z datą.'**
  String get an_noPayments;

  /// No description provided for @an_noGuests.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości.'**
  String get an_noGuests;

  /// No description provided for @an_willAttend.
  ///
  /// In pl, this message translates to:
  /// **'Przyjdą'**
  String get an_willAttend;

  /// No description provided for @an_willNotAttend.
  ///
  /// In pl, this message translates to:
  /// **'Nie przyjdą'**
  String get an_willNotAttend;

  /// No description provided for @dash_emptyTiles.
  ///
  /// In pl, this message translates to:
  /// **'Brak kafelków. Kliknij „Edytuj\", aby dodać.'**
  String get dash_emptyTiles;

  /// No description provided for @dash_afterWedding.
  ///
  /// In pl, this message translates to:
  /// **'Już po ślubie!'**
  String get dash_afterWedding;

  /// No description provided for @gal_photoVideo.
  ///
  /// In pl, this message translates to:
  /// **'📸 Galeria zdjęć i filmów'**
  String get gal_photoVideo;

  /// No description provided for @gal_musicChoice.
  ///
  /// In pl, this message translates to:
  /// **'🎵 Wybór muzyki'**
  String get gal_musicChoice;

  /// No description provided for @gal_photos.
  ///
  /// In pl, this message translates to:
  /// **'📷 Zdjęcia'**
  String get gal_photos;

  /// No description provided for @gal_combined.
  ///
  /// In pl, this message translates to:
  /// **'Połączony'**
  String get gal_combined;

  /// No description provided for @gifts_forGuests.
  ///
  /// In pl, this message translates to:
  /// **'Dla gości'**
  String get gifts_forGuests;

  /// No description provided for @gifts_count.
  ///
  /// In pl, this message translates to:
  /// **'Prezentów'**
  String get gifts_count;

  /// No description provided for @gifts_totalValue.
  ///
  /// In pl, this message translates to:
  /// **'Łączna wartość'**
  String get gifts_totalValue;

  /// No description provided for @gifts_favoursCount.
  ///
  /// In pl, this message translates to:
  /// **'Upominków'**
  String get gifts_favoursCount;

  /// No description provided for @gifts_totalCost.
  ///
  /// In pl, this message translates to:
  /// **'Łączny koszt'**
  String get gifts_totalCost;

  /// No description provided for @gifts_totalCostFor.
  ///
  /// In pl, this message translates to:
  /// **'Łączny koszt ({count} os.)'**
  String gifts_totalCostFor(String count);

  /// No description provided for @gifts_recalcToReal.
  ///
  /// In pl, this message translates to:
  /// **'Przelicz na gości rzeczywistych'**
  String get gifts_recalcToReal;

  /// No description provided for @gifts_addProposal.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj propozycję'**
  String get gifts_addProposal;

  /// No description provided for @gifts_proposalHint.
  ///
  /// In pl, this message translates to:
  /// **'Tytuł propozycji…'**
  String get gifts_proposalHint;

  /// No description provided for @rsvpAll_qr.
  ///
  /// In pl, this message translates to:
  /// **'📋 Potwierdzenia (RSVP)'**
  String get rsvpAll_qr;

  /// No description provided for @rsvpAll_entries.
  ///
  /// In pl, this message translates to:
  /// **'Wpisów'**
  String get rsvpAll_entries;

  /// No description provided for @rsvpAll_manual.
  ///
  /// In pl, this message translates to:
  /// **'✍ Ręczny'**
  String get rsvpAll_manual;

  /// No description provided for @rsvp_attendingShort.
  ///
  /// In pl, this message translates to:
  /// **'✓ Przyjdzie'**
  String get rsvp_attendingShort;

  /// No description provided for @rsvp_qrTitle.
  ///
  /// In pl, this message translates to:
  /// **'Kod QR potwierdzeń'**
  String get rsvp_qrTitle;

  /// No description provided for @rsvp_attendingCount.
  ///
  /// In pl, this message translates to:
  /// **'✓ Przyjdą ({count})'**
  String rsvp_attendingCount(int count);

  /// No description provided for @rsvp_notAttendingCount.
  ///
  /// In pl, this message translates to:
  /// **'✗ Nie przyjdą ({count})'**
  String rsvp_notAttendingCount(int count);

  /// No description provided for @music_headerTitle.
  ///
  /// In pl, this message translates to:
  /// **'🎵 Muzyka — propozycje gości'**
  String get music_headerTitle;

  /// No description provided for @music_needTitle.
  ///
  /// In pl, this message translates to:
  /// **'Podaj tytuł utworu'**
  String get music_needTitle;

  /// No description provided for @music_exportTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tytuł'**
  String get music_exportTitle;

  /// No description provided for @music_exportSpecial.
  ///
  /// In pl, this message translates to:
  /// **'Utwór specjalny'**
  String get music_exportSpecial;

  /// No description provided for @music_exportFromGuest.
  ///
  /// In pl, this message translates to:
  /// **'Od gościa'**
  String get music_exportFromGuest;

  /// No description provided for @music_importHelp.
  ///
  /// In pl, this message translates to:
  /// **'Wklej listę utworów. Obsługiwane formaty:\n• CSV: Tytuł;Wykonawca;Status (separator średnik)\n• Tekst: \"- Tytuł — Wykonawca\" (po jednym w linii)\nStatus rozpoznawany ze słów: „zatwierdzone\", „odrzucone\", „dj\".'**
  String get music_importHelp;

  /// No description provided for @tr_ownTransport.
  ///
  /// In pl, this message translates to:
  /// **'transport własny'**
  String get tr_ownTransport;

  /// No description provided for @tr_unassigned.
  ///
  /// In pl, this message translates to:
  /// **'bez przydziału'**
  String get tr_unassigned;

  /// No description provided for @tr_vehicles.
  ///
  /// In pl, this message translates to:
  /// **'pojazdów'**
  String get tr_vehicles;

  /// No description provided for @tr_route.
  ///
  /// In pl, this message translates to:
  /// **'🛣 {route}'**
  String tr_route(String route);

  /// No description provided for @tr_addToOwn.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj do transportu własnego'**
  String get tr_addToOwn;

  /// No description provided for @tr_typeHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Pojazd Kuby, Bus wynajęty'**
  String get tr_typeHint;

  /// No description provided for @tr_needType.
  ///
  /// In pl, this message translates to:
  /// **'Podaj typ/nazwę'**
  String get tr_needType;

  /// No description provided for @tr_driverName.
  ///
  /// In pl, this message translates to:
  /// **'Imię kierowcy'**
  String get tr_driverName;

  /// No description provided for @tr_routeHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Kościół → Sala'**
  String get tr_routeHint;

  /// {currency} to symbol waluty wesela.
  ///
  /// In pl, this message translates to:
  /// **'Koszt ({currency})'**
  String tr_cost(String currency);

  /// No description provided for @vf_editVendor.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj dostawcę'**
  String get vf_editVendor;

  /// No description provided for @vf_addVendor.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj dostawcę'**
  String get vf_addVendor;

  /// No description provided for @vf_customCategory.
  ///
  /// In pl, this message translates to:
  /// **'Własna kategoria'**
  String get vf_customCategory;

  /// No description provided for @vf_needCompany.
  ///
  /// In pl, this message translates to:
  /// **'Podaj nazwę firmy'**
  String get vf_needCompany;

  /// No description provided for @vf_fullName.
  ///
  /// In pl, this message translates to:
  /// **'Imię i nazwisko'**
  String get vf_fullName;

  /// No description provided for @vf_price.
  ///
  /// In pl, this message translates to:
  /// **'Cena ({currency})'**
  String vf_price(String currency);

  /// No description provided for @vf_paymentStatus.
  ///
  /// In pl, this message translates to:
  /// **'Status płatności'**
  String get vf_paymentStatus;

  /// No description provided for @vf_contractAmount.
  ///
  /// In pl, this message translates to:
  /// **'Kwota umowy / szac. koszt ({currency})'**
  String vf_contractAmount(String currency);

  /// No description provided for @vf_budgetCategory.
  ///
  /// In pl, this message translates to:
  /// **'Kategoria budżetowa'**
  String get vf_budgetCategory;

  /// No description provided for @vend_linkedBody.
  ///
  /// In pl, this message translates to:
  /// **'Dostawca „{vendor}\" jest powiązany z wpisem w budżecie. Co zrobić z powiązanym wpisem?'**
  String vend_linkedBody(String vendor);

  /// No description provided for @vend_deleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno usunąć „{vendor}\"?'**
  String vend_deleteConfirm(String vendor);

  /// No description provided for @vend_deleteBoth.
  ///
  /// In pl, this message translates to:
  /// **'Usuń oba'**
  String get vend_deleteBoth;

  /// No description provided for @vend_anyStatus.
  ///
  /// In pl, this message translates to:
  /// **'Każdy status'**
  String get vend_anyStatus;

  /// No description provided for @vend_byName.
  ///
  /// In pl, this message translates to:
  /// **'Wg nazwy (A–Z)'**
  String get vend_byName;

  /// No description provided for @task_transport.
  ///
  /// In pl, this message translates to:
  /// **'🚗 Transport'**
  String get task_transport;

  /// No description provided for @task_gift.
  ///
  /// In pl, this message translates to:
  /// **'🎁 Prezent'**
  String get task_gift;

  /// No description provided for @task_goToSection.
  ///
  /// In pl, this message translates to:
  /// **'→ {section}'**
  String task_goToSection(String section);

  /// No description provided for @sched_location.
  ///
  /// In pl, this message translates to:
  /// **'📍 {location}'**
  String sched_location(String location);

  /// No description provided for @pay_expensesTab.
  ///
  /// In pl, this message translates to:
  /// **'📋 Wydatki'**
  String get pay_expensesTab;

  /// No description provided for @pay_dueDate.
  ///
  /// In pl, this message translates to:
  /// **'📅 {date}'**
  String pay_dueDate(String date);

  /// No description provided for @lock_unlock.
  ///
  /// In pl, this message translates to:
  /// **'Odblokuj, aby kontynuować'**
  String get lock_unlock;

  /// No description provided for @lock_touchToScan.
  ///
  /// In pl, this message translates to:
  /// **'Dotknij, aby zeskanować odcisk palca'**
  String get lock_touchToScan;

  /// {type} to „PIN" albo „wzór" — patrz sec_backupPin / sec_backupPattern.
  ///
  /// In pl, this message translates to:
  /// **'Użyj {type}'**
  String lock_useBackup(String type);

  /// No description provided for @lock_drawPattern.
  ///
  /// In pl, this message translates to:
  /// **'Narysuj wzór odblokowania'**
  String get lock_drawPattern;

  /// No description provided for @lock_wrongBackup.
  ///
  /// In pl, this message translates to:
  /// **'Błędny {type} — pozostało prób: {left}'**
  String lock_wrongBackup(String type, int left);

  /// No description provided for @lock_useFingerprint.
  ///
  /// In pl, this message translates to:
  /// **'Użyj odcisku palca'**
  String get lock_useFingerprint;

  /// No description provided for @lock_forgot.
  ///
  /// In pl, this message translates to:
  /// **'Nie pamiętasz? Zaloguj przez Google'**
  String get lock_forgot;

  /// No description provided for @setup_confirmBiometric.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź odcisk palca, aby włączyć logowanie biometryczne'**
  String get setup_confirmBiometric;

  /// No description provided for @setup_biometricFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się potwierdzić odcisku palca. Czy ustawić samo zabezpieczenie zapasowe (PIN lub wzór)?'**
  String get setup_biometricFailed;

  /// No description provided for @setup_setPin.
  ///
  /// In pl, this message translates to:
  /// **'Ustaw PIN/wzór'**
  String get setup_setPin;

  /// No description provided for @setup_repeatPin.
  ///
  /// In pl, this message translates to:
  /// **'Powtórz kod PIN'**
  String get setup_repeatPin;

  /// No description provided for @setup_repeatPattern.
  ///
  /// In pl, this message translates to:
  /// **'Powtórz wzór, aby potwierdzić'**
  String get setup_repeatPattern;

  /// No description provided for @setup_pinMismatch.
  ///
  /// In pl, this message translates to:
  /// **'Kody PIN się różnią — spróbuj ponownie'**
  String get setup_pinMismatch;

  /// No description provided for @setup_patternMismatch.
  ///
  /// In pl, this message translates to:
  /// **'Wzory się różnią — spróbuj ponownie'**
  String get setup_patternMismatch;

  /// No description provided for @setup_pinBackupHint.
  ///
  /// In pl, this message translates to:
  /// **'PIN/wzór posłuży, gdy odcisk palca nie zadziała (np. mokry palec).'**
  String get setup_pinBackupHint;

  /// No description provided for @setup_unlockHint.
  ///
  /// In pl, this message translates to:
  /// **'To zabezpieczenie odblokuje aplikację przy kolejnych otwarciach.'**
  String get setup_unlockHint;

  /// No description provided for @setup_pattern.
  ///
  /// In pl, this message translates to:
  /// **'Wzór graficzny'**
  String get setup_pattern;

  /// No description provided for @setup_connectDots.
  ///
  /// In pl, this message translates to:
  /// **'Połącz co najmniej 4 punkty'**
  String get setup_connectDots;

  /// No description provided for @setup_patternTooShort.
  ///
  /// In pl, this message translates to:
  /// **'Wzór jest za krótki — połącz min. 4 punkty'**
  String get setup_patternTooShort;

  /// No description provided for @login_subtitle.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się lub załóż konto, aby zarządzać swoim weselem'**
  String get login_subtitle;

  /// No description provided for @login_secure.
  ///
  /// In pl, this message translates to:
  /// **'🔒 Bezpieczne logowanie'**
  String get login_secure;

  /// No description provided for @login_google.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się przez Google'**
  String get login_google;

  /// No description provided for @login_or.
  ///
  /// In pl, this message translates to:
  /// **'lub'**
  String get login_or;

  /// No description provided for @login_emailButton.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się e-mailem'**
  String get login_emailButton;

  /// No description provided for @auth_cancelled.
  ///
  /// In pl, this message translates to:
  /// **'Anulowano logowanie.'**
  String get auth_cancelled;

  /// No description provided for @wsum_owner.
  ///
  /// In pl, this message translates to:
  /// **'Właściciel'**
  String get wsum_owner;

  /// No description provided for @wsum_collab.
  ///
  /// In pl, this message translates to:
  /// **'Współpraca'**
  String get wsum_collab;

  /// No description provided for @hotel_added.
  ///
  /// In pl, this message translates to:
  /// **'Dodano hotel'**
  String get hotel_added;

  /// No description provided for @hotel_needsRoom.
  ///
  /// In pl, this message translates to:
  /// **'Potrzebuje noclegu'**
  String get hotel_needsRoom;

  /// No description provided for @common_noName.
  ///
  /// In pl, this message translates to:
  /// **'(bez imienia)'**
  String get common_noName;

  /// No description provided for @hotel_edit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj hotel'**
  String get hotel_edit;

  /// No description provided for @hotel_add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj hotel'**
  String get hotel_add;

  /// No description provided for @hotel_nameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa hotelu *'**
  String get hotel_nameRequired;

  /// No description provided for @hotel_streetCity.
  ///
  /// In pl, this message translates to:
  /// **'Ulica, miasto'**
  String get hotel_streetCity;

  /// No description provided for @hotel_pricePerNight.
  ///
  /// In pl, this message translates to:
  /// **'Cena za os./noc'**
  String get hotel_pricePerNight;

  /// No description provided for @hotel_bookingLink.
  ///
  /// In pl, this message translates to:
  /// **'Link do rezerwacji'**
  String get hotel_bookingLink;

  /// No description provided for @an_byEstimate.
  ///
  /// In pl, this message translates to:
  /// **'Wg orientacyjnego'**
  String get an_byEstimate;

  /// No description provided for @an_estimateShort.
  ///
  /// In pl, this message translates to:
  /// **'Orientac.'**
  String get an_estimateShort;

  /// No description provided for @an_noMenu.
  ///
  /// In pl, this message translates to:
  /// **'Bez menu'**
  String get an_noMenu;

  /// No description provided for @an_noMenuData.
  ///
  /// In pl, this message translates to:
  /// **'Brak danych o menu.'**
  String get an_noMenuData;

  /// No description provided for @an_noDietData.
  ///
  /// In pl, this message translates to:
  /// **'Brak danych o dietach.'**
  String get an_noDietData;

  /// No description provided for @bingo_generator.
  ///
  /// In pl, this message translates to:
  /// **'Generator plansz'**
  String get bingo_generator;

  /// No description provided for @bingo_boardCount.
  ///
  /// In pl, this message translates to:
  /// **'Liczba plansz:'**
  String get bingo_boardCount;

  /// No description provided for @bingo_newFieldHint.
  ///
  /// In pl, this message translates to:
  /// **'Nowe pole bingo…'**
  String get bingo_newFieldHint;

  /// No description provided for @bev_bottlesPerPerson.
  ///
  /// In pl, this message translates to:
  /// **'butelek / os.'**
  String get bev_bottlesPerPerson;

  /// No description provided for @bev_costPerPerson.
  ///
  /// In pl, this message translates to:
  /// **'koszt / os.'**
  String get bev_costPerPerson;

  /// No description provided for @bev_brand.
  ///
  /// In pl, this message translates to:
  /// **'Marka / nazwa (opcjonalnie)'**
  String get bev_brand;

  /// No description provided for @bev_pieces.
  ///
  /// In pl, this message translates to:
  /// **'szt.'**
  String get bev_pieces;

  /// No description provided for @bs_plannedPlusReserve.
  ///
  /// In pl, this message translates to:
  /// **'Planowany + rezerwa'**
  String get bs_plannedPlusReserve;

  /// No description provided for @bs_ofWhichVenue.
  ///
  /// In pl, this message translates to:
  /// **'w tym sala'**
  String get bs_ofWhichVenue;

  /// No description provided for @bs_reserveUsed.
  ///
  /// In pl, this message translates to:
  /// **'Wykorzystana rezerwa'**
  String get bs_reserveUsed;

  /// No description provided for @ef_edit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj wydatek'**
  String get ef_edit;

  /// No description provided for @ef_add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wydatek'**
  String get ef_add;

  /// No description provided for @ef_nameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Atrakcje dla dzieci'**
  String get ef_nameHint;

  /// No description provided for @ef_estimate.
  ///
  /// In pl, this message translates to:
  /// **'Kwota orientacyjna'**
  String get ef_estimate;

  /// No description provided for @ef_confirmed.
  ///
  /// In pl, this message translates to:
  /// **'Kwota rzeczywista (potwierdzona)'**
  String get ef_confirmed;

  /// No description provided for @vf_companyName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa firmy'**
  String get vf_companyName;

  /// No description provided for @vf_companyHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Studio Foto'**
  String get vf_companyHint;

  /// No description provided for @vf_contactPerson.
  ///
  /// In pl, this message translates to:
  /// **'Osoba kontaktowa'**
  String get vf_contactPerson;

  /// No description provided for @vf_vendorCategory.
  ///
  /// In pl, this message translates to:
  /// **'Kategoria dostawcy'**
  String get vf_vendorCategory;

  /// No description provided for @common_email.
  ///
  /// In pl, this message translates to:
  /// **'E-mail'**
  String get common_email;

  /// No description provided for @sala_cateringBase.
  ///
  /// In pl, this message translates to:
  /// **'Baza cateringu'**
  String get sala_cateringBase;

  /// No description provided for @sala_cateringExtras.
  ///
  /// In pl, this message translates to:
  /// **'Dodatki cateringu'**
  String get sala_cateringExtras;

  /// No description provided for @sala_inCosts.
  ///
  /// In pl, this message translates to:
  /// **'W kosztach'**
  String get sala_inCosts;

  /// No description provided for @sala_menuExtras.
  ///
  /// In pl, this message translates to:
  /// **'Dodatki do menu'**
  String get sala_menuExtras;

  /// No description provided for @sala_separateCatering.
  ///
  /// In pl, this message translates to:
  /// **'Catering (oddzielny)'**
  String get sala_separateCatering;

  /// No description provided for @sala_venueTotal.
  ///
  /// In pl, this message translates to:
  /// **'Razem sala'**
  String get sala_venueTotal;

  /// No description provided for @sala_staffNameHint.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa (np. Kelnerzy)'**
  String get sala_staffNameHint;

  /// No description provided for @gal_videos.
  ///
  /// In pl, this message translates to:
  /// **'▶ Filmy'**
  String get gal_videos;

  /// No description provided for @gal_pdfPrints.
  ///
  /// In pl, this message translates to:
  /// **'Wydruki PDF'**
  String get gal_pdfPrints;

  /// No description provided for @gal_galleryQr.
  ///
  /// In pl, this message translates to:
  /// **'Galeria (QR)'**
  String get gal_galleryQr;

  /// No description provided for @pc_needChallenge.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw dodaj przynajmniej jedno wyzwanie.'**
  String get pc_needChallenge;

  /// No description provided for @pc_editChallenge.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj wyzwanie'**
  String get pc_editChallenge;

  /// No description provided for @gp_needTwoAnswers.
  ///
  /// In pl, this message translates to:
  /// **'Podaj przynajmniej 2 odpowiedzi'**
  String get gp_needTwoAnswers;

  /// No description provided for @quiz_needQuestion.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw dodaj przynajmniej jedno pytanie.'**
  String get quiz_needQuestion;

  /// No description provided for @gp_noAnswers.
  ///
  /// In pl, this message translates to:
  /// **'brak odpowiedzi'**
  String get gp_noAnswers;

  /// No description provided for @quiz_editQuestion.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj pytanie'**
  String get quiz_editQuestion;

  /// No description provided for @tf_needStatement.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw dodaj przynajmniej jedno stwierdzenie.'**
  String get tf_needStatement;

  /// No description provided for @tf_editStatement.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj stwierdzenie'**
  String get tf_editStatement;

  /// No description provided for @tf_isItTrue.
  ///
  /// In pl, this message translates to:
  /// **'Czy to prawda?'**
  String get tf_isItTrue;

  /// No description provided for @wheel_mode.
  ///
  /// In pl, this message translates to:
  /// **'Tryb losowania'**
  String get wheel_mode;

  /// No description provided for @wheel_addField.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pole'**
  String get wheel_addField;

  /// No description provided for @wheel_addHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pola przyciskiem +.'**
  String get wheel_addHint;

  /// No description provided for @wheel_fieldN.
  ///
  /// In pl, this message translates to:
  /// **'Pole {index}'**
  String wheel_fieldN(int index);

  /// No description provided for @wheel_drawn.
  ///
  /// In pl, this message translates to:
  /// **'🎉 Wylosowano'**
  String get wheel_drawn;

  /// No description provided for @wheel_inPool.
  ///
  /// In pl, this message translates to:
  /// **'W puli: {count}'**
  String wheel_inPool(int count);

  /// No description provided for @gifts_addGift.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj prezent'**
  String get gifts_addGift;

  /// No description provided for @gifts_fromWho.
  ///
  /// In pl, this message translates to:
  /// **'Od kogo…'**
  String get gifts_fromWho;

  /// No description provided for @gifts_giftDesc.
  ///
  /// In pl, this message translates to:
  /// **'Opis prezentu…'**
  String get gifts_giftDesc;

  /// No description provided for @gifts_recalcAll.
  ///
  /// In pl, this message translates to:
  /// **'Przelicz na rzeczywistych + wirtualnych'**
  String get gifts_recalcAll;

  /// No description provided for @gifts_favourHint.
  ///
  /// In pl, this message translates to:
  /// **'Upominek…'**
  String get gifts_favourHint;

  /// No description provided for @common_descriptionHint.
  ///
  /// In pl, this message translates to:
  /// **'Opis…'**
  String get common_descriptionHint;

  /// No description provided for @gc_seatHint.
  ///
  /// In pl, this message translates to:
  /// **'np. miejsce przy rodzinie'**
  String get gc_seatHint;

  /// No description provided for @gc_allergyHint.
  ///
  /// In pl, this message translates to:
  /// **'np. orzechy, gluten'**
  String get gc_allergyHint;

  /// No description provided for @gc_extraInfo.
  ///
  /// In pl, this message translates to:
  /// **'Dodatkowe informacje…'**
  String get gc_extraInfo;

  /// No description provided for @advices_emptyCategory.
  ///
  /// In pl, this message translates to:
  /// **'Brak rad w tej kategorii.'**
  String get advices_emptyCategory;

  /// No description provided for @advices_autoplay.
  ///
  /// In pl, this message translates to:
  /// **'Auto-pokaz'**
  String get advices_autoplay;

  /// No description provided for @guestMap_onMap.
  ///
  /// In pl, this message translates to:
  /// **'Na mapie'**
  String get guestMap_onMap;

  /// No description provided for @guestMap_savedEntry.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano wpis'**
  String get guestMap_savedEntry;

  /// No description provided for @guestMap_addedEntry.
  ///
  /// In pl, this message translates to:
  /// **'Dodano wpis'**
  String get guestMap_addedEntry;

  /// No description provided for @guestMap_editEntry.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj wpis'**
  String get guestMap_editEntry;

  /// No description provided for @capsule_opened.
  ///
  /// In pl, this message translates to:
  /// **'💌 Otwarta'**
  String get capsule_opened;

  /// No description provided for @lock_locked.
  ///
  /// In pl, this message translates to:
  /// **'Aplikacja zablokowana'**
  String get lock_locked;

  /// No description provided for @lock_welcomeBack.
  ///
  /// In pl, this message translates to:
  /// **'Witaj ponownie, {name}'**
  String lock_welcomeBack(String name);

  /// No description provided for @lock_enterPin.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz kod PIN'**
  String get lock_enterPin;

  /// No description provided for @setup_biometricUnconfirmed.
  ///
  /// In pl, this message translates to:
  /// **'Biometria niepotwierdzona'**
  String get setup_biometricUnconfirmed;

  /// No description provided for @setup_chooseBackup.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz zabezpieczenie zapasowe'**
  String get setup_chooseBackup;

  /// No description provided for @setup_setPinCode.
  ///
  /// In pl, this message translates to:
  /// **'Ustaw kod PIN (4 cyfry)'**
  String get setup_setPinCode;

  /// No description provided for @setup_changeBackup.
  ///
  /// In pl, this message translates to:
  /// **'Zmiana zabezpieczenia'**
  String get setup_changeBackup;

  /// No description provided for @setup_lockConfig.
  ///
  /// In pl, this message translates to:
  /// **'Konfiguracja blokady'**
  String get setup_lockConfig;

  /// No description provided for @setup_pinCode.
  ///
  /// In pl, this message translates to:
  /// **'Kod PIN'**
  String get setup_pinCode;

  /// No description provided for @setup_fourDigits.
  ///
  /// In pl, this message translates to:
  /// **'4 cyfry'**
  String get setup_fourDigits;

  /// No description provided for @login_signingIn.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie…'**
  String get login_signingIn;

  /// No description provided for @music_specialFilter.
  ///
  /// In pl, this message translates to:
  /// **'⭐ Specjalne'**
  String get music_specialFilter;

  /// No description provided for @music_genre.
  ///
  /// In pl, this message translates to:
  /// **'Gatunek / gust'**
  String get music_genre;

  /// No description provided for @music_specialMoment.
  ///
  /// In pl, this message translates to:
  /// **'⭐ Moment specjalny'**
  String get music_specialMoment;

  /// No description provided for @music_notSpecial.
  ///
  /// In pl, this message translates to:
  /// **'— nie jest specjalny —'**
  String get music_notSpecial;

  /// No description provided for @music_partyMoment.
  ///
  /// In pl, this message translates to:
  /// **'Moment imprezy'**
  String get music_partyMoment;

  /// No description provided for @music_exportHeader.
  ///
  /// In pl, this message translates to:
  /// **'LISTA PIOSENEK NA WESELE'**
  String get music_exportHeader;

  /// No description provided for @music_exportSpecialHeader.
  ///
  /// In pl, this message translates to:
  /// **'### ⭐ UTWORY SPECJALNE — KLUCZOWE MOMENTY'**
  String get music_exportSpecialHeader;

  /// No description provided for @music_exportAllHeader.
  ///
  /// In pl, this message translates to:
  /// **'### WSZYSTKIE UTWORY (wg momentu imprezy)'**
  String get music_exportAllHeader;

  /// No description provided for @room_freeSeats.
  ///
  /// In pl, this message translates to:
  /// **'Wolne miejsca'**
  String get room_freeSeats;

  /// No description provided for @rsvpAll_tabEntries.
  ///
  /// In pl, this message translates to:
  /// **'Wpisy RSVP'**
  String get rsvpAll_tabEntries;

  /// No description provided for @rsvpAll_tabQr.
  ///
  /// In pl, this message translates to:
  /// **'Kody QR i linki'**
  String get rsvpAll_tabQr;

  /// No description provided for @rsvp_notAttendingShort.
  ///
  /// In pl, this message translates to:
  /// **'✗ Nie przyjdzie'**
  String get rsvp_notAttendingShort;

  /// No description provided for @rsvp_noStatus.
  ///
  /// In pl, this message translates to:
  /// **'Brak statusu'**
  String get rsvp_noStatus;

  /// No description provided for @rsvp_fromForm.
  ///
  /// In pl, this message translates to:
  /// **'🌐 Z formularza'**
  String get rsvp_fromForm;

  /// No description provided for @rsvp_noReplyCount.
  ///
  /// In pl, this message translates to:
  /// **'Brak odpowiedzi ({count})'**
  String rsvp_noReplyCount(int count);

  /// No description provided for @sched_editEvent.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj wydarzenie'**
  String get sched_editEvent;

  /// No description provided for @sched_addEvent.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj wydarzenie'**
  String get sched_addEvent;

  /// No description provided for @common_nameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa *'**
  String get common_nameRequired;

  /// No description provided for @sched_placeHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Sala weselna'**
  String get sched_placeHint;

  /// No description provided for @common_responsible.
  ///
  /// In pl, this message translates to:
  /// **'Osoba odpowiedzialna'**
  String get common_responsible;

  /// No description provided for @sched_responsibleHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Oboje'**
  String get sched_responsibleHint;

  /// No description provided for @sched_mapLink.
  ///
  /// In pl, this message translates to:
  /// **'Link do lokalizacji'**
  String get sched_mapLink;

  /// No description provided for @sched_eventAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano wydarzenie'**
  String get sched_eventAdded;

  /// No description provided for @common_noNameNeutral.
  ///
  /// In pl, this message translates to:
  /// **'(bez nazwy)'**
  String get common_noNameNeutral;

  /// No description provided for @common_seats.
  ///
  /// In pl, this message translates to:
  /// **'Liczba miejsc'**
  String get common_seats;

  /// No description provided for @task_edit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj zadanie'**
  String get task_edit;

  /// No description provided for @task_add.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj zadanie'**
  String get task_add;

  /// No description provided for @task_goal.
  ///
  /// In pl, this message translates to:
  /// **'Cel / zdarzenie (opcjonalnie)'**
  String get task_goal;

  /// No description provided for @task_goalName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa celu'**
  String get task_goalName;

  /// No description provided for @task_goalHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Znalezienie fotografa'**
  String get task_goalHint;

  /// No description provided for @task_hideExtra.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj dodatkowe opcje'**
  String get task_hideExtra;

  /// No description provided for @task_accommodation.
  ///
  /// In pl, this message translates to:
  /// **'🏨 Nocleg'**
  String get task_accommodation;

  /// No description provided for @task_music.
  ///
  /// In pl, this message translates to:
  /// **'🎵 Muzyka'**
  String get task_music;

  /// No description provided for @task_allStatuses.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie statusy'**
  String get task_allStatuses;

  /// No description provided for @common_noSorting.
  ///
  /// In pl, this message translates to:
  /// **'Bez sortowania'**
  String get common_noSorting;

  /// No description provided for @task_byDue.
  ///
  /// In pl, this message translates to:
  /// **'Wg terminu'**
  String get task_byDue;

  /// No description provided for @task_byPriority.
  ///
  /// In pl, this message translates to:
  /// **'Wg priorytetu'**
  String get task_byPriority;

  /// No description provided for @common_byStatus.
  ///
  /// In pl, this message translates to:
  /// **'Wg statusu'**
  String get common_byStatus;

  /// No description provided for @tr_inVehicles.
  ///
  /// In pl, this message translates to:
  /// **'w pojazdach'**
  String get tr_inVehicles;

  /// No description provided for @tr_assignTo.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz do: {vehicle}'**
  String tr_assignTo(String vehicle);

  /// No description provided for @tr_boltTaxi.
  ///
  /// In pl, this message translates to:
  /// **'Bolt / Taxi'**
  String get tr_boltTaxi;

  /// No description provided for @tr_infoCodePhone.
  ///
  /// In pl, this message translates to:
  /// **'Info / kod / telefon'**
  String get tr_infoCodePhone;

  /// No description provided for @tr_editVehicle.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj pojazd'**
  String get tr_editVehicle;

  /// No description provided for @tr_addVehicle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pojazd'**
  String get tr_addVehicle;

  /// No description provided for @tr_typeRequired.
  ///
  /// In pl, this message translates to:
  /// **'Typ / nazwa pojazdu *'**
  String get tr_typeRequired;

  /// No description provided for @tr_departure.
  ///
  /// In pl, this message translates to:
  /// **'Godzina odjazdu'**
  String get tr_departure;

  /// No description provided for @vf_customCategoryHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Animator'**
  String get vf_customCategoryHint;

  /// No description provided for @vf_companyRequired.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa firmy *'**
  String get vf_companyRequired;

  /// No description provided for @vf_mapsLink.
  ///
  /// In pl, this message translates to:
  /// **'Link do Google Maps'**
  String get vf_mapsLink;

  /// No description provided for @vend_vendorChip.
  ///
  /// In pl, this message translates to:
  /// **'🏢 Dostawca'**
  String get vend_vendorChip;

  /// No description provided for @vend_instalmentHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Zadatek'**
  String get vend_instalmentHint;

  /// No description provided for @layout_forcePhone.
  ///
  /// In pl, this message translates to:
  /// **'Wymuś telefon'**
  String get layout_forcePhone;

  /// No description provided for @layout_forceTablet.
  ///
  /// In pl, this message translates to:
  /// **'Wymuś tablet'**
  String get layout_forceTablet;

  /// No description provided for @layout_autoHint.
  ///
  /// In pl, this message translates to:
  /// **'Układ dobiera się do szerokości ekranu'**
  String get layout_autoHint;

  /// No description provided for @layout_phoneHint.
  ///
  /// In pl, this message translates to:
  /// **'Zawsze dolny pasek nawigacji'**
  String get layout_phoneHint;

  /// No description provided for @layout_tabletHint.
  ///
  /// In pl, this message translates to:
  /// **'Zawsze boczna nawigacja i szersze siatki'**
  String get layout_tabletHint;

  /// No description provided for @common_statusHint.
  ///
  /// In pl, this message translates to:
  /// **'Status…'**
  String get common_statusHint;

  /// No description provided for @gs_companion.
  ///
  /// In pl, this message translates to:
  /// **'osoba towarzysząca'**
  String get gs_companion;

  /// No description provided for @gs_accompanies.
  ///
  /// In pl, this message translates to:
  /// **'towarzyszy gościowi'**
  String get gs_accompanies;

  /// No description provided for @notif_programmeItem.
  ///
  /// In pl, this message translates to:
  /// **'punkt programu'**
  String get notif_programmeItem;

  /// No description provided for @taskSvc_fromTask.
  ///
  /// In pl, this message translates to:
  /// **'Utworzono z zadania: {name}'**
  String taskSvc_fromTask(String name);

  /// No description provided for @vendSvc_vendor.
  ///
  /// In pl, this message translates to:
  /// **'Dostawca: {label}'**
  String vendSvc_vendor(String label);

  /// No description provided for @wedSvc_weddingId.
  ///
  /// In pl, this message translates to:
  /// **'Wesele {id}'**
  String wedSvc_weddingId(String id);

  /// Status dostawcy; w bazie zostaje `contacted`.
  ///
  /// In pl, this message translates to:
  /// **'Skontaktowano'**
  String get vendStatus_contacted;

  /// No description provided for @vendStatus_confirmed.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzony'**
  String get vendStatus_confirmed;

  /// No description provided for @vendStatus_cancelled.
  ///
  /// In pl, this message translates to:
  /// **'Anulowany'**
  String get vendStatus_cancelled;

  /// Przykładowe pytanie quizu wstawiane przy zakładaniu wesela. Zapisuje się w bazie w języku interfejsu i późniejsza zmiana języka go NIE rusza — to już treść pary, mogła ją edytować.
  ///
  /// In pl, this message translates to:
  /// **'Gdzie się poznaliśmy?'**
  String get quizEx_q1;

  /// No description provided for @quizEx_q1a1.
  ///
  /// In pl, this message translates to:
  /// **'W pracy'**
  String get quizEx_q1a1;

  /// No description provided for @quizEx_q1a2.
  ///
  /// In pl, this message translates to:
  /// **'Na studiach'**
  String get quizEx_q1a2;

  /// No description provided for @quizEx_q1a3.
  ///
  /// In pl, this message translates to:
  /// **'Przez znajomych'**
  String get quizEx_q1a3;

  /// No description provided for @quizEx_q1a4.
  ///
  /// In pl, this message translates to:
  /// **'W wakacje'**
  String get quizEx_q1a4;

  /// No description provided for @quizEx_q3.
  ///
  /// In pl, this message translates to:
  /// **'Gdzie była nasza pierwsza randka?'**
  String get quizEx_q3;

  /// No description provided for @quizEx_q3a1.
  ///
  /// In pl, this message translates to:
  /// **'W kinie'**
  String get quizEx_q3a1;

  /// No description provided for @quizEx_q3a2.
  ///
  /// In pl, this message translates to:
  /// **'W restauracji'**
  String get quizEx_q3a2;

  /// No description provided for @quizEx_q3a3.
  ///
  /// In pl, this message translates to:
  /// **'Na spacerze'**
  String get quizEx_q3a3;

  /// No description provided for @quizEx_q3a4.
  ///
  /// In pl, this message translates to:
  /// **'W kawiarni'**
  String get quizEx_q3a4;

  /// No description provided for @quizEx_q4.
  ///
  /// In pl, this message translates to:
  /// **'Kto się pierwszy oświadczył?'**
  String get quizEx_q4;

  /// No description provided for @tfEx_1.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda poznała się w pracy'**
  String get tfEx_1;

  /// No description provided for @tfEx_1e.
  ///
  /// In pl, this message translates to:
  /// **'Poznali się przez wspólnych znajomych.'**
  String get tfEx_1e;

  /// No description provided for @tfEx_2.
  ///
  /// In pl, this message translates to:
  /// **'Pierwsza randka była w kinie'**
  String get tfEx_2;

  /// No description provided for @tfEx_2e.
  ///
  /// In pl, this message translates to:
  /// **'Pierwsza randka była w kawiarni.'**
  String get tfEx_2e;

  /// No description provided for @tfEx_3.
  ///
  /// In pl, this message translates to:
  /// **'Oświadczyny odbyły się za granicą'**
  String get tfEx_3;

  /// No description provided for @tfEx_3e.
  ///
  /// In pl, this message translates to:
  /// **'Oświadczyny odbyły się podczas wspólnego wyjazdu.'**
  String get tfEx_3e;

  /// No description provided for @pcEx_1.
  ///
  /// In pl, this message translates to:
  /// **'Zrób selfie z Parą Młodą'**
  String get pcEx_1;

  /// No description provided for @pcEx_2.
  ///
  /// In pl, this message translates to:
  /// **'Sfotografuj najpiękniejszy toast'**
  String get pcEx_2;

  /// No description provided for @pcEx_3.
  ///
  /// In pl, this message translates to:
  /// **'Znajdź i sfotografuj najstarszego gościa'**
  String get pcEx_3;

  /// No description provided for @pcEx_4.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcie z parkietu'**
  String get pcEx_4;

  /// No description provided for @pcEx_5.
  ///
  /// In pl, this message translates to:
  /// **'Grupowe zdjęcie Twojego stolika'**
  String get pcEx_5;

  /// No description provided for @pcEx_6.
  ///
  /// In pl, this message translates to:
  /// **'Uchwyć pierwszy taniec'**
  String get pcEx_6;

  /// Domyślna nazwa nowego stołu; {number} to kolejny numer.
  ///
  /// In pl, this message translates to:
  /// **'Stół {number}'**
  String tableSvc_defaultName(int number);

  /// No description provided for @cfg_defaultEventName.
  ///
  /// In pl, this message translates to:
  /// **'Ceremonia Weselna'**
  String get cfg_defaultEventName;

  /// Przykładowe imiona w danych startowych — dostosuj do języka.
  ///
  /// In pl, this message translates to:
  /// **'Patrycji i Piotra'**
  String get cfg_defaultPersons;

  /// No description provided for @taskSvc_song.
  ///
  /// In pl, this message translates to:
  /// **'Utwór'**
  String get taskSvc_song;

  /// No description provided for @err_noActiveWedding.
  ///
  /// In pl, this message translates to:
  /// **'Brak aktywnego wesela — nie wiadomo, komu przypisać dane. Wybierz wesele i spróbuj ponownie.'**
  String get err_noActiveWedding;

  /// No description provided for @err_weddingDocMissing.
  ///
  /// In pl, this message translates to:
  /// **'Dokument wesela nie istnieje'**
  String get err_weddingDocMissing;

  /// No description provided for @err_guestViewMissing.
  ///
  /// In pl, this message translates to:
  /// **'guestView/main nie powstał — sprawdź reguły'**
  String get err_guestViewMissing;

  /// No description provided for @err_guestViewTokenMismatch.
  ///
  /// In pl, this message translates to:
  /// **'Token w guestView nie zgadza się z weselem'**
  String get err_guestViewTokenMismatch;

  /// No description provided for @common_optionalHint.
  ///
  /// In pl, this message translates to:
  /// **'Opcjonalnie…'**
  String get common_optionalHint;

  /// No description provided for @common_phoneHint.
  ///
  /// In pl, this message translates to:
  /// **'np. 600 100 200'**
  String get common_phoneHint;

  /// No description provided for @common_emailHint.
  ///
  /// In pl, this message translates to:
  /// **'kontakt@firma.pl'**
  String get common_emailHint;

  /// No description provided for @qr_schedule.
  ///
  /// In pl, this message translates to:
  /// **'📅 Harmonogram'**
  String get qr_schedule;

  /// No description provided for @qr_music.
  ///
  /// In pl, this message translates to:
  /// **'🎵 Muzyka'**
  String get qr_music;

  /// No description provided for @qr_bingo.
  ///
  /// In pl, this message translates to:
  /// **'🎲 Ślubne Bingo'**
  String get qr_bingo;

  /// No description provided for @qr_guestbook.
  ///
  /// In pl, this message translates to:
  /// **'💝 Księga gości'**
  String get qr_guestbook;

  /// No description provided for @qr_quiz.
  ///
  /// In pl, this message translates to:
  /// **'🧠 Quiz o Parze Młodej'**
  String get qr_quiz;

  /// No description provided for @qr_advices.
  ///
  /// In pl, this message translates to:
  /// **'💌 Rady dla Pary Młodej'**
  String get qr_advices;

  /// No description provided for @qr_trueFalse.
  ///
  /// In pl, this message translates to:
  /// **'🤔 Prawda czy Fałsz'**
  String get qr_trueFalse;

  /// No description provided for @qr_photoGuess.
  ///
  /// In pl, this message translates to:
  /// **'📸 Zgadnij zdjęcie'**
  String get qr_photoGuess;

  /// No description provided for @qr_capsule.
  ///
  /// In pl, this message translates to:
  /// **'⏳ Kapsuła czasu'**
  String get qr_capsule;

  /// No description provided for @qr_guestMap.
  ///
  /// In pl, this message translates to:
  /// **'🗺️ Mapa gości'**
  String get qr_guestMap;

  /// No description provided for @qr_photoChallenge.
  ///
  /// In pl, this message translates to:
  /// **'📷 Foto-wyzwania'**
  String get qr_photoChallenge;

  /// No description provided for @pay_venueTab.
  ///
  /// In pl, this message translates to:
  /// **'🏠 Sala'**
  String get pay_venueTab;

  /// No description provided for @pay_vendorsTab.
  ///
  /// In pl, this message translates to:
  /// **'🏢 Dostawcy'**
  String get pay_vendorsTab;

  /// No description provided for @hm_variantName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa wariantu'**
  String get hm_variantName;

  /// No description provided for @hm_offerLink.
  ///
  /// In pl, this message translates to:
  /// **'Link do oferty (https://…)'**
  String get hm_offerLink;

  /// No description provided for @common_linkHint.
  ///
  /// In pl, this message translates to:
  /// **'Link (https://…)'**
  String get common_linkHint;

  /// No description provided for @bingo_generatePdf.
  ///
  /// In pl, this message translates to:
  /// **'Generuj PDF ({count} plansz, {format})'**
  String bingo_generatePdf(int count, String format);

  /// Skrot slowa osob przy liczbach, np. 12 os.
  ///
  /// In pl, this message translates to:
  /// **'os.'**
  String get common_personsShort;

  /// No description provided for @notif_oneNew.
  ///
  /// In pl, this message translates to:
  /// **'1 nowe'**
  String get notif_oneNew;

  /// Domyślne pole koła fortuny; zapisuje się do bazy przy tworzeniu wesela w języku interfejsu.
  ///
  /// In pl, this message translates to:
  /// **'Kto wznosi toast'**
  String get wheelEx_toast;

  /// No description provided for @wheelEx_gamesTask.
  ///
  /// In pl, this message translates to:
  /// **'Zadanie na oczepiny'**
  String get wheelEx_gamesTask;

  /// No description provided for @wheelEx_veilKiss.
  ///
  /// In pl, this message translates to:
  /// **'Pocałunek przez welon'**
  String get wheelEx_veilKiss;

  /// No description provided for @wheelEx_blindDance.
  ///
  /// In pl, this message translates to:
  /// **'Wspólny taniec z zawiązanymi oczami'**
  String get wheelEx_blindDance;

  /// No description provided for @wheelEx_singSong.
  ///
  /// In pl, this message translates to:
  /// **'Odśpiewajcie ulubioną piosenkę'**
  String get wheelEx_singSong;

  /// No description provided for @wheelEx_feedCake.
  ///
  /// In pl, this message translates to:
  /// **'Nakarmcie się nawzajem tortem'**
  String get wheelEx_feedCake;

  /// No description provided for @wheelEx_longKiss.
  ///
  /// In pl, this message translates to:
  /// **'Pocałunek dłuższy niż 10 sekund'**
  String get wheelEx_longKiss;

  /// No description provided for @wheelEx_compliment.
  ///
  /// In pl, this message translates to:
  /// **'Powiedzcie sobie komplement'**
  String get wheelEx_compliment;

  /// No description provided for @wheelEx_bouquetToss.
  ///
  /// In pl, this message translates to:
  /// **'Rzut bukietem'**
  String get wheelEx_bouquetToss;

  /// No description provided for @wheelEx_tieToss.
  ///
  /// In pl, this message translates to:
  /// **'Rzut muszką / krawatem'**
  String get wheelEx_tieToss;

  /// No description provided for @wheelEx_chairDance.
  ///
  /// In pl, this message translates to:
  /// **'Taniec z krzesłami'**
  String get wheelEx_chairDance;

  /// No description provided for @wheelEx_bestDance.
  ///
  /// In pl, this message translates to:
  /// **'Konkurs na najlepszy taniec'**
  String get wheelEx_bestDance;

  /// No description provided for @wheelEx_charades.
  ///
  /// In pl, this message translates to:
  /// **'Kalambury weselne'**
  String get wheelEx_charades;

  /// No description provided for @wheelEx_nextCouple.
  ///
  /// In pl, this message translates to:
  /// **'Wybór następnej pary do ślubu'**
  String get wheelEx_nextCouple;

  /// No description provided for @quizEx_film3.
  ///
  /// In pl, this message translates to:
  /// **'Forrest Gump'**
  String get quizEx_film3;

  /// Tytuł filmu w przykładowej odpowiedzi — użyj tytułu z danego rynku.
  ///
  /// In pl, this message translates to:
  /// **'Skazani na Shawshank'**
  String get quizEx_film4;

  /// Wstęp na karcie do wydruku dołączanej do zaproszenia — ton uprzejmy, zwrot do gościa.
  ///
  /// In pl, this message translates to:
  /// **'Cieszymy się, że będziesz z nami! Poniżej znajdziesz wszystko, czego potrzebujesz, aby dołączyć do naszego wesela w aplikacji.'**
  String get invite_pdfLead;

  /// No description provided for @invite_pdfScanHint.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj w aplikacji: „Dołącz do wesela\" → „Skanuj\"'**
  String get invite_pdfScanHint;

  /// No description provided for @invite_pdfStep1.
  ///
  /// In pl, this message translates to:
  /// **'Zainstaluj aplikację Moje Wesele i zaloguj się kontem Google.'**
  String get invite_pdfStep1;

  /// No description provided for @invite_pdfStep2.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz „Dołącz do wesela\" i zeskanuj kod QR albo przepisz kod ręcznie.'**
  String get invite_pdfStep2;

  /// No description provided for @invite_pdfStep3.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełnij datę ślubu i nazwisko z tej karty — gotowe.'**
  String get invite_pdfStep3;

  /// No description provided for @invite_printButton.
  ///
  /// In pl, this message translates to:
  /// **'Wydruk dla gości (PDF)'**
  String get invite_printButton;

  /// No description provided for @invite_printHint.
  ///
  /// In pl, this message translates to:
  /// **'Elegancka karta z kodem QR i danymi do dołączenia — do wydrukowania i włożenia do zaproszenia.'**
  String get invite_printHint;

  /// No description provided for @invite_printFormat.
  ///
  /// In pl, this message translates to:
  /// **'Format wydruku'**
  String get invite_printFormat;

  /// Nazwa pliku PDF — bez polskich znaków i spacji.
  ///
  /// In pl, this message translates to:
  /// **'zaproszenie-kod-wesela.pdf'**
  String get invite_printFileName;

  /// No description provided for @invite_printError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się przygotować wydruku: {error}'**
  String invite_printError(String error);

  /// No description provided for @invite_codeGroupHint.
  ///
  /// In pl, this message translates to:
  /// **'Kod pokazujemy w grupach po cztery znaki — myślniki są tylko dla czytelności, gość nie musi ich wpisywać.'**
  String get invite_codeGroupHint;

  /// No description provided for @settings_invitesCard.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenia dla gości'**
  String get settings_invitesCard;

  /// No description provided for @settings_invitesHint.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz, czy goście dostają jeden wspólny link, czy każde zaproszenie ma własny kod QR. Kod per zaproszenie pozwala rozpoznać, kto co dodał.'**
  String get settings_invitesHint;

  /// No description provided for @settings_invitesOpen.
  ///
  /// In pl, this message translates to:
  /// **'Ustaw zaproszenia'**
  String get settings_invitesOpen;

  /// No description provided for @inv_title.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenia dla gości'**
  String get inv_title;

  /// No description provided for @inv_modeHeader.
  ///
  /// In pl, this message translates to:
  /// **'TRYB ZAPRASZANIA'**
  String get inv_modeHeader;

  /// No description provided for @inv_modeShared.
  ///
  /// In pl, this message translates to:
  /// **'Wspólny link dla wszystkich'**
  String get inv_modeShared;

  /// No description provided for @inv_modeSharedHint.
  ///
  /// In pl, this message translates to:
  /// **'Jeden link i kod QR dla całego wesela. Goście są anonimowi — widzisz, co dodali, ale nie kto to był.'**
  String get inv_modeSharedHint;

  /// No description provided for @inv_modeIndividual.
  ///
  /// In pl, this message translates to:
  /// **'Kod dla każdego zaproszenia'**
  String get inv_modeIndividual;

  /// No description provided for @inv_modeIndividualHint.
  ///
  /// In pl, this message translates to:
  /// **'Dodatkowo każda paczka zaproszeniowa dostaje własny kod QR. Gość wybiera z listy, kim jest, więc widzisz, kto co dodał.'**
  String get inv_modeIndividualHint;

  /// No description provided for @inv_sharedStaysTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wspólny link działa dalej'**
  String get inv_sharedStaysTitle;

  /// Kluczowe: tryb indywidualny DOKŁADA kody, nie zastępuje wspólnego linku.
  ///
  /// In pl, this message translates to:
  /// **'Kod indywidualny NIE zastępuje wspólnego — dokłada się do niego. Wspólny link zostaje na stołach i dla gości, którzy zgubili zaproszenie.'**
  String get inv_sharedStaysBody;

  /// No description provided for @inv_notProofTitle.
  ///
  /// In pl, this message translates to:
  /// **'To rozpoznanie, nie weryfikacja tożsamości'**
  String get inv_notProofTitle;

  /// Ostrzeżenie dla organizatora — ma studzić zaufanie do kodu. Zachowaj stanowczy ton.
  ///
  /// In pl, this message translates to:
  /// **'Kod jest wydrukowany na zaproszeniu, więc każdy, kto go zobaczy, może wybrać dowolną osobę z tej paczki. Traktuj wynik jako „prawdopodobnie Anna\", a nie dowód. Do niczego wiążącego się nie nadaje.'**
  String get inv_notProofBody;

  /// No description provided for @inv_saved.
  ///
  /// In pl, this message translates to:
  /// **'Zapisano tryb zaproszeń'**
  String get inv_saved;

  /// No description provided for @inv_packagesHeader.
  ///
  /// In pl, this message translates to:
  /// **'PACZKI ZAPROSZENIOWE'**
  String get inv_packagesHeader;

  /// No description provided for @inv_statPackages.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszeń'**
  String get inv_statPackages;

  /// No description provided for @inv_statPeople.
  ///
  /// In pl, this message translates to:
  /// **'Osób'**
  String get inv_statPeople;

  /// No description provided for @inv_statMulti.
  ///
  /// In pl, this message translates to:
  /// **'Wieloosobowych'**
  String get inv_statMulti;

  /// No description provided for @inv_statPending.
  ///
  /// In pl, this message translates to:
  /// **'Bez imienia'**
  String get inv_statPending;

  /// No description provided for @inv_previewHint.
  ///
  /// In pl, this message translates to:
  /// **'Tak podzielą się zaproszenia. Paczkę tworzy gość wraz ze swoimi osobami towarzyszącymi — zmienisz ją, zmieniając powiązania na liście gości.'**
  String get inv_previewHint;

  /// No description provided for @inv_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak gości. Dodaj pierwszych gości, a zaproszenia ułożą się same.'**
  String get inv_empty;

  /// No description provided for @inv_packageSize.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 osoba} few{{count} osoby} other{{count} osób}}'**
  String inv_packageSize(int count);

  /// No description provided for @inv_pendingBadge.
  ///
  /// In pl, this message translates to:
  /// **'imię do uzupełnienia'**
  String get inv_pendingBadge;

  /// No description provided for @inv_mainBadge.
  ///
  /// In pl, this message translates to:
  /// **'adresat'**
  String get inv_mainBadge;

  /// No description provided for @inv_noName.
  ///
  /// In pl, this message translates to:
  /// **'(imię nieuzupełnione)'**
  String get inv_noName;

  /// No description provided for @inv_codesLater.
  ///
  /// In pl, this message translates to:
  /// **'Wydruk kodów dołożymy w kolejnym kroku — na razie sprawdź, czy podział na zaproszenia i kody się zgadzają.'**
  String get inv_codesLater;

  /// No description provided for @inv_codesHeader.
  ///
  /// In pl, this message translates to:
  /// **'KODY ZAPROSZEŃ'**
  String get inv_codesHeader;

  /// No description provided for @inv_generate.
  ///
  /// In pl, this message translates to:
  /// **'Wygeneruj brakujące kody'**
  String get inv_generate;

  /// No description provided for @inv_generating.
  ///
  /// In pl, this message translates to:
  /// **'Generuję kody… {done} z {total}'**
  String inv_generating(int done, int total);

  /// No description provided for @inv_generated.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =0{Wszystkie paczki mają już kod} =1{Wygenerowano 1 kod} few{Wygenerowano {count} kody} other{Wygenerowano {count} kodów}}'**
  String inv_generated(int count);

  /// No description provided for @inv_noCode.
  ///
  /// In pl, this message translates to:
  /// **'brak kodu'**
  String get inv_noCode;

  /// No description provided for @inv_codeRevoked.
  ///
  /// In pl, this message translates to:
  /// **'unieważniony'**
  String get inv_codeRevoked;

  /// No description provided for @inv_codeStale.
  ///
  /// In pl, this message translates to:
  /// **'skład się zmienił'**
  String get inv_codeStale;

  /// No description provided for @inv_copyCode.
  ///
  /// In pl, this message translates to:
  /// **'Kopiuj kod'**
  String get inv_copyCode;

  /// No description provided for @inv_regenerate.
  ///
  /// In pl, this message translates to:
  /// **'Nowy kod'**
  String get inv_regenerate;

  /// No description provided for @inv_revoke.
  ///
  /// In pl, this message translates to:
  /// **'Unieważnij'**
  String get inv_revoke;

  /// No description provided for @inv_restore.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć'**
  String get inv_restore;

  /// No description provided for @inv_codeCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano kod: {code}'**
  String inv_codeCopied(String code);

  /// No description provided for @inv_regenerateTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wystawić nowy kod?'**
  String get inv_regenerateTitle;

  /// Ostrzeżenie przed wystawieniem nowego kodu — stary QR na wydrukowanym zaproszeniu przestaje działać.
  ///
  /// In pl, this message translates to:
  /// **'Dotychczasowy kod tej paczki przestanie działać. Jeśli zaproszenie jest już wydrukowane, kod QR na nim stanie się bezużyteczny — trzeba będzie przekazać nowy.'**
  String get inv_regenerateBody;

  /// No description provided for @inv_regenerated.
  ///
  /// In pl, this message translates to:
  /// **'Wystawiono nowy kod'**
  String get inv_regenerated;

  /// No description provided for @inv_revokeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Unieważnić kod?'**
  String get inv_revokeTitle;

  /// No description provided for @inv_revokeBody.
  ///
  /// In pl, this message translates to:
  /// **'Gość skanujący to zaproszenie zobaczy komunikat, że kod jest nieaktualny. Możesz go później przywrócić.'**
  String get inv_revokeBody;

  /// No description provided for @inv_revoked.
  ///
  /// In pl, this message translates to:
  /// **'Kod unieważniony'**
  String get inv_revoked;

  /// No description provided for @inv_restored.
  ///
  /// In pl, this message translates to:
  /// **'Kod przywrócony'**
  String get inv_restored;

  /// Znacznik: opublikowany skład paczki rozjechał się z listą gości.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{Kod nieaktualny dla 1 paczki} few{Kody nieaktualne dla {count} paczek} other{Kody nieaktualne dla {count} paczek}}'**
  String inv_staleTitle(int count);

  /// No description provided for @inv_staleBody.
  ///
  /// In pl, this message translates to:
  /// **'Skład tych zaproszeń zmienił się po wygenerowaniu kodu. Odświeżamy go automatycznie, więc gość zobaczy aktualne imiona — ale jeśli zaproszenie jest już wydrukowane, skład na papierze się nie zgadza.'**
  String get inv_staleBody;

  /// No description provided for @inv_synced.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{Odświeżono skład 1 paczki} few{Odświeżono skład {count} paczek} other{Odświeżono skład {count} paczek}}'**
  String inv_synced(int count);

  /// No description provided for @inv_syncFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się odświeżyć {count} paczek. Sprawdź połączenie i uprawnienia.'**
  String inv_syncFailed(int count);

  /// No description provided for @inv_rulesNeededTitle.
  ///
  /// In pl, this message translates to:
  /// **'Kody wymagają wdrożenia reguł'**
  String get inv_rulesNeededTitle;

  /// No description provided for @inv_rulesNeededBody.
  ///
  /// In pl, this message translates to:
  /// **'Zapis kodów zaproszeń działa dopiero po wdrożeniu reguły „inviteCodes\". Do tego czasu generowanie zakończy się błędem uprawnień.'**
  String get inv_rulesNeededBody;

  /// No description provided for @inv_error.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się: {error}'**
  String inv_error(String error);

  /// No description provided for @id_title.
  ///
  /// In pl, this message translates to:
  /// **'Kim jesteś?'**
  String get id_title;

  /// No description provided for @id_lead.
  ///
  /// In pl, this message translates to:
  /// **'Rozpoznaliśmy Twoje zaproszenie. Wybierz siebie z listy — dzięki temu Para Młoda będzie wiedziała, od kogo są Twoje wpisy.'**
  String get id_lead;

  /// No description provided for @id_leadSingle.
  ///
  /// In pl, this message translates to:
  /// **'Rozpoznaliśmy Twoje zaproszenie. Potwierdź, że to Ty.'**
  String get id_leadSingle;

  /// No description provided for @id_companion.
  ///
  /// In pl, this message translates to:
  /// **'Jestem osobą towarzyszącą'**
  String get id_companion;

  /// No description provided for @id_companionHint.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenie obejmuje osobę, której imienia jeszcze nie ma'**
  String get id_companionHint;

  /// No description provided for @id_notMine.
  ///
  /// In pl, this message translates to:
  /// **'To nie moje zaproszenie'**
  String get id_notMine;

  /// Wejście bez przypisania — trafia do sekcji „do przypisania" (etap 5).
  ///
  /// In pl, this message translates to:
  /// **'Wejdź jako gość bez przypisania — Para Młoda to uzupełni'**
  String get id_notMineHint;

  /// No description provided for @id_yourName.
  ///
  /// In pl, this message translates to:
  /// **'Twoje imię'**
  String get id_yourName;

  /// No description provided for @id_yourNameHint.
  ///
  /// In pl, this message translates to:
  /// **'Jak mamy Cię podpisywać?'**
  String get id_yourNameHint;

  /// No description provided for @id_lastNameOptional.
  ///
  /// In pl, this message translates to:
  /// **'Nazwisko lub pseudonim (opcjonalnie)'**
  String get id_lastNameOptional;

  /// No description provided for @id_needName.
  ///
  /// In pl, this message translates to:
  /// **'Podaj imię, żebyśmy wiedzieli, kto to.'**
  String get id_needName;

  /// No description provided for @id_enter.
  ///
  /// In pl, this message translates to:
  /// **'Wejdź do strefy gości'**
  String get id_enter;

  /// Uczciwe postawienie sprawy dla gościa: organizator zna tożsamość, inni goście widzą tylko podpis przy wpisie.
  ///
  /// In pl, this message translates to:
  /// **'Twoje imię widzi Para Młoda. Inni goście zobaczą tylko to, czym sam się podpiszesz przy wpisach.'**
  String get id_privacy;

  /// No description provided for @id_notMeMenu.
  ///
  /// In pl, this message translates to:
  /// **'To nie ja — zmień osobę'**
  String get id_notMeMenu;

  /// No description provided for @id_invalidTitle.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowe zaproszenie'**
  String get id_invalidTitle;

  /// No description provided for @id_invalidBody.
  ///
  /// In pl, this message translates to:
  /// **'Ten kod nie należy do żadnego wesela. Sprawdź, czy link jest kompletny, albo poproś Parę Młodą o nowy.'**
  String get id_invalidBody;

  /// No description provided for @id_revokedTitle.
  ///
  /// In pl, this message translates to:
  /// **'To zaproszenie jest już nieaktualne'**
  String get id_revokedTitle;

  /// No description provided for @id_revokedBody.
  ///
  /// In pl, this message translates to:
  /// **'Para Młoda unieważniła ten kod. Poproś ją o nowe zaproszenie — albo skorzystaj ze wspólnego linku do strony gości, jeśli go masz.'**
  String get id_revokedBody;

  /// No description provided for @id_notReadyTitle.
  ///
  /// In pl, this message translates to:
  /// **'Strona gości nie jest jeszcze gotowa'**
  String get id_notReadyTitle;

  /// No description provided for @id_notReadyBody.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenie jest prawidłowe, ale Para Młoda nie przygotowała jeszcze strony dla gości. Zajrzyj później.'**
  String get id_notReadyBody;

  /// No description provided for @id_claimFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zapisać wyboru — wchodzisz dalej, ale Para Młoda może nie powiązać Twoich wpisów z zaproszeniem.'**
  String get id_claimFailed;

  /// No description provided for @emailAuth_titleSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get emailAuth_titleSignIn;

  /// No description provided for @emailAuth_titleRegister.
  ///
  /// In pl, this message translates to:
  /// **'Załóż konto'**
  String get emailAuth_titleRegister;

  /// No description provided for @emailAuth_titleReset.
  ///
  /// In pl, this message translates to:
  /// **'Resetuj hasło'**
  String get emailAuth_titleReset;

  /// No description provided for @emailAuth_emailLabel.
  ///
  /// In pl, this message translates to:
  /// **'Adres e-mail'**
  String get emailAuth_emailLabel;

  /// No description provided for @emailAuth_emailHint.
  ///
  /// In pl, this message translates to:
  /// **'np. jan@przyklad.pl'**
  String get emailAuth_emailHint;

  /// No description provided for @emailAuth_passwordLabel.
  ///
  /// In pl, this message translates to:
  /// **'Hasło'**
  String get emailAuth_passwordLabel;

  /// No description provided for @emailAuth_confirmPasswordLabel.
  ///
  /// In pl, this message translates to:
  /// **'Powtórz hasło'**
  String get emailAuth_confirmPasswordLabel;

  /// No description provided for @emailAuth_submitSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get emailAuth_submitSignIn;

  /// No description provided for @emailAuth_submitRegister.
  ///
  /// In pl, this message translates to:
  /// **'Załóż konto'**
  String get emailAuth_submitRegister;

  /// No description provided for @emailAuth_submitReset.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij link resetujący'**
  String get emailAuth_submitReset;

  /// No description provided for @emailAuth_switchToRegister.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz konta? Załóż je'**
  String get emailAuth_switchToRegister;

  /// No description provided for @emailAuth_switchToSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Masz już konto? Zaloguj się'**
  String get emailAuth_switchToSignIn;

  /// No description provided for @emailAuth_forgotPassword.
  ///
  /// In pl, this message translates to:
  /// **'Zapomniałeś hasła?'**
  String get emailAuth_forgotPassword;

  /// No description provided for @emailAuth_backToSignIn.
  ///
  /// In pl, this message translates to:
  /// **'Wróć do logowania'**
  String get emailAuth_backToSignIn;

  /// No description provided for @emailAuth_resetIntro.
  ///
  /// In pl, this message translates to:
  /// **'Podaj adres e-mail, na który wyślemy link do zresetowania hasła.'**
  String get emailAuth_resetIntro;

  /// No description provided for @emailAuth_resetSentMessage.
  ///
  /// In pl, this message translates to:
  /// **'Wysłaliśmy link resetujący hasło na podany adres e-mail.'**
  String get emailAuth_resetSentMessage;

  /// No description provided for @emailAuth_verificationNote.
  ///
  /// In pl, this message translates to:
  /// **'Po założeniu konta wyślemy e-mail weryfikacyjny na podany adres.'**
  String get emailAuth_verificationNote;

  /// No description provided for @emailAuth_errorEmailRequired.
  ///
  /// In pl, this message translates to:
  /// **'Podaj adres e-mail.'**
  String get emailAuth_errorEmailRequired;

  /// No description provided for @emailAuth_errorEmailInvalid.
  ///
  /// In pl, this message translates to:
  /// **'Podaj poprawny adres e-mail.'**
  String get emailAuth_errorEmailInvalid;

  /// No description provided for @emailAuth_errorPasswordRequired.
  ///
  /// In pl, this message translates to:
  /// **'Podaj hasło.'**
  String get emailAuth_errorPasswordRequired;

  /// No description provided for @emailAuth_errorPasswordTooShort.
  ///
  /// In pl, this message translates to:
  /// **'Hasło musi mieć co najmniej 6 znaków.'**
  String get emailAuth_errorPasswordTooShort;

  /// No description provided for @emailAuth_errorPasswordMismatch.
  ///
  /// In pl, this message translates to:
  /// **'Hasła nie są takie same.'**
  String get emailAuth_errorPasswordMismatch;

  /// No description provided for @emailAuth_showPassword.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż hasło'**
  String get emailAuth_showPassword;

  /// No description provided for @emailAuth_hidePassword.
  ///
  /// In pl, this message translates to:
  /// **'Ukryj hasło'**
  String get emailAuth_hidePassword;

  /// No description provided for @emailAuth_backButton.
  ///
  /// In pl, this message translates to:
  /// **'Wstecz'**
  String get emailAuth_backButton;

  /// No description provided for @unassigned_title.
  ///
  /// In pl, this message translates to:
  /// **'Do przypisania'**
  String get unassigned_title;

  /// No description provided for @unassigned_hint.
  ///
  /// In pl, this message translates to:
  /// **'Poniżej goście, którzy weszli kodem paczki, ale nie udało się ich jednoznacznie dopasować do listy gości. Przypisz do istniejącej osoby, utwórz nową, albo odrzuć zgłoszenie.'**
  String get unassigned_hint;

  /// No description provided for @unassigned_empty.
  ///
  /// In pl, this message translates to:
  /// **'Brak zgłoszeń czekających na przypisanie. Tu trafiają goście, którzy kliknęli „to nie moje zaproszenie” albo wpisali imię, którego nie było na liście oczekujących.'**
  String get unassigned_empty;

  /// No description provided for @unassigned_badge.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 tożsamość do przypisania} few{{count} tożsamości do przypisania} other{{count} tożsamości do przypisania}}'**
  String unassigned_badge(int count);

  /// No description provided for @unassigned_fromCode.
  ///
  /// In pl, this message translates to:
  /// **'Z zaproszenia: {code}'**
  String unassigned_fromCode(String code);

  /// No description provided for @unassigned_sourcePicked.
  ///
  /// In pl, this message translates to:
  /// **'wybrał(a) z listy'**
  String get unassigned_sourcePicked;

  /// No description provided for @unassigned_sourceTyped.
  ///
  /// In pl, this message translates to:
  /// **'wpisał(a) inne imię'**
  String get unassigned_sourceTyped;

  /// No description provided for @unassigned_hasRsvpYes.
  ///
  /// In pl, this message translates to:
  /// **'✓ Potwierdził(a) obecność'**
  String get unassigned_hasRsvpYes;

  /// No description provided for @unassigned_hasRsvpNo.
  ///
  /// In pl, this message translates to:
  /// **'✗ Odwołał(a) obecność'**
  String get unassigned_hasRsvpNo;

  /// No description provided for @unassigned_hasMapEntry.
  ///
  /// In pl, this message translates to:
  /// **'📍 Wpisał(a) się na mapę gości'**
  String get unassigned_hasMapEntry;

  /// No description provided for @unassigned_assignTo.
  ///
  /// In pl, this message translates to:
  /// **'To {name}'**
  String unassigned_assignTo(String name);

  /// No description provided for @unassigned_createGuest.
  ///
  /// In pl, this message translates to:
  /// **'Nowy gość'**
  String get unassigned_createGuest;

  /// No description provided for @unassigned_reject.
  ///
  /// In pl, this message translates to:
  /// **'Odrzuć'**
  String get unassigned_reject;

  /// No description provided for @unassigned_rejectTitle.
  ///
  /// In pl, this message translates to:
  /// **'Odrzucić zgłoszenie?'**
  String get unassigned_rejectTitle;

  /// No description provided for @unassigned_rejectBody.
  ///
  /// In pl, this message translates to:
  /// **'Wpis zniknie z listy „Do przypisania”. Jeśli ta sama przeglądarka wejdzie ponownie tym samym kodem, może pojawić się jeszcze raz.'**
  String get unassigned_rejectBody;

  /// No description provided for @unassigned_assigned.
  ///
  /// In pl, this message translates to:
  /// **'Przypisano do gościa.'**
  String get unassigned_assigned;

  /// No description provided for @unassigned_created.
  ///
  /// In pl, this message translates to:
  /// **'Utworzono nowego gościa i przypisano.'**
  String get unassigned_created;

  /// No description provided for @unassigned_rejected.
  ///
  /// In pl, this message translates to:
  /// **'Odrzucono.'**
  String get unassigned_rejected;

  /// No description provided for @unassigned_error.
  ///
  /// In pl, this message translates to:
  /// **'Błąd: {error}'**
  String unassigned_error(String error);

  /// No description provided for @unassigned_inviterMissing.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono gościa głównego tej paczki.'**
  String get unassigned_inviterMissing;

  /// No description provided for @common_and.
  ///
  /// In pl, this message translates to:
  /// **'i'**
  String get common_and;

  /// No description provided for @notif_companionGroup.
  ///
  /// In pl, this message translates to:
  /// **'Osoba towarzysząca'**
  String get notif_companionGroup;

  /// No description provided for @notif_companionReminderGeneric.
  ///
  /// In pl, this message translates to:
  /// **'Jesteś zaproszony/a z osobą towarzyszącą. Pamiętaj o tym przy potwierdzaniu obecności.'**
  String get notif_companionReminderGeneric;

  /// No description provided for @notif_companionReminder.
  ///
  /// In pl, this message translates to:
  /// **'Jesteś zaproszony/a z osobą towarzyszącą ({names}). Pamiętaj o tym przy potwierdzaniu obecności.'**
  String notif_companionReminder(String names);

  /// No description provided for @vis_showAuthorNames.
  ///
  /// In pl, this message translates to:
  /// **'Pokazuj imiona autorów'**
  String get vis_showAuthorNames;

  /// No description provided for @inv_printHeader.
  ///
  /// In pl, this message translates to:
  /// **'WYDRUK ZAPROSZEŃ'**
  String get inv_printHeader;

  /// No description provided for @inv_printRangeLabel.
  ///
  /// In pl, this message translates to:
  /// **'Zakres'**
  String get inv_printRangeLabel;

  /// No description provided for @inv_printRangeAll.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie'**
  String get inv_printRangeAll;

  /// No description provided for @inv_printRangeSelected.
  ///
  /// In pl, this message translates to:
  /// **'Zaznaczone ({count})'**
  String inv_printRangeSelected(int count);

  /// No description provided for @inv_printRangeMissing.
  ///
  /// In pl, this message translates to:
  /// **'Bez kodu ({count})'**
  String inv_printRangeMissing(int count);

  /// No description provided for @inv_printFormatLabel.
  ///
  /// In pl, this message translates to:
  /// **'Format'**
  String get inv_printFormatLabel;

  /// No description provided for @inv_printPerPageLabel.
  ///
  /// In pl, this message translates to:
  /// **'Kart na arkuszu'**
  String get inv_printPerPageLabel;

  /// No description provided for @inv_printPerPageOne.
  ///
  /// In pl, this message translates to:
  /// **'cała strona'**
  String get inv_printPerPageOne;

  /// No description provided for @inv_printPerPageTwo.
  ///
  /// In pl, this message translates to:
  /// **'2 na arkuszu'**
  String get inv_printPerPageTwo;

  /// No description provided for @inv_printPerPageFour.
  ///
  /// In pl, this message translates to:
  /// **'4 na arkuszu'**
  String get inv_printPerPageFour;

  /// No description provided for @inv_printGenerate.
  ///
  /// In pl, this message translates to:
  /// **'Generuj PDF'**
  String get inv_printGenerate;

  /// No description provided for @inv_printNothingSelected.
  ///
  /// In pl, this message translates to:
  /// **'Nie wybrano żadnej paczki do wydruku.'**
  String get inv_printNothingSelected;

  /// No description provided for @inv_printNoCodes.
  ///
  /// In pl, this message translates to:
  /// **'Żadna z wybranych paczek nie ma jeszcze kodu — najpierw go wygeneruj.'**
  String get inv_printNoCodes;

  /// No description provided for @inv_printSkipped.
  ///
  /// In pl, this message translates to:
  /// **'Pominięto {count} paczek bez kodu — wygeneruj im kody i wydrukuj ponownie.'**
  String inv_printSkipped(int count);

  /// No description provided for @inv_printFileName.
  ///
  /// In pl, this message translates to:
  /// **'zaproszenia-indywidualne'**
  String get inv_printFileName;

  /// No description provided for @pdf_individualFor.
  ///
  /// In pl, this message translates to:
  /// **'Zaproszenie dla: {names}'**
  String pdf_individualFor(String names);

  /// No description provided for @pdf_individualScanHint.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj kod QR telefonem, żeby wejść do swojej strefy gościa'**
  String get pdf_individualScanHint;
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
