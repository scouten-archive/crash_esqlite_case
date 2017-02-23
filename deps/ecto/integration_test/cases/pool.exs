Code.require_file "../support/file_helpers.exs", __DIR__

# IMPORTANT! This test seems to be a necessary condition for the crash we're tracking.
# When I removed this test suite, it did not crash in 200 attempts.

defmodule Ecto.Integration.PoolTest do
  use ExUnit.Case, async: true

  use Ecto.Integration.Case

  repo = Application.get_env(:ecto, Ecto.Integration.TestRepo) ||
         raise "could not find configuration for Ecto.Integration.TestRepo"

  pool =
    case System.get_env("ECTO_POOL") || "poolboy" do
      "poolboy"        -> DBConnection.Poolboy
      "sojourn_broker" -> DBConnection.SojournBroker
    end

  Application.put_env(:ecto, __MODULE__.MockRepo,
                      [pool: pool, pool_size: 1] ++ repo)

  defmodule MockRepo do
    use Ecto.Repo, otp_app: :ecto

    def after_connect(conn) do
      send Application.get_env(:ecto, :pool_test_pid), {:after_connect, conn}
    end
  end

  setup do
    Application.put_env(:ecto, :pool_test_pid, self())
    :ok
  end

  test "starts repo with different names" do
    assert {:ok, pool1} = MockRepo.start_link()
    assert {:error, {:already_started, _}} = MockRepo.start_link()

    assert {:ok, pool2} = MockRepo.start_link(name: MockRepo.Named, query_cache_owner: false)
    assert pool1 != pool2
  end
end
