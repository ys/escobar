require_relative "../../spec_helper"

describe Escobar::Client do
  def default_heroku_headers
    {
      "Accept"          => "application/vnd.heroku+json; version=3",
      "Accept-Encoding" => "",
      "Authorization"   => "Bearer #{Escobar.heroku_api_token}",
      "Content-Type"    => "application/json",
      "User-Agent"      => "Faraday v0.9.2"
    }
  end

  def hubot_uuid
  end

  def slash_heroku_uuid
  end

  def stub_path_with_response(path, response)
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: response, headers: {})
  end

  def heroku_fixture_data(file)
    fixture_data("heroku#{file}")
  end

  let(:client) { Escobar::Client.from_environment }

  before do
    stub_path_with_response("/pipelines", heroku_fixture_data("/pipelines"))
  end

  describe "pipelines" do
    it "gets a list of available pipeline deployments" do
      expect(client.pipelines.size).to eql(2)
      expect(client.app_names).to eql(["hubot", "slash-heroku"])
      expect(client["hubot"]).to_not be_nil
      expect(client["slash-heroku"]).to_not be_nil
    end
  end

  # rubocop:disable Metrics/LineLength
  describe "multi-environment pipelines" do
    it "loads basic information about your apps from pipelines" do
      stub_path_with_response("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111",
                              heroku_fixture_data("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111"))
      stub_path_with_response("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings",
                              heroku_fixture_data("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings"))

      pipeline = client["hubot"]
      expect(pipeline.name).to eql("hubot")
      expect(pipeline.couplings.size).to eql(1)
      expect(pipeline.couplings.first.name).to eql("production")
    end
  end

  describe "single-environment pipelines" do
    it "loads basic information about your apps from pipelines" do
      stub_path_with_response("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc",
                              heroku_fixture_data("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc"))
      stub_path_with_response("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings",
                              heroku_fixture_data("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings"))

      pipeline = client["slash-heroku"]
      expect(pipeline.name).to eql("slash-heroku")
      expect(pipeline.couplings.size).to eql(2)
      expect(pipeline.couplings.first.name).to eql("production")
      expect(pipeline.couplings.last.name).to eql("staging")
    end
  end
  # rubocop:enable Metrics/LineLength
end
