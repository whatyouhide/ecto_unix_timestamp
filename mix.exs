defmodule EctoUnixTimestamp.MixProject do
  use Mix.Project

  @version "1.0.0"
  @description "Nimble Ecto type for datetime fields to cast from Unix timestamps."
  @repo_url "https://github.com/whatyouhide/ecto_unix_timestamp"

  def project do
    [
      app: :ecto_unix_timestamp,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        "coveralls.html": :test
      ],

      # Tests
      test_coverage: [tool: ExCoveralls],

      # Dialyzer
      dialyzer: [
        plt_local_path: "plts",
        plt_core_path: "plts"
      ],

      # Hex
      package: package(),
      description: @description,

      # Docs
      name: "EctoUnixTimestamp",
      docs: [
        main: "EctoUnixTimestamp",
        source_ref: "v#{@version}",
        source_url: @repo_url
      ]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp package do
    [
      maintainers: ["Andrea Leopardi"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url, "Sponsor" => "https://github.com/sponsors/whatyouhide"}
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.0"},

      # Dev/test dependencies
      {:castore, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.4 and >= 1.4.2", only: [:dev, :test], runtime: false},
      {:ecto_sqlite3, "~> 0.13", only: :test},
      {:ex_doc, "~> 0.31", only: :dev},
      {:excoveralls, "~> 0.17", only: :test}
    ]
  end
end
