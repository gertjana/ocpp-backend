defmodule OcppBackend do

  @doc """
  Start up a cowboy http server.  The start_http method of cowboy takes
  four arguments:
    * The protocol of the server
    * "NbAcceptors" - a non-negative-integer. the number of Accepter processes
    * TCP options for Ranch as a list of tuples.  In this case the one one
      we are using is :port, to set the server listening on port 8080.
      You could also, for example, set ipv6, timeouts, and a number of other things here.
      SEE ALSO: http://ninenines.eu/docs/en/ranch/1.2/manual/ranch_tcp/
    * Protocol options for cowboy as a list of tuples.  This can be a very big
      structure because it includes you "middleware environment", which among
      other things includes your entire routing table. Here that is the only option
      we are specifying.
      SEE ALSO: http://ninenines.eu/docs/en/cowboy/1.0/manual/cowboy_protocol/

  SEE ALSO: http://ninenines.eu/docs/en/cowboy/1.0/guide/getting_started/
  """
#  def start(_type, _args) do
  def start(_type, _args) do
    IO.puts "Starting OCPP Backend"
    dispatch_config = build_dispatch_config()
    { :ok, _ } = :cowboy.start_http(:http,
                                    4096,
                                   [{:port, 8383}],
                                   [{ :env, [{:dispatch, dispatch_config}]}]
                                   )
    OcppBackend.Supervisor.start_link
  end

  def build_dispatch_config do
    :cowboy_router.compile([
      { :_,
        [
          {"/client", DynamicPageHandler, []},
          {"/ocppws/:serial", WebsocketHandler, []}
      ]}
    ])

  end

end
