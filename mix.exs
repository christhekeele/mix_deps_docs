defmodule MixDepsDocs.MixProject do
  use Mix.Project

  @version File.read!("VERSION")

  def project do
    [
      app: :mix_deps_docs,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:req, ">= 0.4.0", runtime: false}
    ]
  end
end
