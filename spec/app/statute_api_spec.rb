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
        expected = {statutes: [{errors: ["A statute was not specified."]}]}.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
      it "returns an error message JSON if a JSON statute parameter value of an empty string is supplied" do
        get "/", {statutes: [{statute: ""}]}
        expected = {statutes: [{errors: ["A statute was not specified."]}]}.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
      it "returns an error message JSON if a JSON statute parameter value is supplied that is not found in the source JSON file" do
        get "/", {statutes: [{statute: "55.55.55"}]}
        expected = {statutes: [{errors: ["The statute '55.55.55' was not found."]}]}.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
    end
    describe "retrieve parameter" do
      it "returns an error message JSON if the retrieve parameter is not specified" do
        get "/", {statutes: [{statute: "12.34.567.A"}]}
        expected = {statutes: [{errors: ["The 'retrieve' parameter was not specified."], statute: "12.34.567.A"}]}.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq expected
      end
      describe "text" do
        it "returns an error message JSON if the JSON data does not have a text attribute" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["text"]}]}
          expected = {statutes: [{errors: ["The text for this statute was not found."], statute: "99.99.999.A"}]}.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns the text for a valid statute with text when supplied with a valid statute and retrieve text" do
          get "/", {statutes: [{statute: "12.34.567.A", retrieve: ["text"]}]}
          expected = {statutes: [{statute: "12.34.567.A", text: "Example of a valid statute."}]}.to_json

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
      end
      describe "requirements" do
        it "returns an error message JSON if the JSON data does not have a requirements attribute" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["requirements"]}]}
          expected = {statutes: [{errors: ["The requirements for this statute were not found."], statute: "99.99.999.A"}]}.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns the requirements for a valid statute with requirements when supplied with a valid statute and retrieve requirements" do
          get "/", {statutes: [{statute: "12.34.567.A", retrieve: ["requirements"]}]}
          expected = {statutes: [{statute: "12.34.567.A", requirements: [{conditional:"include",sources: ["cats","dogs"],value: [{maximum: 85}],units: "dBA"}]}]}.to_json
        
          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
      end
      describe "compliance" do
        it "returns an error message JSON if the compliance parameter is specified but the observed_data parameter is not specified" do
          get "/", {statutes: [{statute: "99.99.999.B", retrieve: ["compliance"]}]}
          expected = {statutes: [{errors: ["The observed_data was missing and is required to determine compliance."], statute: "99.99.999.B"}]}.to_json
        
          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns an error message JSON if the compliance parameter is specified but the observed_data parameter value is nil or empty" do
          get "/", {statutes: [{statute: "99.99.999.B", retrieve: ["compliance"], observed_data: nil}]}
          expected = {statutes: [{errors: ["The observed_data was missing and is required to determine compliance."], statute: "99.99.999.B"}]}.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected

          get "/", {statutes: [{statute: "99.99.999.B", retrieve: ["compliance"], observed_data: {}}]}
          expected = {statutes: [{errors: ["The observed_data was missing and is required to determine compliance."], statute: "99.99.999.B"}]}.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns an error message JSON if the compliance and observed_data parameter is specified but the JSON data does not have a requirements attribute" do
          get "/", {statutes: [{statute: "99.99.999.A", retrieve: ["compliance"], observed_data: {foo: "bar"}}]}
          expected = {statutes: [{errors: ["The requirements for this statute to determine compliance were missing."], statute: "99.99.999.A"}]}.to_json
        
          expect(last_response.status).to eq 400
          expect(last_response.body).to eq expected
        end
        it "returns true for a valid statute when supplied with valid statute, retrieve compliance parameter, and observed_data that is within the requirements" do
          get "/", {statutes: [{statute: "12.34.567.A", 
                                retrieve: ["compliance"], 
                                observed_data: {sources: ["cats"], 
                                                value: 65,
                                                units: "dBA"}}]}
          expected = {statutes: [{statute: "12.34.567.A", compliance: true}]}.to_json

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
        it "returns false for a valid statute when supplied with valid statute, retrieve compliance parameter, and observed_data that is not within the requirements" do
          get "/", {statutes: [{statute: "12.34.567.A",
                                retrieve: ["compliance"],
                                observed_data: {sources: ["cats"],
                                                value: 95,
                                                units: "dBA"}}]}
          expected = {statutes: [{statute: "12.34.567.A", compliance: false}]}.to_json

          expect(last_response.status).to eq 200
          expect(last_response.body).to eq expected
        end
        describe "refer_to_section" do
          describe "with no local conditional" do
            it "should determine compliance is true when valid data is supplied within the requirements" do
              get "/", {statutes: [{statute: "22.22.222.A", retrieve: ["compliance"]},
                                   {statute: "22.22.222.C", 
                                    retrieve: ["compliance"],
                                    observed_data: {sources: ["left_hand"],
                                                    value: 4,
                                                    units: "fingers"}}]}
              expected = {statutes: [{statute: "22.22.222.A", compliance: true},
                                     {statute: "22.22.222.C", compliance: true}]}.to_json
                                     
              expect(last_response.status).to eq 200
              expect(last_response.body).to eq expected
            end
            it "should determine compliance is false when valid data is supplied outside the requirements" do
              get "/", {statutes: [{statute: "22.22.222.A", retrieve: ["compliance"]},
                                  {statute: "22.22.222.C",
                                   retrieve: ["compliance"],
                                   observed_data: {sources: ["left_hand"],
                                                   value: 8,
                                                   units: "fingers"}}]}
              expected = {statutes: [{statute: "22.22.222.A", compliance: false},
                                     {statute: "22.22.222.C", compliance: false}]}.to_json

              expect(last_response.status).to eq 200
              expect(last_response.body).to eq expected
            end
          end
          describe "with a local conditional" do
            it "should determine compliance is true when valid data is supplied within the requirements" do
              get "/", {statutes: [{statute: "22.22.222.B",
                                    retrieve: ["compliance"],
                                    observed_data: {sources: ["right_hand"],
                                                    value: 4,
                                                    units: "fingers"}},
                                   {statute: "22.22.222.C",
                                    retrieve: ["compliance"],
                                    observed_data: {sources: ["left_hand"],
                                                    value: 4,
                                                    units: "fingers"}}]}
              expected = {statutes: [{statute: "22.22.222.B", compliance: true},
                                     {statute: "22.22.222.C", compliance: true}]}.to_json

              expect(last_response.status).to eq 200
              expect(last_response.body).to eq expected
            end
            it "should determine local compliance is false when valid data is supplied locally outside the requirements but dependent section is inside the requirements" do
              get "/", {statutes: [{statute: "22.22.222.B",
                                    retrieve: ["compliance"],
                                    observed_data: {sources: ["right_hand"],
                                                    value: 8,
                                                    units: "fingers"}},
                                    {statute: "22.22.222.C",
                                     retrieve: ["compliance"],
                                     observed_data: {sources: ["left_hand"],
                                                     value: 4,
                                                     units: "fingers"}}]}
              expected = {statutes: [{statute: "22.22.222.B", compliance: false},
                                     {statute: "22.22.222.C", compliance: true}]}.to_json

              expect(last_response.status).to eq 200
              expect(last_response.body).to eq expected
            end
            it "should determine local compliance is false when valid data is supplied locally inside the requirements but dependent section is outside the requirements" do
              get "/", {statutes: [{statute: "22.22.222.B",
                                    retrieve: ["compliance"],
                                    observed_data: {sources: ["right_hand"],
                                                    value: 4,
                                                    units: "fingers"}},
                                    {statute: "22.22.222.C",
                                     retrieve: ["compliance"],
                                     observed_data: {sources: ["left_hand"],
                                                     value: 8,
                                                     units: "fingers"}}]}
              expected = {statutes: [{statute: "22.22.222.B", compliance: false},
                                     {statute: "22.22.222.C", compliance: false}]}.to_json

              expect(last_response.status).to eq 200
              expect(last_response.body).to eq expected
            end
          end
        end
        describe "source all" do
          it "returns true for a valid statute supplied with valid statute, retrieve compliance parameter, and observed_data given any source" do
            get "/", {statutes: [{statute: "33.33.333.A",
                                  retrieve: ["compliance"],
                                  observed_data: {sources: ["alien"],
                                                  value: 3,
                                                  units: "feet"}}]}
            expected = {statutes: [{statute: "33.33.333.A", compliance: true}]}.to_json

            expect(last_response.status).to eq 200
            expect(last_response.body).to eq expected
          end
        end
        describe "when for time units" do
          describe "given a valid statute supplied with valid statute, retrieve compliance parameter, and observed_data" do
            describe "for invalid when observed_data" do
              it "returns an error for invalid formatted date" do
                expected = {statutes: [{errors: ["when date could not be formatted (expects 'YYYY-MM-DD')"], statute: "44.44.444.A"}]}.to_json
                invalid_date_formats = ["2000-100-01",
                                        "2000-01-100",
                                        "AB-01-01",
                                        "2000-AB-01",
                                        "2000-01-AB",
                                        "200012-01",
                                        "2000-1201",
                                        "2001-01-01A",
                                        "A2001-01-01",
                                        "@#%#@!...."]
                
                invalid_date_formats.each do |invalid_date_format|
                  get "/", {statutes: [{statute: "44.44.444.A",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: invalid_date_format }}]}

                  expect(last_response.status).to eq 400
                  expect(last_response.body).to eq expected
                end
              end
              it "returns an error for an invalid calendar date" do
                expected = {statutes: [{errors: ["when date was not valid date (check calendar date)"], statute: "44.44.444.A"}]}.to_json
                invalid_calendar_dates = ["2000-13-01",
                                          "2000-12-32"]
                invalid_calendar_dates.each do |invalid_calendar_date|
                  get "/", {statutes: [{statute: "44.44.444.A",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: invalid_calendar_date }}]}

                  expect(last_response.status).to eq 400
                  expect(last_response.body).to eq expected
                end
              end
            end
            it "returns true if the observed_data is a valid formatted date" do
              expected = {statutes: [{statute: "44.44.444.A", compliance: true}]}.to_json
              valid_date_formats = ["2000-01-01",
                                    "20000-01-01",
                                    "2000/01/01",
                                    "20000/01/01"]
              valid_date_formats.each do |valid_date_format|
                get "/", {statutes: [{statute: "44.44.444.A",
                                      retrieve: ["compliance"],
                                      observed_data: {sources: ["vampires"],
                                                      value: "3:00",
                                                      units: "time",
                                                      when: valid_date_format }}]}

                expect(last_response.status).to eq 200
                expect(last_response.body).to eq expected
              end
            end
            describe "given a when requirement with daily" do
              it "returns true for any day" do
                get "/", {statutes: [{statute: "44.44.444.A",
                                      retrieve: ["compliance"],
                                      observed_data: {sources: ["vampires"],
                                                      value: "3:00",
                                                      units: "time",
                                                      when: "2022-01-01" }}]}
                expected = {statutes: [{statute: "44.44.444.A", compliance: true}]}.to_json

                expect(last_response.status).to eq 200
                expect(last_response.body).to eq expected
              end
            end
            describe "given a when requirement with only a single day" do
              it "return true when observed_data when date is within the requirements" do
                get "/", {statutes: [{statute: "44.44.444.B",
                                      retrieve: ["compliance"],
                                      observed_data: {sources: ["vampires"],
                                                      value: "3:00",
                                                      units: "time",
                                                      when: "2016-01-10" }}]}
                expected = {statutes: [{statute: "44.44.444.B", compliance: true}]}.to_json

                expect(last_response.status).to eq 200
                expect(last_response.body).to eq expected
              end
              it "returns false when observed_data when date is outside the requirements" do
                get "/", {statutes: [{statute: "44.44.444.B",
                                      retrieve: ["compliance"],
                                      observed_data: {sources: ["vampires"],
                                                      value: "3:00",
                                                      units: "time",
                                                      when: "2016-01-11" }}]}
                expected = {statutes: [{errors: ["weekdays required and not found"], statute: "44.44.444.B"}]}.to_json


                expect(last_response.status).to eq 400
                expect(last_response.body).to eq expected
              end
            end
            describe "given a when requirement with multiple days" do 
              it "returns true when observed_data when date is within the requirements" do
                valid_dates = ["2016-01-06",
                               "2016-01-07"]
                expected = {statutes: [{statute: "44.44.444.C", compliance: true}]}.to_json
                valid_dates.each do |valid_date|
                  get "/", {statutes: [{statute: "44.44.444.C",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: valid_date }}]}
                  expect(last_response.status).to eq 200
                  expect(last_response.body).to eq expected
                end
              end
              it "returns false when observed_data when date is outside the requirements" do
                invalid_dates = ["2016-01-05",
                                 "2016-01-08"]
                expected = {statutes: [{errors: ["weekdays required and not found"], statute: "44.44.444.C"}]}.to_json
                invalid_dates.each do |invalid_date|
                  get "/", {statutes: [{statute: "44.44.444.C",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: invalid_date}}]}
                  expect(last_response.status).to eq 400
                  expect(last_response.body).to eq expected
                end
              end
            end
            describe "given a when requirement with legal_holidays only" do
              it "returns true when observed_data when date is within the requirements" do
                legal_holidays_2016 = ["2016-01-01",
                                       "2016-01-18",
                                       "2016-02-15",
                                       "2016-05-30",
                                       "2016-07-04",
                                       "2016-09-05",
                                       "2016-11-11",
                                       "2016-11-24",
                                       "2016-12-25"]
                expected = {statutes: [{statute: "44.44.444.D", compliance: true}]}.to_json
                legal_holidays_2016.each do |legal_holiday|
                  get "/", {statutes: [{statute: "44.44.444.D",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: legal_holiday}}]}
                  expect(last_response.status).to eq 200
                  expect(last_response.body).to eq expected
                end
              end
              it "returns false when observed_data when date is outside the requirements" do
                not_legal_holidays_2016 = ["2016-01-02",
                                           "2016-09-04",
                                           "2016-12-24"]
                expected = {statutes: [{statute: "44.44.444.D", compliance: false}]}.to_json
                not_legal_holidays_2016.each do |not_legal_holiday|
                  get "/", {statutes: [{statute: "44.44.444.D",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: not_legal_holiday}}]}
                  expect(last_response.status).to eq 200
                  expect(last_response.body).to eq expected
                end
              end
            end
            describe "given a when requirement of legal_holidays or Thursday or Friday" do
              it "returns true when observed_data when date is within the requirements" do
                valid_days = ["2016-01-01",
                              "2016-01-18",
                              "2016-02-15",
                              "2016-05-30",
                              "2016-07-04",
                              "2016-09-05",
                              "2016-11-11",
                              "2016-11-24",
                              "2016-12-25",
                              "2016-12-29",
                              "2016-12-30"]
                expected = {statutes: [{statute: "44.44.444.E", compliance: true}]}.to_json
                valid_days.each do |valid_day|
                  get "/", {statutes: [{statute: "44.44.444.E",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: valid_day}}]}
                  expect(last_response.status).to eq 200
                  expect(last_response.body).to eq expected
                end
              end
              it "returns false when observed_data when date is outside the requirements" do
                invalid_days = ["2016-12-05",
                                "2016-12-06"]
                expected = {statutes: [{statute: "44.44.444.E", compliance: false}]}.to_json
                invalid_days.each do |invalid_day|
                  get "/", {statutes: [{statute: "44.44.444.E",
                                        retrieve: ["compliance"],
                                        observed_data: {sources: ["vampires"],
                                                        value: "3:00",
                                                        units: "time",
                                                        when: invalid_day}}]}
                  expect(last_response.status).to eq 200
                  expect(last_response.body).to eq expected
                end                
              end
            end
          end
        end
      end
    end
  end
end