defmodule PageUtils do

  @moduledoc """
    Utility functions
  """

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

end
