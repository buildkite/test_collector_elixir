import Config

config :git_ops,
  mix_project: BuildkiteTestCollector.MixProject,
  changelog_file: "CHANGELOG.md",
  repository_url: "https://github.com/buildkite/text_collector_elixir",
  manage_mix_version: true,
  manage_readme_version: "README.md",
  version_tag_prefix: "v"

import_config "#{config_env()}.exs"
