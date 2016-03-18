require "spec_helper"

describe Escobar::GitHub::Client do
  def default_github_headers
    {
      "Accept"          => "application/vnd.github+json",
      "Authorization"   => "token #{Escobar.github_api_token}",
      "Content-Type"    => "application/json",
      "User-Agent"      => "Faraday v0.9.2"
    }
  end
  let(:escobar) { Escobar::Client.from_environment }
  let(:client) do
    Escobar::GitHub::Client.new(escobar.github_token, "atmos/hubot")
  end

  before do
    WebMock.disable_net_connect!
  end

  # rubocop:disable Metrics/LineLength
  describe "Escobar::GitHub::Client#archive_link" do
    it "gets an archive link for a repository" do
      token = Base64.encode64(Time.now.utc.to_s)
      url = "https://codeload.github.com/atmos/hubot/legacy.tar.gz/master?token=#{token}"
      stub_request(:head, "https://api.github.com/repos/atmos/hubot/tarball/master")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: "", headers: { "Location" => url })

      expect(url).to eql(client.archive_link("master"))
    end
  end

  describe "Escobar::GitHub::Client#create_deployment" do
    it "creates a deployment given a set of information" do
      response = fixture_data("api.github.com/repos/atmos/hubot/deployments/success")
      stub_request(:post, "https://api.github.com/repos/atmos/hubot/deployments")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      options = {
        ref: "mybranch",
        payload: {},
        environment: "production"
      }

      deployment = client.create_deployment(options)
      expect(deployment["sha"]).to eql("26439af517132e32eb7cf329cd1ca4d8bad973a0")
      expect(deployment["url"])
        .to eql("https://api.github.com/repos/atmos/hubot/deployments/4303989")
    end
  end
  # rubocop:enable Metrics/LineLength
end
