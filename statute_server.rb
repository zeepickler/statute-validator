require 'sinatra'
require 'json'

# example:
# curl -H "Content-Type: application/json" 
# -X POST -d '{"foo":"bar"}' http://localhost:4567/

before do
  @statutes = JSON.parse(File.open(ENV[:statute_source_file]))
  @routes = ["text","requirements","compliance"]
end

get '/' do
  data = request.body.read
  if data == ""
    return return_error_msg("No JSON data found.")
  end
  data = JSON.parse(data)

  payload = {}

  statute = data["statue"]

  if statute.nil? || statute.empty?
    return return_error_msg("A statute is not specified.")
  elsif @statutes[statute].nil?
    return return_error_msg("The statute \'#{statute}\' was not found.")
  else
    payload["statute"] = statute
  end
  
  retrieve = data["retrieve"]

  if retrieve.nil? || retrieve.empty? || (@routes & retrieve).empty?
    return return_error_msg("The \'retrieve\' value is not specified.")
  end
  if retrieve.include?(@routes[0])
    statute_text = @statutes[data["statute"]][@routes[0]]
    if statute_text.nil?
      return return_error_msg("The #{@routes[0]} for this statue was not found.")
    else
      payload[@routes[0]] = statute_text
    end
  end
  if retrieve.include?(@routes[1])
    statute_requirements = @statutes[data["statute"]][@routes[1]]
    if statute_requirements.nil?
      return return_error_msg("The #{@routes[1]} for this statute were not found.")
    else
      payload[@routes[1]] = statute_requirements
    end
  end
  if retrieve.include?(@routes[2])
    observed_data = data["observed_data"]
    if observed_data.nil?
      return return_error_msg("The observed_data was missing and is required to determine #{@routes[2]}.")
    end
    statute_requirements = @statutes[data["statute"]][@routes[1]]
    if statute_requirements.nil?
      return return_error_msg("The #{@routes[1]} for this statute to determine #{@routes[2]} was missing.")
    end
    payload[@routes[2]] = determine_compliance(statute_requirements, observed_data)
  end
  return return_data(payload)
end

def return_error_msg(msg)
  content_type :json
  {error: msg}.to_json
end

def return_data(data)
  content_type :json
  data.to_json
end

def determine_compliance(requirements, data)

end