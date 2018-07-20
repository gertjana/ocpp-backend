
defmodule WebsocketClientPageHandler do
  def init(req, state) do
    handle(req, state)
  end

  def handle(request, state) do
    req = :cowboy_req.reply(
      200,
      [ {"content-type", "text/html"} ],
      build_body(request),
      request
    )

    {:ok, req, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end

  def build_body(_request) do
    Utils.renderFragment("client_page.html", [])
  end
end
