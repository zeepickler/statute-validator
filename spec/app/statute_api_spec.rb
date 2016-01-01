require "spec_helper"

RSpec.describe StatuteApi do
  describe "GET" do
    it "returns an error message JSON if no json data is supplied" do
      get "/"
      expected = {errors: ["No JSON data found."]}.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    it "returns an error message JSON if a json statute parameter value of nil is supplied" do
      get "/", {statutes: [{statute: nil}]}
      expected = [{errors: ["A statute was not specified."]}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    it "returns an error message JSON if a json statute parameter value of an empty string is supplied" do
      get "/", {statutes: [{statute: ""}]}
      expected = [{errors: ["A statute was not specified."]}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    it "returns an error message JSON if a json statute parameter value is supplied that is not found in the source JSON file" do
      get "/", {statutes: [{statute: "55.55.55"}]}
      expected = [{errors: ["The statute '55.55.55' was not found."]}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    it "returns an error message JSON if the retrieve parameter is not specified" do
      get "/", {statutes: [{statute: "18.10.060.A"}]}
      expected = [{errors: ["The 'retrieve' parameter was not specified."], statute: "18.10.060.A"}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
  end
end