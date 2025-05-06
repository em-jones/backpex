defmodule Backpex.LiveDashboard.Index do
  @moduledoc false
  use BackpexWeb, :html

  require Backpex

  def mount(_params, _session, socket, live_dashboard) do
    if Phoenix.LiveView.connected?(socket) do
      # [server: server, topic: topic] = live_dashboard.pubsub()
      #
      # Phoenix.PubSub.subscribe(server, topic)
    end

    socket
    |> assign(:live_dashboard, live_dashboard)
    |> assign(:panels, live_dashboard.panels())
    |> assign(:fluid?, live_dashboard.config(:fluid?))
    |> ok()
  end

  def render(assigns), do: Backpex.HTML.Dashboard.index(assigns)

end
