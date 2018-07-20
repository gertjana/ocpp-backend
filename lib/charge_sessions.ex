defmodule Chargesessions do
  use GenServer
  use Agent
  import Logger
 
 @moduledoc """
  Provides access to charge sessions
 """
 
  def start_link(_) do 
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

# %{id: transactionId, start: meterStart, timestamp: timestamp, idTag: idToken}

  def handle_call({:start, transaction_id, serial, id_tag, start_time}, _from, state) do
    session = %Model.Session{transaction_id: transaction_id, serial: serial, token: id_tag, start_time: start_time}
    {:ok, inserted} = OcppBackendRepo.insert(session)
    {:reply, {:ok, inserted}, state}
  end

  def handle_call({:stop, transaction_id, volume, end_time}, _from, state) do
    session = getSession(transaction_id)
    start_time = session.start_time
    duration = Timex.diff(end_time, start_time, :minutes)

    {:ok, updated} = update(transaction_id, %{stop_time: end_time, duration: duration, volume: volume})

    {:reply, {:ok, updated}, state}
  end

  def handle_call(:all, _from, state) do
    sessions = Model.Session |> OcppBackendRepo.all()
    {:reply, {:ok, sessions}, state}
  end

  defp getSession(transaction_id) do
    Model.Session |> OcppBackendRepo.get_by(transaction_id: transaction_id)
  end

  defp update(transaction_id, changes) do
    session = getSession(transaction_id)
    changeset = Model.Session.changeset(session, changes)
    OcppBackendRepo.update(changeset)
  end
end