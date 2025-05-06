defmodule Backpex.Metric do
  @moduledoc ~S"""
  Behaviour implemented by all metrics.

  Metrics are info boxes for your resources displaying key indicators prominently on the index view in your application.
  An example could be to show the current total of all orders received today. You may create your own metrics by
  implementing this behaviour.
  """
alias Backpex.LiveResource

  @doc """
  Used to render the metric as a heex template on the index views.
  """
  @callback render(assigns :: map()) :: %Phoenix.LiveView.Rendered{}
  @callback query(query :: Ecto.Queryable.t(), select :: any(), repo :: Ecto.Repo.t()) ::
              Ecto.Schema.t() | term() | nil
  @callback format(data :: any(), format :: any()) :: term()

  require Logger
  @doc """
  Returns a list of criteria to be used for filtering the metric data.

  """
  @callback criteria(assigns :: map()) :: Keyword.t()
  def criteria(assigns) do
        %{
          live_resource: live_resource,
          fields: fields,
          query_options: query_options,
        } = assigns
        adapter_config = live_resource.config(:adapter_config)
        filters = LiveResource.active_filters(assigns)
        [
          search: Backpex.LiveResource.search_options(query_options, fields, adapter_config[:schema]),
          filters: Backpex.LiveResource.filter_options(query_options, filters)
        ]
        |> tap(&Logger.debug("Metric criteria: #{inspect(&1)}"))
  end

  defmacro __using__(_) do
    quote do
      @impl Backpex.Metric
      def criteria(assigns), do: unquote(__MODULE__).criteria(assigns)
      defoverridable criteria: 1
    end
  end
  @doc """
  Determine if metrics are visible for given live_resource.
  """
  def metrics_visible?(%{} = visibility, resource) when is_atom(resource) do
    metrics_visible?(visibility, Atom.to_string(resource))
  end

  def metrics_visible?(%{} = visibility, resource) do
    Map.get(visibility, resource, true)
  end
end
