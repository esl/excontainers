defmodule Docker.Api do
  alias Docker.{Client, Container, ContainerState}

  @one_minute 60_000

  def ping() do
    case Client.get("/_ping") do
      {:ok, %{status: 200}} -> :ok
      {:ok, %{status: status}} -> {:error, {:http_error, status}}
      {:error, message} -> {:error, message}
    end
  end

  def inspect_container(container_id) do
    case Client.get("/containers/#{container_id}/json") do
      {:ok, %{status: 200, body: body}} -> {:ok, ContainerState.parse_docker_response(body)}
      {:ok, %{status: status}} -> {:error, {:http_error, status}}
      {:error, message} -> {:error, message}
    end
  end

  defdelegate run_container(container_config, name \\ nil), to: Container, as: :run

  defdelegate create_container(container_config, name \\ nil), to: Container, as: :create

  defdelegate start_container(container_id), to: Container, as: :start

  defdelegate stop_container(container_id, options \\ []), to: Container, as: :stop

  defdelegate exec_and_wait(container_id, command), to: Docker.Exec, as: :exec_and_wait

  def pull_image(name) do
    image_name =
      name
      |> with_latest_tag_by_default()

    case Tesla.post(Client.plain_text(), "/images/create", "",
           query: %{fromImage: image_name},
           opts: [adapter: [recv_timeout: @one_minute]]
         ) do
      {:ok, %{status: 200}} -> :ok
      {:ok, %{status: status}} -> {:error, {:http_error, status}}
      {:error, message} -> {:error, message}
    end
  end

  defp with_latest_tag_by_default(name) do
    case String.contains?(name, ":") do
      true -> name
      false -> "#{name}:latest"
    end
  end
end
