defmodule Chargepoints do
  use GenServer
  import Logger
  alias Model.Charger, as: Charger

  @moduledoc """
    Provides access to charge points
  """

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def handle_call({:subscribe, serial}, _from, _state) do
    case getChargerBySerial(serial) do
      nil ->
        charger = %Charger{serial: serial,
                                 status: "Available",
                                 connected: Timex.now,
                                 last_seen: Timex.now}
        {:ok, inserted} = OcppBackendRepo.insert(charger)
        {:reply, :ok, inserted}

      _charger ->
        {:ok, updated} = update(serial, %{status: "Available"})
        {:reply, :ok, updated}
    end
  end

  def handle_call({:subscriber, serial}, _from, state) do
    charger = getChargerBySerial(serial)
    {:reply, {:ok, charger}, state}
  end

  def handle_call({:unsubscribe, serial}, _from, _state) do
    {:ok, updated} = update(serial, %{status: "Offline"})
    {:reply, :ok, updated}
  end

  def handle_call(:subscribers, _from, state) do
    chargepoints = Charger |> OcppBackendRepo.all(order_by: :last_seen)
    {:reply, {:ok, chargepoints}, state}
  end

  def handle_call({:status, status, serial}, _from, _state) do
    {:ok, updated} = update(serial, %{status: status})
    {:reply, :ok, updated}
  end

  def handle_call({:message_seen, serial}, _from, _state) do
    {:ok, updated} = update(serial, %{last_seen: Timex.now})
    {:reply, :ok, updated}
  end

  def getChargerBySerial(serial) do
    Charger |> OcppBackendRepo.get_by(serial: serial)
  end

  defp update(serial, changes) do
    charger = getChargerBySerial(serial)
    changeset = Charger.changeset(charger, changes)
    OcppBackendRepo.update(changeset)
  end
end
