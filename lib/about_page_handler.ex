defmodule AboutPageHandler do
  import Logger

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

  def build_body(_request) do
    PageUtils.renderMarkdown("README.md", "About", [])
  end
end
