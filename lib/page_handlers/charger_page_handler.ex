defmodule PageHandlers.Charger do

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
  	{:ok, charger} = Chargepoints.subscriber(serial)
    {:ok, sessions} = Chargesessions.for_serial(serial, 20, 0)
    {:ok, evse_connectors} = Chargepoints.evse_connectors(serial)
    online = OnlineChargers.get(serial) != nil

    PageUtils.renderPage("charger_page.html", "Charger #{serial}", [
        charger: charger, sessions: sessions, evse_connectors: evse_connectors, online: online
      ])
  end
end
