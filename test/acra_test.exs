defmodule Overseer.AcraTest do
  use ExUnit.Case
  doctest Overseer.Acra

  test "Acra API returns the specified fields" do
    {:ok, profile} =
      Overseer.Acra.get_business_profile("16888888A")

    assert profile.entity_name === "ABC ENTERPRISE"
    assert profile.status_of_business == "LIVE"
    assert profile.rep_name == "NG AH MEI"
    assert profile.primary_code == "47112"
  end
end
