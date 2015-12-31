require "spec_helper"

RSpec.describe StatuteApi do
  describe "GET" do
    it "returns an error message if no json data is supplied" do
      get "/"
      @expected = {error: "No JSON data found."}.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq @expected
    end
  end
end