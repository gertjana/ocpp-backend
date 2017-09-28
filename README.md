OCPP 1.6 Backend
===================

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
    iex -S mix

Then use a websocket client on localhost:8383/client


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
