require_relative "../../../spec_helper"

describe Escobar::Heroku::Pipeline do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }

  before do
    stub_heroku_response("/pipelines")
  end

  describe "pipelines" do
    it "gets a list of available pipeline deployments" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline.github_repository).to eql("atmos/slash-heroku")
      expect(pipeline).to be_configured

      couplings = pipeline.couplings
      expect(couplings.size).to eql(2)
      expect(couplings.first.stage).to eql("production")
      expect(couplings.last.stage).to eql("staging")
    end

    it "knows a respository is misconfigured if no github repo connected" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")

      response = { id: "not_found", message: "Not found." }.to_json
      stub_request(:get, "https://kolkrabbit.com#{pipeline_path}/repository")
        .with(headers: default_kolkrabbi_headers)
        .to_return(status: 404, body: response)

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline).to_not be_configured
      expect(pipeline.github_repository).to be_nil

      couplings = pipeline.couplings
      expect(couplings.size).to eql(2)
      expect(couplings.first.stage).to eql("production")
      expect(couplings.last.stage).to eql("staging")
    end

    # rubocop:disable Metrics/LineLength
    it "knows the required contexts of a pipeline" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})
      response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline.github_repository).to eql("atmos/slash-heroku")
      expect(pipeline).to be_configured
      expect(pipeline.default_branch).to eql("master")
      expect(pipeline.required_contexts).to eql(["continuous-integration/travis-ci/push"])
    end
    # rubocop:enable Metrics/LineLength
  end
end
