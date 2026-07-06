defmodule OverseerWeb.HomeLiveTest do
  use OverseerWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Overseer"
  end
end
