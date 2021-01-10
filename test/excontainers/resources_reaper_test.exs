defmodule Excontainers.ResourcesReaperTest do
  use ExUnit.Case, async: true

  alias Excontainers.{Containers, ResourcesReaper}
  import Support.DockerTestUtils

  @sample_container Containers.new("alpine", cmd: ~w(sleep infinity))
  @expected_timeout_seconds 10

  test "when it terminates, reaps all registered resources after a timeout" do
    {:ok, resources_reaper_pid} = ResourcesReaper.start_link()
    {:ok, container_id} = Docker.Api.run_container(@sample_container)

    resources_reaper_pid
    |> ResourcesReaper.register({"id", container_id})

    assert container_exists?(container_id)

    resources_reaper_pid
    |> Process.exit(:normal)

    wait_for_timeout()

    refute container_exists?(container_id)
  end

  defp wait_for_timeout do
    time_to_wait_ms = (@expected_timeout_seconds + 1) * 1000

    :timer.sleep(time_to_wait_ms)
  end

  defp container_exists?(container_id) do
    {all_containers, _exit_code = 0} = System.cmd("docker", ~w(ps -a))
    all_containers =~ short_id(container_id)
  end
end
