defmodule Twitter.ApiJ1M1CollaborationTest do
  use ExUnit.Case, async: true
  alias Twitter.ApiJ1M1
  import TwitterAPIMocker

  setup_all do
    {:ok,
     %{
       screen_name: Confex.fetch_env!(:twitter_wall, :screen_name),
       bearer_token: Confex.fetch_env!(:twitter_wall, :bearer_token),
       oauth_consumer_key: Confex.fetch_env!(:twitter_wall, :oauth_consumer_key),
       oauth_token: Confex.fetch_env!(:twitter_wall, :oauth_token)
     }}
  end

  describe "TwitterService.ApiJ1M1 should" do
    test "send appropriate count, and screen_name param values, authorize with header on call for favorites",
         %{screen_name: name} = ctx do
      mock_favorites_list_request(&send(self(), {:request_attrs, &1.query, &1.headers}))

      ApiJ1M1.favorites(5)

      bearer = "Bearer #{ctx.bearer_token}"

      assert_received {:request_attrs, %{count: 5, screen_name: ^name},
                       %{"Authorization" => ^bearer}}
    end

    test "send appropriate count, and screen_name param values, authorize with OAuth1 headers on call for user_timeline",
         %{screen_name: name} = ctx do
      mock_user_timeline_request(&send(self(), {:request_attrs, &1.query, &1.headers}))

      ApiJ1M1.user_timeline(5)

      assert_received {:request_attrs, %{screen_name: ^name}, %{"Authorization" => auth}}
      assert auth =~ ~r{^OAuth .+}
      assert auth =~ ~r{oauth_consumer_key="#{ctx.oauth_consumer_key}"}
      assert auth =~ ~r{oauth_nonce="[^"]+"}
      assert auth =~ ~r{oauth_signature="[^"]+"}
      assert auth =~ ~r{oauth_signature_method="HMAC-SHA1"}
      assert auth =~ ~r{oauth_timestamp="[^"]+"}
      assert auth =~ ~r{oauth_token="#{ctx.oauth_token}"}
      assert auth =~ ~r{oauth_version="1.0"}
    end
  end
end
