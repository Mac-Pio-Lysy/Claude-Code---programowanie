/// The fixed sections of the budget sheet grid.
enum SheetSection {
  income('Wpływy'),
  fixedExpenses('Wydatki stałe'),
  utilities('Użytkowe'),
  wants('Zachcianki'),
  savings('Oszczędności');

  const SheetSection(this.label);

  final String label;
}
