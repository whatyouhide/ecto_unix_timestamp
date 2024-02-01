defmodule EctoUnixTimestampTest do
  use ExUnit.Case, async: true

  doctest EctoUnixTimestamp

  import Ecto.Changeset
  import EctoUnixTimestamp.TestHelpers

  defmodule Repo do
    use Ecto.Repo,
      otp_app: :ecto_unix_timestamp,
      adapter: Ecto.Adapters.SQLite3
  end

  defmodule UserAction do
    use Ecto.Schema

    @primary_key false
    schema "my_schemas" do
      field :id, :integer, primary_key: true

      field :timestamp_second_utc, EctoUnixTimestamp,
        unit: :second,
        underlying_type: :utc_datetime

      field :timestamp_millisecond_utc, EctoUnixTimestamp,
        unit: :millisecond,
        underlying_type: :utc_datetime_usec

      field :timestamp_microsecond_utc, EctoUnixTimestamp,
        unit: :microsecond,
        underlying_type: :utc_datetime_usec

      field :timestamp_nanosecond_utc, EctoUnixTimestamp,
        unit: :nanosecond,
        underlying_type: :utc_datetime_usec

      field :timestamp_second_naive, EctoUnixTimestamp,
        unit: :second,
        underlying_type: :naive_datetime

      field :timestamp_millisecond_naive, EctoUnixTimestamp,
        unit: :millisecond,
        underlying_type: :naive_datetime_usec

      field :timestamp_microsecond_naive, EctoUnixTimestamp,
        unit: :microsecond,
        underlying_type: :naive_datetime_usec

      field :timestamp_nanosecond_naive, EctoUnixTimestamp,
        unit: :nanosecond,
        underlying_type: :naive_datetime_usec
    end
  end

  for unit <- [:second, :millisecond, :microsecond] do
    test "timestamps are casted correctly with unit #{inspect(unit)} (utc)" do
      now = datetime_utc_now(unquote(unit))
      field = :"timestamp_#{unquote(unit)}_utc"
      params = %{field => DateTime.to_unix(now, unquote(unit))}

      changeset = cast(%UserAction{}, params, [field])
      assert changeset.valid?

      my_schema = apply_action!(changeset, :validate)
      assert Map.fetch!(my_schema, field) == now
    end

    test "timestamps are casted correctly with unit #{inspect(unit)} (naive)" do
      now = naive_datetime_utc_now(unquote(unit))
      field = :"timestamp_#{unquote(unit)}_naive"

      params = %{
        field => now |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(unquote(unit))
      }

      changeset = cast(%UserAction{}, params, [field])
      assert changeset.valid?

      my_schema = apply_action!(changeset, :validate)
      assert Map.fetch!(my_schema, field) == now
    end

    test "timestamps are validated when casting (with unit #{inspect(unit)})" do
      field = :"timestamp_#{unquote(unit)}_naive"
      params = %{field => -377_705_116_801_342_343}

      changeset = cast(%UserAction{}, params, [field])
      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[field]
    end
  end

  test "timestamps are casted correctly as integers with unit :nanosecond (utc)" do
    now = DateTime.utc_now()
    params = %{timestamp_nanosecond_utc: DateTime.to_unix(now, :nanosecond)}

    changeset = cast(%UserAction{}, params, [:timestamp_nanosecond_utc])
    assert changeset.valid?

    my_schema = apply_action!(changeset, :validate)
    assert Map.fetch!(my_schema, :timestamp_nanosecond_utc) == now
  end

  test "timestamps are casted correctly as integers with unit :nanosecond (naive)" do
    now = NaiveDateTime.utc_now()

    params = %{
      timestamp_nanosecond_naive: now |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:nanosecond)
    }

    changeset = cast(%UserAction{}, params, [:timestamp_nanosecond_naive])
    assert changeset.valid?

    my_schema = apply_action!(changeset, :validate)
    assert Map.fetch!(my_schema, :timestamp_nanosecond_naive) == now
  end

  @tag :tmp_dir
  test "persisting to the database", %{tmp_dir: tmp_dir} do
    db_path = Path.join(tmp_dir, "ecto_unix_timestamp_test.sqlite3")
    start_supervised!({Repo, database: db_path, log: false})

    Repo.transaction(fn ->
      Repo.query!("""
      CREATE TABLE IF NOT EXISTS my_schemas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp_second_utc INTEGER,
        timestamp_millisecond_utc INTEGER,
        timestamp_microsecond_utc INTEGER,
        timestamp_nanosecond_utc INTEGER,
        timestamp_second_naive INTEGER,
        timestamp_millisecond_naive INTEGER,
        timestamp_microsecond_naive INTEGER,
        timestamp_nanosecond_naive INTEGER
      )
      """)

      utc_now = DateTime.utc_now()
      naive_now = NaiveDateTime.utc_now()

      my_schema = %UserAction{
        timestamp_second_utc: DateTime.truncate(utc_now, :second),
        timestamp_millisecond_utc: DateTime.truncate(utc_now, :millisecond),
        timestamp_microsecond_utc: utc_now,
        timestamp_nanosecond_utc: utc_now,
        timestamp_second_naive: NaiveDateTime.truncate(naive_now, :second),
        timestamp_millisecond_naive: NaiveDateTime.truncate(naive_now, :millisecond),
        timestamp_microsecond_naive: naive_now,
        timestamp_nanosecond_naive: naive_now
      }

      assert {:ok, my_schema} = Repo.insert(my_schema, returning: true)

      assert Repo.get!(UserAction, my_schema.id) == my_schema

      assert my_schema.timestamp_second_utc == DateTime.truncate(utc_now, :second)
      assert my_schema.timestamp_millisecond_utc == DateTime.truncate(utc_now, :millisecond)
      assert my_schema.timestamp_microsecond_utc == DateTime.truncate(utc_now, :microsecond)
      assert my_schema.timestamp_nanosecond_utc == utc_now

      assert my_schema.timestamp_second_naive == NaiveDateTime.truncate(naive_now, :second)
      assert my_schema.timestamp_millisecond_naive == NaiveDateTime.truncate(naive_now, :millisecond)
      assert my_schema.timestamp_microsecond_naive == NaiveDateTime.truncate(naive_now, :microsecond)
      assert my_schema.timestamp_nanosecond_naive == naive_now

      Repo.rollback(:all_good)
    end)
  end

  test "casting nils" do
    changeset = cast(%UserAction{}, %{timestamp_second_utc: nil}, [:timestamp_second_utc], empty_values: [])
    assert changeset.valid?
  end

  test "casting invalid terms" do
    for field <- [
          :timestamp_second_utc,
          :timestamp_millisecond_utc,
          :timestamp_microsecond_utc,
          :timestamp_nanosecond_utc,
          :timestamp_second_naive,
          :timestamp_millisecond_naive,
          :timestamp_microsecond_naive,
          :timestamp_nanosecond_naive
        ] do
      changeset = cast(%UserAction{}, %{field => :invalid}, [field])
      refute changeset.valid?
      assert {"is invalid", meta} = changeset.errors[field]
      assert meta[:reason] == "Unix timestamp must be an integer or a DateTime/NaiveDateTime struct"
    end
  end

  @tag :tmp_dir
  test "persisting nils to the database", %{tmp_dir: tmp_dir} do
    db_path = Path.join(tmp_dir, "ecto_unix_timestamp_test.sqlite3")
    start_supervised!({Repo, database: db_path, log: false})

    Repo.transaction(fn ->
      Repo.query!("""
      CREATE TABLE IF NOT EXISTS my_schemas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp_second_utc INTEGER,
        timestamp_millisecond_utc INTEGER,
        timestamp_microsecond_utc INTEGER,
        timestamp_nanosecond_utc INTEGER,
        timestamp_second_naive INTEGER,
        timestamp_millisecond_naive INTEGER,
        timestamp_microsecond_naive INTEGER,
        timestamp_nanosecond_naive INTEGER
      )
      """)

      my_schema = %UserAction{}

      assert {:ok, my_schema} = Repo.insert(my_schema, returning: true)

      assert Repo.get!(UserAction, my_schema.id) == my_schema

      assert my_schema.timestamp_second_utc == nil
      assert my_schema.timestamp_millisecond_utc == nil
      assert my_schema.timestamp_microsecond_utc == nil
      assert my_schema.timestamp_nanosecond_utc == nil

      assert my_schema.timestamp_second_naive == nil
      assert my_schema.timestamp_millisecond_naive == nil
      assert my_schema.timestamp_microsecond_naive == nil
      assert my_schema.timestamp_nanosecond_naive == nil

      Repo.rollback(:all_good)
    end)
  end

  describe "when validating options" do
    test "raises if :unit is missing" do
      assert_raise ArgumentError, "missing required option :unit", fn ->
        EctoUnixTimestamp.init([])
      end
    end

    test "raises if :unit is invalid" do
      assert_raise ArgumentError, ~r/invalid value for the :unit option/, fn ->
        EctoUnixTimestamp.init(unit: :invalid_unit, underlying_type: :utc_datetime)
      end
    end

    test "raises if :underlying_type is missing" do
      assert_raise ArgumentError, "missing required option :underlying_type", fn ->
        EctoUnixTimestamp.init(unit: :second)
      end
    end

    test "raises if :underlying_type is invalid" do
      assert_raise ArgumentError, ~r/invalid value for the :underlying_type option/, fn ->
        EctoUnixTimestamp.init(unit: :second, underlying_type: :invalid_type)
      end
    end
  end
end
