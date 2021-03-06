require_relative "../../../spec_helper"

describe Escobar::Heroku::App do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }
  let(:pipeline) { Escobar::Heroku::Pipeline.new(client, id, name) }
  let(:app) { pipeline.environments["production"].first.app }

  before do
    stub_heroku_response("/pipelines")

    pipeline_path = "/pipelines/#{id}"
    stub_heroku_response(pipeline_path)
    stub_heroku_response("#{pipeline_path}/pipeline-couplings")
    stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
    stub_kolkrabbi_response("#{pipeline_path}/repository")
  end

  it "handle preauthorization success" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/pre-authorizations"
    stub_request(:put, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}")
      )
    expect(app.preauth("867530")).to eql(true)
  end

  it "handle preauthorization failure" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/pre-authorizations"
    stub_request(:put, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}-failed")
      )
    expect(app.preauth("867530")).to eql(false)
  end

  it "handles locked applications" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 403, body: { id: "two_factor" }.to_json)
    expect(app).to be_locked
  end

  it "handles unlocked applications" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: { "RACK_ENV": "production" }.to_json)
    expect(app).to_not be_locked
  end
end
