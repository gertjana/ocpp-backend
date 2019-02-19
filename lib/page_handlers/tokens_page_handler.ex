defmodule PageHandlers.Tokens do

  @moduledoc """
    Render the Tokens page
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

  defp build_body(_request) do
  	{:ok, tokens} = Chargetokens.all
  	PageUtils.renderPage("tokens_page.html", "Tokens", [tokens: tokens])
  end
end
