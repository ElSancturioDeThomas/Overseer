defmodule Overseer.Acra.BusinessProfile do
  @moduledoc """
  Functions for ACRA connection and readability
  """

  defstruct [
    :entity_name,
    :incorporation_date,
    :expiry_date,
    :status_of_business,
    :rep_name,
    :nationality,
    :primary_code,
    :primary_desc,
    :secondary_code,
    :secondary_desc
  ]
end

defmodule Overseer.Acra do
  alias Overseer.Acra.BusinessProfile

  @business_profile_url "https://api-sandbox.bizfile.gov.sg/api/acra/entityQuery/businessProfile"

  def get_business_profile(uen) do
    fetch_data(uen) |> parse_response()
  end

  defp fetch_data(uen) do
    Req.get(
      @business_profile_url,
      headers: %{
        "token" =>
          "qvOFt_z-rta-wfXVHONv1anHMHcL5RuKFjm9OqvUm19y1w5qHND88sWpYUVUaqcy0x2Jkk-9FQv7NJYG27EGB860LxsWVA06V1EmQHD9J5gE9QHQ8HYzgbxHqG7hgBSP",
        "accept" => "application/json"
      },
      params: [uen: uen]
    )
  end

  defp parse_response({:ok, response}) do
    [entities] = response.body["entities"]

    %{
      "entityName" => entity_name,
      "commencementDate" => incorporation_date,
      "expiryDate" => expiry_date,
      "statusOfBusiness" => status_of_business,

      # Dig right into the nested map in the same step!
      "authorisedRepresentative" => %{
        "principalName" => rep_name,
        "id" => _rep_id,
        "nationalityCitizenship" => nationality_citizenship
      },
      "primaryActivity" => %{
        "code" => primary_activity_code,
        "description" => primary_activity_description
      },
      "secondaryActivity" => %{
        "code" => secondary_activity_code,
        "description" => secondary_activity_description
      }
    } = entities

    {:ok,
     %BusinessProfile{
       entity_name: entity_name,
       incorporation_date: incorporation_date,
       expiry_date: expiry_date,
       status_of_business: status_of_business,
       rep_name: rep_name,
       nationality: nationality_citizenship,
       primary_code: primary_activity_code,
       primary_desc: primary_activity_description,
       secondary_code: secondary_activity_code,
       secondary_desc: secondary_activity_description
     }}
  end

  defp parse_response({:error, error}) do
    IO.puts("The request failed!")
    IO.inspect("Error: #{inspect(error)}")
    {:error, error}
  end
end
