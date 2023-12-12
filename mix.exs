defmodule EctoUnixTimestamp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_unix_timestamp,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.0"},

      # Dev/test dependencies
      {:ecto_sqlite3, "~> 0.13", only: :test}
    ]
  end
end
