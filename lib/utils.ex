defmodule Utils do
  use Timex

@moduledoc """
  Utility functions
 """

  @spec time_as_string() :: String.t()
  def time_as_string do
    {hh, mm, ss} = :erlang.time()
    :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B", [hh, mm, ss])
    |> :erlang.list_to_binary()
  end

  @spec datetime_as_string() :: String.t()
  def datetime_as_string do
    {:ok, result} = Timex.now
                    |> Timex.format("{ISO:Extended}")
    result
  end

  @spec datetime_as_string(integer) :: String.t()
  def datetime_as_string(shift_minutes) do
    {:ok, result} = Timex.now
                    |> Timex.shift(minutes: shift_minutes)
                    |> Timex.format("{ISO:Extended}")
  	result
  end

  @spec timestamp_as_string() :: String.t()
  def timestamp_as_string do
    Integer.to_string(:os.system_time(:seconds))
  end

  @spec default(any, any) :: any
  def default(value, default_value) do
    case value do
      nil -> default_value
      _ -> value
    end
  end

  def renderPage(filename, title, bindings) do
    basedir = "#{Path.expand(__DIR__)}/../priv/templates/"
    content = EEx.eval_file("#{basedir}#{filename}.eex", bindings)

    EEx.eval_file("#{basedir}page.html.eex", [
      title: title,
      content: content
      ])
  end

  def renderFragment(filename, bindings) do
    basedir = "#{Path.expand(__DIR__)}/../priv/templates/"
    EEx.eval_file("#{basedir}#{filename}.eex", bindings)
  end

  def pid_from_string(string) do
    pids = ~r{\>|\<} |> Regex.split(string) |> Enum.at(1) |> String.split(".") |> Enum.map(&String.to_integer/1)
    :c.pid(Enum.at(pids, 0), Enum.at(pids, 1), Enum.at(pids, 2))
  end

end
