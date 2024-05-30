defmodule EctoUnixTimestamp do
  @moduledoc """
  An Ecto type for datetime fields that are cast as **Unix timestamps**.

  This type is useful when the data you're casting comes in as a Unix timestamp. In those
  cases, the built-in Ecto types `:utc_datetime`, `:utc_datetime_usec`, `:naive_datetime`,
  and `:naive_datetime_usec` work for *storing* the data but not for *casting*. You're forced
  to pre-parse the parameters that contain the Unix timestamps and convert them into
  `DateTime` or `NaiveDateTime` structs before passing them to Ecto, which somewhat defeats
  the purpose of Ecto casting for those fields. This nimble library solves exactly this issue.

  > #### Casting Datetimes {: .info}
  >
  > When casting a field of type `EctoUnixTimestamp`, the value of the field can also be a
  > `DateTime` or `NaiveDateTime` struct. In that case, the value is passed through as-is.

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

    * `:accept_strings` - A boolean that indicates whether the type should accept strings
      as input. If `true`, the type will attempt to parse strings as integers. If `false`,
      the type will only accept integers and `DateTime`/`NaiveDateTime` structs. Defaults to
      `true`. *Available since v1.0.0*.

  ## Examples of Casting

      iex> type = Ecto.ParameterizedType.init(EctoUnixTimestamp, unit: :millisecond, underlying_type: :utc_datetime)
      iex> Ecto.Type.cast(type, 1706818415865)
      {:ok, ~U[2024-02-01 20:13:35.865Z]}

      iex> type = Ecto.ParameterizedType.init(EctoUnixTimestamp, unit: :second, underlying_type: :naive_datetime)
      iex> Ecto.Type.cast(type, 1706818415)
      {:ok, ~N[2024-02-01 20:13:35Z]}

  With a `DateTime` or `NaiveDateTime` struct:

      iex> type = Ecto.ParameterizedType.init(EctoUnixTimestamp, unit: :second, underlying_type: :naive_datetime)
      iex> Ecto.Type.cast(type, ~N[2024-02-01 20:13:35Z])
      {:ok, ~N[2024-02-01 20:13:35Z]}

      iex> type = Ecto.ParameterizedType.init(EctoUnixTimestamp, unit: :second, underlying_type: :utc_datetime_usec)
      iex> Ecto.Type.cast(type, ~U[2024-02-01 20:13:35.846393Z])
      {:ok, ~U[2024-02-01 20:13:35.846393Z]}

  With a string:

      iex> type = Ecto.ParameterizedType.init(EctoUnixTimestamp, unit: :millisecond, underlying_type: :utc_datetime, accept_strings: true)
      iex> Ecto.Type.cast(type, "1706818415866")
      {:ok, ~U[2024-02-01 20:13:35.866Z]}

  `nil` is always valid, as with any other Ecto type:

      iex> type = Ecto.ParameterizedType.init(EctoUnixTimestamp, unit: :second, underlying_type: :naive_datetime)
      iex> Ecto.Type.cast(type, nil)
      {:ok, nil}

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

    accept_strings? = Keyword.get(opts, :accept_strings, true)

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

    if not is_boolean(accept_strings?) do
      raise ArgumentError, """
      invalid value for the :accept_strings option, expected a boolean, got: \
      #{inspect(accept_strings?)}
      """
    end

    %{unit: unit, type: underlying_type, accept_strings?: accept_strings?}
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

  def cast(%mod{} = data, %{type: type}) when mod in [DateTime, NaiveDateTime] do
    Ecto.Type.cast(type, data)
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

  def cast(data, %{accept_strings?: true} = params) when is_binary(data) do
    case Integer.parse(data) do
      {int, ""} ->
        cast(int, params)

      _other ->
        error = """
        Unix timestamp must be an integer, a string with a Unix timestamp, or a \
        DateTime/NaiveDateTime struct\
        """

        {:error, [reason: error]}
    end
  end

  def cast(_other, _params) do
    {:error, [reason: "Unix timestamp must be an integer or a DateTime/NaiveDateTime struct"]}
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
