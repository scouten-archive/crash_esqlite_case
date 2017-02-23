defmodule Ecto.Integration.TransactionTest do
  # We can keep this test async as long as it
  # is the only one access the transactions table
  use ExUnit.Case, async: true

  alias Ecto.Integration.PoolRepo
  alias Ecto.Integration.TestRepo

  setup do
    PoolRepo.delete_all "transactions"
    :ok
  end

  defmodule Trans do
    use Ecto.Schema

    schema "transactions" do
      field :text, :string
    end
  end

  test "transaction returns value" do
    x = PoolRepo.transaction(fn ->
      PoolRepo.transaction(fn ->
        42
      end)
    end)
    assert x == {:ok, {:ok, 42}}
  end

  test "transaction commits" do
    PoolRepo.transaction(fn ->
      e = PoolRepo.insert!(%Trans{text: "1"})
      assert [^e] = PoolRepo.all(Trans)
      assert [] = TestRepo.all(Trans)
    end)

    assert [%Trans{text: "1"}] = TestRepo.all(Trans)
  end

  test "transaction rolls back per repository" do
    message = "cannot call rollback outside of transaction"

    assert_raise RuntimeError, message, fn ->
      PoolRepo.rollback(:done)
    end

    assert_raise RuntimeError, message, fn ->
      TestRepo.transaction fn ->
        PoolRepo.rollback(:done)
      end
    end
  end

  test "manual rollback doesn't bubble up" do
    x = PoolRepo.transaction(fn ->
      e = PoolRepo.insert!(%Trans{text: "6"})
      assert [^e] = PoolRepo.all(Trans)
      PoolRepo.rollback(:oops)
    end)

    assert x == {:error, :oops}
    assert [] = TestRepo.all(Trans)
  end

  test "manual rollback bubbles up on nested transaction" do
    assert PoolRepo.transaction(fn ->
      e = PoolRepo.insert!(%Trans{text: "6"})
      assert [^e] = PoolRepo.all(Trans)
      assert {:error, :oops} = PoolRepo.transaction(fn ->
        PoolRepo.rollback(:oops)
      end)
      assert_raise DBConnection.Error, "transaction rolling back",
        fn() -> PoolRepo.insert!(%Trans{text: "5"}) end
    end) == {:error, :rollback}

    assert [] = TestRepo.all(Trans)
  end

  test "transactions are not shared in repo" do
    pid = self

    new_pid = spawn_link fn ->
      PoolRepo.transaction(fn ->
        e = PoolRepo.insert!(%Trans{text: "7"})
        assert [^e] = PoolRepo.all(Trans)
        send(pid, :in_transaction)
        receive do
          :commit -> :ok
        after
          5000 -> raise "timeout"
        end
      end)
      send(pid, :committed)
    end

    receive do
      :in_transaction -> :ok
    after
      5000 -> raise "timeout"
    end
    assert [] = PoolRepo.all(Trans)

    send(new_pid, :commit)
    receive do
      :committed -> :ok
    after
      5000 -> raise "timeout"
    end

    assert [%Trans{text: "7"}] = PoolRepo.all(Trans)
  end

  ## Logging

  test "log begin, commit and rollback" do
    Process.put(:on_log, &send(self(), &1))
    PoolRepo.transaction(fn ->
      assert_received %Ecto.LogEntry{params: nil, result: :ok} = entry
      assert is_integer(entry.query_time) and entry.query_time >= 0
      assert is_integer(entry.queue_time) and entry.queue_time >= 0

      refute_received %Ecto.LogEntry{}
      Process.put(:on_log, &send(self(), &1))
    end)

    assert_received %Ecto.LogEntry{params: nil, result: :ok} = entry
    assert is_integer(entry.query_time) and entry.query_time >= 0
    assert is_nil(entry.queue_time)

    assert PoolRepo.transaction(fn ->
      refute_received %Ecto.LogEntry{}
      Process.put(:on_log, &send(self(), &1))
      PoolRepo.rollback(:log_rollback)
    end) == {:error, :log_rollback}
    assert_received %Ecto.LogEntry{params: nil, result: :ok} = entry
    assert is_integer(entry.query_time) and entry.query_time >= 0
    assert is_nil(entry.queue_time)
  end

  test "log queries inside transactions" do
    PoolRepo.transaction(fn ->
      Process.put(:on_log, &send(self(), &1))
      assert [] = PoolRepo.all(Trans)

      assert_received %Ecto.LogEntry{params: [], result: {:ok, _}} = entry
      assert is_integer(entry.query_time) and entry.query_time >= 0
      assert is_integer(entry.decode_time) and entry.query_time >= 0
      assert is_nil(entry.queue_time)
    end)
  end
end
