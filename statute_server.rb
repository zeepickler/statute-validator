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
      return return_error_msg("The text for this statue was not found.")
    else
      payload[@routes[0]] = statute_text
    end
  end
  if retrieve.include?("requirements")
  end
  if retrieve.include?()
end

def return_error_msg(msg)
  content_type :json
  {error: msg}.to_json
end