OCPP Backend
===================
[![Build Status](https://travis-ci.org/gertjana/ocpp16-backend.svg?branch=master)](https://travis-ci.org/gertjana/ocpp16-backend) [![codebeat badge](https://codebeat.co/badges/a97a16d8-3f75-4deb-8ecc-9d8141ddf3c9)](https://codebeat.co/projects/github-com-gertjana-ocpp16-backend-master)

Start of an OCPP 1.6/2.0 compatible backend in Elixir using Cowboy

~~This is primarly meant for an knowledge sharing session within my company~~

~~This is used now to test certain features in our main software~~

This is starting to make sense on its own

Protocol support
----------------
OCPP 1.6 
 * Most normal Chargepoint operations are supported
OCPP 2.0
 * Just the Heartbeat message is implemented

Why not Phoenix?
-----------------
Almost every elixir person I have talked too about this asked me this

2 reasons:
 * I want to learn about Elixir, not about Phoenix
 * Phoenix has their own implementation on top of websockets, I need the raw stuff



Usage:
------------------

This is verified to run on 
 * Elixir 1.5.3 / Erlang OTP 20.2.2
 * Elixir 1.7.2 / Erlang OTP 20.2.2

Clone the repo, and change directory to it.  Run the following commands:

    mix deps.get
    mix deps.compile


Have a local postgres database ready and configure acces in `config/dev.exs` (and test.exs and prod.exs)


run the database migrations

    mix ecto.migrate

and then start it up with:

    iex -S mix

Connect a 1.6 or 2.0 Charger or simulator to localhost:8383/ocppws/:serial 

Or use the websocket client on localhost:8383/client page

There's a UI running at localhost:8383/dashboard

Sending commands back:
----------------------

There is an API to send commands back to the charger.

The buttons on the UI charger page call this API

call `POST /api/chargers/:serial/command` with body
```
{
  "command":"Reset",
  "data": {
    "resetType":"hard"
  }
}
``` 

Docker: 
-------

Running the following command will build a release of the app in a docker-container. this will make sure everything is compiled for the linux architeture that is used when running the app in a docker container
```
docker build -t buildhelper.app -f Dockerfile.build --build-arg APP=ocpp_backend .
```
As this image is reasonably large we want to build an image that is only capable of running the app and we copy over the release that was build in the previous step

```
docker run -v /var/run/docker.sock:/var/run/docker.sock buildhelper.app docker build -t ocppbackend -f Dockerfile --build-arg APP=ocpp_backend --build-arg VERSION=0.0.3 .
```

the version argument should match with the one in your mix.exs

and then run it with:
```
docker run -p 8383:8383 ocppbackend
```


Attributions:
-------------
This is based on a cowboy_elixir_example by
* [Evan Dorn](https://github.com/idahoev)

Contributing:
-------------

All contributions are welcome

License:
--------

This code is released under the MIT license.  See LICENSE.
