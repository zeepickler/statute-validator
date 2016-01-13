require 'sinatra'
require 'json'
require 'chronic'
require 'date'

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

        outcome, required_actions, refer_to_section_found, reasons_for_noncompliance, errors = determine_compliance(statute_requirements, observed_data)
        unless errors.empty?
          payload["errors"] << errors.join(", ")
          payload_array << payload
          next
        end
        refer_to_section_array += refer_to_section_found unless refer_to_section_found.empty?
        payload[@routes[2]] = outcome
        payload["reasons_for_noncompliance"] = reasons_for_noncompliance
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

  get '/demo' do

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

  def comparison_reason(requirement, data, item)
    return "The required #{item} (#{requirement[item].join(", ")}) does not match the observed_data (#{data[item].join(", ")})."
  end

  def is_within_constraints?(conditional, requirement, data)
    errors = []
    reasons_for_noncompliance = []
    requirement = extract_relavent_data(requirement)
    data = extract_relavent_data(data)

    unless ((requirement["sources"] & data["sources"]) == data["sources"]) || (requirement["sources"] == ["all"])
      reasons_for_noncompliance << comparison_reason(requirement, data, "sources")
    end
    unless requirement["units"] == data["units"]
      reasons_for_noncompliance << comparison_reason(requirement, data, "units")
    end

    # when:
    # requirements 'when' possible values (and any combination of):
    # - daily
    # - legal_holidays
    # - Sunday
    # - Monday
    # - Tuesday
    # - Wednesday
    # - Thursday
    # - Friday
    # - Saturday
    #
    # when used in combination all must be true ie. ["Sunday", "legal_holiday"], day must be on Sunday and a legal holiday
    if requirement["when"]
      formattable_date, date = format_date(data["when"])
      if formattable_date
        data["when"] = date
      else
        return false, nil, reasons_for_noncompliance, ["when date could not be formatted (expects 'YYYY-MM-DD')"]
      end
      unless data["when"] && date_valid?(data["when"])
        return false, nil, reasons_for_noncompliance, ["when date was not valid date (check calendar date)"]
      end
      if requirement["when"].include?("daily")
        # do nothing
      end
      legal_holidays_present = false
      weekdays_present = false
      legal_holidays_found = false
      weekdays_found = false
      if requirement["when"].include?("legal_holidays")
        legal_holidays_present = true
        legal_holidays = get_legal_holidays(get_date_year(data["when"]))
        if legal_holidays.include?(data["when"])
          legal_holidays_found = true
        end
      end
      weekdays = requirement["when"] & ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
      unless weekdays.empty?
        weekdays_present = true
        day = Date.parse(data["when"]).strftime("%A")
        if weekdays.any?{|d| d == day }
          weekdays_found = true
        end
      end
      date_errors = []
      if weekdays_present && legal_holidays_present
        date_errors << "weekdays required and not found" unless weekdays_found 
        date_errors << "legal holidays required and not found" unless legal_holidays_found
      elsif weekdays_present
        date_errors << "weekdays required and not found" unless weekdays_found 
      elsif legal_holidays_present
        date_errors << "legal holidays required and not found" unless legal_holidays_found
      end
      unless date_errors.empty?
        reasons_for_noncompliance += date_errors
      end
      unless reasons_for_noncompliance.empty?
        return false, nil, reasons_for_noncompliance, []
      end
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
        return true, requirement["required_action"], [], []
      else
        return false, nil, ["values were not within the included constraints"], []
      end
    when "exclude"
      if overall_outcome
        return false, nil, ["values were within the excluded constraints"], []
      else
        return true, requirement["required_action"], [], []
      end
    end
  end

  def determine_compliance(requirements, data)
    outcome = []
    required_actions = []
    refer_to_section = []
    reasons_for_noncompliance = []
    errors = []

    requirements.each do |requirement|
      if requirement["conditional"]

        result, required_action, found_reasons_for_noncompliance, found_errors = is_within_constraints?(requirement["conditional"], requirement, data)
        outcome << result
        required_actions << required_action if required_action
        reasons_for_noncompliance += found_reasons_for_noncompliance unless found_reasons_for_noncompliance.empty?
        errors += found_errors unless found_errors.empty?
      end
      if requirement["refer_to_section"]
        refer_to_section += requirement["refer_to_section"]
      end
    end

    if outcome.empty? && !refer_to_section.empty?
      outcome = [true]
    end
    overall_outcome = outcome.all?{|x| x == true }
    
    return overall_outcome, required_actions, refer_to_section, reasons_for_noncompliance, errors
  end

  # US Legal Holidays
  def format_date(str)
    unless /^\d{4,}[\/|-]\d{2}[\/|-]\d{2}$/ =~ str
      return false, str
    end
    if str.include?("/")
      if str.count("/") == 2
        str.gsub!("/","-")
      else
        return false, str
      end
    end
    return true, str
  end
  def date_valid?(str, format='%Y-%m-%d')
    begin
      Date.strptime(str,format)
      return true
    rescue
      return false
    end
  end

  def get_date_year(str, format='%Y-%m-%d')
    Date.strptime(str,format).year
  end

  # For fixed holidays: If occurs on a Sat., it is observed on day before (Fri.). If occurs on Sun., it is observed on day after (Mon.).
  def check_fixed_date(date)
    if date.saturday?
      date = date.prev_day
    elsif date.sunday?
      date = date.next_day
    end
    date.strftime("%Y-%m-%d")
  end

  def get_legal_holidays(year)
    legal_holidays = []
    # New Year's Day = Jan. 1st
    legal_holidays << check_fixed_date(Date.new(year,1,1))
    # MLK Jr. Day = 3rd Monday in Jan.
    legal_holidays << Chronic.parse('3rd monday in january', now: Time.local(year,1,1)).strftime('%Y-%m-%d')
    # George Washington's Birthday
    legal_holidays << Chronic.parse('3rd monday in february', now: Time.local(year,1,1)).strftime('%Y-%m-%d')
    # Memorial Day = Last Monday in May
    memorial_day = Date.new(year,5,-1)
    memorial_day -= (memorial_day.wday - 1) % 7
    legal_holidays << memorial_day.strftime('%Y-%m-%d')
    # Independence Day = July 4th
    legal_holidays << Date.new(year,7,4).strftime('%Y-%m-%d')
    # Labor Day = 1st Mon. in Sept.
    legal_holidays << Chronic.parse('1st monday in september', now: Time.local(year,1,1)).strftime('%Y-%m-%d')
    # Veteran's Day = Nov. 11th
    legal_holidays << Date.new(year,11,11).strftime('%Y-%m-%d')
    # Thanksgiving Day = 4th Thurs. in Nov.
    legal_holidays << Chronic.parse('4th thursday in november', now: Time.local(year,1,1)).strftime('%Y-%m-%d')
    # Christmas Day = Dec. 25th
    legal_holidays << Date.new(year,12,25).strftime('%Y-%m-%d')
    return legal_holidays
  end
end