defmodule FlyWeb.AppLive.Show do
  use FlyWeb, :live_view
  require Logger

  alias Fly.Client
  alias FlyWeb.Components.HeaderBreadcrumbs

  @refresh 5

  @impl true
  def mount(%{"name" => name}, session, socket) do
    socket =
      assign(socket,
        config: client_config(session),
        state: :loading,
        app: nil,
        app_name: name,
        count: 0,
        authenticated: true
      )

    # Only make the API call if the websocket is setup. Not on initial render.
    if connected?(socket) do
      Process.send_after(self(), :update, :timer.seconds(@refresh))
      {:ok, fetch_app(socket)}
    else
      {:ok, socket}
    end
  end

  defp client_config(session) do
    Fly.Client.config(access_token: session["auth_token"] || System.get_env("FLYIO_ACCESS_TOKEN"))
  end

  defp fetch_app(socket) do
    app_name = socket.assigns.app_name

    case Client.fetch_app(app_name, socket.assigns.config) do
      {:ok, app} ->
        app = update_allocations_time_ago(app)
        assign(socket, :app, app)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  @impl true
  def handle_event("click", _params, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, :timer.seconds(@refresh))
    {:noreply, fetch_app(socket)}
  end

  def status_bg_color(app) do
    case app["status"] do
      "running" -> "bg-green-100"
      "dead" -> "bg-red-100"
      _ -> "bg-yellow-100"
    end
  end

  def status_text_color(app) do
    case app["status"] do
      "running" -> "text-green-800"
      "dead" -> "text-red-800"
      _ -> "text-yellow-800"
    end
  end

  def preview_url(app) do
    "https://#{app["name"]}.fly.dev"
  end

  def health_checks(allocation) do
    if allocation["totalCheckCount"] > 0 do
      [
        {allocation["totalCheckCount"], "total"},
        {allocation["passingCheckCount"], "passing"},
        {allocation["warningCheckCount"], "warning"},
        {allocation["criticalCheckCount"], "critical"}
      ]
      |> Enum.filter(fn {count, _} -> count > 0 end)
      |> Enum.reduce([], fn {count, text}, acc ->
        ["#{count} #{text}" | acc]
      end)
      |> Enum.reverse()
      |> Enum.join(", ")
    else
      "No active checks"
    end
  end

  defp time_ago(allocation) do
    {:ok, t, 0} = DateTime.from_iso8601(allocation["createdAt"])
    milliseconds = DateTime.diff(DateTime.utc_now(), t, :millisecond)

    cond do
      milliseconds < :timer.seconds(1) ->
        "Just now"

      milliseconds < :timer.minutes(1) ->
        "#{seconds(milliseconds)}s ago"

      milliseconds < :timer.hours(1) ->
        "#{minutes(milliseconds)}m#{Integer.mod(seconds(milliseconds), 60)}s ago"

      milliseconds < :timer.hours(24) ->
        "#{hours(milliseconds)}h#{Integer.mod(minutes(milliseconds), 60)}m ago"

      true ->
        allocation["createdAt"]
    end
  end

  defp seconds(milliseconds), do: div(milliseconds, 1000)
  defp minutes(milliseconds), do: milliseconds |> seconds() |> div(60)
  defp hours(milliseconds), do: milliseconds |> minutes() |> div(60)

  defp update_allocations_time_ago(app) do
    Map.update!(app, "allocations", fn allocation ->
      Enum.map(allocation, fn allo ->
        Map.put_new(allo, "createdAtTimeAgo", time_ago(allo))
      end)
    end)
  end

  defp deployment_instance_counts(app) do
    "#{app["deploymentStatus"]["desiredCount"]} desired, " <>
      "#{app["deploymentStatus"]["placedCount"]} placed, " <>
      "#{app["deploymentStatus"]["healthyCount"]} healthy, " <>
      "#{app["deploymentStatus"]["unhealthyCount"]} unhealthy"
  end
end
