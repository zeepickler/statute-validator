require "spec_helper"

RSpec.describe StatuteApi do
  describe "GET" do
    it "returns an error message JSON if no json data is supplied" do
      get "/"
      expected = {errors: ["No JSON data found."]}.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    it "returns an error message JSON if a json statute value of nil is supplied" do
      get "/", {statutes: [{statute: nil}]}
      expected = [{errors: ["A statute was not specified."]}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    it "returns an error message JSON if a json statute value of an empty string is supplied" do
      get "/", {statutes: [{statue: ""}]}
      expected = [{errors: ["A statute was not specified."]}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
  end
end