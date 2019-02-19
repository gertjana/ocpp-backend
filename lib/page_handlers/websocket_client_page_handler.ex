
defmodule PageHandlers.WebsocketClient do
@moduledoc """
  Renders A Client to test the backend
 """
  def init(req, state), do: handle(req, state)

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

  def build_body(_request) do
    {:ok, chargers} = Chargepoints.subscribers
    PageUtils.renderPage("client_page.html", "WebsocketClient", [chargers: chargers])
  end
end
