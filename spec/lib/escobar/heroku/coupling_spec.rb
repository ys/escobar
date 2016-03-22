require_relative "../../../spec_helper"

describe Escobar::Heroku::Coupling do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }

  before do
    stub_heroku_response("/pipelines")

    pipeline_path = "/pipelines/#{id}"
    stub_heroku_response(pipeline_path)
    stub_heroku_response("#{pipeline_path}/pipeline-couplings")
    stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_kolkrabbi_response("#{pipeline_path}/repository")
  end

  it "gets a list of available pipeline deployments" do
    pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
    expect(pipeline.github_repository).to eql("atmos/slash-heroku")
    expect(pipeline).to be_configured

    couplings = pipeline.couplings
    expect(couplings.size).to eql(2)

    production = pipeline.environments["production"]
    expect(production.size).to eql(1)
    expect(production.first.name).to eql("slash-heroku-production")
    expect(production.first.stage).to eql("production")

    staging = pipeline.environments["staging"]
    expect(staging.size).to eql(1)
    expect(staging.first.name).to eql("slash-heroku-staging")
    expect(staging.first.stage).to eql("staging")
  end
end
