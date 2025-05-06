defmodule Backpex.HTML.Dashboard do
  @moduledoc """
  Contains all Backpex resource components.
  """
  use BackpexWeb, :html


  embed_templates("dashboard/*")

  # @doc """
  # Renders a resource table.
  # """
  # @doc type: :component
  #
  # attr :socket, :any, required: true
  # attr :live_resources, :list, required: true, doc: "module of the live resource"
  # attr :params, :string, required: true, doc: "query parameters"

end
