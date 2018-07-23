defmodule ChargerCommandHandler do
  import Logger

  @moduledoc """
    Module to handle command send via api calls
  """

  def init(request, options \\ []) do
    {:cowboy_rest, request, options}
  end

  def content_types_provided(request, state) do
    {[{"application/json", :to_json}], request, state}
  end

  def to_json(request, state) do
    serial = :cowboy_req.binding(:serial, request)
    command = :cowboy_req.binding(:command, request)
    info "Received: #{command} for #{serial}"
    {"{\"#{serial}\":\"#{command}\"}", request, state}
  end
end
