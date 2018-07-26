OCPP 1.6 Backend
===================
[![Build Status](https://travis-ci.org/gertjana/ocpp16-backend.svg?branch=master)](https://travis-ci.org/gertjana/ocpp16-backend) [![codebeat badge](https://codebeat.co/badges/a97a16d8-3f75-4deb-8ecc-9d8141ddf3c9)](https://codebeat.co/projects/github-com-gertjana-ocpp16-backend-master)
Start of an OCPP 1.6 compatible backend in Elixir using Cowboy

~~This is primarly meant for an knowledge sharing session within my company~~

This is used now to test certain features in our main software


Usage:
------------------

Make sure you have elixir >= 1.0.0 installed.  
```
brew install elixir
```

Clone the repo, and change directory to it.  Run the following commands:

    mix deps.get
    mix deps.compile


Have a local postgres database ready and configure acces in `config/config.exs`


run the database migrations

    mix ecto.migrate

and then start it up with:

    iex -S mix

Connect a 1.6 Charger or simulator to localhost:8383/ocppws/:serial 

Or use the websocket client on localhost:8383/client

There's a simple UI running at localhost:8383/chargers

Sending messages back:
----------------------
Whenever a chargepoint connected the following message will appear in the console
```
12:16:16.148 [info]  Initializing WebSocketconnection for #PID<0.320.0>
```
please note the PID number
to send a message from the console simply do:
```
send pid("0.320.0"), [2,"42", "TriggerMessage", %{"requestedMessage" => "Heartbeat"}]
```
where the PID number is the one mentioned above,
the message is in default elixir primitives, eq a List of 3, id, MessageType and a Payload which is a Map


Attributions:
-------------
This is based on a cowboy_elixir_example by
* [Evan Dorn](https://github.com/idahoev)

Contributing:
-------------

please do.

License:
--------

This code is released under the MIT license.  See LICENSE.
