require 'sinatra'
require 'json'

class StatuteApi < Sinatra::Base
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
    refer_to_section_array = []

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
        statute_requirements = @statutes[data["statute"]][@routes[1]]
        if statute_requirements.nil?
          payload["errors"] << "The #{@routes[1]} for this statute to determine #{@routes[2]} were missing."
          payload_array << payload
          next
        end

        observed_data = data["observed_data"]
        if observed_data.nil? && statute_requirements.select{|r| r.keys.include?("refer_to_section")}.empty?
          payload["errors"] << "The observed_data was missing and is required to determine #{@routes[2]}."
          payload_array << payload
          next
        end

        outcome, required_actions, refer_to_section_found = determine_compliance(statute_requirements, observed_data)
        refer_to_section_array += refer_to_section_found unless refer_to_section_found.empty?
        payload[@routes[2]] = outcome
        payload["required_actions"] = required_actions unless required_actions.empty?
      end
      payload.delete("errors") if payload["errors"].empty?
      payload_array << payload
    end

    unless refer_to_section_array.empty?
      dependant_results = []
      refer_to_section_array.each do |refer_to_section|
        dependant_results += refer_to_section["requires"].collect do |dependant|
          payload_array.select{|payload| payload["statute"] == dependant["statute"]}[0]["compliance"]
        end
        result = dependant_results.all?{|d| d == true }

        section_with_dependency = payload_array.select{|payload| payload["statute"] == refer_to_section["statute"]}
        unless section_with_dependency[0]["compliance"] == false
          payload_array.map! do |payload|
            if payload["statute"] == refer_to_section["statute"]
              payload["refer_to_section_compliance"] = result
            end
            payload
          end
        end
      end

      payload_array.map! do |payload|
        unless payload["refer_to_section_compliance"].nil?
          unless payload["compliance"] == false
            payload["compliance"] = payload["refer_to_section_compliance"]
            payload.delete("refer_to_section_compliance")
          end
        end
        payload
      end
    end
    return return_data(payload_array)
  end

  def return_data(data)
    if data.any?{|d| !d["errors"].nil? && !d["errors"].empty? }
      status 400
    else
      status 200
    end
    {statutes: data}.to_json
  end

  def extract_relavent_data(data)
    data.select{|k,v| ["sources","value","units","location","when","conditional","refer_to_section","required_action"].include?(k) }
  end

  def is_within_constraints?(conditional, requirement, data)
    requirement = extract_relavent_data(requirement)
    data = extract_relavent_data(data)

    unless (requirement["sources"] & data["sources"]) == data["sources"]
      return false, nil
    end
    unless requirement["units"] == data["units"]
      return false, nil
    end

    outcome = []
    requirement["value"].each do |restraint_hash|
      restraint = restraint_hash.keys.first
      value = restraint_hash.values.first.to_s
      case restraint
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
    refer_to_section = []

    requirements.each do |requirement|
      if requirement["conditional"]
        result, required_action = is_within_constraints?(requirement["conditional"], requirement, data)
        outcome << result
        required_actions << required_action if required_action
      end
      if requirement["refer_to_section"]
        refer_to_section += requirement["refer_to_section"]
      end
    end

    if outcome.empty? && !refer_to_section.empty?
      outcome = [true]
    end
    overall_outcome = outcome.all?{|x| x == true }
    
    return overall_outcome, required_actions, refer_to_section
  end
end