defmodule Chargesessions do
  use GenServer
  use Agent
  import Logger

  def start_link(_) do 
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

# %{id: transactionId, start: meterStart, timestamp: timestamp, idTag: idToken}

  def handle_call({:start, transactionId, serial, idTag, startTime}, _from, state) do
    session = %Model.Session{transaction_id: transactionId, serial: serial, token: idTag, start_time: startTime}
    {:ok, inserted} = OcppBackendRepo.insert(session)
    {:reply, {:ok, inserted}, state}
  end

  def handle_call({:stop, transactionId, volume, endTime}, _from, state) do
    session = getSession(transactionId)
    startTime = session.start_time
    duration = Timex.diff(endTime, startTime, :minutes)

    {:ok, updated} = update(transactionId, %{stop_time: endTime, duration: duration, volume: volume})

    {:reply, {:ok, updated}, state}
  end

  def handle_call(:all, _from, state) do
    sessions = Model.Session |> OcppBackendRepo.all()
    {:reply, {:ok, sessions}, state}
  end

  defp getSession(transactionId) do
    Model.Session |> OcppBackendRepo.get_by(transaction_id: transactionId)
  end

  defp update(transactionId, changes) do
    session = getSession(transactionId)
    changeset = Model.Session.changeset(session, changes)
    OcppBackendRepo.update(changeset)
  end
end