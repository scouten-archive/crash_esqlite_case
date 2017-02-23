defmodule Sqlite.Ecto.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlite_ecto2,
     version: "2.0.0-dev.1",
     name: "Sqlite.Ecto2",
     elixir: "~> 1.3",
     elixirc_options: [warnings_as_errors: true],
     deps: deps(),
     elixirc_paths: elixirc_paths(Mix.env),
     package: package(),
     test_paths: test_paths()]
  end

  def application do
    [applications: [:db_connection, :ecto, :logger]]
  end

  defp deps do
    [{:backoff, path: "deps/backoff", override: true},
     {:db_connection, path: "deps/db_connection", override: true},
     {:esqlite, path: "deps/esqlite", override: true},
     {:ecto, path: "deps/ecto", override: true},
     {:poison, path: "deps/poison", override: true},
     {:postgrex, path: "deps/postgrex", override: true},
     {:sbroker, path: "deps/sbroker", override: true},
     {:sqlitex, path: "deps/sqlitex", override: true}]
  end

  defp package do
    [maintainers: ["Jason M Barnes", "Eric Scouten"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/scouten/sqlite_ecto2"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/sqlite_db_connection/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths, do: ["integration/sqlite", "test"]
end
