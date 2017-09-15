OCPP 1.6 Backend
===================

Start of an OCPP 1.6 compatible backend in Elixir using Cowboy

This is primarly meant for an knowledge sharing session within my company


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

Then use a websocket client on localhost:8383


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
