ExUnit.start()

defmodule EctoUnixTimestamp.TestHelpers do
  # TODO: remove this once we require Elixir 1.15+, which has DateTime.utc_now/2
  # which supports built-in truncation.
  def datetime_utc_now(precision) do
    DateTime.truncate(DateTime.utc_now(), precision)
  end

  # TODO: remove this once we require Elixir 1.15+, which has NaiveDateTime.utc_now/2
  # which supports built-in truncation.
  def naive_datetime_utc_now(precision) do
    NaiveDateTime.truncate(NaiveDateTime.utc_now(), precision)
  end
end
