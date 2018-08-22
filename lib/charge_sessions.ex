defmodule Chargesessions do
  use GenServer
  use Agent
  import Logger
  import Ecto.Query, only: [from: 2]
  alias Model.Session, as: Session

  @moduledoc """
  Provides access to charge sessions
  """

  def init(args) do
    {:ok, args}
  end

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    info "Started #{__MODULE__} #{inspect(pid)}"
    {:ok, pid}
  end

  def handle_call({:start, connector_id, transaction_id, serial, id_tag, start_time}, _from, state) do
    session = %Session{connector_id: connector_id |> Integer.to_string, transaction_id: transaction_id, serial: serial, token: id_tag, start_time: start_time}
    {:ok, inserted} = OcppBackendRepo.insert(session)
    {:reply, {:ok, inserted}, state}
  end

  def handle_call({:stop, transaction_id, volume, end_time}, _from, state) do
    session = getSession(transaction_id)
    duration = Timex.diff(end_time, session.start_time, :minutes)

    {:ok, updated} = update(transaction_id, %{stop_time: end_time, duration: duration, volume: volume})

    {:reply, {:ok, updated}, state}
  end

  def handle_call({:all, limit, offset}, _from, state) do
    sessions = OcppBackendRepo.all(
                from s in Session,
                order_by: [desc: s.start_time],
                limit: ^limit,
                offset: ^offset
               )
    {:reply, {:ok, sessions}, state}
  end

  def handle_call({:serial, serial, limit, offset}, _from, state) do
    sessions = OcppBackendRepo.all(
      from s in Session,
      where: s.serial == ^serial,
      order_by: [desc: s.start_time],
      limit: ^limit,
      offset: ^offset
    )
    {:reply, {:ok, sessions}, state}
  end

  defp getSession(transaction_id) do
    sessions = OcppBackendRepo.all(
      from s in Session,
      where: s.transaction_id == ^transaction_id and is_nil(s.stop_time),
      limit: 1
    )
    sessions |> List.first
  end

  defp update(transaction_id, changes) do
    session = getSession(transaction_id)
    changeset = Session.changeset(session, changes)
    OcppBackendRepo.update(changeset)
  end
end
