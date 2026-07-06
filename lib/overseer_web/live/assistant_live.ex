defmodule OverseerWeb.AssistantLive do
  use OverseerWeb, :live_view

  require Logger

  alias Overseer.HydraDB

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Assistant")
     # The conversation: a list of %{role: :user | :assistant, content: "..."}
     |> assign(:messages, [])
     # True while we're waiting on the LLM, so we can show a "thinking" state.
     |> assign(:loading, false)
     # A blank form to back the message input.
     |> assign(:form, to_form(%{"message" => ""}, as: :chat))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_tab={:assistant} current_entity={@current_entity}>
      <.header>
        Assistant
        <:subtitle>Ask questions about your data and run actions.</:subtitle>
      </.header>

      <div class="mt-4 flex h-[calc(100dvh_-_15rem)] flex-col">
        <div
          id="chat-messages"
          phx-hook="ChatScroll"
          class="min-h-0 flex-1 space-y-3 overflow-y-auto pr-1"
        >
          <div :for={msg <- @messages} class={["chat", chat_side(msg.role)]}>
            <div class={["chat-bubble", msg.role == :user && "chat-bubble-primary"]}>
              <%= if msg.role == :assistant do %>
                <div class="markdown">{markdown(msg.content)}</div>
              <% else %>
                {msg.content}
              <% end %>
            </div>
          </div>

          <div :if={@loading} class="chat chat-start">
            <div class="chat-bubble">
              <span class="loading loading-dots loading-sm"></span>
            </div>
          </div>

          <p :if={@messages == [] and not @loading} class="text-base-content/60">
            Start the conversation below.
          </p>
        </div>

        <.form
          for={@form}
          phx-submit="send"
          class="mt-3 flex items-center gap-2 border-t border-base-300 pt-3"
        >
          <input
            type="text"
            name="chat[message]"
            value={@form[:message].value}
            placeholder="Ask about your data..."
            autocomplete="off"
            class="input flex-1"
          />
          <.button variant="primary" disabled={@loading} phx-disable-with="Sending...">
            Send
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("send", %{"chat" => %{"message" => text}}, socket) do
    case String.trim(text) do
      "" ->
        # Ignore empty submissions.
        {:noreply, socket}

      message ->
        # Append the new user message, then hand the whole conversation to the
        # agent so it has full context (and can run tools).
        history = socket.assigns.messages ++ [%{role: :user, content: message}]

        socket =
          socket
          |> assign(:messages, history)
          |> assign(:loading, true)
          # Clear the input by resetting the form.
          |> assign(:form, to_form(%{"message" => ""}, as: :chat))
          # Run the agent in a separate process; the result returns to
          # handle_async/3 below, tagged with the name :chat.
          |> start_async(:chat, fn -> Overseer.AIAgent.run(history) end)

        {:noreply, socket}
    end
  end

  # start_async wraps the function's return value in {:ok, ...}, and our
  # LLM.chat/1 itself returns {:ok, text} | {:error, reason} — hence the
  # double tuple {:ok, {:ok, reply}} on success.
  @impl true
  def handle_async(:chat, {:ok, {:ok, reply}}, socket) do
    # Pipe this exchange into HydraDB as a memory (non-blocking).
    store_memory(last_user_message(socket.assigns.messages), reply)

    {:noreply,
     socket
     |> update(:messages, &(&1 ++ [%{role: :assistant, content: reply}]))
     |> assign(:loading, false)}
  end

  # The LLM call returned an error tuple.
  def handle_async(:chat, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> put_flash(:error, "The assistant couldn't respond: #{inspect(reason)}")}
  end

  # The background process crashed.
  def handle_async(:chat, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> put_flash(:error, "The request failed: #{inspect(reason)}")}
  end

  defp chat_side(:user), do: "chat-end"
  defp chat_side(:assistant), do: "chat-start"

  # The most recent user message in the conversation, or nil.
  defp last_user_message(messages) do
    case messages |> Enum.reverse() |> Enum.find(&(&1.role == :user)) do
      %{content: content} -> content
      _ -> nil
    end
  end

  # Store the user/assistant exchange in HydraDB in the background, logging
  # (rather than crashing the LiveView) if it fails.
  defp store_memory(nil, _reply), do: :ok

  defp store_memory(user, reply) do
    Task.start(fn ->
      case HydraDB.ingest_memory([%{user: user, assistant: reply}]) do
        {:ok, _data} -> :ok
        {:error, reason} -> Logger.warning("HydraDB ingest failed: #{inspect(reason)}")
      end
    end)
  end

  # Render assistant Markdown as sanitized HTML. Earmark turns Markdown into
  # HTML; HtmlSanitizeEx strips anything dangerous before we mark it safe.
  defp markdown(text) do
    text
    |> Earmark.as_html!()
    |> HtmlSanitizeEx.html5()
    |> raw()
  end
end
