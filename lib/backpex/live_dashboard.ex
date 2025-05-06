defmodule Backpex.LiveDashboard do
  @moduledoc ~S'''
  A LiveDashboard makes it easy to manage existing resources in your application. It provides extensive configuration options in order to meet everyone's needs. In connection with `Backpex.Components` you can build an individual admin dashboard on top of your application in minutes.

  > #### `use Backpex.LiveDashboard` {: .info}
  >
  > When you `use Backpex.LiveDashboard`, the `Backpex.LiveDashboard` module will set `@behavior Backpex.LiveDashboard`. Additionally it will create a LiveView based on the given configuration in order to create fully functional index, show, new and edit views for a resource. It will also insert fallback functions that can be overridden.
  '''

  use Phoenix.LiveView

  require Backpex

  @options_schema [
    adapter: [
      doc: "The data layer adapter to use.",
      type: :atom,
      default: Backpex.Adapters.Ecto
    ],
    adapter_config: [
      doc: "The configuration for the data layer. See corresponding adapter for possible configuration values.",
      type: :keyword_list,
      required: true
    ],
    resources: [
      doc: "List of resources to be used by the LiveDashboard.",
      type: {:list, :mod_arg},
      default: []
    ],
    layout: [
      doc: "Layout to be used by the LiveDashboard.",
      type: :mod_arg,
      required: true
    ],
    pubsub: [
      doc: "PubSub configuration.",
      type: :keyword_list,
      required: false,
      keys: [
        server: [
          doc: "PubSub server of the project.",
          required: false,
          type: :atom
        ],
        topic: [
          doc: """
          The topic for PubSub.

          By default a stringified version of the live resource module name is used.
          """,
          required: false,
          type: :string
        ]
      ]
    ]
  ]

  @doc """
  A list of panels to group certain fields together.
  """
  @callback panels() :: list()

  @doc """
  The function that can be used to add content to certain positions on Backpex views. It may also be used to overwrite content.

  See the following list for the available positions and the corresponding actions:

  - all actions
    - `:before_page_title`
    - `:page_title`
    - `:before_main`
    - `:main`
    - `:after_main`
  - `:index` action
    - `:before_actions`
    - `:actions`
    - `:before_filters`
    - `:filters`
    - `:before_metrics`
    - `:metrics`
  """
  @callback render_dashboard_slot(assigns :: map(), action :: atom(), position :: atom()) ::
              %Phoenix.LiveView.Rendered{}

  @doc """
  This function can be used to provide custom translations for texts. See the [translations guide](/guides/translations/translations.md#modify-strings) for detailed information.

  ## Options

  #{NimbleOptions.docs(@options_schema)}
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, options_schema: @options_schema] do
      @before_compile Backpex.LiveDashboard
      @behaviour Backpex.LiveDashboard

      @dashboard_opts NimbleOptions.validate!(opts, options_schema)

      @dashboard_opts[:adapter].validate_config!(@dashboard_opts[:adapter_config])

      use BackpexWeb, :html
      import Backpex.LiveDashboard
      import Phoenix.LiveView.Helpers

      require Backpex

      def config(key), do: Keyword.get(@resource_opts, key)

      @impl Backpex.LiveDashboard
      def live_resources, do: []

      defoverridable live_resources: 0

      live_dashboard = __MODULE__

      for action <- ~w(Index)a do
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        defmodule String.to_atom("#{__MODULE__}.#{action}") do
          @dashboard_opts NimbleOptions.validate!(opts, options_schema)

          use Phoenix.LiveView, layout: @resource_opts[:layout]

          @action_module String.to_existing_atom("Elixir.Backpex.LiveDashboard.#{action}")

          def mount(params, session, socket), do: @action_module.mount(params, session, socket, unquote(live_dashboard))
          def handle_params(params, url, socket), do: @action_module.handle_params(params, url, socket)
          def render(assigns), do: @action_module.render(assigns)
          def handle_info(msg, socket), do: @action_module.handle_info(msg, socket)
          def handle_event(event, params, socket), do: @action_module.handle_event(event, params, socket)
        end
      end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro __before_compile__(_env) do
    quote do
      import Backpex.HTML.Layout
      import Backpex.HTML.Dashboard

      alias Backpex.LiveDashboard
      alias Backpex.Router

      @impl Backpex.LiveDashboard
      def panels, do: []

      @impl Backpex.LiveDashboard
      def live_resources, do: []

      @impl Backpex.LiveDashboard
      def render_resource_slot(var!(assigns), :index, :page_title) do
        ~H"""
        <.main_title>
          {@page_title}
        </.main_title>
        """
      end

      @impl Backpex.LiveDashboard
      def render_resource_slot(var!(assigns), :index, :main) do
        ~H"""
        <div>
          <ul>
            <li :for={live_resource <- @live_resources}>
              {live_resource.render_resource_slot(assigns, :index, :metrics)}
            </li>
          </ul>
        </div>
        """
      end
    end
  end

  def default_attrs(_live_action, _fields, _assigns), do: %{}
end
