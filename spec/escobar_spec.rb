require "spec_helper"

describe Escobar do
  it "has a version number" do
    expect(Escobar::VERSION).not_to be nil
  end

  it "fetches the GitHub token from $NETRC" do
    expect(Escobar.github_api_token).not_to be nil
  end

  it "fetches the Heroku token from $NETRC" do
    expect(Escobar.heroku_api_token).not_to be nil
  end
end
