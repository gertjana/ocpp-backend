defmodule Utils do
  use Timex

  def time_as_string do
    {hh, mm, ss} = :erlang.time()
    :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B", [hh, mm, ss])
    |> :erlang.list_to_binary()
  end

  def datetime_as_string do
  	{:ok, dt_string} = Timex.format(Timex.now, "{ISO:Extended}")
  	dt_string
  end

  def datetime_as_string(shift_minutes) do
    {:ok, dt_string} = Timex.format(Timex.shift(Timex.now, minutes: shift_minutes), "{ISO:Extended}")
  	dt_string
  end

  def default(val, default) do
    case val do
      nil -> default
      _ -> val
    end
  end

end