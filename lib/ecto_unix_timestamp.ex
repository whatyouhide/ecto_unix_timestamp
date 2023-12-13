defmodule EctoUnixTimestamp do
  @moduledoc """
  An Ecto type for datetime fields that are cast as **Unix timestamps**.

  This type is useful when the data you're casting comes in as a Unix timestamp. In those
  cases, the built-in Ecto types `:utc_datetime`, `:utc_datetime_usec`, `:naive_datetime`,
  and `:naive_datetime_usec` work for *storing* the data but not for *casting*. You're forced
  to pre-parse the parameters that contain the Unix timestamps and convert them into
  `DateTime` or `NaiveDateTime` structs before passing them to Ecto, which somewhat defeats
  the purpose of Ecto casting for those fields. This nimble library solves exactly this issue.

  ## Usage

  Use this Ecto type in your schemas. You'll have to choose the **precision** of the Unix
  timestamp, and the underlying database data type you want to *store* the data as.

      defmodule User do
        use Ecto.Schema

        schema "users" do
          field :created_at, EctoUnixTimestamp, unit: :second, underlying_type: :utc_datetime
        end
      end

  Once you have this, you can cast Unix timestamps:

      import Ecto.Changeset

      changeset = cast(%User{}, %{created_at: 1672563600}, [:created_at])

      fetch_field!(changeset, :created_at)
      #=> ~U[2023-01-01 09:00:00Z]

  ## Options

  A `field` whose type is `EctoUnixTimestamp` accepts the following options:

    * `:unit` - The precision of the Unix timestamp. Must be one of `:second`,
      `:millisecond`, `:microsecond`, or `:nanosecond`. This option is **required**.

    * `:underlying_type` - The underlying Ecto type to use for storing the data.
      This option is **required**. It can be one of the native datetime types, that is,
      `:utc_datetime`, `:utc_datetime_usec`, `:naive_datetime`, or
      `:naive_datetime_usec`.

  """

  use Ecto.ParameterizedType

  @typedoc """
  Type for a field of type `EctoUnixTimestamp`.
  """
  @typedoc since: "0.2.0"
  @type t() :: DateTime.t() | NaiveDateTime.t()

  @valid_units [
    :second,
    :millisecond,
    :microsecond,
    :nanosecond
  ]

  @valid_underlying_types [
    :utc_datetime,
    :utc_datetime_usec,
    :naive_datetime,
    :naive_datetime_usec
  ]

  @impl true
  def init(opts) do
    unit =
      Keyword.get_lazy(opts, :unit, fn ->
        raise ArgumentError, "missing required option :unit"
      end)

    underlying_type =
      Keyword.get_lazy(opts, :underlying_type, fn ->
        raise ArgumentError, "missing required option :underlying_type"
      end)

    if unit not in @valid_units do
      raise ArgumentError, """
      invalid value for the :unit option, expected one of #{inspect(@valid_units)}, \
      got: #{inspect(unit)}
      """
    end

    if underlying_type not in @valid_underlying_types do
      raise ArgumentError, """
      invalid value for the :underlying_type option, expected one of \
      #{inspect(@valid_underlying_types)}, got: #{inspect(underlying_type)}
      """
    end

    %{unit: unit, type: underlying_type}
  end

  @impl true
  def type(%{type: type}) do
    type
  end

  @impl true
  def cast(data, params)

  def cast(nil, _params) do
    {:ok, nil}
  end

  def cast(data, %{unit: unit, type: type}) when is_integer(data) do
    case DateTime.from_unix(data, unit) do
      {:ok, dt} when type in [:naive_datetime, :naive_datetime_usec] ->
        {:ok, DateTime.to_naive(dt)}

      {:ok, dt} ->
        {:ok, dt}

      {:error, _reason} ->
        :error
    end
  end

  def cast(_other, _params) do
    {:error, [reason: "Unix timestamp must be an integer"]}
  end

  @impl true
  def load(data, loader, params)
  def load(nil, _loader, _params), do: {:ok, nil}
  def load(%mod{} = data, _loader, _params) when mod in [DateTime, NaiveDateTime], do: {:ok, data}
  def load(_data, _loader, _params), do: :error

  @impl true
  def dump(data, dumper, params)
  def dump(nil, _dumper, _params), do: {:ok, nil}
  def dump(%mod{} = data, _dumper, _params) when mod in [DateTime, NaiveDateTime], do: {:ok, data}
  def dump(_data, _dumper, _params), do: :error
end
