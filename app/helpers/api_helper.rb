#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options
#TODO Could Replace this with a http request gem/lib (eg. typheous)

@@last_request_id
  
module ApiHelper
    
  def self.set_request_id
    @@last_request_id = Time.now.nsec.to_s
  end
    
  def self.last_request
    return @@last_request_id
  end
  def self.clear_request_id
    @@last_request_id=nil
  end
  
  def self.last_request_msg
    "Check request / response with id = #{last_request} for more details"
  end
  
  def self.parse_response(response_txt)
    response = Hash.new
    headers = Hash.new

    header_and_body = false
    status_line=true
    header_section = false
    body_section=false
    has_headers = false
    has_body= false
    
    response_txt.split("\n").each do |line|
      if status_line then
        response["status_line"] = line.strip
        response["http_version"],response["code"] ,response["reason_msg"] = response["status_line"].split(/\s+/,3)
        status_line = false
        header_section = true
      elsif header_section then
        #           puts "Header Line: #{line}"
        if line=~/^\s*$/ then
          #             puts "Found Blank Line"
          response["headers"]=headers
          header_section = false
          body_section = true
        else
          has_headers = true
          header_name,header_value =line.split(":",2)
          #             puts "Line with Header to assign #{header_name} #{header_value}" 
          headers[header_name]=header_value.strip
        end
      elsif body_section then
        #          puts "Body Line: #{line}"
        has_body= true
        response.has_key?("body") ? response["body"] << (line + "\n") : response["body"] = (line + "\n") 
      end  
    end
    response['has_headers'] = has_headers
    response['has_body'] = has_body
    return response
    
    
  end  
  
 
  def self.options(resource_url,oauth_data,code_only,expected_codes)
    
    base_uri = (ControlHelper.data['api_base_uri'] ? ControlHelper.data['api_base_uri'] : oauth_data['base_uri'])
    
    # curl asking for headers and body -i shows headers, -s disables progress meter, -S shows curl errors, -k insecure
    curl = "curl #{ControlHelper.proxy_if_needed()}  -i -s -S -k  -X OPTIONS  -H 'Accept: application/json'  -H 'Authorization:Bearer #{oauth_data['access_token']}' '#{base_uri}#{resource_url}' "
    
    self.handle_request(curl,expected_codes,'OPTIONS')
  end
  
  # create request id 
  # exec curl and form result      
  def self.handle_request(curl,expected_codes,operation)
    
    
    request = self.set_request_id
    OutputHelper.puts_opt("(id=#{request}) #{curl}","show_curl") 
    response_txt =  `#{curl}`      
    response = parse_response(response_txt)
    # deal with proxies that package response in body and add their own status line. Gatekeeper can do this sometimes
    if(ControlHelper.data['response_as_body_allowed']=='true')
      if (response['body'].start_with?("HTTP")) 
        response=parse_response(response['body'])
      end  
    end     
    
    OutputHelper.puts_opt(JSON.pretty_generate(response),"show_response")
    
    if expected_codes 
      OutputHelper.fatal_msg("#{operation} returned #{response["code"]} when allowable codes were #{expected_codes}") if !expected_codes.include?(response["code"])
    end
    
    return response
  end  
  
  def self.get(resource_url,oauth_data,code_only,expected_codes)
    
    # if the url passed starts with the http protocol we regard as absolute!
    
    if /^http/=~resource_url 
      base_uri = ''
    else   
      base_uri = (ControlHelper.data['api_base_uri'] ? ControlHelper.data['api_base_uri'] : oauth_data['base_uri'])
    end 
    
    # curl asking for headers and body -i shows headers, -s disables progress meter, -S shows curl errors, -k insecure
    curl = "curl #{ControlHelper.proxy_if_needed()}  -i -s -S -k  -X GET  -H 'Accept: application/json'  -H 'Authorization:Bearer #{oauth_data['access_token']}' '#{base_uri}#{resource_url}' "
    self.handle_request(curl,expected_codes,'GET')
    
  end
  
  def self.try_simple_get(oauth_data,collection_uri)
    
    result = get(collection_uri,oauth_data,true,nil)  

    return result
  end
  
end
