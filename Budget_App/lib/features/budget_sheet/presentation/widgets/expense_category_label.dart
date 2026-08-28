import '../../domain/models/expense_category_type.dart';

String expenseCategoryTypeLabel(ExpenseCategoryType type) => switch (type) {
      ExpenseCategoryType.mandatory => 'Wymagane',
      ExpenseCategoryType.utility => 'Użytkowe',
      ExpenseCategoryType.wants => 'Zachcianki',
    };
