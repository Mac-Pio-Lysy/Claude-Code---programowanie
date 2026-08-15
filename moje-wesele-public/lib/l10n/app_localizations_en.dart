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

  @override
  String get budget_title => 'Budget';

  @override
  String get budget_tabSummary => 'Summary';

  @override
  String get budget_tabVenue => 'Venue';

  @override
  String get budget_tabExpenses => 'Expenses';

  @override
  String get budget_tabAlcohol => 'Alcohol';

  @override
  String get budget_tabSoft => 'Soft drinks';

  @override
  String get budget_tabHoneymoon => 'Honeymoon';

  @override
  String get budget_planned => 'Planned budget';

  @override
  String get budget_reserveHint =>
      'Set the reserve in Settings → „Budget settings”.';

  @override
  String get budget_saveButton => 'Save budget';

  @override
  String get budget_savedToast => 'Budget saved';

  @override
  String get budget_invalidAmount => 'Invalid amount';

  @override
  String get budget_paidShort => 'paid';

  @override
  String budget_paidAmount(String amount) {
    return 'Paid: $amount';
  }

  @override
  String get budget_actual => 'Actual budget (costs)';

  @override
  String get budget_ofWhichPaid => 'of which paid';

  @override
  String get budget_remaining => 'Left in budget';

  @override
  String get budget_expenseDeleteTitle => 'Delete expense?';

  @override
  String budget_expenseDeleteBody(String name) {
    return 'Delete „$name”?';
  }

  @override
  String get budget_expenseDeletedToast => 'Expense deleted';

  @override
  String budget_expenseAddedToast(String name) {
    return 'Item added: $name';
  }

  @override
  String get budget_expensesEmpty =>
      'No expenses yet. Add the first one below.';

  @override
  String get budget_expensesEmptyFiltered => 'No expenses match these filters.';

  @override
  String get budget_collapse => 'collapse';

  @override
  String get budget_expand => 'expand';

  @override
  String get budget_quickAddHint =>
      'Tap to add a ready-made expense — edit the list in Settings.';

  @override
  String get budget_customItem => 'Custom item';

  @override
  String get budget_customName => 'Custom name';

  @override
  String get budget_paid => 'Paid';

  @override
  String get budget_left => 'Left';

  @override
  String get budget_statusPaid => '✓ Paid';

  @override
  String get budget_statusPartial => '⚡ Partial';

  @override
  String get budget_statusUnpaid => '✗ Unpaid';

  @override
  String get budget_manual => 'Manual';

  @override
  String budget_paidShortPrefix(String amount) {
    return 'paid $amount';
  }

  @override
  String get budget_paymentDate => 'Payment date';

  @override
  String get budget_split => 'Split';

  @override
  String get budget_splitCosts => 'Cost split';

  @override
  String get budget_isVendor => '🏢 This is a vendor/service';

  @override
  String get budget_isVendorHint =>
      'It will also appear in the Vendors section as THE SAME record (the amount isn\'t counted twice).';

  @override
  String get budget_vendorName => 'Full name';

  @override
  String get budget_paymentsEmpty => 'No payments in this view.';

  @override
  String get budget_paymentsFilter => 'Filter payments';

  @override
  String get budget_paymentsReminders => '🔔 Payment reminders';

  @override
  String get budget_overdue => 'overdue!';

  @override
  String get budget_dueSoon => 'due soon';

  @override
  String get budget_tripShort => '✈️ Trip';

  @override
  String budget_paidRemaining(String paid, String remaining) {
    return 'Paid $paid · Left $remaining';
  }

  @override
  String budget_panelRemoveTitle(String panel) {
    return 'Remove panel: $panel';
  }

  @override
  String get budget_panelRemovedToast => 'Panel removed';

  @override
  String budget_panelRemovedInfo(String panel) {
    return 'The „$panel” panel is removed and is NOT counted towards the budget. Its items stay saved — you can restore the panel.';
  }

  @override
  String get budget_panelRestore => 'Restore panel';

  @override
  String get budget_addItem => 'Add item';

  @override
  String get budget_addItemHint => 'Tap + to add an item.';

  @override
  String get budget_bottlesTotal => 'bottles in total';

  @override
  String get budget_costTotal => 'total cost';

  @override
  String get budget_includeVirtual =>
      'Include virtual guests in the per-person figure';

  @override
  String get budget_splitHeader => '⚖ Cost split';

  @override
  String get budget_splitExceeds => '⚠ The split exceeds the total cost.';

  @override
  String get budget_honeymoonTitle => '✈ Honeymoon';

  @override
  String get budget_honeymoonName => 'Name / destination';

  @override
  String get budget_openOffer => 'Open the offer';

  @override
  String get budget_addVariant => 'Add a trip option';

  @override
  String get budget_variantsHint =>
      'Add a few options and mark which one counts towards the budget.';

  @override
  String get budget_variantsHeader => '✈ Honeymoon options';

  @override
  String get budget_includeMoreExpensive => 'Count the pricier option';

  @override
  String get budget_includeMoreExpensiveHint =>
      'Safe planning — uses the most expensive option.';

  @override
  String get budget_payments => 'Payments';

  @override
  String get budget_toBudget => 'To budget';

  @override
  String get budget_alreadyPaid => 'Paid';

  @override
  String get budget_installments => 'Payment schedule';

  @override
  String get budget_addInstallment => 'Add instalment';

  @override
  String get budget_noInstallments =>
      'No instalments — add a payment schedule.';

  @override
  String get budget_linkFailed => 'Couldn\'t open the link';

  @override
  String get budget_installmentPaid => '✓ Paid';

  @override
  String get budget_installmentDue => '○ Due';

  @override
  String get budget_withChildrenTitle => 'Wedding with children';

  @override
  String get budget_withChildrenSwitch => 'Will there be children?';

  @override
  String get budget_withChildrenHint =>
      'Children are excluded from alcohol estimates. You can also add a children\'s table (in the Room plan) and a separate children\'s meal.';

  @override
  String get budget_childrenAuto => 'Count children from the guest list';

  @override
  String get budget_childrenAutoOn =>
      'The number comes from guests marked as a child (Guests → „🧒 This is a child”).';

  @override
  String get budget_childrenAutoOff =>
      'You enter the number manually. Turn on if children are on the guest list.';

  @override
  String get budget_childrenFromGuests => 'Children (from the guest list)';

  @override
  String get budget_childrenCount => 'Number of children';

  @override
  String budget_childrenMismatch(String fromGuests, String manual) {
    return 'The guest list has $fromGuests marked, but $manual entered here. Check which number is right.';
  }

  @override
  String get budget_childMenuSeparate => 'Separate meal for children?';

  @override
  String budget_childMenuOn(int count) {
    return 'Children ($count) charged at the children\'s price.';
  }

  @override
  String get budget_childMenuOff =>
      'Children charged as adults (price per person).';

  @override
  String get budget_childMenuPrice => 'Price per child (meal)';

  @override
  String get budget_childMenuCost => 'Children\'s meal cost';

  @override
  String get budget_cateringSeparate => 'Catering from another company';

  @override
  String get budget_cateringSeparateHint =>
      'Catering from a different company than the venue — counted separately, per person (same headcount rules as the venue).';

  @override
  String get budget_cateringPricePerPerson => 'Catering price per person';

  @override
  String get budget_noAddons => 'No add-ons. Add one with +.';

  @override
  String budget_perPersonShort(String currency) {
    return '$currency/pers.';
  }

  @override
  String get budget_peopleForCalc => 'Headcount for calculations';

  @override
  String get budget_cateringTotal => 'Catering total';

  @override
  String get budget_pricePerPerson => 'Price per person';

  @override
  String get budget_venueMinGuests => 'Minimum headcount (venue threshold)';

  @override
  String get budget_guestsAssigned => 'Guests seated at tables';

  @override
  String get budget_catVenueCatering => 'Venue and catering';

  @override
  String get budget_catDress => 'Wedding dress';

  @override
  String get budget_catSuit => 'Suit / outfit';

  @override
  String get budget_catRings => 'Wedding rings';

  @override
  String get budget_catPhoto => 'Photographer';

  @override
  String get budget_catVideo => 'Videographer';

  @override
  String get budget_catFlowersDecor => 'Flowers / decorations';

  @override
  String get budget_catBouquet => 'Bridal bouquet';

  @override
  String get budget_catFlowersCouple => 'Flowers for the couple';

  @override
  String get budget_catChurchDecor => 'Church decorations';

  @override
  String get budget_catCake => 'Wedding cake';

  @override
  String get budget_catMusic => 'Music / DJ / band';

  @override
  String get budget_catInvitations => 'Invitations';

  @override
  String get budget_catBeauty => 'Beauty';

  @override
  String get budget_catHairMakeup => 'Hair and make-up';

  @override
  String get budget_catTransport => 'Transport';

  @override
  String get budget_catRideReception => 'Ride to the reception';

  @override
  String get budget_catRideChurch => 'Ride to the church';

  @override
  String get budget_catGiftsGuests => 'Gifts for guests';

  @override
  String get budget_catGiftsParents => 'Gifts for parents';

  @override
  String get budget_catGiftsWitnesses => 'Gifts for witnesses';

  @override
  String get budget_catHoneymoon => 'Honeymoon';

  @override
  String get budget_catAlcohol => 'Alcohol';

  @override
  String get budget_catOther => 'Other';

  @override
  String get budget_expenseFallbackName => 'Expense';

  @override
  String get budget_guestsUnassigned => 'Unseated guests';

  @override
  String get budget_guestsBilledTotal => 'Guests counted in total';

  @override
  String get budget_guestsCost => 'Guest cost';

  @override
  String get budget_countUnassigned => 'Count guests not seated at tables';

  @override
  String budget_countUnassignedOn(int count) {
    return 'Unseated ($count) are included in the cost.';
  }

  @override
  String budget_countUnassignedOff(int count) {
    return 'Unseated ($count) are NOT included.';
  }

  @override
  String get budget_virtualGuests => 'Virtual guests (to the venue threshold)';

  @override
  String get budget_virtualGuestsCost => 'Virtual guest cost';

  @override
  String get budget_includeVirtualCalc =>
      'Include virtual guests in calculations';

  @override
  String get budget_cateringSeparateNote =>
      'Catering (separate company) is counted in its own card below.';

  @override
  String get budget_cateringIncluded =>
      'Catering is included in the venue price per person.';

  @override
  String get budget_staff => 'Staff';

  @override
  String get budget_staffHint =>
      'Waiters, photographer, DJ, videographer — people who eat but aren\'t guests. Counted separately.';

  @override
  String get budget_staffEmpty => 'No staff yet. Add with +.';

  @override
  String get budget_staffRate =>
      'Staff rate per person (empty = same as guests)';

  @override
  String get budget_staffInclude => 'Add staff to the venue cost';

  @override
  String get budget_staffIncludeHint =>
      'Only staff marked „in costs” is counted.';

  @override
  String get budget_staffCountTotal => 'Staff in total';

  @override
  String get budget_staffRateShort => 'Staff rate / pers.';

  @override
  String get budget_staffCost => 'Staff cost';

  @override
  String get budget_menuAddonsTotal => 'Menu add-ons total';

  @override
  String get budget_tableDecor => 'Table decorations (per table)';

  @override
  String get budget_honorTable => '⭐ Couple\'s table';

  @override
  String get budget_honorTableEmpty =>
      'No decorations for the couple\'s table.';

  @override
  String budget_regularTables(int count) {
    return 'Other tables (×$count)';
  }

  @override
  String get budget_regularTablesEmpty =>
      'No decorations for the other tables.';

  @override
  String budget_perTableShort(String currency) {
    return '$currency/table';
  }

  @override
  String get budget_honorTableDecor => 'Couple\'s table decorations';

  @override
  String get budget_regularTablesDecor => 'Other tables\' decorations';

  @override
  String get budget_decorTotal => 'Decorations total';

  @override
  String get budget_venueSummary => 'Venue cost summary';

  @override
  String budget_guestsCostCount(int count) {
    return 'Guest cost ($count pers.)';
  }

  @override
  String budget_virtualCostCount(int count) {
    return 'Virtual guests ($count pers.)';
  }

  @override
  String budget_staffCostCount(int count) {
    return 'Staff ($count pers.)';
  }

  @override
  String budget_staffCostCountExcluded(int count) {
    return 'Staff ($count pers., not counted)';
  }

  @override
  String get budget_cateringSeparateCard => 'Catering (separate)';

  @override
  String get budget_childrenSuffix => 'children';

  @override
  String get budget_tableDecorTotal => 'Table decorations';

  @override
  String budget_variantBudgeted(String name) {
    return 'To budget: $name';
  }

  @override
  String get budget_variantNone => 'none selected';

  @override
  String get budget_reserveSettings => 'Budget settings';

  @override
  String get budget_expensesQuickAdd =>
      'Tap to add a ready-made expense — edit the list in Settings.';

  @override
  String get budget_statusPaidShort => 'Paid';

  @override
  String get schedule_title => '📅 Wedding day schedule';

  @override
  String get schedule_qrForGuests => 'QR code for guests';

  @override
  String get schedule_forGuests => 'For guests';

  @override
  String get schedule_eventNameHint => 'e.g. Ceremony';

  @override
  String get schedule_nameRequired => 'Enter a name';

  @override
  String get schedule_detailsHint => 'Details…';

  @override
  String get schedule_private => '🔒 Private (hidden from guests)';

  @override
  String get schedule_showLink => '👁 Show the link to guests';

  @override
  String get schedule_deleteTitle => 'Delete event?';

  @override
  String schedule_deleteBody(String name) {
    return 'Delete „$name”?';
  }

  @override
  String get schedule_deletedToast => 'Event deleted';

  @override
  String get schedule_empty => 'No events yet. Add the first one below.';

  @override
  String get schedule_openLocation => 'Open location';

  @override
  String schedule_guestPreview(int count) {
    return 'Guest preview ($count)';
  }

  @override
  String get schedule_noneVisible => 'No event is marked as visible to guests.';

  @override
  String get schedule_guestPreviewHint =>
      'This is how guests see the schedule on /harmonogram:';

  @override
  String get schedule_visibility => 'Event visibility';

  @override
  String get schedule_emptyAddInPlan =>
      'No events yet. Add them in the „Day plan” tab.';

  @override
  String get schedule_visibilityHint => 'Choose which events guests can see.';

  @override
  String get schedule_visibleToGuests => 'Visible to guests';

  @override
  String get checklist_addHint => 'What to do…';

  @override
  String checklist_progress(int done, int total, int percent) {
    return '$done/$total done ($percent%)';
  }

  @override
  String get checklist_addItem => 'Add item';

  @override
  String get tasks_deleteTitle => 'Delete task?';

  @override
  String tasks_deleteBody(String name) {
    return 'Delete „$name”?';
  }

  @override
  String get tasks_deletedToast => 'Task deleted';

  @override
  String get tasks_goalReached => '🎯 Goal reached';

  @override
  String tasks_goalReachedBody(String goal) {
    return '„$goal” has been marked as done.\n\nCreate a budget item from it?';
  }

  @override
  String get tasks_goalCreateYes => 'Yes, create';

  @override
  String get tasks_budgetItemCreated => 'Budget item created';

  @override
  String get tasks_newBudgetItem => '💰 New budget item';

  @override
  String tasks_estimatedCost(String currency) {
    return 'Estimated cost ($currency)';
  }

  @override
  String get tasks_budgetCategory => 'Budget category';

  @override
  String get tasks_create => 'Create';

  @override
  String tasks_progress(int done, int total, int percent) {
    return '$done/$total done ($percent%)';
  }

  @override
  String get tasks_allLinks => 'All links';

  @override
  String get tasks_linkBudget => '💰 Budget';

  @override
  String get tasks_linkVendor => '👨‍🍳 Vendor';

  @override
  String get tasks_noLink => 'No link';

  @override
  String get tasks_dragHere => 'Drag here';

  @override
  String get tasks_deleteAction => '🗑 Delete';

  @override
  String get tasks_nameHint => 'e.g. Book the venue';

  @override
  String get tasks_nameRequired => 'Enter a task name';

  @override
  String get tasks_customGoal => '➕ Other goal (write your own)';

  @override
  String get tasks_goalDone => '🎯 Goal reached';

  @override
  String get tasks_goalDoneHint =>
      'e.g. „DJ booked” — tick when the goal is done.';

  @override
  String get tasks_showMore => 'Show more options';

  @override
  String get tasks_customPerson => 'Custom person (optional)';

  @override
  String get tasks_customPersonHint => 'Name — overrides the choice above';

  @override
  String get tasks_startDate => 'Start date';

  @override
  String get tasks_endDate => 'End date';

  @override
  String get tasks_linkBudgetSwitch => '💰 Link to budget';

  @override
  String get tasks_linkBudgetHint =>
      'Creates/updates a linked budget entry (a reference).';

  @override
  String get tasks_links => '🔗 Links';

  @override
  String get tasks_linksHint =>
      'Link the task to a Vendor, Transport, Accommodation or Music. You can create a new item — it becomes a reference (the same record visible in both sections), with no duplicated data.';

  @override
  String get tasks_createVendor => '➕ Create a new vendor';

  @override
  String get tasks_createTransport => '➕ Create a transport entry';

  @override
  String get tasks_createAccommodation => '➕ Create an accommodation entry';

  @override
  String get tasks_createSong => '➕ Create a song';

  @override
  String get tasks_song => 'Song';

  @override
  String tasks_costWithCurrency(String amount, String currency) {
    return '💰 $amount $currency';
  }

  @override
  String get schedule_tabDayPlan => 'Day plan';

  @override
  String get schedule_tabChecklist => 'Checklist';

  @override
  String get vendors_catVenue => 'Venue';

  @override
  String get vendors_catOutfit => 'Outfit';

  @override
  String get vendors_catDocs => 'Documents';

  @override
  String get vendors_catDecor => 'Decorations';

  @override
  String get vendors_catOther => 'Other';

  @override
  String get tasks_title => 'Tasks';

  @override
  String get tasks_addButton => 'Add task';

  @override
  String get tasks_addedToast => 'Task added';

  @override
  String get tasks_notNow => 'Not now';

  @override
  String get tasks_editAction => '✏ Edit';

  @override
  String get budget_expenseAddedShort => 'Expense added';

  @override
  String get budget_addExpense => 'Add expense';

  @override
  String get budget_quickItems => '⚡ Quick items';

  @override
  String get budget_filtersSort => 'Filters and sorting';

  @override
  String get budget_allCategories => 'All categories';

  @override
  String get budget_offerLink => 'Offer link';

  @override
  String get budget_roughAmount => 'Rough amount';

  @override
  String get budget_addVariantShort => 'Add option';

  @override
  String get budget_cateringAddons => 'Catering add-ons (per person)';

  @override
  String get budget_cateringSeparateAsk => 'Is catering separate?';

  @override
  String get budget_menuAddons => 'Menu add-ons (per person)';

  @override
  String get budget_includeInVenueCost => 'Include in the venue cost';

  @override
  String checklist_newItem(String category) {
    return 'New item — $category';
  }

  @override
  String checklist_addedToast(String text) {
    return 'Added: $text';
  }

  @override
  String get checklist_empty => 'No items yet.';

  @override
  String get schedule_addEvent => 'Add event';

  @override
  String get roomplan_roomDimsLabel => 'Room dimensions (m)';

  @override
  String get roomplan_addElementSheet => 'Add a room element';

  @override
  String get roomplan_autoSizeHint =>
      '0 = size derived from the number of seats.';

  @override
  String tables_assignTo(String table) {
    return 'Assign to: $table';
  }

  @override
  String tables_seatsOf(int used, int total) {
    return '$used/$total seats';
  }

  @override
  String get vendors_title => 'Vendors';

  @override
  String get vendors_addButton => 'Add vendor';

  @override
  String get vendors_addedToast => 'Vendor added';

  @override
  String get vendors_deleteTitle => 'Delete vendor?';

  @override
  String get vendors_deleteKeepEntry => 'Delete, keep the entry';

  @override
  String get vendors_deletedToast => 'Vendor deleted';

  @override
  String get vendors_empty => 'No vendors yet.';

  @override
  String vendors_contact(String name) {
    return '👤 $name';
  }

  @override
  String vendors_price(String amount) {
    return 'Price: $amount';
  }

  @override
  String get vendors_installments => '💵 Instalments / payments';

  @override
  String get vendors_noInstallments => 'No instalments.';

  @override
  String vendors_paidRemaining(String paid, String remaining) {
    return 'Paid: $paid · Left: $remaining';
  }

  @override
  String get vendors_toPay => 'Due';

  @override
  String get vendors_paid => 'Paid';

  @override
  String get vendors_linkBudget => '💰 Link to budget';

  @override
  String get vendors_linkBudgetHint =>
      'Creates/updates a linked budget entry (a reference).';

  @override
  String get transport_title => 'Transport';

  @override
  String get transport_addVehicle => 'Add vehicle';

  @override
  String get transport_vehicleAdded => 'Vehicle added';

  @override
  String get transport_noGuestsAvailable => 'No guests available';

  @override
  String get transport_showOwn => 'Show own transport';

  @override
  String transport_seatsOf(int used, int total) {
    return '$used/$total seats';
  }

  @override
  String get transport_ownHeader => '🚶 Own transport';

  @override
  String get transport_ownEmpty => 'No guests arriving on their own.';

  @override
  String get transport_addGuest => 'Add guest';

  @override
  String transport_unassignedHeader(int count) {
    return '❓ Unassigned ($count)';
  }

  @override
  String get transport_allAssigned => 'Every guest has transport.';

  @override
  String get transport_internalHeader => '🚕 Local transport';

  @override
  String get transport_internalEmpty => 'Empty. Add Bolt / taxi / other.';

  @override
  String get transport_showInSchedule => 'Show to guests in the schedule';

  @override
  String get accommodation_title => 'Accommodation';

  @override
  String get accommodation_deleteHotelTitle => 'Delete hotel?';

  @override
  String accommodation_deleteHotelBody(String name) {
    return 'Delete „$name”?';
  }

  @override
  String get accommodation_guestsNeeding => 'Guests who need a room';

  @override
  String get accommodation_hotels => 'Hotels and places to stay';

  @override
  String get accommodation_addHotel => 'Add hotel';

  @override
  String get accommodation_noHotel => 'No hotel';

  @override
  String get accommodation_statusHint => 'Status…';

  @override
  String get accommodation_onSite => '🏰 On site';

  @override
  String get accommodation_onSiteSwitch => '🏰 Hotel at the wedding venue';

  @override
  String vendors_paidRemainingTotal(
    String paid,
    String remaining,
    String total,
  ) {
    return 'Paid: $paid · Left: $remaining · Total: $total';
  }

  @override
  String get analytics_title => 'Analytics';

  @override
  String get analytics_empty => 'Nothing to analyse yet';

  @override
  String get analytics_emptyHint =>
      'Add guests and expenses to see analytics — RSVPs, cost breakdown, payment progress, meals and diets.';

  @override
  String get analytics_budgetForecast => 'Final budget forecast';

  @override
  String get analytics_costPerGuest => 'Cost per guest';

  @override
  String get dashboard_availableTiles => 'Available tiles';

  @override
  String get rsvp_title => 'RSVP';

  @override
  String get rsvp_allTitle => 'All RSVPs';

  @override
  String get rsvp_allHint => 'All replies plus QR codes and links for guests.';

  @override
  String get rsvp_allEmpty =>
      'No RSVPs yet. They\'ll show up here once guests start replying.';

  @override
  String get rsvp_qrHint =>
      'All QR codes and links to guest pages in one place.';

  @override
  String rsvp_qrError(String error) {
    return 'QR generation failed: $error';
  }

  @override
  String rsvp_quotedMessage(String message) {
    return '„$message”';
  }

  @override
  String get rsvp_deleteEntry => 'Delete entry';

  @override
  String get rsvp_deleteEntryTitle => 'Delete this RSVP?';

  @override
  String get rsvp_clearAll => 'Clear all';

  @override
  String get rsvp_clear => 'Clear';

  @override
  String get rsvp_clearAllTitle => 'Clear all RSVPs?';

  @override
  String get rsvp_empty =>
      'No RSVPs yet. Share the QR code with guests (at the bottom of this page).';

  @override
  String rsvp_unmatched(int count) {
    return 'Unmatched RSVPs ($count)';
  }

  @override
  String rsvp_guestsCount(int count) {
    return 'Guests ($count)';
  }

  @override
  String get rsvp_noGuestsInCategory => 'No guests in this category.';

  @override
  String get rsvp_assignToGuest => 'Assign to a guest…';

  @override
  String get games_title => 'Wedding games';

  @override
  String get games_activeForGuests => 'Game active for guests';

  @override
  String get games_quizActiveForGuests => 'Quiz active for guests';

  @override
  String get games_ranking => '🏆 Guest ranking';

  @override
  String get games_addAnswer => 'Add answer';

  @override
  String games_scoreOf(int score, int total) {
    return '$score/$total';
  }

  @override
  String get games_bingo => 'Wedding Bingo';

  @override
  String get games_quiz => 'Quiz about the couple';

  @override
  String get games_trueFalse => 'True or False';

  @override
  String get games_photoGuess => 'Guess the photo';

  @override
  String get games_wheel => 'Wheel of fortune';

  @override
  String get games_photoChallenge => 'Photo challenges';

  @override
  String get quiz_addQuestion => 'Add question';

  @override
  String get quiz_empty => 'No questions';

  @override
  String get quiz_emptyHint =>
      'Add your own questions or start from ready-made examples.';

  @override
  String get quiz_examplesAdded => 'Example questions added';

  @override
  String get quiz_addExamples => 'Add example questions';

  @override
  String get quiz_saved => 'Question saved';

  @override
  String get quiz_added => 'Question added';

  @override
  String get quiz_deleteTitle => 'Delete question?';

  @override
  String quiz_deleteBody(String text) {
    return 'Delete „$text”?';
  }

  @override
  String get quiz_deleted => 'Question deleted';

  @override
  String get quiz_hardest => '📊 Hardest questions';

  @override
  String quiz_numbered(int index, String text) {
    return '$index. $text';
  }

  @override
  String get tf_addStatement => 'Add statement';

  @override
  String get tf_empty => 'No statements';

  @override
  String get tf_emptyHint =>
      'Add your own statements or start from ready-made examples.';

  @override
  String get tf_examplesAdded => 'Example statements added';

  @override
  String get tf_addExamples => 'Add examples';

  @override
  String get tf_saved => 'Statement saved';

  @override
  String get tf_added => 'Statement added';

  @override
  String get tf_deleteTitle => 'Delete statement?';

  @override
  String tf_deleteBody(String text) {
    return 'Delete „$text”?';
  }

  @override
  String get tf_deleted => 'Statement deleted';

  @override
  String get photoGuess_add => 'Add a photo with a question';

  @override
  String get photoGuess_empty => 'No photos';

  @override
  String get photoGuess_emptyHint =>
      'Add old photos (e.g. from childhood) and questions for guests to guess.';

  @override
  String get photoGuess_saved => 'Photo saved';

  @override
  String get photoGuess_added => 'Photo added';

  @override
  String get photoGuess_deleteTitle => 'Delete photo?';

  @override
  String photoGuess_deleteBody(String text) {
    return 'Delete the question „$text”?';
  }

  @override
  String get photoGuess_deleted => 'Photo deleted';

  @override
  String get photoGuess_hardest => '📊 Hardest photos';

  @override
  String get photoGuess_noPhoto => 'No photo';

  @override
  String get photoGuess_fromGallery => 'From gallery';

  @override
  String get photoChallenge_add => 'Add challenge';

  @override
  String get photoChallenge_empty => 'No challenges';

  @override
  String get photoChallenge_emptyHint =>
      'Add your own challenges or start from ready-made examples.';

  @override
  String get photoChallenge_examplesAdded => 'Example challenges added';

  @override
  String get photoChallenge_addExamples => 'Add examples';

  @override
  String get photoChallenge_saved => 'Challenge saved';

  @override
  String get photoChallenge_added => 'Challenge added';

  @override
  String get photoChallenge_deleteTitle => 'Delete challenge?';

  @override
  String photoChallenge_deleteBody(String text) {
    return 'Delete „$text”? The submitted photos will be deleted along with the challenge.';
  }

  @override
  String get photoChallenge_deleted => 'Challenge deleted';

  @override
  String photoChallenge_points(int points) {
    return '⭐ $points pts';
  }

  @override
  String get photoChallenge_deletePhotoTitle => 'Delete photo?';

  @override
  String photoChallenge_deletePhotoBody(String name) {
    return 'Delete the photo from „$name”?';
  }

  @override
  String get photoChallenge_photoDeleted => 'Photo deleted';

  @override
  String get photoChallenge_text => 'Challenge text';

  @override
  String get photoChallenge_textHint => 'e.g. Take a selfie with the couple';

  @override
  String get photoChallenge_textRequired => 'Enter the challenge text';

  @override
  String get common_filtersSort => 'Filters and sorting';

  @override
  String common_pdfError(String error) {
    return 'PDF generation failed: $error';
  }

  @override
  String get common_exportPdf => 'Export to PDF';

  @override
  String get common_sortBy => 'Sort:';

  @override
  String get common_view => 'View:';

  @override
  String get gallery_title => 'Gallery & QR';

  @override
  String gallery_readError(String error) {
    return 'Couldn\'t read the gallery: $error';
  }

  @override
  String gallery_usage(String used) {
    return 'Used: $used / 25 GB';
  }

  @override
  String get gallery_empty => 'No files in the gallery.';

  @override
  String get gallery_video => '▶ video';

  @override
  String gallery_uploadedBy(String name) {
    return '📷 $name';
  }

  @override
  String get gallery_format => 'Format:';

  @override
  String gallery_pdfError(String error) {
    return 'PDF error: $error';
  }

  @override
  String get gallery_deleteTitle => 'Remove file from the gallery?';

  @override
  String get gallery_deleteBody =>
      'It disappears from the guest gallery. The original stays in Cloudinary.';

  @override
  String get gallery_deleted => 'File removed';

  @override
  String get gifts_thanked => 'Thanked';

  @override
  String get gifts_empty => 'No gifts yet.';

  @override
  String get gifts_addPerson => '+ Add person…';

  @override
  String get gifts_wishlistHint =>
      'The couple\'s wish list. Selected suggestions are visible to guests on the schedule page.';

  @override
  String get gifts_showToGuests => 'Show to guests on the schedule page';

  @override
  String get keepsakes_title => 'Wedding keepsakes';

  @override
  String get keepsakes_guestbook => 'Guest book';

  @override
  String get keepsakes_advices => 'Advice for the couple';

  @override
  String get keepsakes_timeCapsule => 'Time capsule';

  @override
  String get keepsakes_guestMap => 'Guest map';

  @override
  String get advices_filterByCategory => 'Filter by category';

  @override
  String get advices_slideshow => 'Slideshow';

  @override
  String advices_labelCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get advices_delete => 'Delete advice';

  @override
  String get advices_deleteTitle => 'Delete advice?';

  @override
  String get advices_deleted => 'Advice deleted';

  @override
  String get advices_header => '💌 Advice for the couple';

  @override
  String advices_position(int index, int total) {
    return '$index / $total';
  }

  @override
  String advices_quoted(String message) {
    return '„$message”';
  }

  @override
  String get guestbook_deleteEntry => 'Delete entry';

  @override
  String get guestbook_deleteTitle => 'Delete entry?';

  @override
  String get guestbook_deleted => 'Entry deleted';

  @override
  String get capsule_exportOpen => 'Export opened to PDF';

  @override
  String capsule_sealedUntil(String date) {
    return '🔒 Sealed until $date';
  }

  @override
  String get capsule_hasPhoto => '📷 includes a photo';

  @override
  String get capsule_deleteMessage => 'Delete message';

  @override
  String get capsule_openAllTitle => 'Open everything now?';

  @override
  String get capsule_openAllBody =>
      'You\'ll see the contents of sealed messages too, before their date arrives.';

  @override
  String get capsule_openAll => 'Open everything';

  @override
  String get capsule_deleteTitle => 'Delete message?';

  @override
  String get capsule_deleted => 'Message deleted';

  @override
  String get guestMap_addManually => 'Add guest manually';

  @override
  String get guestMap_empty =>
      'No located guests yet. Pins appear once entries include a town.';

  @override
  String guestMap_farthest(String name) {
    return 'Farthest guest: $name';
  }

  @override
  String get guestMap_setVenueHint =>
      'To measure the farthest guest, set „Reception venue” in Configuration.';

  @override
  String guestMap_kmFromVenue(int km) {
    return '$km km from the venue';
  }

  @override
  String get guestMap_notLocated => '⚠ Not located — add a town';

  @override
  String get guestMap_deleteTitle => 'Delete entry?';

  @override
  String get guestMap_deleted => 'Entry deleted';

  @override
  String get guestMap_name => 'Name';

  @override
  String get guestMap_city => 'Town';

  @override
  String get guestMap_cityHint => 'e.g. Kraków';

  @override
  String get guestMap_greeting => 'Greeting (optional)';

  @override
  String get music_title => 'Music';

  @override
  String get music_added => 'Song added';

  @override
  String get music_qrForGuests => 'QR code for guests';

  @override
  String music_unmatched(int count) {
    return '⚠ Unmatched / to verify ($count)';
  }

  @override
  String music_list(int count) {
    return 'Song list ($count)';
  }

  @override
  String get music_emptyFiltered => 'No songs match these filters.';

  @override
  String get music_searchDeezer => 'Search a song (Deezer)…';

  @override
  String get music_addManually => 'Add manually';

  @override
  String get music_deezerError =>
      'Couldn\'t reach Deezer (check your internet/CORS).';

  @override
  String get music_deezerEmpty => 'Not found on Deezer.';

  @override
  String music_addedTitle(String title) {
    return 'Added: $title';
  }

  @override
  String get music_addedUnmatched => 'Added as unmatched';

  @override
  String music_addToVerify(String query) {
    return 'Add „$query” to verify';
  }

  @override
  String get music_allMoments => 'All moments';

  @override
  String get music_fromGuest => '👤 from a guest';

  @override
  String get music_momentsHint => 'Songs for the key moments. Drag to reorder.';

  @override
  String get music_addOwnMoment => 'Add your own moment';

  @override
  String get music_outsideList => 'outside the list';

  @override
  String get music_removeMoment => 'Remove moment from the list';

  @override
  String get music_noSongAssigned => 'No song — add or assign one.';

  @override
  String get music_addNew => 'Add new';

  @override
  String get music_assignmentRemoved => 'Assignment removed';

  @override
  String get music_removeAssignment => 'Remove assignment';

  @override
  String get music_newMoment => 'New moment';

  @override
  String get music_momentName => 'Moment name';

  @override
  String get music_momentNameHint => 'e.g. Day-after party';

  @override
  String get music_momentExists => 'That moment already exists';

  @override
  String music_momentAdded(String name) {
    return 'Moment added: $name';
  }

  @override
  String get music_removeMomentTitle => 'Remove moment from the list?';

  @override
  String music_removeMomentBody(String label) {
    return '„$label” disappears from the list. Assigned songs will NOT be deleted.';
  }

  @override
  String get music_emptyAddFirst => 'No songs on the list. Add a song first.';

  @override
  String music_assignTo(String label) {
    return 'Assign to: $label';
  }

  @override
  String music_assignedTo(String label) {
    return 'Song assigned to: $label';
  }

  @override
  String get music_nothingToExport => 'No songs to export';

  @override
  String get music_exportCsv => 'Export CSV';

  @override
  String get music_exportText => 'Export as text';

  @override
  String get music_copiedToClipboard => 'Copied to clipboard';

  @override
  String get music_import => 'Import songs';

  @override
  String get music_pasteHere => 'Paste here…';

  @override
  String get music_nothingRecognized => 'No songs recognised';

  @override
  String music_imported(int count) {
    return 'Imported $count songs';
  }

  @override
  String get music_addSongManually => 'Add a song manually';

  @override
  String get music_songTitle => 'Title';

  @override
  String get music_searchInDeezer => 'Search Deezer…';

  @override
  String get music_nothingFound =>
      'Nothing found (you can add it manually below).';

  @override
  String get music_orAddManually => '…or add manually';

  @override
  String guestMap_deleteBody(String name) {
    return 'Delete „$name”?';
  }

  @override
  String guestbook_deleteBody(String name) {
    return 'Delete the entry from „$name”?';
  }

  @override
  String capsule_deleteBody(String name) {
    return 'Delete the message from „$name”?';
  }

  @override
  String get music_momentsHintFull =>
      'Songs for the key moments of the wedding. Drag to reorder.';

  @override
  String get rsvp_allEmptyFull =>
      'No RSVPs yet. They\'ll show up here once guests start replying.';

  @override
  String get rsvp_qrHintFull =>
      'All QR codes and links to guest pages in one place.';

  @override
  String get rsvp_emptyFull =>
      'No RSVPs yet. Share the QR code with guests (at the bottom of this page).';

  @override
  String get guestMap_txt1 =>
      'A page where guests mark where they\'re travelling from. Show them the QR code or send the link.';

  @override
  String get guestMap_txt2 =>
      'No entries yet. Share the QR code from the „Guest page” tab.';

  @override
  String get guestMap_txt3 =>
      'No located guests yet. Pins appear once guests write in or you add someone with a town.';

  @override
  String get guestMap_txt4 =>
      'To measure the distance to the farthest guest, set „Reception venue” in Configuration (Settings section).';

  @override
  String get capsule_txt1 =>
      'A page where guests leave messages to open in the future (e.g. on an anniversary). Show them the QR code or send the link.';

  @override
  String get capsule_txt2 =>
      'No messages yet. Share the QR code from the „Guest page” tab.';

  @override
  String get capsule_txt3 =>
      'You\'ll see the contents of sealed messages too, before their date arrives. This is only a preview for you — it doesn\'t change opening dates or what others see. Still, the most joy comes from waiting.';

  @override
  String get guestbook_txt1 =>
      'A page where guests leave wishes and messages for the couple (with an optional photo). Show them the QR code or send the link.';

  @override
  String get guestbook_txt2 =>
      'No entries yet. Share the QR code from the „Guest page” tab so guests can start writing.';

  @override
  String get advices_txt1 =>
      'A page where guests leave advice and words of wisdom about marriage. Show them the QR code or send the link.';

  @override
  String get advices_txt2 =>
      'No advice yet. Share the QR code from the „Guest page” tab.';

  @override
  String get music_txt1 =>
      'A page where guests suggest songs to play. Show them the QR code or send the link.';

  @override
  String get music_txt2 =>
      'Songs for the key moments of the wedding. Drag to set the order. Add a new song or assign an existing one to each moment.';

  @override
  String get rsvp_txt1 =>
      'No RSVPs yet. They\'ll show up here once guests fill in the /rsvp form or you set a status manually in the „RSVP” section.';

  @override
  String get rsvp_txt2 =>
      'All QR codes and links to guest pages in one place. You can copy, open or download each code.';

  @override
  String get rsvpMain_txt1 =>
      'No RSVPs yet. Share the QR code with guests (at the bottom of this section) or the link to the /rsvp page to start collecting replies.';

  @override
  String get rsvpMain_txt2 =>
      'Share the RSVP page with your guests. Show the QR code or send the link.';

  @override
  String get gallery_txt1 =>
      'Guest page: a shared gallery of photos and videos, plus the option to suggest music. Show the QR code or send the link.';

  @override
  String get photoChallenge_txt1 =>
      'A page where guests take on photo challenges and upload their shots. Turn the game on in the „Challenges” tab.';

  @override
  String get photoChallenge_txt2 =>
      'No photos yet. Once guests complete the challenges, they\'ll appear here — grouped by challenge.';

  @override
  String get photoGuess_txt1 =>
      'A page where guests look at old photos and guess the answers. Turn the game on in the „Photos” tab, show the QR code or send the link.';

  @override
  String get photoGuess_txt2 =>
      'Add old photos (e.g. from childhood) and questions for guests to guess.';

  @override
  String get tf_txt1 =>
      'A page where guests decide whether statements about the couple are true or false. Turn the game on in the „Statements” tab.';

  @override
  String get quiz_txt1 =>
      'A page where guests answer questions about the couple and see their score. Turn the quiz on in the „Questions” tab.';

  @override
  String guestbook_deleteBodyNamed(String name) {
    return 'Delete the entry from „$name”? This cannot be undone.';
  }

  @override
  String capsule_deleteBodyNamed(String name) {
    return 'Delete the message from „$name”? This cannot be undone.';
  }

  @override
  String get guestSection_rsvp => 'RSVP';

  @override
  String get guestSection_gallery => 'Gallery';

  @override
  String get guestSection_schedule => 'Schedule';

  @override
  String get guestSection_music => 'Music';

  @override
  String get guestSection_guestbook => 'Guest book';

  @override
  String get guestSection_advice => 'Advice';

  @override
  String get guestSection_timeCapsule => 'Time capsule';

  @override
  String get guestSection_guestMap => 'Guest map';

  @override
  String get guestSection_quiz => 'Quiz';

  @override
  String get guestSection_trueFalse => 'True/False';

  @override
  String get guestSection_photoGuess => 'Guess the photo';

  @override
  String get guestSection_photoChallenge => 'Photo challenges';

  @override
  String get guestSection_bingo => 'Wedding Bingo';

  @override
  String get gw_appTitle => 'Wedding — guest zone';

  @override
  String get gw_language => 'Language';

  @override
  String get gw_help => 'Help';

  @override
  String get gw_connecting => 'Connecting…';

  @override
  String get gw_invalidLink => 'Invalid or inactive link';

  @override
  String get gw_invalidLinkBody =>
      'Ask the couple for an up-to-date link or QR code to the guest page.';

  @override
  String get gw_guestZone => 'Guest zone';

  @override
  String get gw_unavailable =>
      'The guest page is temporarily unavailable. Check back later.';

  @override
  String get gw_ourWedding => 'Our Wedding';

  @override
  String get gw_emptyInfo =>
      'Guest sections will appear here once the couple shares them.';

  @override
  String gw_availableFrom(String date) {
    return 'Available from $date';
  }

  @override
  String get gw_noLongerAvailable => 'No longer available';

  @override
  String get gw_unavailableShort => 'Unavailable';

  @override
  String get gw_comingSoon => 'This section will be available soon';

  @override
  String get gw_yourName => 'Your name';

  @override
  String get gw_guest => 'Guest';

  @override
  String get gw_sending => 'Sending…';

  @override
  String get gw_thanks => 'Thank you ✓';

  @override
  String get gw_updated => 'Updated ✓';

  @override
  String get gw_saveChanges => 'Save changes';

  @override
  String gw_sendError(String error) {
    return 'Couldn\'t send: $error';
  }

  @override
  String get gw_sessionError =>
      'Couldn\'t set up the guest session. Refresh the page and try again.';

  @override
  String get gw_nameFirst => 'Enter your name first.';

  @override
  String get gw_scheduleSoon => 'The schedule will appear soon.';

  @override
  String get gw_scheduleItem => 'Programme item';

  @override
  String get gw_guestbookHint => 'Your message to the couple…';

  @override
  String get gw_guestbookCta => 'Add entry';

  @override
  String get gw_guestbookEmpty => 'Be the first — leave a message!';

  @override
  String get gw_adviceHint => 'Your advice for the couple…';

  @override
  String get gw_adviceCta => 'Add advice';

  @override
  String get gw_adviceEmpty => 'Share the first piece of advice!';

  @override
  String get gw_needNameAndMessage => 'Enter your name and a message.';

  @override
  String get gw_needNameAndCity => 'Enter your name and town.';

  @override
  String get gw_fromWhereCity => 'Where are you travelling from (town)';

  @override
  String get gw_greetingOptional => 'Greeting (optional)';

  @override
  String get gw_addToMap => 'Add to the map';

  @override
  String get gw_mapEmpty => 'Be the first on the guest map!';

  @override
  String get gw_needNameAndText => 'Enter your name and a message.';

  @override
  String get gw_capsuleSealed => 'Message sealed!';

  @override
  String get gw_capsuleSealedBody =>
      'The couple will open your message at the chosen time. Thank you!';

  @override
  String get gw_capsuleIntro =>
      'Leave a message the couple will open in the future. Other guests won\'t see it.';

  @override
  String get gw_capsuleHint => 'Your message for the time capsule…';

  @override
  String get gw_capsuleSeal => 'Seal the message';

  @override
  String get gw_needFullName => 'Enter your first and last name.';

  @override
  String get gw_rsvpSeeYou => 'See you at the wedding! 🎉';

  @override
  String get gw_rsvpThanks => 'Thank you for your reply';

  @override
  String get gw_rsvpSent => 'Your reply has reached the couple.';

  @override
  String get gw_rsvpEdit => 'Change my reply';

  @override
  String get gw_rsvpExistingHint =>
      'This is your earlier reply. You can change it — we\'ll save the new version instead of adding another one.';

  @override
  String get gw_rsvpNewHint =>
      'One reply is enough. If your plans change, come back here and update it.';

  @override
  String get gw_fullName => 'First and last name';

  @override
  String get gw_rsvpQuestion => 'Will you be at the wedding?';

  @override
  String get gw_rsvpYes => 'I\'ll be there';

  @override
  String get gw_rsvpNo => 'I can\'t make it';

  @override
  String get gw_companions => 'Number of companions';

  @override
  String get gw_dietOptional => 'Diet / allergies (optional)';

  @override
  String get gw_messageOptional => 'Message for the couple (optional)';

  @override
  String get gw_rsvpSend => 'Send reply';

  @override
  String get gw_photoCaption => 'Photo caption (optional)';

  @override
  String get gw_photoThanks => 'Thank you for the photo ✓';

  @override
  String gw_photoError(String error) {
    return 'Couldn\'t add the photo: $error';
  }

  @override
  String get gw_galleryError => 'Couldn\'t load the gallery.';

  @override
  String get gw_galleryEmpty => 'Be the first — add a photo!';

  @override
  String get gw_photoUploading => 'Uploading photo…';

  @override
  String get gw_camera => 'Camera';

  @override
  String get gw_pickPhoto => 'Pick a photo';

  @override
  String get gw_searchUnavailable =>
      'Search is unavailable — type the title and artist manually.';

  @override
  String get gw_needSongTitle => 'Enter the song title.';

  @override
  String get gw_proposalSent => 'Suggestion sent ✓';

  @override
  String get gw_musicIntro =>
      'Suggest a song you\'d like to hear at the wedding. Suggestions go to the couple.';

  @override
  String get gw_musicSearch => 'Search for a song or artist';

  @override
  String get gw_noResults => 'No results — try a different phrase.';

  @override
  String get gw_addManually => 'Add manually';

  @override
  String get gw_songTitle => 'Song title';

  @override
  String get gw_artistOptional => 'Artist (optional)';

  @override
  String get gw_sendProposal => 'Send suggestion';

  @override
  String get gw_yourProposals => 'Your suggestions';

  @override
  String get gw_gameInactive => 'This game isn\'t active right now.';

  @override
  String get gw_questionsSoon => 'Questions will appear soon.';

  @override
  String get gw_statementsSoon => 'Statements will appear soon.';

  @override
  String get gw_answerAllQuestions => 'Answer every question.';

  @override
  String get gw_answerAllStatements => 'Answer every statement.';

  @override
  String get gw_finishAndSend => 'Finish and send my score';

  @override
  String gw_scoreError(String error) {
    return 'Couldn\'t send the score: $error';
  }

  @override
  String get gw_scorePrivate =>
      'Only the couple sees your score. There\'s no public ranking.';

  @override
  String get gw_true => 'True';

  @override
  String get gw_false => 'False';

  @override
  String gw_yourScore(int score, int total) {
    return 'Your score: $score / $total';
  }

  @override
  String get gw_scoreEarlier =>
      'This is your earlier score. You can try again — the new score will replace it.';

  @override
  String get gw_scoreThanks =>
      'Thanks for playing! Your score went to the couple.';

  @override
  String get gw_playAgain => 'Play again';

  @override
  String get gw_challengesInactive =>
      'Photo challenges aren\'t active right now.';

  @override
  String get gw_challengesSoon => 'Challenges will appear soon.';

  @override
  String get gw_challengeHint =>
      'One photo per challenge — a new one replaces the old.';

  @override
  String get gw_guestPhotos => 'Guest photos';

  @override
  String get gw_photosError => 'Couldn\'t load the photos.';

  @override
  String get gw_photosEmpty => 'Nobody has sent a photo yet — be the first!';

  @override
  String gw_points(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pts',
      one: '1 pt',
    );
    return '$_temp0';
  }

  @override
  String get gw_sendPhoto => 'Send photo';

  @override
  String get gw_photoSent => 'Photo sent ✓';

  @override
  String get gw_bingoSoon => 'The bingo board will appear soon.';

  @override
  String get gw_bingoIntro =>
      'Cross off squares as you spot them at the wedding. Crosses stay on your phone only — send your entry once you have a full set.';

  @override
  String gw_bingoMarked(int marked, int total) {
    return 'Crossed off: $marked / $total';
  }

  @override
  String get gw_bingoDone => 'Bingo!';

  @override
  String get gw_bingoFree => 'FREE';

  @override
  String get settings_configSaved => 'Configuration saved ✓';

  @override
  String get settings_syncCard => 'Sync status';

  @override
  String get settings_syncOk => 'Synced with Firestore';

  @override
  String get settings_syncConnecting => 'Connecting…';

  @override
  String get settings_guideCard => 'Guide and help';

  @override
  String get settings_guideHint =>
      'Go back to the interactive guide or to the list of wedding planning steps.';

  @override
  String get settings_helpOpen => 'Help — feature descriptions';

  @override
  String get settings_legacyCard => 'Data from older sections (legacy)';

  @override
  String get settings_legacyHint =>
      'Entries from the single-wedding era (gallery, guest book, advice, map, time capsule, game scores) have no wedding assigned. The migration assigns them to THIS wedding — without it they\'ll disappear from the panel once the new security rules go live.';

  @override
  String get settings_legacyBefore =>
      'Run this BEFORE deploying the new rules.';

  @override
  String get settings_legacyCheck => 'Check';

  @override
  String get settings_legacyMigrate => 'Migrate';

  @override
  String settings_legacyError(String collection, String error) {
    return '$collection: ERROR — $error';
  }

  @override
  String settings_legacyToDo(String collection, int stamped, int skipped) {
    return '$collection: to migrate $stamped, already assigned $skipped';
  }

  @override
  String settings_legacyDone(String collection, int stamped, int skipped) {
    return '$collection: assigned $stamped, skipped $skipped';
  }

  @override
  String settings_legacyCheckFailed(String error) {
    return 'Couldn\'t check: $error';
  }

  @override
  String get settings_legacyConfirmTitle =>
      'Assign old entries to this wedding?';

  @override
  String get settings_legacyConfirmBody =>
      'Every entry with no wedding assigned (gallery, guest book, advice, map, time capsule, game scores) will be assigned to the ACTIVE wedding. Entries that already have a wedding are left alone. This can\'t be undone with one click.';

  @override
  String get settings_legacyAssign => 'Assign';

  @override
  String get settings_legacyFinished => 'Migration complete ✓';

  @override
  String settings_legacyFailed(String error) {
    return 'Migration failed: $error';
  }

  @override
  String settings_currencyToast(String code) {
    return 'Currency: $code';
  }

  @override
  String get settings_displayModeCard => 'Display mode';

  @override
  String get settings_displayModeHint =>
      'By default the layout follows the screen width. You can force it — handy on a small tablet, or when you prefer the phone layout on a big screen.';

  @override
  String get settings_interactionsCard => 'Guest interactions (moderation)';

  @override
  String get settings_interactionsHint =>
      'See and moderate what guests sent through the web page: RSVPs, guest book entries, advice, the guest map and the time capsule.';

  @override
  String get settings_interactionsOpen => 'View guest interactions';

  @override
  String get settings_loading => 'Loading…';

  @override
  String get settings_guestLinkCard => 'Guest link and QR (web page)';

  @override
  String get settings_guestLinkHint =>
      'Share this link or QR code with your guests. It opens the guest page WITHOUT signing in — they only see guest sections, following your visibility settings.';

  @override
  String get settings_guestLinkCopied => 'Guest link copied';

  @override
  String get settings_copyLink => 'Copy link';

  @override
  String get settings_qrCode => 'QR code';

  @override
  String get settings_peopleCard => 'People and access';

  @override
  String get settings_peopleHint =>
      'Manage who has access to the wedding: add co-organisers and planners, set an expiry date, block and remove access.';

  @override
  String get settings_peopleOpen => 'Manage people';

  @override
  String get settings_inviteCard => 'Guest invitation (join with an account)';

  @override
  String get settings_inviteHint =>
      'Give your guests the QR code or the three details on this card. They enter them in the app („Join a wedding\") and see the wedding on their own account. That\'s a different route from the guest page link below — that one works without signing in.';

  @override
  String settings_codeCopied(String code) {
    return 'Code copied: $code';
  }

  @override
  String get settings_copyCode => 'Copy code';

  @override
  String get settings_qrScanHint => 'scan it in the app';

  @override
  String get settings_inviteCopied => 'Ready-made invitation copied';

  @override
  String get settings_copyInvite => 'Copy ready-made invitation';

  @override
  String get settings_inviteDataTitle => 'What the guest needs to enter';

  @override
  String get settings_weddingCode => 'Wedding code';

  @override
  String get settings_weddingDate => 'Wedding date';

  @override
  String get settings_notSet => 'not set';

  @override
  String get settings_coupleSurname => 'Couple\'s surname';

  @override
  String settings_copiedValue(String value) {
    return 'Copied: $value';
  }

  @override
  String get settings_surnameMissing =>
      'Fill in „Couple\'s surname(s)\" in Configuration — without it the guest has nothing to type and can\'t join.';

  @override
  String get settings_surnameFallback =>
      'For now the guest enters „Persons\". Fill in the „Couple\'s surname(s)\" field in Configuration if you\'d rather they entered a surname.';

  @override
  String get settings_inviteTextHeader =>
      'You\'re invited! Join our wedding in the Moje Wesele app:';

  @override
  String get settings_inviteTextStep1 =>
      '1. Install the app and create an account.';

  @override
  String get settings_inviteTextStep2 => '2. Choose „Join a wedding\".';

  @override
  String get settings_inviteTextStep3 => '3. Enter the following:';

  @override
  String settings_inviteTextCode(String code) {
    return '   • Wedding code: $code';
  }

  @override
  String settings_inviteTextDate(String date) {
    return '   • Wedding date: $date';
  }

  @override
  String settings_inviteTextSurname(String surname) {
    return '   • Couple\'s surname: $surname';
  }

  @override
  String get settings_inviteTextQr =>
      'You can also scan our QR code — it fills the code in for you.';

  @override
  String get settings_joinStepsTitle => 'How a guest joins — step by step';

  @override
  String get settings_joinStep1 =>
      'The guest installs the app and creates an account (or signs in to theirs).';

  @override
  String get settings_joinStep2 =>
      'On the wedding list they choose „Join a wedding\".';

  @override
  String get settings_joinStep3 =>
      'They enter the wedding code — or tap „Scan\" and scan your QR code, which fills the field in automatically.';

  @override
  String get settings_joinStep4 =>
      'They pick the wedding date from the calendar.';

  @override
  String get settings_joinStep5 =>
      'They enter the couple\'s surname (the one on this card).';

  @override
  String get settings_joinStep6 => 'Done — the wedding appears on their list.';

  @override
  String get settings_visibilityCard => 'Guest visibility';

  @override
  String get settings_visibilityHint =>
      'Decide which sections guests see on the public pages and when (e.g. RSVP up to a week before, gallery from the wedding day).';

  @override
  String get settings_visibilityOpen => 'Set section visibility';

  @override
  String get settings_notificationsHint =>
      'Choose what you want to hear about on your phone. The in-app bell always works, regardless of these settings.';

  @override
  String get settings_notificationsOpen => 'Notification settings';

  @override
  String get settings_securityCard => 'Sign-in';

  @override
  String get settings_securityHint =>
      'Biometrics (fingerprint), a PIN or a pattern to unlock the app on later launches.';

  @override
  String get settings_securityOpen => 'Sign-in and security';

  @override
  String get settings_configOwnerHint =>
      'Changes to the wedding date and surnames must be saved by the wedding owner — otherwise the guest joining details stay out of date.';

  @override
  String get settings_coupleType => 'Type of celebration';

  @override
  String settings_coupleTypeHint(String hint) {
    return '$hint. You can change this at any time — only the labels change, guest data stays untouched.';
  }

  @override
  String get settings_eventName => 'Event name';

  @override
  String get settings_persons => 'Persons';

  @override
  String get settings_verificationSurnames => 'Couple\'s surname(s)';

  @override
  String get settings_verificationHint =>
      'Used only to verify a guest joining with a code — it\'s never displayed anywhere. If the surnames differ, enter both (e.g. „Smith Jones\").';

  @override
  String get settings_time => 'Time';

  @override
  String get settings_ceremonyPlace => 'Ceremony venue';

  @override
  String get settings_receptionPlace => 'Reception venue';

  @override
  String get settings_person1 => 'Person 1 (cost split)';

  @override
  String get settings_person2 => 'Person 2';

  @override
  String get settings_witnesses => 'Number of witnesses';

  @override
  String get settings_witnessesHint =>
      'Two by default. For non-traditional weddings you can set more.';

  @override
  String get settings_children => 'Children at the wedding';

  @override
  String get settings_childrenHint =>
      'You can mark guests as children, add a children\'s table and a separate menu. Prices are set in Budget → Venue.';

  @override
  String get settings_childrenSwitch => 'Turn on if children will attend.';

  @override
  String get settings_menuDict => 'Menu dictionary (one per line)';

  @override
  String get settings_expenseCategories => 'Expense categories (one per line)';

  @override
  String get settings_saveConfig => 'Save configuration';

  @override
  String get settings_budgetCard => 'Budget settings';

  @override
  String get settings_budgetHint =>
      'The planned budget is the amount you start with. The reserve is an optional buffer for the unexpected — added to the planned amount as a safety net.';

  @override
  String settings_budgetPlanned(String currency) {
    return 'Planned budget ($currency)';
  }

  @override
  String settings_budgetReserve(String currency) {
    return 'Reserve ($currency)';
  }

  @override
  String get settings_budgetSave => 'Save budget settings';

  @override
  String get settings_budgetSaved => 'Budget settings saved ✓';

  @override
  String get settings_accessCard => 'Access';

  @override
  String get settings_accessHint =>
      'Registration is open — any Google account can sign in and create its own wedding. Access to this wedding is limited to the people linked to it (the owner and invitees).';

  @override
  String get settings_devCard => 'Developer settings';

  @override
  String get settings_exportData => 'Export data';

  @override
  String get settings_importData => 'Import data';

  @override
  String get settings_backupCreate => 'Create backup';

  @override
  String get settings_backupsCard => 'Backups';

  @override
  String get settings_backupsHint =>
      'Backups (last 3) are kept locally on this device.';

  @override
  String get settings_exportTitle => 'Data export (JSON)';

  @override
  String get settings_importWarning =>
      '⚠ The import REPLACES all current data. Paste valid JSON.';

  @override
  String get settings_importHint => 'Paste JSON…';

  @override
  String get settings_importButton => 'Import (replace)';

  @override
  String get settings_importBadFormat => 'Invalid JSON format';

  @override
  String get settings_importDone => 'Data imported';

  @override
  String settings_importFailed(String error) {
    return 'Import error: $error';
  }

  @override
  String get settings_backupCreated => 'Backup created';

  @override
  String get settings_backupsEmpty => 'No backups yet.';

  @override
  String get settings_backupRestore => 'Restore';

  @override
  String get settings_backupRestoreTitle => 'Restore the backup?';

  @override
  String settings_backupRestoreBody(String date) {
    return 'Data from $date will replace the current data.';
  }

  @override
  String get settings_backupRestored => 'Backup restored';

  @override
  String settings_backupRestoreFailed(String error) {
    return 'Restore error: $error';
  }

  @override
  String get role_planner => 'Planner';

  @override
  String get role_collaborator => 'Co-organiser';

  @override
  String get role_guest => 'Guest';

  @override
  String get status_active => 'Active';

  @override
  String get status_blocked => 'Blocked';

  @override
  String get status_pending => 'Pending';

  @override
  String get status_expired => 'Expired';

  @override
  String get vis_saved => 'Visibility settings saved ✓';

  @override
  String get vis_title => 'Guest visibility';

  @override
  String get vis_sectionsHeader => 'GUEST SECTIONS';

  @override
  String get vis_saving => 'Saving…';

  @override
  String get vis_save => 'Save settings';

  @override
  String get vis_intro =>
      'Decide when guests see each section on the public pages. You can set a FROM date, a TO date, both or neither. Dates use Polish time (Europe/Warsaw).';

  @override
  String get vis_masterTitle => 'Guest page';

  @override
  String get vis_masterOn => 'On — the section settings below apply';

  @override
  String get vis_masterOff => 'Off — guests see no sections at all';

  @override
  String get vis_from => 'Visible from';

  @override
  String get vis_to => 'Visible until';

  @override
  String get vis_outOfRange => 'When unavailable to a guest:';

  @override
  String get vis_showMessage => 'Show a message';

  @override
  String get vis_hideSection => 'Hide the section';

  @override
  String get vis_stateVisible => 'Visible to guests now';

  @override
  String vis_stateFrom(String date) {
    return 'Will be visible from $date';
  }

  @override
  String vis_stateTo(String date) {
    return 'No longer available (until $date)';
  }

  @override
  String get vis_stateOff => 'Off for guests';

  @override
  String get vis_stateMasterOff => 'The whole guest page is off';

  @override
  String get notif_pushWhen => 'Send me a push when:';

  @override
  String get notif_soonTitle => 'Phone notifications — coming soon';

  @override
  String get notif_soonBody =>
      'Push doesn\'t work yet — it needs system notifications enabled and a service running on our side. We save your choice right now, so once push is live everything works without setting it up again.';

  @override
  String get notif_bellTitle => 'The in-app bell always works';

  @override
  String get notif_bellBody =>
      'The notification centre in the top right corner shows changes regardless of the settings below. These switches only affect notifications sent to your phone while you\'re not using the app.';

  @override
  String get notif_allOff =>
      'Everything is off — once push goes live you won\'t get any phone notification. The in-app bell will still work.';

  @override
  String get sec_enabled => 'Security enabled ✓';

  @override
  String get sec_disableTitle => 'Turn security off?';

  @override
  String get sec_disableBody =>
      'The app will stop asking for a fingerprint / PIN on opening. The saved PIN/pattern will be removed from this device.';

  @override
  String get sec_disable => 'Turn off';

  @override
  String get sec_disabled => 'Security turned off';

  @override
  String get sec_confirmBiometric =>
      'Confirm your fingerprint to enable fast sign-in';

  @override
  String get sec_biometricFailed => 'Biometrics not confirmed';

  @override
  String get sec_biometricOn => 'Fingerprint sign-in enabled';

  @override
  String get sec_biometricOff => 'Fingerprint sign-in disabled';

  @override
  String get sec_backupChanged => 'Backup method changed ✓';

  @override
  String get sec_title => 'Sign-in';

  @override
  String get sec_statusCard => 'Security status';

  @override
  String get sec_lockOn => 'App lock is active';

  @override
  String get sec_lockOff => 'App lock is off';

  @override
  String get sec_biometricStatusOn => 'Fingerprint sign-in: on';

  @override
  String get sec_biometricStatusOff => 'Fingerprint sign-in: off';

  @override
  String sec_backupStatus(String type) {
    return 'Backup method: $type';
  }

  @override
  String get sec_noReader =>
      'This device has no biometric reader — only a PIN/pattern is available.';

  @override
  String get sec_lockCard => 'App lock';

  @override
  String get sec_requireBiometric => 'Require a fingerprint or PIN';

  @override
  String get sec_requirePin => 'Require a PIN or pattern';

  @override
  String get sec_onNextOpen => 'On subsequent app launches.';

  @override
  String get sec_fingerprint => 'Fingerprint';

  @override
  String get sec_fastLogin => 'Fast sign-in with a fingerprint';

  @override
  String get sec_pinStaysBackup =>
      'The PIN/pattern stays as the backup method.';

  @override
  String get sec_noReaderLong =>
      'No biometric reader on this device. You unlock the app with a PIN or pattern.';

  @override
  String get sec_backupCard => 'Backup method';

  @override
  String sec_backupCurrent(String type) {
    return 'Currently: $type. You can change it without turning the whole lock off.';
  }

  @override
  String get sec_changePin => 'Change PIN / pattern';

  @override
  String people_addConfirm(String email, String role) {
    return 'Add „$email\" as $role?';
  }

  @override
  String people_codeConfirm(String role) {
    return 'Generate an invitation code for the $role role?';
  }

  @override
  String people_added(String role) {
    return 'Added as $role ✓';
  }

  @override
  String people_noAccount(String email) {
    return 'No account found for „$email\". They need to create an account in the app first.';
  }

  @override
  String get people_alreadyMember =>
      'This person already has access to the wedding.';

  @override
  String get people_error => 'Error. Please try again.';

  @override
  String people_inviteCodeTitle(String role) {
    return 'Invitation code — $role';
  }

  @override
  String get people_inviteCodeBody =>
      'Pass this code on. After signing in they open „I have an invitation code\" on the „Your weddings\" screen and claim access.';

  @override
  String people_codeCopied(String code) {
    return 'Code copied: $code';
  }

  @override
  String get people_blockTitle => 'Block access?';

  @override
  String get people_unblockTitle => 'Restore access?';

  @override
  String people_blockBody(String who) {
    return '„$who\" will lose access to the wedding until you restore it.';
  }

  @override
  String people_unblockBody(String who) {
    return '„$who\" will have access to the wedding again.';
  }

  @override
  String get people_blocked => 'Access blocked';

  @override
  String get people_unblocked => 'Access restored';

  @override
  String get people_removeTitle => 'Remove this person?';

  @override
  String people_removeBody(String who) {
    return '„$who\" will be removed from the wedding entirely. You can add them again later.';
  }

  @override
  String get people_removed => 'Person removed';

  @override
  String get people_expiryTitle => 'Planner access expiry date';

  @override
  String get people_expiryUpdated => 'Expiry date updated';

  @override
  String get people_title => 'People and access';

  @override
  String get people_add => 'Add person';

  @override
  String get people_intro =>
      'Manage who has access to the wedding. A co-organiser gets the full panel with no time limit; a planner gets the full panel with an expiry date. You (the couple) always stay the owner.';

  @override
  String get people_you => ' (you)';

  @override
  String people_validUntil(String date) {
    return 'valid until $date';
  }

  @override
  String people_code(String code) {
    return 'code: $code';
  }

  @override
  String get people_actions => 'Actions';

  @override
  String get people_changeExpiry => 'Change expiry date';

  @override
  String get people_block => 'Block access';

  @override
  String get people_unblock => 'Restore access';

  @override
  String get people_remove => 'Remove person';

  @override
  String get people_pendingInvite => 'Invitation (pending)';

  @override
  String get people_person => 'Person';

  @override
  String get people_setExpiry => 'Set an expiry date for the planner.';

  @override
  String get people_role => 'Role';

  @override
  String get people_plannerHint =>
      'Full panel with an access expiry date (cut off after it).';

  @override
  String get people_collaboratorHint =>
      'Full panel with no time limit (best man, mum…).';

  @override
  String get people_expiry => 'Expiry date';

  @override
  String get people_pickDate => 'Pick a date';

  @override
  String get people_howToAdd => 'How to add';

  @override
  String get people_byEmail => 'By e-mail';

  @override
  String get people_byCode => 'Invitation code';

  @override
  String get people_email => 'Their e-mail (they must have an account)';

  @override
  String get people_emailHint => 'e.g. john.smith@gmail.com';

  @override
  String get people_codeHint =>
      'We\'ll generate a code for you to pass on. They claim it under „I have an invitation code\" on their „Your weddings\" screen.';

  @override
  String get gi_title => 'Guest interactions';

  @override
  String get gi_tabGuestbook => 'Guest book';

  @override
  String get gi_tabAdvice => 'Advice';

  @override
  String get gi_tabMap => 'Map';

  @override
  String get gi_tabCapsule => 'Capsule';

  @override
  String get gi_tabGallery => 'Gallery';

  @override
  String get gi_tabChallenges => 'Photo challenges';

  @override
  String get gi_tabMusic => 'Music';

  @override
  String get gi_tabQuiz => 'Quiz';

  @override
  String get gi_tabTrueFalse => 'True/False';

  @override
  String get gi_tabPhotoGuess => 'Guess the photo';

  @override
  String get gi_tabBingo => 'Bingo';

  @override
  String get gi_deleteTitle => 'Delete this entry?';

  @override
  String get gi_deletePhotoBody =>
      'The photo disappears from the guest page. The original stays in Cloudinary.';

  @override
  String get gi_deleteEntryBody =>
      'The guest\'s entry will be permanently deleted.';

  @override
  String gi_loadError(String error) {
    return 'Couldn\'t load: $error';
  }

  @override
  String get gi_empty => 'No entries yet.';

  @override
  String get gi_musicNew => 'New';

  @override
  String get gi_musicAccepted => 'We\'ll play it';

  @override
  String get gi_musicRejected => 'Declined';

  @override
  String gi_score(String name, int score, int total) {
    return '$name — $score/$total pts';
  }

  @override
  String gi_bingoMarked(String name, int marked, int total) {
    return '$name — crossed off $marked/$total';
  }

  @override
  String gi_proposedBy(String name) {
    return 'Suggested by: $name';
  }

  @override
  String gi_challengeNo(String id) {
    return 'Challenge #$id';
  }

  @override
  String gi_diet(String diet) {
    return 'Diet: $diet';
  }

  @override
  String get cw_title => 'New wedding';

  @override
  String get cw_intro =>
      'Enter the basics — you\'ll fill in the rest later in Settings.';

  @override
  String get cw_name => 'Wedding name';

  @override
  String get cw_nameHint => 'e.g. Our Wedding';

  @override
  String get cw_defaultName => 'Our Wedding';

  @override
  String cw_coupleTypeHint(String hint) {
    return '$hint. You can change this later in Settings → Configuration.';
  }

  @override
  String get cw_names => 'The couple\'s first names (optional)';

  @override
  String cw_namesHint(String category) {
    return 'The names you enter go straight onto the guest list as „$category\". Skip the empty fields — you can add them another time.';
  }

  @override
  String get cw_personsHint => 'e.g. Anna and Peter';

  @override
  String get cw_dateOptional => 'Wedding date (optional)';

  @override
  String get cw_pickDateLater => 'Pick a date (you can do this later)';

  @override
  String get cw_children => 'Children will attend';

  @override
  String get cw_childrenHint =>
      'You can change this later in Settings → Configuration. Children\'s menu prices are set in the Budget.';

  @override
  String get cw_childrenCount => 'How many children (roughly, optional)';

  @override
  String get cw_childrenCountHint => 'e.g. 8';

  @override
  String get cw_childrenAuto =>
      'Leave it empty and the number of children is counted from the guest list — just mark them as children.';

  @override
  String get cw_childrenManual =>
      'The number you enter is used in the calculations. Once you add children to the guest list, switch counting to automatic in the Budget.';

  @override
  String get cw_create => 'Create wedding';

  @override
  String get cw_firstName => 'First name';

  @override
  String get jw_fillAll => 'Fill in every field: code, date and surname.';

  @override
  String get jw_joined => 'Joined the wedding as a guest ✓';

  @override
  String get jw_alreadyMember => 'You already belong to this wedding.';

  @override
  String get jw_badData =>
      'Wrong wedding details. Check the code, the wedding date and the couple\'s surname.';

  @override
  String get jw_connectionError => 'Connection error. Please try again.';

  @override
  String get jw_title => 'Join a wedding';

  @override
  String get jw_codeHint => 'e.g. ABC234';

  @override
  String get jw_scan => 'Scan';

  @override
  String get jw_surnameHint => 'e.g. Smiths / Anna and Peter';

  @override
  String get jw_checking => 'Checking…';

  @override
  String get jw_intro =>
      'To confirm you\'re an invited guest, enter three details from the invitation: the wedding code, the wedding date and the couple\'s surname. All three must match.';

  @override
  String get jw_scanTitle => 'Scan the QR code';

  @override
  String get jw_scanHint =>
      'Point the camera at the QR code from the invitation';

  @override
  String wl_createFailed(String error) {
    return 'Couldn\'t create the wedding: $error';
  }

  @override
  String get wl_create => 'Create a wedding';

  @override
  String get wl_haveCodeLong =>
      'I have an invitation code (co-organiser / planner)';

  @override
  String get wl_haveCode => 'I have an invitation code';

  @override
  String get wl_haveCodeBody =>
      'Enter the code you got from the couple to claim access as a co-organiser or planner.';

  @override
  String get wl_redeem => 'Claim';

  @override
  String get wl_redeemed => 'Access claimed ✓';

  @override
  String get wl_alreadyAccess => 'You already have access to this wedding.';

  @override
  String get wl_badCode => 'Invalid or already used invitation code.';

  @override
  String get wl_error => 'Error. Please try again.';

  @override
  String get wl_preparing => 'Preparing the guest zone…';

  @override
  String wl_failed(String error) {
    return 'Failed: $error';
  }

  @override
  String get wl_nothingToPrepare => 'No weddings to prepare';

  @override
  String wl_prepareResult(int ok, int total) {
    return 'Done: $ok of $total';
  }

  @override
  String get wl_noFullAccess =>
      'You have no weddings with full access. Weddings where you\'re only a guest are prepared by their organiser.';

  @override
  String get wl_itemOk => 'done ✓';

  @override
  String wl_itemError(String error) {
    return 'ERROR: $error';
  }

  @override
  String get wl_title => 'Your weddings';

  @override
  String get wl_subtitle => 'Pick a wedding or create a new one';

  @override
  String get wl_more => 'More';

  @override
  String get wl_prepareGuestZone => 'Prepare the guest zone';

  @override
  String get wl_prepareForAll => 'For all your weddings';

  @override
  String get wl_empty => 'You don\'t have a wedding yet';

  @override
  String get wl_emptyBody =>
      'Create your first wedding to start planning. You can also join a wedding someone invites you to.';

  @override
  String get wl_createFirst => 'Create your first wedding';

  @override
  String get wl_loadError => 'Couldn\'t load your weddings';

  @override
  String get wl_dateTbd => 'Date to be decided';

  @override
  String setup_todo(int count) {
    return 'To do ($count)';
  }

  @override
  String get setup_basic => 'Basic';

  @override
  String get setup_advanced => 'Advanced';

  @override
  String setup_progress(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get setup_allDone => 'Everything is filled in ✓';

  @override
  String setup_partial(int done, int total, int left) {
    return '$done of $total done — $left to go';
  }

  @override
  String get setup_basicDone =>
      'The basics are done. Take a look at Advanced to fine-tune the budget, tables and guest zone.';

  @override
  String get setup_complete => 'Complete — all wedding details are filled in.';

  @override
  String setup_done(int count) {
    return 'Done ($count)';
  }

  @override
  String setup_goTo(String section) {
    return '→ $section';
  }

  @override
  String get setup_fix => 'Fix';

  @override
  String get setup_go => 'Go';

  @override
  String get plan_newStep => 'New step';

  @override
  String get plan_resetTitle => 'Restore the default list?';

  @override
  String get plan_resetBody =>
      'The „Where do I start?\" list goes back to the default. Your changes will be lost.';

  @override
  String get plan_reset => 'Restore';

  @override
  String get plan_orderTitle => 'Suggested order for planning a wedding';

  @override
  String get plan_orderHint =>
      'Tick off completed steps — the bar shows your progress.';

  @override
  String plan_progress(int done, int total, int pct) {
    return '$done of $total done · $pct%';
  }

  @override
  String get plan_deleteStep => 'Delete step';

  @override
  String get plan_addStep => 'Add step';

  @override
  String get plan_resetDefaults => 'Restore defaults';

  @override
  String people_codeConfirmUntil(String role, String date) {
    return 'Generate an invitation code for the $role role (valid until $date)?';
  }

  @override
  String get gh_title => 'Wedding';

  @override
  String get gh_loadError => 'Couldn\'t load the guest zone.';

  @override
  String get gh_loadErrorHint =>
      'Check your internet connection and try again.';

  @override
  String get gh_notReady => 'The guest zone isn\'t ready yet';

  @override
  String get gh_notReadyBody =>
      'The couple hasn\'t prepared it yet. Check back later, or ask them to share the guest sections.';

  @override
  String get gh_account => 'Account';

  @override
  String get gh_guide => 'Guide';

  @override
  String get gh_switchWedding => 'Switch wedding';

  @override
  String get sec_backupPin => 'PIN';

  @override
  String get sec_backupPattern => 'pattern';

  @override
  String get bio_reason => 'Confirm your identity to unlock the app';

  @override
  String get bio_signInTitle => 'Biometric sign-in';

  @override
  String get bio_hint => 'Verify your identity';

  @override
  String get bio_notRecognized => 'Not recognised — try again';

  @override
  String get bio_success => 'Recognised';

  @override
  String get bio_settings => 'Settings';

  @override
  String get bio_settingsHint => 'Set up biometrics in your device settings.';

  @override
  String get help_start_title => 'Getting started';

  @override
  String get help_start_1Title => 'Dashboard';

  @override
  String get help_start_1Body =>
      'A countdown to the wedding, shortcuts to sections and the key figures. You arrange the tiles yourself — hide the ones you don\'t use.';

  @override
  String get help_start_2Title => 'Where do I start?';

  @override
  String get help_start_2Body =>
      'A suggested order for planning the wedding. Tick off completed steps and the bar shows your progress. You can open it from Settings at any time — the list is shared by everyone organising the wedding.';

  @override
  String get help_start_3Title => 'Guide vs. Help';

  @override
  String get help_start_3Body =>
      'The guide walks you through the app step by step and highlights things on screen. Help (this screen) is an encyclopedia of features, for when you\'re after a specific answer.';

  @override
  String get help_guests_title => 'Guests';

  @override
  String get help_guests_1Title => 'Guest list';

  @override
  String get help_guests_1Body =>
      'Add invitees and manage their details. Every guest can have a companion — add them on the guest\'s entry rather than as a separate guest, so the totals in the summary add up.';

  @override
  String get help_guests_2Title => 'Guest details';

  @override
  String get help_guests_2Body =>
      'Everything useful for planning: diet, allergies, age, whether they need accommodation and transport, notes. These details also drive the Budget calculations and the assignments in Accommodation.';

  @override
  String get help_guests_3Title => 'Guest summary';

  @override
  String get help_guests_3Body =>
      'The totals in one place: invited, confirmed, children, diets. Check them before you talk to the venue — catering is agreed on this basis.';

  @override
  String get help_guests_4Title => 'RSVPs';

  @override
  String get help_guests_4Body =>
      'There are two sources: entries you add yourself in the panel, and replies guests send from the guest zone. You\'ll find the latter under Settings → Guest interactions → RSVP. Each guest sends one reply and can update it themselves if plans change.';

  @override
  String get help_budget_title => 'Budget';

  @override
  String get help_budget_1Title =>
      'One source of truth — the most important rule';

  @override
  String get help_budget_1Body =>
      'An item added under Vendors, Gifts or Honeymoon shows up in the Budget automatically, labelled „added in…\". Edit it where it was created — that way nothing is counted twice and you don\'t have to keep two lists in sync.';

  @override
  String get help_budget_2Title => 'Budget summary';

  @override
  String get help_budget_2Body =>
      'Your limit against your spending, what\'s left to allocate, and every payment and deadline in one place.';

  @override
  String get help_budget_3Title => 'Venue and catering';

  @override
  String get help_budget_3Body =>
      'You enter a per-person rate and the app works out the cost from the number of guests. You can count in staff (photographer, band) separately, children at a different rate, and guests not yet assigned to tables. Set the venue\'s guaranteed minimum too, if your contract has one.';

  @override
  String get help_budget_4Title => 'Expenses';

  @override
  String get help_budget_4Body =>
      'All other costs, grouped into categories. You edit the categories under Settings → Configuration.';

  @override
  String get help_budget_5Title => 'Alcohol and drinks';

  @override
  String get help_budget_5Body =>
      'Types, quantities and prices — alcohol and soft drinks kept apart. Handy when deciding what you bring yourselves and what comes from the venue.';

  @override
  String get help_budget_6Title => 'Honeymoon';

  @override
  String get help_budget_6Body =>
      'Counted separately from the wedding costs so it doesn\'t distort the reception budget — but its payments appear in the Summary alongside the rest.';

  @override
  String get help_budget_7Title => 'Instalments and payment dates';

  @override
  String get help_budget_7Body =>
      'Break a vendor or expense down into instalments with dates. Upcoming deadlines show up in the Budget summary and on the dashboard.';

  @override
  String get help_room_title => 'Seating plan';

  @override
  String get help_room_1Title => 'Arranging the room';

  @override
  String get help_room_1Body =>
      'Turn on „Edit plan\" to drag tables and objects around and resize them. Outside edit mode the plan is for browsing and seating guests — it\'s harder to move something by accident.';

  @override
  String get help_room_2Title => 'Seating guests at tables';

  @override
  String get help_room_2Body =>
      'Drag a guest onto a seat at a table. Unseated guests are listed separately — keep an eye on them, as they may count towards the catering cost depending on your Budget settings.';

  @override
  String get help_room_3Title => 'Staff tables';

  @override
  String get help_room_3Body =>
      'Mark tables for the photographer, band or crew separately — they have their own catering rate and don\'t mix with the guest list.';

  @override
  String get help_schedule_title => 'Schedule and tasks';

  @override
  String get help_schedule_1Title => 'Running order';

  @override
  String get help_schedule_1Body =>
      'Programme items with times, a category and a place. It\'s the single most important document of the day — the photographer, the band and the venue staff will all want it.';

  @override
  String get help_schedule_2Title => 'Private item';

  @override
  String get help_schedule_2Body =>
      'An item marked private does NOT reach the guest zone. Use it for logistics: „florist arrives\", „settle up with the venue\".';

  @override
  String get help_schedule_3Title => 'Map link for guests';

  @override
  String get help_schedule_3Body =>
      'You can add a map link to an item and separately decide whether guests see it. Without ticking that option the link stays just for you.';

  @override
  String get help_schedule_4Title => 'Checklist';

  @override
  String get help_schedule_4Body =>
      'Things to tick off before and during the wedding — separate from Tasks, because it\'s for quick „done / not done\".';

  @override
  String get help_schedule_5Title => 'Tasks and links between them';

  @override
  String get help_schedule_5Body =>
      'You can assign a task to a person and link it to an expense, a vendor or a gift. That way one screen tells you what\'s left to do and what it costs.';

  @override
  String get help_vendors_title => 'Vendors, transport, accommodation';

  @override
  String get help_vendors_1Title => 'Vendors';

  @override
  String get help_vendors_1Body =>
      'Contacts, contract amounts, payment statuses and instalments. A vendor\'s amount goes into the Budget automatically — don\'t add it a second time as an expense.';

  @override
  String get help_vendors_2Title => 'Transport';

  @override
  String get help_vendors_2Body =>
      'Routes, vehicles and passenger assignments. The „needs transport\" flag comes from the guest\'s details.';

  @override
  String get help_vendors_3Title => 'Accommodation';

  @override
  String get help_vendors_3Body =>
      'Places, rooms and bookings for guests. Like transport, it uses the flags from the guest details.';

  @override
  String get help_guestZone_title => 'Guest zone';

  @override
  String get help_guestZone_1Title => 'Guest link and QR code';

  @override
  String get help_guestZone_1Body =>
      'Settings → „Guest link and QR\". A guest opens the page without signing in and without installing anything. This is the code you print on invitations or leave on the tables.';

  @override
  String get help_guestZone_2Title => 'Join code (guest account)';

  @override
  String get help_guestZone_2Body =>
      'A six-character code for a guest who wants the wedding on their own account. Verification is threefold: the code, the wedding date and the surname — the code alone isn\'t enough, since it\'s often out in the open.';

  @override
  String get help_guestZone_3Title => 'Section visibility for guests';

  @override
  String get help_guestZone_3Body =>
      'You decide which sections guests see and for how long (FROM/TO dates). You also choose what happens outside that window: an „available from…\" message, or hiding the tile entirely. Typically: turn RSVP on right away, the gallery only on the wedding day.';

  @override
  String get help_guestZone_4Title => 'Guest interactions and moderation';

  @override
  String get help_guestZone_4Body =>
      'Settings → „Guest interactions\". One place gathers RSVPs, guest book entries, advice, photos, music suggestions and game scores. You can delete any entry with a single tap.';

  @override
  String get help_guestZone_5Title => 'What a guest cannot see';

  @override
  String get help_guestZone_5Body =>
      'The budget, the full guest list, vendors, the seating plan and tasks are off limits to guests — and not merely hidden in the interface: they have no technical access to that data.';

  @override
  String get help_media_title => 'Photos and music';

  @override
  String get help_media_1Title => 'Gallery';

  @override
  String get help_media_1Body =>
      'A shared album: guests upload photos from their phones, you see everything in the panel and can delete anything you\'d rather not keep.';

  @override
  String get help_media_2Title => 'Music and guest suggestions';

  @override
  String get help_media_2Body =>
      'You build the wedding playlist and guests send in song suggestions. Only you see the suggestions — there\'s no public list and no voting. Mark each one „We\'ll play it\" or „Declined\".';

  @override
  String get help_games_title => 'Games and keepsakes';

  @override
  String get help_games_1Title => 'Quiz, True/False, Guess the photo';

  @override
  String get help_games_1Body =>
      'Add questions and switch the game on with the „active\" toggle. Guests play on their own phones and the score comes to you. There\'s no public ranking — nobody is compared with anyone else.';

  @override
  String get help_games_2Title => 'Photo challenges';

  @override
  String get help_games_2Body =>
      'A list of photo tasks with points. A guest sends one photo per challenge; a new one replaces the old.';

  @override
  String get help_games_3Title => 'Wedding Bingo';

  @override
  String get help_games_3Body =>
      'You can type the bingo squares in by hand or generate them from the schedule. Boards print to PDF, and guests can also play on their phones.';

  @override
  String get help_games_4Title => 'Keepsakes';

  @override
  String get help_games_4Body =>
      'The guest book, advice for the couple, the time capsule and the guest map. The capsule is private — only you read it.';

  @override
  String get help_roles_title => 'Roles and access';

  @override
  String get help_roles_1Title => 'The owner has the final say';

  @override
  String get help_roles_1Body =>
      'The couple\'s account outranks everything. Only the owner adds people, issues invitations and can revoke anyone\'s access — the planner included.';

  @override
  String get help_roles_2Title => 'Co-organiser';

  @override
  String get help_roles_2Body =>
      'Best man, mum, a close friend — the full panel with no expiry date. They can\'t add further people, though; that stays with the owner.';

  @override
  String get help_roles_3Title => 'Planner and the expiry date';

  @override
  String get help_roles_3Body =>
      'You can give a planner access with an expiry date. After that date the wedding disappears from their list. Access can be blocked and restored at any time, as often as you like.';

  @override
  String get help_roles_4Title =>
      'How to add a planner or co-organiser — step by step';

  @override
  String get help_roles_4Body =>
      'Settings → „People and access\" → „Add person\". Pick the role (Co-organiser or Planner), and for a planner set an access expiry date. Then you have two routes: give their e-mail address (they must already have an account in the app) or generate an invitation code and pass it on however you like. An invitation adds someone to THIS wedding only — with several weddings each needs its own invitation.';

  @override
  String get help_roles_5Title => 'How the invitation code works';

  @override
  String get help_roles_5Body =>
      'The code is single-use and tied to one wedding and one role. Whoever gets it creates an account (or signs in to an existing one), then picks „I have an invitation code (co-organiser / planner)\" on the wedding list and enters it. Once used, the code stops working — generate a new one for the next person. This is a different route from the guest code, which guests use to join the guest zone.';

  @override
  String get help_roles_6Title => 'The planner\'s access expiry date';

  @override
  String get help_roles_6Body =>
      'You set the date when inviting and change it later on the people list. Once it passes, the wedding disappears from the planner\'s list and they lose access to the data — without anything being deleted on your side. The date can be pushed back, and access blocked and restored as often as you need. A co-organiser has no expiry date.';

  @override
  String get help_roles_7Title => 'Revoking access';

  @override
  String get help_roles_7Body =>
      'On the „People and access\" list every person has a block and a remove action. Blocking keeps them on the list (you can unblock them); removing deletes the membership — coming back needs a fresh invitation. The owner can\'t be removed.';

  @override
  String get help_analytics_title => 'Analytics';

  @override
  String get help_analytics_1Title => 'Charts and statistics';

  @override
  String get help_analytics_1Body =>
      'Planning progress, cost structure and attendance. A good place to check whether the budget is drifting away from the plan.';

  @override
  String get help_settings_title => 'Settings and data';

  @override
  String get help_settings_1Title => 'Wedding configuration';

  @override
  String get help_settings_1Body =>
      'Name, date, time, ceremony and reception venues, the cost split and the dictionaries (menu, expense categories). After changing the date or the surnames, save the configuration — that refreshes the guest joining details.';

  @override
  String get help_settings_2Title => 'Sync';

  @override
  String get help_settings_2Body =>
      'Data is saved in the cloud and shared by everyone organising the wedding. The status card sits at the top of Settings.';

  @override
  String get help_settings_3Title => 'Backups and export';

  @override
  String get help_settings_3Body =>
      'You can create a backup and export all your data to a JSON file. Importing overwrites the wedding\'s data — handle with care.';

  @override
  String get help_settings_4Title => 'App lock';

  @override
  String get help_settings_4Body =>
      'A PIN, a pattern or biometrics protect access on this device. The setting is local — it doesn\'t carry over to other phones.';

  @override
  String get help_planner_title => 'Working with clients';

  @override
  String get help_planner_1Title => 'Several weddings on one account';

  @override
  String get help_planner_1Body =>
      'You can run as many weddings as you like. Switch between them in the menu under the logo → „Switch wedding\". Each wedding\'s data is fully separated — client A never sees client B\'s wedding.';

  @override
  String get help_planner_2Title => 'Your access may be time-limited';

  @override
  String get help_planner_2Body =>
      'The couple can grant you access with an expiry date, and block or restore it. When a wedding disappears from your list it\'s usually an expired date rather than a fault — ask your client to extend it.';

  @override
  String get help_planner_3Title => 'What a planner cannot do';

  @override
  String get help_planner_3Body =>
      'Adding people and issuing invitations is reserved for the wedding\'s owner. That\'s deliberate: the client always controls who has access to their data.';

  @override
  String get help_planner_4Title => 'Handing the wedding over to the couple';

  @override
  String get help_planner_4Body =>
      'There\'s no separate „handover\" — the wedding belongs to the couple from the start. When your work together ends you simply lose access and all the data stays with the client. Nothing needs exporting.';

  @override
  String get help_planner_5Title => 'Clients\' personal data';

  @override
  String get help_planner_5Body =>
      'The guest list holds personal data: surnames, phone numbers, e-mail addresses, dietary information. Treat it as confidential and never move it between weddings.';

  @override
  String get help_planner_6Title => 'What to show the client';

  @override
  String get help_planner_6Body =>
      'These usually work best: the Budget summary (where the money goes), the seating plan (printed) and the running order. Analytics gives you a ready-made progress report.';

  @override
  String get help_gStart_title => 'First things first';

  @override
  String get help_gStart_1Title => 'What this page is';

  @override
  String get help_gStart_1Body =>
      'This is the guest zone put together by the couple. You don\'t need an account and there\'s nothing to install — the link or QR code from the invitation is enough.';

  @override
  String get help_gStart_2Title => 'I can\'t see one of the sections';

  @override
  String get help_gStart_2Body =>
      'The couple decide what to share and when. Some sections appear only closer to the wedding, and some disappear afterwards. Check back later.';

  @override
  String get help_gRsvp_title => 'Confirming attendance';

  @override
  String get help_gRsvp_1Title => 'How to confirm';

  @override
  String get help_gRsvp_1Body =>
      'Open RSVP, enter your first and last name, say whether you\'re coming and send it. If someone\'s coming with you, give the number of companions — don\'t fill the form in a second time on their behalf.';

  @override
  String get help_gRsvp_2Title => 'Changing your answer';

  @override
  String get help_gRsvp_2Body =>
      'One reply is enough. If your plans change, go back to RSVP — the form fills in with your previous answer, and saving replaces it with the new one.';

  @override
  String get help_gRsvp_3Title => 'Diet and allergies';

  @override
  String get help_gRsvp_3Body =>
      'Enter them on the RSVP form. That goes straight to the couple and helps them agree the menu with the venue.';

  @override
  String get help_gPhotos_title => 'Photos';

  @override
  String get help_gPhotos_1Title => 'Adding photos';

  @override
  String get help_gPhotos_1Body =>
      'In the Gallery, enter your name and pick a photo from your phone or take one there and then. You can add a caption. There\'s no limit on how many photos you add.';

  @override
  String get help_gPhotos_2Title => 'Who sees my photos';

  @override
  String get help_gPhotos_2Body =>
      'The gallery is shared — every guest with the link sees it, and so do the couple. They can delete any photo.';

  @override
  String get help_gMusic_title => 'Music';

  @override
  String get help_gMusic_1Title => 'Suggesting a song';

  @override
  String get help_gMusic_1Body =>
      'Search for a song, or type the title and artist in yourself, then send the suggestion. If the search doesn\'t work (it sometimes doesn\'t in a browser), use the manual fields — the result is the same.';

  @override
  String get help_gMusic_2Title => 'Who sees the suggestions';

  @override
  String get help_gMusic_2Body =>
      'Only the couple. There\'s no public list and no voting, so nobody can see what anyone else suggested.';

  @override
  String get help_gSchedule_title => 'Schedule';

  @override
  String get help_gSchedule_1Title => 'Running order';

  @override
  String get help_gSchedule_1Body =>
      'Hour by hour: the ceremony, the reception, the cake, the first dance. At the top you\'ll find a countdown to the wedding.';

  @override
  String get help_gGames_title => 'Games';

  @override
  String get help_gGames_1Title => 'Quiz, True/False, Guess the photo';

  @override
  String get help_gGames_1Body =>
      'Answer every question and send your score. You can have another go — the new score replaces the old one, so you lose nothing.';

  @override
  String get help_gGames_2Title => 'Photo challenges';

  @override
  String get help_gGames_2Body =>
      'A list of photo tasks. You send one photo per challenge; a new one replaces the old. All guests see the photos.';

  @override
  String get help_gGames_3Title => 'Wedding Bingo';

  @override
  String get help_gGames_3Body =>
      'Cross squares off as you spot them at the wedding. The crosses stay on your phone — only send your entry once you have a full set.';

  @override
  String get help_gGames_4Title => 'Who sees the scores';

  @override
  String get help_gGames_4Body =>
      'The couple, and nobody else. There\'s no public ranking, so play for fun rather than to compete.';

  @override
  String get help_gKeepsakes_title => 'Keepsakes';

  @override
  String get help_gKeepsakes_1Title => 'Guest book and advice';

  @override
  String get help_gKeepsakes_1Body =>
      'Leave your wishes or a piece of good advice for the couple. You can add several entries, and other guests see them too — it\'s a shared chronicle of sorts.';

  @override
  String get help_gKeepsakes_2Title => 'Time capsule';

  @override
  String get help_gKeepsakes_2Body =>
      'A private message to the couple. No other guest will see it.';

  @override
  String get help_gKeepsakes_3Title => 'Guest map';

  @override
  String get help_gKeepsakes_3Body =>
      'Mark where you\'re travelling from. One pin per guest — you can correct it by coming back to the section.';

  @override
  String get help_gPrivacy_title => 'Privacy';

  @override
  String get help_gPrivacy_1Title => 'What the couple see';

  @override
  String get help_gPrivacy_1Body =>
      'Your RSVP, your entries, photos, music suggestions and game scores — always with the name you give.';

  @override
  String get help_gPrivacy_2Title => 'What other guests don\'t see';

  @override
  String get help_gPrivacy_2Body =>
      'Your RSVP, your time capsule message, your music suggestions and your game scores. Only these are public: the guest book, advice, the map, the gallery and photo-challenge pictures.';

  @override
  String get setupTask_eventNameLabel => 'Wedding name';

  @override
  String get setupTask_eventNameHint =>
      'E.g. „Anna and Peter\'s Wedding\" — it appears in the app header and on the guest page.';

  @override
  String get setupTask_weddingDateLabel => 'Wedding date and time';

  @override
  String get setupTask_weddingDateHint =>
      'The date drives the dashboard countdown and the guest verification when someone joins with a code.';

  @override
  String get setupTask_coupleTypeLabel => 'Type of celebration';

  @override
  String get setupTask_coupleTypeHint =>
      'Decides the labels across the whole app — „Bride / Groom\", two brides, two grooms, or neutral wording.';

  @override
  String get setupTask_coupleNamesLabel => 'The couple\'s first names';

  @override
  String get setupTask_coupleNamesHint =>
      'Enter both names — the cost split, the labels and the guest list all use them.';

  @override
  String get setupTask_ceremonyPlaceLabel => 'Ceremony venue';

  @override
  String get setupTask_ceremonyPlaceHint =>
      'The church or registry office — guests see the address in the schedule.';

  @override
  String get setupTask_receptionPlaceLabel => 'Reception venue';

  @override
  String get setupTask_receptionPlaceHint =>
      'The venue\'s name and address — this reaches the guest schedule too.';

  @override
  String get setupTask_verificationSurnamesLabel =>
      'Surname for guest verification';

  @override
  String get setupTask_verificationSurnamesHint =>
      'The surname (or both surnames) a guest enters when joining with a code. It\'s never displayed anywhere — it only serves the check.';

  @override
  String get setupTask_guestsLabel => 'First guests';

  @override
  String get setupTask_guestsHint =>
      'Add at least a few people — catering, tables and statistics all depend on the guest list.';

  @override
  String get setupTask_budgetTotalLabel => 'Planned budget';

  @override
  String get setupTask_budgetTotalHint =>
      'The figure you want to stay within. Without it there\'s nothing to compare your spending against.';

  @override
  String get setupTask_pricePerPersonLabel => 'Price per person (venue)';

  @override
  String get setupTask_pricePerPersonHint =>
      'The per-plate rate — multiplied by the number of guests to give the catering cost.';

  @override
  String get setupTask_withChildrenLabel => 'Decision about children';

  @override
  String get setupTask_withChildrenHint =>
      'Decide whether children will attend. If they will, you get a children\'s menu, a children\'s table, and they\'re left out of the drinks calculations.';

  @override
  String get setupTask_menuOptionsLabel => 'Menu dictionary';

  @override
  String get setupTask_menuOptionsHint =>
      'The meal options to pick from for each guest (meat, fish, vegetarian, children\'s).';

  @override
  String get setupTask_expenseCategoriesLabel => 'Expense categories';

  @override
  String get setupTask_expenseCategoriesHint =>
      'Your own cost categories — expenses and the Analytics charts are grouped by them.';

  @override
  String get setupTask_witnessesLabel => 'Witnesses';

  @override
  String get setupTask_witnessesHint =>
      'Mark the witnesses on the guest list — they\'ll show up in the summary and on the seating plan.';

  @override
  String get setupTask_tablesLabel => 'Tables';

  @override
  String get setupTask_tablesHint =>
      'Add tables with their number of seats — without them you can\'t seat anyone.';

  @override
  String get setupTask_seatingLabel => 'Seating guests';

  @override
  String get setupTask_seatingHint =>
      'Assign guests to tables — even just some of them. You\'ll finish the rest closer to the wedding.';

  @override
  String get setupTask_scheduleLabel => 'Running order';

  @override
  String get setupTask_scheduleHint =>
      'Programme items with times. Guests see this same schedule in their zone.';

  @override
  String get setupTask_guestVisibilityLabel => 'Section visibility for guests';

  @override
  String get setupTask_guestVisibilityHint =>
      'Decide what guests see and from when — e.g. RSVP right away, the gallery only on the wedding day.';

  @override
  String get setupLevel_basic => 'Basic setup';

  @override
  String get setupLevel_advanced => 'Advanced setup';

  @override
  String get setupLevel_basicIntro =>
      'The minimum to get going: the wedding details and your first guests.';

  @override
  String get setupLevel_advancedIntro =>
      'The finishing touches: budget, menu, tables, schedule and the guest zone. Anything you\'ve already filled in is ticked off.';

  @override
  String get section_dashboard => 'Dashboard';

  @override
  String get section_guests => 'Guests';

  @override
  String get section_budget => 'Budget';

  @override
  String get section_room => 'Seating plan';

  @override
  String get section_schedule => 'Schedule';

  @override
  String get section_tasks => 'Tasks';

  @override
  String get section_vendors => 'Vendors';

  @override
  String get section_transport => 'Transport';

  @override
  String get section_accommodation => 'Accommodation';

  @override
  String get section_music => 'Music';

  @override
  String get section_gifts => 'Gifts';

  @override
  String get section_gallery => 'Gallery & QR';

  @override
  String get section_games => 'Wedding games';

  @override
  String get section_keepsakes => 'Wedding keepsakes';

  @override
  String get section_analytics => 'Analytics';

  @override
  String get section_rsvp => 'RSVPs';

  @override
  String get section_rsvpAll => 'All RSVPs';

  @override
  String get section_settings => 'Settings';

  @override
  String get onb_desc_dashboard =>
      'Your dashboard — a countdown to the wedding, shortcuts and the key figures in one place.';

  @override
  String get onb_desc_guests =>
      'The invitee list, their details, RSVP statuses and preferences — across the sub-tabs.';

  @override
  String get onb_desc_budget =>
      'Keep every wedding cost in one place — sub-tabs alongside.';

  @override
  String get onb_desc_room =>
      'Lay out tables and objects on an interactive plan. Turn on „Edit plan\" to drag things around and resize them.';

  @override
  String get onb_desc_schedule =>
      'Write out the running order of the day and the checklist — in the sub-tabs.';

  @override
  String get onb_desc_tasks =>
      'Write out tasks, assign people, and link them to the budget, a vendor or a gift.';

  @override
  String get onb_desc_vendors =>
      'Your supplier base — contacts, contracts, payment instalments and budget links.';

  @override
  String get onb_desc_transport =>
      'Organise how guests get there — routes, vehicles and passenger assignments.';

  @override
  String get onb_desc_accommodation =>
      'Manage accommodation for guests — places, rooms and bookings.';

  @override
  String get onb_desc_music =>
      'Build the wedding playlist and collect song suggestions from guests (QR code).';

  @override
  String get onb_desc_gifts =>
      'A record of gifts received, favours for guests and your wish list — across the sub-tabs.';

  @override
  String get onb_desc_gallery =>
      'A shared gallery of wedding photos, plus QR codes to share with guests.';

  @override
  String get onb_desc_games =>
      'Wedding games — entertainment for guests, including Wedding Bingo generated from the schedule. More games coming.';

  @override
  String get onb_desc_keepsakes =>
      'Wedding keepsakes — the guest book, advice for the couple, the time capsule and the guest map. In preparation.';

  @override
  String get onb_desc_analytics =>
      'Charts and planning statistics — progress, costs and attendance.';

  @override
  String get onb_desc_rsvp =>
      'Manage RSVPs and share the online form with your guests.';

  @override
  String get onb_desc_settings =>
      'Here you\'ll find configuration, access, sign-in and tools. You can restart the guide any time from the menu under the logo. That\'s everything — good luck!';

  @override
  String onb_desc_fallback(String section) {
    return 'The „$section\" section of the app.';
  }

  @override
  String get onb_sub_guests_1Title => 'List';

  @override
  String get onb_sub_guests_1Desc =>
      'The invitee list — add guests and manage their details.';

  @override
  String get onb_sub_guests_2Title => 'Details';

  @override
  String get onb_sub_guests_2Desc =>
      'The full record: RSVP status, diet, age and notes.';

  @override
  String get onb_sub_guests_3Title => 'Summary';

  @override
  String get onb_sub_guests_3Desc =>
      'Aggregate statistics: guest count, replies, children and diets.';

  @override
  String get onb_sub_budget_1Title => 'Summary';

  @override
  String get onb_sub_budget_1Desc =>
      'Total budget against spending — how much is already allocated.';

  @override
  String get onb_sub_budget_2Title => 'Venue';

  @override
  String get onb_sub_budget_2Desc =>
      'The venue cost — the per-person rate is multiplied by the guest count (seated, unseated and staff).';

  @override
  String get onb_sub_budget_3Title => 'Expenses';

  @override
  String get onb_sub_budget_3Desc =>
      'Add all other expenses and group them by category.';

  @override
  String get onb_sub_budget_4Title => 'Alcohol';

  @override
  String get onb_sub_budget_4Desc =>
      'Plan the types, quantities and costs of alcohol.';

  @override
  String get onb_sub_budget_5Title => 'Soft drinks';

  @override
  String get onb_sub_budget_5Desc =>
      'Water, juices, fizzy drinks — quantities and costs.';

  @override
  String get onb_sub_budget_6Title => 'Honeymoon';

  @override
  String get onb_sub_budget_6Desc =>
      'The honeymoon budget, kept apart from the wedding costs. „Summary\" also lists every payment and deadline.';

  @override
  String get onb_sub_schedule_1Title => 'Running order';

  @override
  String get onb_sub_schedule_1Desc =>
      'Programme items with times — from the ceremony to the last dance.';

  @override
  String get onb_sub_schedule_2Title => 'Checklist';

  @override
  String get onb_sub_schedule_2Desc =>
      'Things to tick off before and during the wedding.';

  @override
  String get onb_sub_gifts_1Title => 'Received';

  @override
  String get onb_sub_gifts_1Desc =>
      'Note what you got and from whom — useful when writing thank-yous.';

  @override
  String get onb_sub_gifts_2Title => 'For guests';

  @override
  String get onb_sub_gifts_2Desc =>
      'Plan thank-yous and favours for your guests.';

  @override
  String get onb_sub_gifts_3Title => 'Wish list';

  @override
  String get onb_sub_gifts_3Desc =>
      'Your wish list — let guests know what would make you happy.';

  @override
  String get onb_set_1Title => 'Settings · Sync status';

  @override
  String get onb_set_1Desc =>
      'Check whether your data is synced to the cloud (Firestore).';

  @override
  String get onb_set_2Title => 'Settings · Guest visibility';

  @override
  String get onb_set_2Desc =>
      'You decide which sections guests see, and between which dates. For example, turn RSVP on right away and the gallery only on the wedding day.';

  @override
  String get onb_set_3Title => 'Settings · Guest join code';

  @override
  String get onb_set_3Desc =>
      'A six-character code a guest uses to join the wedding on their own account. Verification is threefold: the code, the wedding date and the surname.';

  @override
  String get onb_set_4Title => 'Settings · Guest link and QR';

  @override
  String get onb_set_4Desc =>
      'The link and QR code to the guest zone — it works without signing in and without installing the app. This is what you print on invitations or leave on the tables.';

  @override
  String get onb_set_5Title => 'Settings · Guest interactions';

  @override
  String get onb_set_5Desc =>
      'Everything guests have sent in: RSVPs, guest book entries, advice, photos, music suggestions and game scores. You moderate here too — delete anything unsuitable with a single tap.';

  @override
  String get onb_set_6Title => 'Settings · People and access';

  @override
  String get onb_set_6Desc =>
      'This is where you add a co-organiser (best man, mum) and a planner. „Add person\" → pick a role → give the e-mail of someone with an account, or generate a single-use invitation code and send it to them. The invitee enters the code on their wedding list („I have an invitation code\"). For a planner you set an expiry date — after it, the wedding disappears from their list. You can block and restore access at any time. Only the wedding\'s owner can change anything here — that\'s a safeguard, not a limitation.';

  @override
  String get onb_set_7Title => 'Settings · Configuration';

  @override
  String get onb_set_7Desc =>
      'The event name, date, venues, cost split and dictionaries.';

  @override
  String get onb_set_8Title => 'Settings · Sign-in';

  @override
  String get onb_set_8Desc =>
      'Biometrics, a PIN/pattern and this device\'s security status.';

  @override
  String get onb_set_9Title => 'Settings · Developer';

  @override
  String get onb_set_9Desc => 'Data export/import and backups.';

  @override
  String get onb_plannerDesc_dashboard =>
      'Your CLIENT\'s wedding dashboard — the countdown, progress and statistics. Every wedding on your account has its own dashboard; switch between them under „Switch wedding\".';

  @override
  String get onb_plannerDesc_guests =>
      'Your client\'s guest list with replies and preferences. This is your clients\' personal data — treat it as confidential.';

  @override
  String get onb_plannerDesc_budget =>
      'Your client\'s wedding budget. This is usually where you show the couple where the money goes and where the savings are — sub-tabs alongside.';

  @override
  String get onb_plannerDesc_room =>
      'The seating plan, to agree with the client and the venue. A printed table layout is one of the most requested parts of your service.';

  @override
  String get onb_plannerDesc_schedule =>
      'The running order — your single most important working document. It\'s what goes to the venue staff, the photographer and the band.';

  @override
  String get onb_plannerDesc_tasks =>
      'Tasks with people assigned. Use this to split the work between yourself, the couple and your subcontractors.';

  @override
  String get onb_plannerDesc_vendors =>
      'A supplier base with contracts and instalments. Running several weddings, you build up your own private list of trusted contacts here.';

  @override
  String get onb_plannerDesc_analytics =>
      'Charts and statistics — a ready-made progress report for your client.';

  @override
  String get onb_plannerDesc_settings =>
      'Wedding configuration, people\'s access and section visibility for guests. Remember: the couple remain the wedding\'s owner — they grant and revoke access. You can restart the guide from the menu under the logo.';

  @override
  String get onb_planner_1Title => 'Several weddings on one account';

  @override
  String get onb_planner_1Desc =>
      'As a planner you can run as many weddings as you like. Switch between them in the menu under the logo → „Switch wedding\". Each wedding\'s data is fully separated — client A never sees client B\'s wedding.';

  @override
  String get onb_planner_2Title => 'Your access may have an expiry date';

  @override
  String get onb_planner_2Desc =>
      'The couple grant the planner access, can set an expiry date and can block or restore it at any time. Once it expires the wedding disappears from your list — that\'s normal, not a fault.';

  @override
  String get onb_planner_3Title => 'Handing the wedding to the couple';

  @override
  String get onb_planner_3Desc =>
      'The couple\'s account outranks everything: only they add people and issue invitations. When your work together ends, the couple take full control — nothing needs moving or exporting.';

  @override
  String get onb_guest_1Title => 'Welcome to the guest zone';

  @override
  String get onb_guest_1Desc =>
      'This is your corner of the couple\'s wedding. You\'ll find everything you need as a guest here — no account, nothing to install.';

  @override
  String get onb_guest_2Title => 'Confirming attendance (RSVP)';

  @override
  String get onb_guest_2Desc =>
      'Let them know whether you\'re coming and with how many people. Mention your diet or allergies if you have any. One reply is enough — if your plans change, come back here and update it.';

  @override
  String get onb_guest_3Title => 'Running order';

  @override
  String get onb_guest_3Desc =>
      'Hour by hour: the ceremony, the reception, the cake, the first dance. You\'ll also see a countdown to the wedding.';

  @override
  String get onb_guest_4Title => 'Gallery — add your photos';

  @override
  String get onb_guest_4Desc =>
      'Upload photos straight from your phone and look through the ones other guests added. This is how the couple get shots no photographer could take.';

  @override
  String get onb_guest_5Title => 'Music — suggest a song';

  @override
  String get onb_guest_5Desc =>
      'Search for a song and send your suggestion to the couple. Suggestions go to them alone — there\'s no public list and no voting.';

  @override
  String get onb_guest_6Title => 'Wedding games';

  @override
  String get onb_guest_6Desc =>
      'A quiz about the couple, True/False, Guess the photo, photo challenges and Wedding Bingo. Only the couple see the scores — there\'s no public ranking, so play for fun.';

  @override
  String get onb_guest_7Title => 'Games — how they work';

  @override
  String get onb_guest_7Desc =>
      'The quiz, True/False and Guess the photo work your score out straight away on your phone. You can have another go — the new score replaces the old one. In photo challenges you send one photo per task.';

  @override
  String get onb_guest_8Title => 'Wedding keepsakes';

  @override
  String get onb_guest_8Desc =>
      'Leave your mark: an entry in the guest book, advice for the couple, a message for the time capsule and a pin on the guest map.';

  @override
  String get onb_guest_9Title => 'Guest book and advice';

  @override
  String get onb_guest_9Desc =>
      'You can leave several entries — wishes, a memory, a piece of good advice. Other guests see them, so it\'s a bit like a shared chronicle.';

  @override
  String get onb_guest_10Title => 'Time capsule and guest map';

  @override
  String get onb_guest_10Desc =>
      'The capsule is a private message — only the couple will read it. On the map you mark where you\'re travelling from; one pin per guest, and you can correct it.';

  @override
  String get onb_guest_11Title => 'That\'s everything!';

  @override
  String get onb_guest_11Desc =>
      'Sections appear and disappear according to what the couple have shared — if you can\'t see something, it may become available closer to the wedding. Have a wonderful time!';

  @override
  String get onb_planningTitle => 'Where do I start?';

  @override
  String get onb_planningDesc =>
      'A suggested order for planning the wedding. Tick off completed steps and the bar shows your progress. You can open it from Settings at any time.';

  @override
  String get onb_qrTitle => 'QR codes for guests';

  @override
  String get onb_qrDesc =>
      'Share QR codes with your guests leading to the gallery, music, the schedule and RSVPs.';

  @override
  String onb_subTitle(String section, String tab) {
    return '$section › $tab';
  }

  @override
  String onb_moreSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…and $count more steps on the list',
      one: '…and 1 more step on the list',
    );
    return '$_temp0';
  }

  @override
  String onb_stepHeader(String title) {
    return '🧭  $title';
  }

  @override
  String onb_stepCounter(int index, int total) {
    return 'Step $index of $total';
  }

  @override
  String get onb_skip => 'Skip';

  @override
  String get onb_finish => 'Finish';

  @override
  String get onb_guestTitle => 'Guide for guests';

  @override
  String get onb_guestIntro =>
      'We\'ll show you what you can do on the page the couple prepared. It only takes a moment.';

  @override
  String get onb_plannerTitle => 'Guide for planners';

  @override
  String get onb_plannerIntro =>
      'We\'ll show you your client\'s wedding panel and how a planner\'s work differs from the couple\'s account. You can restart it from Settings.';

  @override
  String get onb_plannerShort =>
      'The main panel sections and how planners work';

  @override
  String get onb_plannerFull => 'Every section, sub-tab and setting';

  @override
  String get onb_ownerTitle => 'App guide';

  @override
  String get onb_ownerIntro =>
      'We\'ll show you the most important places in the app. Choose your pace — you can restart the guide any time from Settings (under the logo).';

  @override
  String get onb_ownerShort => 'Main sections only — a quick overview';

  @override
  String get onb_ownerFull => 'Every section and sub-tab';

  @override
  String get onb_guestPreviewNote =>
      'This is a preview for you. Guests see their zone on a separate page that looks completely different — here we only show the content of their guide.';

  @override
  String get onb_guestPreview => 'View the guest guide';

  @override
  String get onb_start => 'Start';

  @override
  String get onb_guestFull => 'Every guest zone section';

  @override
  String get onb_short => 'Short';

  @override
  String get onb_full => 'Extended';

  @override
  String get onb_guestPreviewHint => 'See what your guests see';

  @override
  String get onb_setupWizardHint => 'Step by step through your wedding details';

  @override
  String get onb_skipTour => 'Skip the guide';

  @override
  String get help_guestTitle => 'Help for guests';

  @override
  String get help_backToOwn => 'Back to your help';

  @override
  String get help_seeGuest => 'View help for guests';

  @override
  String get help_guestPreviewNote =>
      'You\'re viewing the help your guests see.';

  @override
  String get help_searchHint =>
      'Search features, e.g. „budget\", „QR\", „RSVP\"';

  @override
  String get help_tourHint =>
      'Looking for something else? The guide walks you through the app step by step — start it from Settings.';

  @override
  String help_topicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String help_found(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count entries',
      one: 'Found 1 entry',
    );
    return '$_temp0';
  }

  @override
  String help_nothingFound(String query) {
    return 'Nothing found for „$query\".\nTry another word — e.g. „guest\", „table\", „payment\".';
  }
}
