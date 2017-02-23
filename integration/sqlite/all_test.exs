# Old Ecto files don't compile cleanly in Elixir 1.4, so we disable warnings first.
case System.version() do
  "1.4." <> _ -> Code.compiler_options(warnings_as_errors: false)
  _ -> :ok
end

Code.require_file "../../deps/ecto/integration_test/cases/assoc.exs", __DIR__
Code.require_file "../../deps/ecto/integration_test/cases/interval.exs", __DIR__
Code.require_file "../../deps/ecto/integration_test/cases/joins.exs", __DIR__
Code.require_file "../../deps/ecto/integration_test/cases/migrator.exs", __DIR__
Code.require_file "../../deps/ecto/integration_test/cases/pool.exs", __DIR__
Code.require_file "../../deps/ecto/integration_test/cases/preload.exs", __DIR__
Code.require_file "../../deps/ecto/integration_test/cases/repo.exs", __DIR__
