import 'package:flutter/material.dart';

import '../../domain/models/bank_profile.dart';

String bankProfileLabel(BankProfile profile) => switch (profile) {
      BankProfile.pkoBp => 'PKO BP / Inteligo',
      BankProfile.mBank => 'mBank',
      BankProfile.santander => 'Santander Bank Polska',
      BankProfile.ing => 'ING Bank Śląski',
      BankProfile.millennium => 'Bank Millennium',
      BankProfile.revolut => 'Revolut',
      BankProfile.universal => 'Inny bank (szablon uniwersalny)',
    };

IconData bankProfileIcon(BankProfile profile) => switch (profile) {
      BankProfile.revolut => Icons.credit_card_outlined,
      BankProfile.universal => Icons.description_outlined,
      _ => Icons.account_balance_outlined,
    };
