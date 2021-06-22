defmodule HirefirePlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :hirefire_plug,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: ["test.watch": :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 1.0", only: :test},
      {:plug, "~> 1.11"}
    ]
  end
end
