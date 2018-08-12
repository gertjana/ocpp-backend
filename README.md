OCPP 1.6 Backend
===================
[![Build Status](https://travis-ci.org/gertjana/ocpp16-backend.svg?branch=master)](https://travis-ci.org/gertjana/ocpp16-backend) [![codebeat badge](https://codebeat.co/badges/a97a16d8-3f75-4deb-8ecc-9d8141ddf3c9)](https://codebeat.co/projects/github-com-gertjana-ocpp16-backend-master)

Start of an OCPP 1.6 compatible backend in Elixir using Cowboy

~~This is primarly meant for an knowledge sharing session within my company~~

~~This is used now to test certain features in our main software~~

This is starting to make sense on its own

Why not Phoenix?
-----------------
Every elixir person I have talked too about this asked me this

2 reasons:
 * I want to learn about Elixir, not about Phoenix
 * Phoenix has their own implementation on top of websockets, I need the raw stuff


Usage:
------------------

This is verified to run on Elixir 1.5.3 / Erlang OTP 20.2.2

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

Sending commands back:
----------------------

There is the start of an API to send commands back to the charger, although it is not working completely yet

call `POST /api/chargers/<serial/command` with body
```
{
  "command":"Reset",
  "data": {
    "resetType":"hard"
  }
}
``` 

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
