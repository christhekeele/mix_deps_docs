defmodule Mix.Tasks.Deps.Docs do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Echoes arguments"

  @finch_pool Mix.Tasks.Deps.Docs.Pool

  @library_version Mix.Project.get().project()[:version]
  @elixir_version System.version()
  @erlang_version :erlang.system_info(:otp_release)
  @user_agent "mix_deps_docs/#{@library_version} (Elixir/#{@elixir_version}) (OTP/#{@erlang_version})"

  use Mix.Task

  def run() do
    run([])
  end

  @impl Mix.Task
  @requirements ["deps.get"]

  def run([]) do
    run(["install"])
  end

  def run(["install"]) do
    # {packages, []} = Code.eval_file("mix.lock", Path.dirname(Mix.Project.project_file()))
    {packages, []} = Mix.Project.project_file()
    |> Path.dirname()
    |> Path.join("mix.lock")
    |> File.read!
    |> Code.string_to_quoted!(warn_on_unnecessary_quotes: false)
    |> Code.eval_quoted()

    Application.ensure_started(:telemetry)
    {:ok, _} = Finch.start_link(name: @finch_pool)

    for {package, {:hex, package, version, _, _, _, _, _}} <- packages do
      install(package, version)
    end
    |> index
  end

  defp install(package, version) do
    package_name = Atom.to_string(package)

    packages_dir = Mix.Project.deps_path()
    package_dir = Path.join(packages_dir, package_name)
    package_docs_dir = Path.join(package_dir, "docs")
    File.mkdir_p!(package_docs_dir)

    package_docs_url = "https://repo.hex.pm/docs/#{package_name}-#{version}.tar.gz"

    package_docs_response =
      Req.get!(package_docs_url,
        finch: @finch_pool,
        headers: %{
          user_agent: [@user_agent]
        }
      )

    for {package_docs_filename, package_docs_file} <- package_docs_response.body do
      package_docs_file_dir = Path.dirname(package_docs_filename)

      package_docs_dir
      |> Path.join(package_docs_file_dir)
      |> File.mkdir_p!()

      package_docs_dir
      |> Path.join(package_docs_filename)
      |> File.write!(package_docs_file)
    end

    Mix.shell().info(
      "Downloaded docs for #{package} v#{version}: (from: #{package_docs_url}) (to: #{package_docs_dir})"
    )

    {package_name, package_docs_dir}
  end

  defp index(packages) do
    packages = Enum.sort_by(packages, &elem(&1, 0))

    index = ~s"""
      <ul>
        #{for {package_name, package_dir} <- packages, into: "" do
        ~s|  <li><a href="#{package_dir}/index.html">#{package_name}</a></li>|
      end}
      </ul>
    """

    # url = "data:text/html;base64," <> Base.encode64(index)

    # Mix.shell().info("Browse all docs here: #{url}")
    # url

    index_dir = System.tmp_dir!()

    index_signature =
      :crypto.hash(:sha, index)
      |> Base.encode16()
      |> String.downcase()

    index_filename = index_signature <> ".html"
    index_filepath = Path.join(index_dir, index_filename)

    File.write!(index_filepath, index)

    Mix.shell().info("Browse all docs here: #{index_filepath}")
    index_filepath
  end
end
