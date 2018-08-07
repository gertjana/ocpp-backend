defmodule OnlineChargers do
  use Agent
  import Logger

  @moduledoc """
    Module to keep an map of online chargers
  """

  def start_link do
    {:ok, pid} = Agent.start_link(fn -> %{} end, name: __MODULE__)
    info "Started Agent #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def delete(key) do
    Agent.get_and_update(__MODULE__, &Map.pop(&1, key))
  end

  def get_all do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def count do
    Agent.get(__MODULE__, &Kernel.map_size(&1))
  end
end
