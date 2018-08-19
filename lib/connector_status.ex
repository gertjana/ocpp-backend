defmodule ConnectorStatus do
  use Agent
  import Logger

  @moduledoc """
    Module to keep an map of connector statuses
  """

  def start_link do
    {:ok, pid} = Agent.start_link(fn -> %{} end, name: __MODULE__)
    info "Started Agent #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def get(serial, connector_id) do
    Agent.get(__MODULE__, &Map.get(&1, key(serial, connector_id)))
  end

  def put(serial, connector_id, value) do
    Agent.update(__MODULE__, &Map.put(&1, key(serial, connector_id), value))
  end

  def delete(serial, connector_id) do
    Agent.get_and_update(__MODULE__, &Map.pop(&1, key(serial, connector_id)))
  end

  def get_all do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def count do
    Agent.get(__MODULE__, &Kernel.map_size(&1))
  end

  defp key(serial, connector_id) do
    serial <> "_" <> Integer.to_string(connector_id)
  end
end
