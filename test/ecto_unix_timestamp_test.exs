defmodule EctoUnixTimestampTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  defmodule Repo do
    use Ecto.Repo,
      otp_app: :ecto_unix_timestamp,
      adapter: Ecto.Adapters.SQLite3
  end

  defmodule UserAction do
    use Ecto.Schema

    @primary_key false
    schema "user_actions" do
      field :id, :integer, primary_key: true
      field :timestamp_second, EctoUnixTimestamp, unit: :second
      field :timestamp_millisecond, EctoUnixTimestamp, unit: :millisecond
      field :timestamp_microsecond, EctoUnixTimestamp, unit: :microsecond
      field :timestamp_nanosecond, EctoUnixTimestamp, unit: :nanosecond
    end
  end

  for unit <- [:second, :millisecond, :microsecond] do
    test "timestamps are casted correctly as integers with unit #{inspect(unit)}" do
      now = DateTime.utc_now(unquote(unit))
      field = :"timestamp_#{unquote(unit)}"
      params = %{field => DateTime.to_unix(now, unquote(unit))}

      changeset = cast(%UserAction{}, params, [field])
      assert changeset.valid?

      user_action = apply_action!(changeset, :validate)
      assert Map.fetch!(user_action, field) == now
    end
  end

  test "timestamps are casted correctly as integers with unit :nanosecond" do
    now = DateTime.utc_now()
    params = %{timestamp_nanosecond: DateTime.to_unix(now, :nanosecond)}

    changeset = cast(%UserAction{}, params, [:timestamp_nanosecond])
    assert changeset.valid?

    user_action = apply_action!(changeset, :validate)
    assert Map.fetch!(user_action, :timestamp_nanosecond) == now
  end

  test "persisting to the database" do
    start_supervised!({Repo, database: "test/ecto_unix_timestamp_test.sqlite3", log: false})

    Repo.transaction(fn ->
      Repo.query!(
        """
        CREATE TABLE IF NOT EXISTS user_actions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp_second INTEGER,
          timestamp_millisecond INTEGER,
          timestamp_microsecond INTEGER,
          timestamp_nanosecond INTEGER
        )
        """,
        _params = []
      )

      now = DateTime.utc_now()

      user_action = %UserAction{
        timestamp_second: now,
        timestamp_millisecond: now,
        timestamp_microsecond: now,
        timestamp_nanosecond: now
      }

      assert {:ok, user_action} = Repo.insert(user_action, returning: true)

      assert Repo.get!(UserAction, user_action.id) == user_action

      assert user_action.timestamp_second == DateTime.truncate(now, :second)
      assert user_action.timestamp_millisecond == DateTime.truncate(now, :millisecond)
      assert user_action.timestamp_microsecond == DateTime.truncate(now, :microsecond)
      assert user_action.timestamp_nanosecond == now

      Repo.rollback(:all_good)
    end)
  end
end
