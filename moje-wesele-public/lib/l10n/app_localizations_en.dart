// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_add => 'Add';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_close => 'Close';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_done => 'Done';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_search => 'Search';

  @override
  String get common_none => '—';

  @override
  String get common_savedToast => 'Changes saved';

  @override
  String common_saveErrorToast(String error) {
    return 'Save failed: $error';
  }

  @override
  String get common_deleteConfirmTitle => 'Delete this?';

  @override
  String common_guestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
      zero: 'No guests',
    );
    return '$_temp0';
  }

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_configCard => 'Configuration';

  @override
  String get settings_languageCard => 'Language and region';

  @override
  String get settings_language => 'App language';

  @override
  String get settings_languageHint =>
      'Takes effect immediately, no restart needed.';

  @override
  String get settings_languageSystem => 'Match system';

  @override
  String get settings_currency => 'Currency';

  @override
  String get settings_currencyHint =>
      'Changes only the symbol shown next to amounts. It does not convert rates — the amounts you entered stay the same.';

  @override
  String get settings_notificationsCard => 'Notifications';

  @override
  String get settings_helpButton => 'Help';

  @override
  String get settings_tourButton => 'Start the tour';

  @override
  String get settings_planningButton => 'Where do I start?';

  @override
  String get settings_setupWizardButton => 'Walk me through it';

  @override
  String get settings_logoutButton => 'Sign out';

  @override
  String get language_pl => 'Polish';

  @override
  String get language_en => 'English';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_retry => 'Try again';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_copy => 'Copy';

  @override
  String get common_share => 'Share';

  @override
  String get common_open => 'Open';

  @override
  String get common_select => 'Select';

  @override
  String get common_all => 'All';

  @override
  String get common_optional => 'optional';

  @override
  String get common_deleteConfirmBody => 'This cannot be undone.';

  @override
  String get common_deletedToast => 'Deleted';

  @override
  String common_deleteErrorToast(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get common_copiedToast => 'Copied';

  @override
  String get common_offlineToast =>
      'You\'re offline — changes will sync once you\'re back.';

  @override
  String get validation_required => 'This field is required';

  @override
  String get validation_invalidNumber => 'Enter a valid number';

  @override
  String get validation_invalidEmail => 'Enter a valid email address';

  @override
  String validation_tooShort(int min) {
    return 'Too short — at least $min characters';
  }

  @override
  String get date_notSet => 'Date to be confirmed';

  @override
  String get date_pickDate => 'Pick a date';

  @override
  String get date_pickTime => 'Pick a time';

  @override
  String get date_today => 'Today';

  @override
  String get date_tomorrow => 'Tomorrow';

  @override
  String get guests_categoryWitnesses => 'Witnesses';

  @override
  String get guests_categoryParents => 'Parents';

  @override
  String get guests_categoryFamily => 'Family';

  @override
  String get guests_categoryFriends => 'Friends';

  @override
  String get guests_categoryWork => 'Work';

  @override
  String get guests_categoryOther => 'Other';

  @override
  String get guests_genderFemale => '♀ Female';

  @override
  String get guests_genderMale => '♂ Male';

  @override
  String get guests_genderNonbinary => '⚧ Non-binary';

  @override
  String get guests_dietStandard => 'Standard';

  @override
  String get guests_dietVegetarian => 'Vegetarian';

  @override
  String get guests_dietVegan => 'Vegan';

  @override
  String get guests_dietGlutenFree => 'Gluten-free';

  @override
  String get guests_dietOther => 'Other';

  @override
  String get guests_menuMeat => 'Meat dish';

  @override
  String get guests_menuFish => 'Fish dish';

  @override
  String get guests_menuVegetarian => 'Vegetarian';

  @override
  String get guests_menuVegan => 'Vegan';

  @override
  String get guests_menuChild => 'Children\'s meal';

  @override
  String get guests_filterAssigned => 'Seated';

  @override
  String get guests_filterUnassigned => 'Not seated';

  @override
  String get guests_filterWitnesses => '🤝 Witnesses';

  @override
  String get guests_filterChildren => '🧒 Children';

  @override
  String get guests_title => 'Guests';

  @override
  String get guests_addButton => 'Add guest';

  @override
  String guests_addedToast(String name) {
    return 'Guest added: $name';
  }

  @override
  String get guests_deleteTitle => 'Delete guest?';

  @override
  String guests_deleteBody(String name) {
    return 'Delete „$name”? Their seat at the table will be freed up as well.';
  }

  @override
  String get guests_deletedToast => 'Guest deleted';

  @override
  String get guests_noName => '(no name)';

  @override
  String guests_countOf(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String get guests_badgeNoTable => 'No table';

  @override
  String get guests_badgeChild => '🧒 Child';

  @override
  String get guests_badgeAccommodation => '🏨 Stay';

  @override
  String guests_badgeCompanionOf(String name) {
    return '👥 with: $name';
  }

  @override
  String get guests_companionPlaceholder => 'companion';

  @override
  String get guests_formEditTitle => 'Edit guest';

  @override
  String get guests_formAddTitle => 'Add guest';

  @override
  String get guests_formFirstName => 'First name *';

  @override
  String get guests_formFirstNameHint => 'e.g. Anna';

  @override
  String get guests_formFirstNameRequired => 'Enter the guest\'s first name';

  @override
  String get guests_formLastName => 'Last name';

  @override
  String get guests_formLastNameHint => 'e.g. Smith';

  @override
  String get guests_formInvitedBy => 'Invited by';

  @override
  String get guests_formChoose => '— choose —';

  @override
  String get guests_formCategory => 'Category';

  @override
  String get guests_formGender => 'Gender';

  @override
  String get guests_formRole => 'Role';

  @override
  String get guests_formNoRole => 'No role';

  @override
  String get guests_formDiet => 'Diet / meal';

  @override
  String get guests_formNoMenu => '— none —';

  @override
  String get guests_formIsChild => '🧒 This is a child';

  @override
  String get guests_formIsChildHint =>
      'Children are excluded from alcohol estimates and can have a separate meal.';

  @override
  String get guests_formAccommodation => '🏨 Needs accommodation';

  @override
  String guests_formCoupleLimit(int max) {
    return 'The couple is at most $max people — the list is already complete.';
  }

  @override
  String get guests_companionSwitch => '👥 Bringing a companion?';

  @override
  String guests_companionForCouple(String category) {
    return 'The couple doesn\'t have a companion — add the other person as a separate entry in the „$category” category.';
  }

  @override
  String get guests_companionRelation => 'Relationship';

  @override
  String get guests_companionNameUnknown => 'I don\'t know the name yet';

  @override
  String get guests_companionNameUnknownHint =>
      'We\'ll save „Companion” — you can fill in the details later. The person still counts towards the guest list and catering.';

  @override
  String get guests_companionFirstName => 'Companion\'s first name';

  @override
  String get guests_companionLastName => 'Companion\'s last name';

  @override
  String get guests_companionCategory => 'Companion\'s category';

  @override
  String guests_companionInherit(String category) {
    return 'Same as inviter ($category)';
  }

  @override
  String get guests_companionIsChild => '🧒 The companion is a child';

  @override
  String get guests_companionInfo =>
      'The companion will be added as a separate guest linked to this person — so you know who comes with whom.';

  @override
  String get guests_relationPartner => 'Partner';

  @override
  String get guests_relationFamily => 'Family';

  @override
  String get guests_relationUnknown => 'Unknown';

  @override
  String guests_summaryWitnesses(int target) {
    return '🤝 Witnesses (target: $target)';
  }

  @override
  String get guests_summaryWitnessesTotal => 'Assigned in total';

  @override
  String get guests_summaryChildren => '🧒 Children';

  @override
  String get guests_summaryChildrenLabel => 'Children';

  @override
  String get guests_summaryAdults => 'Adults';

  @override
  String get guests_summaryMenu => '🍽 Meals';

  @override
  String get guests_summaryNoMenu => 'No meal chosen';

  @override
  String get guests_summaryDiets => '🥗 Diets';

  @override
  String get guests_summaryTransport => '🚌 Transport';

  @override
  String get guests_summaryTransportOwn => 'Own';

  @override
  String get guests_summaryTransportOrganized => 'Organised';

  @override
  String get guests_summaryTransportNone => 'No transport';

  @override
  String get guests_summaryAccommodation => '🏨 Accommodation';

  @override
  String get guests_summaryAccommodationNeeds => 'Needs a room';

  @override
  String get guests_summaryAccommodationAssigned => 'Assigned to a hotel';

  @override
  String get guests_summaryRsvp => '✉ RSVP';

  @override
  String get guests_rsvpAttending => 'Attending';

  @override
  String get guests_rsvpNotAttending => 'Not attending';

  @override
  String get guests_rsvpNoAnswer => 'No reply';

  @override
  String get guests_cardFullName => 'Full name';

  @override
  String get guests_cardStatus => 'Status';

  @override
  String get guests_cardWith => 'With';

  @override
  String get guests_cardMenu => 'Meal';

  @override
  String get guests_cardDietAllergies => 'Diet / allergies';

  @override
  String get guests_cardTable => 'Table';

  @override
  String get guests_emptyFiltered => 'No guests match these filters.';

  @override
  String get guests_showFilters => 'Show filters';

  @override
  String get guests_hideFilters => 'Hide filters';

  @override
  String get guests_detailInvitedBy => 'Invited by';

  @override
  String get guests_allSeated => 'All guests are already seated.';

  @override
  String get tables_defaultName => 'Table';

  @override
  String get tables_title => 'Table plan';

  @override
  String get tables_addButton => 'Add table';

  @override
  String get tables_addedToast => 'Table added';

  @override
  String get tables_addTitle => 'New table';

  @override
  String get tables_name => 'Table name';

  @override
  String get tables_nameHint => 'e.g. Table 1';

  @override
  String get tables_shape => 'Shape';

  @override
  String get tables_shapeRound => 'Round';

  @override
  String get tables_shapeRect => 'Rectangular';

  @override
  String get tables_seats => 'Number of seats';

  @override
  String get tables_honorSwitch => '⭐ Couple\'s table (head table)';

  @override
  String get tables_honorHint => 'Uses a rectangular layout';

  @override
  String get tables_childSwitch => '🧒 Children\'s table';

  @override
  String get tables_childHint => 'A separate table for the youngest guests';

  @override
  String get tables_deleteTitle => 'Delete table?';

  @override
  String get tables_deleteBody =>
      'Guests seated at this table will return to the unseated list.';

  @override
  String get tables_deletedToast => 'Table deleted';

  @override
  String get tables_full => 'This table is full!';

  @override
  String tables_seatsUsed(int used, int total) {
    return '$used/$total seats';
  }

  @override
  String get tables_assignGuest => 'Seat a guest';

  @override
  String get tables_unassign => 'Free the seat';

  @override
  String get tables_emptyState => 'No tables yet. Add your first one.';

  @override
  String get tables_statTables => 'Tables';

  @override
  String get tables_statSeats => 'Seats';

  @override
  String get tables_statFree => 'Free';

  @override
  String get tables_hintAdultAtChildTable =>
      'An adult was seated at the children\'s table — if that\'s a guardian, all good.';

  @override
  String get tables_hintChildAtRegularTable =>
      'A child at a regular table — there\'s a children\'s table too.';

  @override
  String get roomplan_title => 'Room plan';

  @override
  String get roomplan_editMode => 'Edit mode';

  @override
  String get roomplan_gridOn => 'Grid';

  @override
  String get roomplan_fullscreen => 'Full screen';

  @override
  String get roomplan_addTable => 'Add table';

  @override
  String get roomplan_addElement => 'Add element';

  @override
  String get roomplan_unassignedGuests => 'Unseated guests';

  @override
  String get roomplan_roomSize => 'Room dimensions';

  @override
  String get roomplan_widthMeters => 'Width (m)';

  @override
  String get roomplan_lengthMeters => 'Length (m)';

  @override
  String get roomplan_savedToast => 'Room plan saved';

  @override
  String get guests_namePendingBadge => '✎ name to confirm';

  @override
  String get guests_companionFirstNameHint => 'First name';

  @override
  String guests_badgeSeatedAt(String table) {
    return '✓ $table';
  }

  @override
  String guests_companionOfLine(String name) {
    return '↳ with: $name';
  }

  @override
  String get guests_emptyAll => 'No guests yet.';

  @override
  String guests_shownOf(int shown, int total) {
    return 'Showing $shown of $total guests';
  }

  @override
  String get guests_unknownGuest => 'unknown guest';

  @override
  String get guests_companionPending => 'companion (name to confirm)';

  @override
  String guests_comesWith(String name) {
    return '👥 comes with: $name';
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
  String get tables_guestPickerTitle => 'Choose a guest';

  @override
  String get tables_tapSeatToAssign => 'Tap a seat to place a guest';

  @override
  String get tables_honorBadge => '⭐ Head table';

  @override
  String get tables_childBadge => '🧒 Children\'s';

  @override
  String get tables_seatFree => 'Free';

  @override
  String get tables_addFirst => 'Add your first table';

  @override
  String tables_summary(int tables) {
    String _temp0 = intl.Intl.pluralLogic(
      tables,
      locale: localeName,
      other: '$tables tables',
      one: '1 table',
    );
    return '$_temp0';
  }

  @override
  String tables_seatsSummary(int seats) {
    String _temp0 = intl.Intl.pluralLogic(
      seats,
      locale: localeName,
      other: '$seats seats',
      one: '1 seat',
    );
    return '$_temp0';
  }

  @override
  String get roomplan_elementTable => 'Table';

  @override
  String get roomplan_elementStage => 'Stage';

  @override
  String get roomplan_elementBar => 'Bar';

  @override
  String get roomplan_elementDanceFloor => 'Dance floor';

  @override
  String get roomplan_elementEntrance => 'Entrance';

  @override
  String get roomplan_elementOther => 'Other';

  @override
  String get roomplan_deleteElement => 'Delete element?';

  @override
  String get roomplan_elementName => 'Element name';

  @override
  String get roomplan_staff => 'Staff';

  @override
  String get roomplan_persons => 'Number of people';

  @override
  String get roomplan_includeInCost => 'Include in costs';

  @override
  String get roomplan_dragHint => 'Press and hold to drag';

  @override
  String get roomplan_exitFullscreen => 'Exit full screen';

  @override
  String get tables_nameHintOptional => 'e.g. Table 1 (optional)';

  @override
  String get tables_shapeRoundIcon => '⚪ Round';

  @override
  String get tables_shapeRectIcon => '▭ Rectangular';

  @override
  String tables_deleteBodyNamed(String name) {
    return 'Delete table „$name”? Guests seated there will return to the unseated list.';
  }

  @override
  String get tables_removeFromTable => 'Remove from table';

  @override
  String tables_unassignedHeader(int count) {
    return 'Unseated guests ($count)';
  }

  @override
  String get tables_dragHint =>
      'Press and drag a guest onto a table, or use „Assign”.';

  @override
  String get tables_allSeatedCheer => '🎉 Every guest has a seat!';

  @override
  String get tables_assignGuestAction => 'Assign a guest';

  @override
  String get tables_deleteTable => 'Delete table';

  @override
  String get tables_emptyStateHint =>
      'No tables yet. Add your first one with the button above.';

  @override
  String get tables_statGuests => 'Guests';

  @override
  String get roomplan_zoomIn => 'Zoom in';

  @override
  String get roomplan_widthShort => 'Width';

  @override
  String get roomplan_lengthShort => 'Length';

  @override
  String get roomplan_tableDiameterShort => 'Table dia.';

  @override
  String get roomplan_hint =>
      'Press and drag a table or element to move it. Tap a table to seat guests or change its size.';

  @override
  String roomplan_unassignedDrag(int count) {
    return 'Unseated ($count) — drag onto a table';
  }

  @override
  String get roomplan_guest => 'Guest';

  @override
  String roomplan_addedToTable(String name) {
    return 'Added to table: $name';
  }

  @override
  String get roomplan_guestsAtTable => 'Guests at this table';

  @override
  String get roomplan_noGuestsAtTable => 'No guests seated here.';

  @override
  String get roomplan_tableSize => 'Table size';

  @override
  String get roomplan_diameterMeters => 'Diameter (m)';

  @override
  String get roomplan_rotate90 => 'Rotate 90°';

  @override
  String get roomplan_allSeated => 'All guests are seated.';

  @override
  String roomplan_roomDims(String width, String length) {
    return '$width m × $length m';
  }

  @override
  String get roomplan_zoomOut => 'Zoom out';

  @override
  String get roomplan_fit => 'Fit to screen';

  @override
  String get roomplan_editPlan => 'Edit plan';

  @override
  String roomplan_addedElement(String name) {
    return 'Element added: $name';
  }

  @override
  String get roomplan_elementSize => 'Element size';
}
