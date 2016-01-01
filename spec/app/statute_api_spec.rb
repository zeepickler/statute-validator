require "spec_helper"

RSpec.describe StatuteApi do
  describe "GET" do
    it "returns an error message JSON if no JSON data is supplied" do
      get "/"
      expected = {errors: ["No JSON data found."]}.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq expected
    end
    describe "statute parameter" do
      it "returns an error message JSON if a JSON statute parameter value of nil is supplied" do
        get "/", {statutes: [{statute: nil}]}
        expected = [{errors: ["A statute was not specified."]}].to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
      it "returns an error message JSON if a JSON statute parameter value of an empty string is supplied" do
        get "/", {statutes: [{statute: ""}]}
        expected = [{errors: ["A statute was not specified."]}].to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
      it "returns an error message JSON if a JSON statute parameter value is supplied that is not found in the source JSON file" do
        get "/", {statutes: [{statute: "55.55.55"}]}
        expected = [{errors: ["The statute '55.55.55' was not found."]}].to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
    end
    describe "retrieve parameter" do
      it "returns an error message JSON if the retrieve parameter is not specified" do
        get "/", {statutes: [{statute: "12.34.567.A"}]}
        expected = [{errors: ["The 'retrieve' parameter was not specified."], statute: "12.34.567.A"}].to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
      describe "text" do
        it "returns an error message JSON if the JSON data does not have a text attribute" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["text"]}]}
          expected = [{errors: ["The text for this statute was not found."], statute: "99.99.999.A"}].to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns the text for a valid statute with text when supplied with a valid statute and retrieve text" do
          get "/", {statutes: [{statute: "12.34.567.A", retrieve: ["text"]}]}
          expected = [{statute: "12.34.567.A", text: "Example of a valid statute."}].to_json

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
      end
      describe "requirements" do
        it "returns an error message JSON if the JSON data does not have a requirements attribute" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["requirements"]}]}
          expected = [{errors: ["The requirements for this statute were not found."], statute: "99.99.999.A"}].to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns the requirements for a valid statute with requirements when supplied with a valid statute and retrieve requirements" do
          get "/", {statutes: [{statute: "12.34.567.A", retrieve: ["requirements"]}]}
          expected = [{statute: "12.34.567.A", requirements: [{conditional:"include",sources: ["cats","dogs"],value: [{maximum: 85}],units: "dBA"}]}].to_json
        
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
      end
      describe "compliance" do
        it "returns an error message JSON if the compliance parameter is specified but the observed_data parameter is not specified" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["compliance"]}]}
          expected = [{errors: ["The observed_data was missing and is required to determine compliance."], statute: "99.99.999.A"}].to_json
        
          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns an error message JSON if the compliance parameter is specified but the observed_data parameter value is nil or empty" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["compliance"], observed_data: nil}]}
          expected = [{errors: ["The observed_data was missing and is required to determine compliance."], statute: "99.99.999.A"}].to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected

          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["compliance"], observed_data: {}}]}
          expected = [{errors: ["The observed_data was missing and is required to determine compliance."], statute: "99.99.999.A"}].to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns an error message JOSN if the compliance and observed_data parameter is specified but the JSON data does not have a requirements attribute" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["compliance"], observed_data: {foo: "bar"}}]}
          expected = [{errors: ["The requirements for this statute to determine compliance were missing."], statute: "99.99.999.A"}].to_json
        
          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns true for a valid statute when supplied with valid statute, retrieve compliance parameter, and observed_data that is within the requirements" do
          get "/", {statutes: [{statute: "12.34.567.A", 
                                retrieve: ["compliance"], 
                                observed_data: {sources: ["cats"], 
                                                value: 65,
                                                units: "dBA"}
                                }]}
          expected = [{statute: "12.34.567.A", compliance: true}].to_json
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
        it "returns false for a valid statute when supplied with valid statute, retrieve compliance parameter, and observed_data that is not within the requirements" do
          get "/", {statutes: [{statute: "12.34.567.A",
                                retrieve: ["compliance"],
                                observed_data: {sources: ["cats"],
                                                value: 95,
                                                units: "dBA"}
                                }]}
          expected = [{statute: "12.34.567.A", compliance: false}].to_json
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
      end
    end
  end
end