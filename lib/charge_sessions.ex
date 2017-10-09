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

  def handle_call({:start, transactionId, serial, idTag, startTime}, _from, chargesessions) do
    {:reply, :ok, Map.put(chargesessions, transactionId, 
      %{serial: serial, idtag: idTag, starttime: startTime, endtime: nil, volume: nil, duration: nil})}
  end

  def handle_call({:stop, transactionId, volume, endTime}, _from, chargesessions) do
    startTime = get_in(chargesessions, [transactionId, :starttime])
    duration = Timex.diff(
      Timex.parse!(endTime, "{ISO:Extended}"),
      Timex.parse!(startTime, "{ISO:Extended}"),
      :minutes)

    cs2 = put_in(chargesessions[transactionId].volume, volume)
    cs3 = put_in(cs2[transactionId].endtime, endTime)
    cs4 = put_in(cs3[transactionId].duration, duration)

    {:reply, :ok, cs4}
  end

  def handle_call(:all, _from, chargesessions) do
    {:reply, {:ok, chargesessions}, chargesessions}
  end

end