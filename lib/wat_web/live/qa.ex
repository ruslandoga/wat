defmodule WatWeb.QALive do
  use WatWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen max-w-2xl mx-auto">
      <form id="ask-form" class="w-full" phx-submit="ask">
        <input
          type="text"
          name="question"
          placeholder="Ask a question about Plausible..."
          class="mt-4 w-full dark:bg-zinc-500 dark:border-zinc-400"
        />
      </form>

      <%= if @answer do %>
        <div class="mt-4 prose prose-zinc dark:prose-invert"><%= raw(@answer) %></div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, answering: false), temporary_assigns: [answer: nil]}
  end

  @impl true
  def handle_event("ask", %{"question" => question}, %{assigns: %{answering: false}} = socket) do
    lv = self()

    Task.start(fn ->
      Wat.stream_answer(question, fn answer ->
        send(lv, {:answer, answer})
      end)

      send(lv, {:answer, :done})
    end)

    {:noreply, assign(socket, answering: true)}
  end

  @impl true
  def handle_info({:answer, answer}, socket) when is_binary(answer) do
    socket =
      case Earmark.as_html(answer) do
        {:ok, html, _} -> assign(socket, answer: html)
        _ -> assign(socket, answer: answer)
      end

    {:noreply, socket}
  end

  def handle_info({:answer, :done}, socket) do
    {:noreply, assign(socket, answering: false)}
  end
end
