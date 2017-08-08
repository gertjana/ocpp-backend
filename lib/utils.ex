defmodule Utils do
  use Timex

  def time_as_string do
    {hh, mm, ss} = :erlang.time()
    :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B", [hh, mm, ss])
    |> :erlang.list_to_binary()
  end

  def datetime_as_string do
  	{:ok, default_str} = Timex.format(Timex.now, "{ISO:Extended}")
  	default_str
  end

  def datetime_as_string(shift_minutes) do
    {:ok, default_str} = Timex.format(Timex.shift(Timex.now, minutes: shift_minutes), "{ISO:Extended}")
  	default_str
  end
end