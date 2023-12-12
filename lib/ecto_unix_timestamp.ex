defmodule EctoUnixTimestamp do
  @moduledoc """
  Documentation for `EctoUnixTimestamp`.
  """

  use Ecto.ParameterizedType

  @valid_units [
    :second,
    :millisecond,
    :microsecond,
    :nanosecond
  ]

  @impl true
  def type(_params) do
    :integer
  end

  @impl true
  def init(opts) do
    if not Keyword.has_key?(opts, :unit) do
      raise ArgumentError, "missing required option :unit"
    end

    Enum.each(opts, fn
      {:unit, unit} ->
        if unit not in @valid_units do
          raise ArgumentError, """
          invalid value for the :unit option, expected one of #{inspect(@valid_units)}, \
          got: #{inspect(unit)}
          """
        end

      {:field, field} ->
        {:field, field}

      {:schema, schema} ->
        {:schema, schema}
    end)

    Map.new(opts)
  end

  @impl true
  def cast(data, params)

  def cast(nil, _params) do
    {:ok, nil}
  end

  def cast(data, %{unit: unit}) do
    case DateTime.from_unix(data, unit) do
      {:ok, dt} -> {:ok, dt}
      {:error, _reason} -> :error
    end
  end

  @impl true
  def load(data, loader, params)

  def load(nil, _loader, _params) do
    {:ok, nil}
  end

  def load(data, _loader, %{unit: unit}) do
    DateTime.from_unix(data, unit)
  end

  @impl true
  def dump(data, dumper, params)

  def dump(nil, _dumper, _params) do
    {:ok, nil}
  end

  def dump(data, _dumper, %{unit: unit}) do
    {:ok, DateTime.to_unix(data, unit)}
  end

  @impl true
  def equal?(a, b, _params) do
    a == b
  end
end
