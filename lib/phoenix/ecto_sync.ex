defmodule Phoenix.EctoSync do
  @moduledoc """
  Documentation for `EctoSyncPhoenix`.
  """

  alias EctoSync
  alias Phoenix.Component
  alias Phoenix.LiveView
  alias Phoenix.LiveView.{AsyncResult, LiveStream}
  import Macro

  defmacro __using__(which) do
    quote do
      import unquote(__MODULE__ |> IO.inspect(label: :import_module))
      Module.register_attribute(__MODULE__, :phoenix_ecto_sync, accumulate: true)
      # @before_compile {Phoenix.EctoSync, :"__#{unquote(which)}__"}
    end
  end

  # defmacro __live_view__(env) do
  #   tracked = Module.get_attribute(env.module, :phoenix_ecto_sync)
  #   # async_tracks = Enum.filter(tracked, &(&1.async == true))

  #   # quoted_async_tracks =
  #   #   for %{schema: schema, assign: assign, function: function} <- async_tracks do
  #   #     quote do
  #   #       socket =
  #   #         if Phoenix.Component.connected?(socket) do
  #   #           fun = unquote(function).(socket)
  #   #           socket
  #   #           |> Phoenix.Component.assign(unquote(assign), Phoenix.LiveView.AsyncResult.loading())
  #   #           |> Phoenix.LiveView.start_async(:"do_async_#{unquote(assign)}", fun)
  #   #         end
  #   #     end
  #   #   end
  #   #   |> IO.inspect()
  #   handlers = for task <- tracked do
  #     async_operation = fn name -> :"do_async_#{name}" end
  #     quote do
  #       def handle_async(unquote(async_operation.(task.assign)), {ok_or_exit, result}, socket) do
  #         IO.inspect(result, label: :result_from_async)
  #         Phoenix.EctoSync.subscribe(unquote(task.assign, result)
  #         {:noreply, update(socket, unquote(task.assign), fn assign -> ok_or_exit == :ok && AsyncResult.ok(assign, result) || AsyncResult.failed(assign, result) end)}
  #       end

  #       def handle_info({EctoSync, {unquote(task.schema), :inserted, _}} = sync_args, socket) do
  #         {:noreply, unquote(__MODULE__).sync(socket, unquote(task.assign)
  #       end
  #     end
  #   end

  #   if Module.defines?(env.module, {:mount, 3}) do
  #     [quote do
  #       defoverridable mount: 3

  #       def mount(params, session, socket) do
  #         {:ok, socket} = super(params, session, socket)

  #         socket = if Phoenix.LiveView.connected?(socket) do
  #           Enum.reduce(@phoenix_ecto_sync, socket, fn %{async: true} = task, socket ->
  #             fun = apply(__MODULE__, task.function, [socket])
  #             socket
  #             |> Phoenix.Component.assign(task.assign, Phoenix.LiveView.AsyncResult.loading())
  #             |> Phoenix.LiveView.start_async(:"do_async_#{task.assign}", fun)
  #           end)
  #           else
  #             socket
  #         end
  #         {:ok, socket}
  #       end

  #     end]
  #     ++ handlers
  #     |> IO.inspect(label: :quoted)
  #   end
  # end

  # defmacro __live_component__(env) do
  #   tracked = Module.get_attribute(env.module, :phoenix_ecto_sync)

  #   if Module.defines?(env.module, {:update, 2}) do
  #     quote do
  #       defoverridable update: 2

  #       def update(var!(assigns), socket) do
  #         unquote(quoted_updated_assigns)

  #         {assigns, socket} = Surface.LiveComponent.move_private_assigns(var!(assigns), socket)

  #         super(Map.merge(assigns, updated_assigns), socket)
  #       end
  #     end
  #   else
  #     quote do
  #       def update(var!(assigns), socket) do
  #         unquote(quoted_updated_assigns)

  #         socket =
  #           socket
  #           |> Phoenix.Component.assign(var!(assigns))
  #           |> Phoenix.Component.assign(updated_assigns)

  #         {:ok, socket}
  #       end
  #     end
  #   end
  # end

  defmacro subscribe_async(key, schema, function, opts \\ []) do
    quote do
      @phoenix_ecto_sync %{
        assign: unquote(key),
        schema: unquote(schema),
        function: unquote(function),
        async: true,
        opts: opts
      }
    end
  end

  defmacro handle_sync(schema, assign_key, _block \\ []) do
    quote do
      @impl true
      def handle_info({{unquote(schema), event}, sync_args}, socket) do
        assign = Map.get(socket.assigns, key)
        {:ok, value} = EctoSync.sync(assign, sync_args)

        {:noreply, assign(socket, unquote(assign_key), value)}
      end
    end
  end

  @doc """
  Syncs an assign in the socket.
  """
  def sync(socket, assign, {schema, event, {%{id: id}, ref}} = sync_args, opts \\ []) do
    {stream_insert_opts, opts} = Keyword.pop(opts, :stream_opts, [])
    {after_fun, opts} = Keyword.pop(opts, :after, nil)

    case socket.assigns[assign] do
      %AsyncResult{loading: true} ->
        socket

      %AsyncResult{ok?: true, result: result} = async_result ->
        Component.update(socket, assign, fn async_result ->
          %{async_result | result: EctoSync.sync(result, sync_args, opts)}
        end)

      %LiveStream{} = stream ->
        synced = EctoSync.get(sync_args)

        case event do
          :deleted -> LiveView.stream_delete(socket, assign, synced)
          _ -> LiveView.stream_insert(socket, assign, synced, stream_insert_opts)
        end

      value ->
        synced = EctoSync.sync(value, sync_args, opts)

        Component.update(socket, assign, fn _ -> synced end)
        |> then(fn socket ->
          if after_fun do
            after_fun.(socket, value)
          else
            socket
          end
        end)
    end
  end
end
