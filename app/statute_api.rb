require 'sinatra'
require 'json'

class StatuteApi < Sinatra::Base
  # example:
  # curl -H "Content-Type: application/json" 
  # -X POST -d '{"foo":"bar"}' http://localhost:4567/

  before do
    @statutes = JSON.parse(File.read(ENV["STATUTE_SOURCE_FILE"]))
    @routes = ["text","requirements","compliance"]
  end

  get '/' do
    content_type :json
    data = params.select{|k,v| ["statute", "retrieve", "observed_data"]}
    if data.empty?
      status 400
      return {errors: ["No JSON data found."]}.to_json
    end
    
    payload_array = []

    data["statutes"].each do |data|
      payload = {}
      payload["errors"] = []

      statute = data["statute"]

      if statute.nil? || statute.empty?
        payload["errors"] << "A statute was not specified."
        payload_array << payload
        next
      elsif @statutes[statute].nil?
        payload["errors"] << "The statute \'#{statute}\' was not found."
        payload_array << payload
        next
      else
        payload["statute"] = statute
      end
      
      retrieve = data["retrieve"]

      if retrieve.nil? || retrieve.empty? || (@routes & retrieve).empty?
        payload["errors"] << "The \'retrieve\' parameter was not specified."
        payload_array << payload
        next
      end
      if retrieve.include?(@routes[0])
        statute_text = @statutes[data["statute"]][@routes[0]]
        if statute_text.nil?
          payload["errors"] << "The #{@routes[0]} for this statute was not found."
          payload_array << payload
          next
        else
          payload[@routes[0]] = statute_text
        end
      end
      if retrieve.include?(@routes[1])
        statute_requirements = @statutes[data["statute"]][@routes[1]]
        if statute_requirements.nil?
          payload["errors"] << "The #{@routes[1]} for this statute were not found."
          payload_array << payload
          next
        else
          payload[@routes[1]] = statute_requirements
        end
      end
      if retrieve.include?(@routes[2])
        observed_data = data["observed_data"]
        if observed_data.nil?
          payload["errors"] << "The observed_data was missing and is required to determine #{@routes[2]}."
          payload_array << payload
          next
        end
        statute_requirements = @statutes[data["statute"]][@routes[1]]
        if statute_requirements.nil?
          payload["errors"] << "The #{@routes[1]} for this statute to determine #{@routes[2]} was missing."
          payload_array << payload
          next
        end
        outcome, required_actions = determine_compliance(statute_requirements, observed_data)
        payload[@routes[2]] = outcome
        unless required_actions.empty?
          payload["required_actions"] = required_actions
        end
      end
      payload_array << payload
    end
    return return_data(payload_array)
  end

  def return_data(data)
    if data.any?{|d| !d["errors"].empty? }
      status 400
    else
      status 200
    end
    data.to_json
  end

  # EXAMPLE ########
  #requirements = [
  #      {"source": ["trucks",
  #                  "pile drivers", 
  #                  "pavement breakers", 
  #                  "scrapers", 
  #                  "concrete saws", 
  #                  "rock drills"],
  #       "value": [{"maximum": 85}],
  #       "units": "dBA",
  #       "conditional": "exclude"}
  #    ]
#
  #observed_data = {
  #  "source": "truck",
  #  "value": 40,
  #  "units": "dBA"
  #}
  ##################

  def extract_relavent_data(data)
    data.select{|k,v| ["source","value","units","location","when","conditional","refer_to_section","required_action"].include?(k) }
  end

  def is_within_constraints?(conditional, requirement, data)
    requirement = extract_relavent_data(requirement)
    data = extract_relavent_data(data)

    unless requirement["source"].include?(data["source"])
      return nil
    end
    unless requirement["units"] == data["units"]
      return nil
    end

    outcome = []
    requirement["value"].each do |conditional, value|
      case conditional
      when "minimum"
        result = data["value"] >= value ? true : false
      when "maximum"
        result = data["value"] <= value ? true : false 
      end
      outcome << result
    end
    overall_outcome = outcome.all?{|x| x == true }

    case conditional
    when "include"
      if overall_outcome
        return true, requirement["required_action"]
      else
        return false, nil
      end
    when "exclude"
      if overall_outcome
        return false, nil
      else
        return true, requirement["required_action"]
      end
    end
    
  end

  def determine_compliance(requirements, data)
    outcome = []
    required_actions = []
    requirements.each do |requirement|
      if requirement["conditional"]
        result, required_action = is_within_constraints?(requirement["conditional"], requirement, data)
      end
      outcome << result
      required_actions << required_action if required_action
    end
    overall_outcome = outcome.all?{|x| x == true }
    return overall_outcome, required_actions
  end
end