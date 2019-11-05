defmodule TwitterWall.TweetsTest do
  use ExUnit.Case, async: true
  alias TwitterWall.Tweets
  alias TwitterWall.Tweet

  describe "Tweets should" do
    test "return count of tweets" do
      tweets = Tweets.new(List.duplicate(%Tweet{}, 17))

      assert Tweets.count(tweets) == 17
    end

    test "return errors" do
      tweets = %Tweets{all: List.duplicate(%Tweet{}, 5), errors: [:err1, :err2, :err3]}

      assert tweets.errors == [:err1, :err2, :err3]
    end

    test "be additive as sum of tweets and errors" do
      tweets1 = %Tweets{all: [%Tweet{html: "1"}], errors: [:err1, :err5]}

      tweets2 = %Tweets{
        all: [%Tweet{html: "3"}, %Tweet{html: "4"}],
        errors: [:err1, :err2, :err4]
      }

      assert Tweets.add(tweets1, tweets2) == %Tweets{
               all: [%Tweet{html: "1"}, %Tweet{html: "3"}, %Tweet{html: "4"}],
               errors: [:err1, :err5, :err1, :err2, :err4]
             }
    end
  end
end
