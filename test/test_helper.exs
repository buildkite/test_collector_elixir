Mimic.copy(BuildkiteTestCollector.CiEnv)
Mimic.copy(BuildkiteTestCollector.HttpTransport)
Mimic.copy(Tesla)

ExUnit.start(
  capture_log: true,
  formatters: [ExUnit.CLIFormatter, BuildkiteTestCollector.Formatter]
)
