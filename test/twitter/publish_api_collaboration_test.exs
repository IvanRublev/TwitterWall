defmodule Twitter.PublishApiCollaborationTest do
  use ExUnit.Case, async: true
  alias Twitter.PublishApi
  import TwitterAPIMocker

  describe "TwitterService.PublishBase should" do
    test "send appropriate url and omit_script parameter values on call for oembed" do
      mock_oembed_request(&send(self(), {:request_attributes, &1.query}))

      PublishApi.oembed("https://someurl")

      assert_received {:request_attributes, %{url: "https://someurl", omit_script: true}}
    end
  end
end
