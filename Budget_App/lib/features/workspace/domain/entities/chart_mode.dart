/// Which visualization the workspace chart card is currently showing.
enum ChartMode {
  pie,
  line;

  ChartMode get next => this == pie ? line : pie;
}
