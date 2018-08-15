defmodule ChargerPageHandler do

  @moduledoc """
    Renders Page for a single charger
  """

  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
   req = :cowboy_req.reply(
      200,
      %{"content-type" => "text/html"},
      build_body(request),
      request
    )
    {:ok, req, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  def build_body(request) do
  	serial = :cowboy_req.binding(:serial, request)
  	{:ok, charger} = GenServer.call(Chargepoints, {:subscriber, serial})
    {:ok, sessions} = GenServer.call(Chargesessions, {:serial, serial, 20, 0})
    online = OnlineChargers.get(serial) != nil

    PageUtils.renderPage("charger_page.html", "Charger #{serial}", [
        charger: charger, sessions: sessions, online: online
      ])
  end
end
