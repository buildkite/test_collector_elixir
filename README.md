# Buildkite Test Collector for Elixir (Beta)

The official Elixir adapter for [Buildkite Test Analytics](https://buildkite.com/test-analytics) which uses an ExUnit formatter to connect information about your tests.

⚒ **Supported test frameworks:** ExUnit.
📦 **Supported CI systems:** Buildkite, GitHub Actions, CircleCI, and others via the `BUILDKITE_ANALYTICS_*` environment variables.

## 👉 Installing

1. [Create a test suite](https://buildkite.com/docs/test-analytics), and copy the API token that it gives you.

2. Add `buildkite_test_collector` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:buildkite_test_collector, "~> 0.3.1", only: [:test]}
  ]
end
```

3. Set up your API token

In your `config/test.exs` (or other environment configuration as appropriate) add the analytics API token.  We suggest that you retrieve the token from the environment, and configure your CI environment accordingly (eg via secrets).

```elixir
import Config


config :buildkite_test_collector,
  api_key: System.get_env("BUILDKITE_ANALYTICS_TOKEN")
```

4. Add `BuildkiteTestCollectorFormatter` to your ExUnit configuration in
   `test/test_helper.exs`:

```elixir
ExUnit.configure formatters: [BuildkiteTestCollector.Formatter, ExUnit.CLIFormatter]
ExUnit.start
```

5. Run your tests

Run your tests like normal.  Note that we attempt to detect the presence of several common CI environments, however if this fails you can set the `CI` environment variable to any value and it will work.

```sh
$ mix test

...

Finished in 0.01 seconds (0.003s on load, 0.004s on tests)
3 tests, 0 failures

Randomized with seed 12345
```

5. Verify that it works

If all is well, you should see the test run in the test analytics section of the Buildkite dashboard.

## 🎢 Tracing

Buildkite Test Analytics has support for tracing potentially slow operations within your tests (SQL queries, HTTP requests, etc).  Because ExUnit can run multiple tests simultaneously, it is difficult to achieve this without requiring code changes - we cannot simply use [telemetry](https://hex.pm/packages/telemetry) events because we cannot easily attribute the events to specific tests across process boundaries.  Instead we have provided [a simple API](https://hexdocs.pm/buildkite_test_collector/BuildkiteTestCollector.Tracing.html) to manually instrument operations within your tests.

## 🔜 Roadmap

See the [GitHub 'enhancement' issues](https://github.com/buildkite/test_collector_elixir/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement) for planned features. Pull requests are always welcome, and we’ll give you feedback and guidance if you choose to contribute 💚

## ⚒ Developing

After cloning the repository, install the dependencies:

```
mix deps.get
```

And run the tests:

```
mix test
```

Useful resources for developing collectors include the [Buildkite Test Analytics docs](https://buildkite.com/docs/test-analytics) and the [RSpec and Minitest collectors](https://github.com/buildkite/rspec-buildkite-analytics).

## 👩‍💻 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite/test_collector_elixir

Please use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) so that the changelog and version can be automatically tracked via the [git_ops](https://hex.pm/packages/git_ops) package.

## 🚀 Releasing

Important: some of this process is already automated by Github Actions.  It should be completely automated shortly.

```sh
# Generate the new version and changelog
mix git_ops.release

# Push the tags
git push && git push --tags

# Publish the Hex package
mix hex.publish

# Create a new GitHub release
open "https://github.com/buildkite/test_collector_elixir/releases"
```

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🤙 Thanks

Thanks to the folks at [Alembic](https://alembic.com.au/) for building and maintaining this package.
