# EctoUnixTimestamp

[![Documentation badge](https://img.shields.io/badge/Documentation-ff69b4)][docs]

A nimble Elixir library that provides a [`Ecto.Type`][ecto-type] for fields that come in as [**Unix timestamps**][unix-timestamp].

## Installation

```elixir
defp deps do
  [
    # ...,
    {:ecto_unix_timestamp, "~> 0.1.0"}
  ]
end
```

## Usage

Use this Ecto type in your schemas. You'll have to choose the **precision** of the Unix
timestamp, and the underlying database data type you want to *store* the data as.

```elixir
schema "users" do
  field :created_at, EctoUnixTimestamp, unit: :second, underlying_type: :utc_datetime_usec
end
```

Once you have this, you can cast Unix timestamps:

```elixir
import Ecto.Changeset

changeset = cast(%User{}, %{created_at: System.system_time(:second)}, [:created_at])

fetch_field!(changeset, :created_at)
#=> ~U[...] # a DateTime
```

## License

Released under the MIT license. See the [license file](LICENSE.txt).

[unix-timestamp]: https://en.wikipedia.org/wiki/Unix_time
[ecto-type]: https://hexdocs.pm/ecto/Ecto.Type.html
[docs]: https://hexdocs.pm/ecto_unix_timestamp
