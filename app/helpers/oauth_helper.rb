#TODO pass flags as options
module OauthHelper
  ##############################################################################
  # This method fetches an access token using the refresh token; Tranquilize   #
  # will try this method if the access token is not valid when we attempt to   #
  # use it.                                                                    #
  ##############################################################################
  def self.get_at_using_rt(oauth_data)

    url = oauth_data['base_uri'] + oauth_data['token_endpoint']

    curl_command = "curl #{ControlHelper.proxy_if_needed()} -s -S -X POST -d grant_type=refresh_token \
                                         -d client_id=#{oauth_data['client_id']}  \
                                         -d client_secret=#{oauth_data['client_secret']}  \
                                         -d redirect_url=#{oauth_data['callback_uri']} \
                                         -d refresh_token=#{oauth_data['refresh_token']} \
                                         #{oauth_data['base_uri']+oauth_data['token_endpoint']}"
    OutputHelper.puts_opt("  >> CURL COMMAND >> #{curl_command}","show_curl")
    result_json = `#{curl_command}`
    OutputHelper.puts_opt("    >> RESPONSE TXT >> #{result_json}","show_response")

    result = result_json =JSON.parse(result_json)
    if (result["error"]) then
      return false
    else
      OutputHelper.puts_opt("Got access token using refresh token - updating oauth.json file with updated tokens","progress")
      oauth_data["access_token"]=result["access_token"]
      oauth_data["refresh_token"]=result["refresh_token"]
      JsonHelper.write_file(ControlHelper.location_of('oauth'),oauth_data)
      return true
    end

  end

  ##############################################################################
  # This method fetches an access token using the code; Tranquilize will try   #
  # this is if the access token is invalid, e.g., expired, and the refresh     #
  # token did not work either to get a valid access token. This is the last try#
  # before giving up completely.                                               #
  ##############################################################################
  def self.get_at_using_code(oauth_data)

    curl_command="curl  #{ControlHelper.proxy_if_needed()}  -s -S -X POST -d grant_type=authorization_code \
             -d client_id=#{oauth_data['client_id']} \
             -d client_secret=#{oauth_data['client_secret']} \
             -d redirect_uri=#{oauth_data['callback_uri']} \
             -d code=#{oauth_data['code']}  #{oauth_data['base_uri']+oauth_data['token_endpoint']}"
    
    OutputHelper.puts_opt(curl_command,"show_curl")

    result_json = `#{curl_command}`
    result =JSON.parse(result_json)
    OutputHelper.puts_opt("Curl Result:","show_curl")
    OutputHelper.puts_opt(result,"show_curl")
    
    if (result["error"]) then
      return false
    else
      OutputHelper.puts_opt("Got access token from code - updating oauth.json file with updated tokens","process")
      oauth_data["access_token"]=result["access_token"]
      oauth_data["refresh_token"]=result["refresh_token"]
      JsonHelper.write_file(ControlHelper.location_of('oauth'),oauth_data)
      return true
    end

  end
  ##############################################################################
  # This method will attempt to verify the access token by calling a test      #
  # collection API with the supplied credentials.  If it succeeds all is good  #
  # otherwise we will try to refresh the token using the refresh token, and if #
  # that fails, finally we try to get the access token using the client code.  #
  # If that fails, we have to give up.                                         #
  ##############################################################################

  def self.get_at(oauth_data,example_collection_uri)
    # Make the initial call using the supplied information
    if(ApiHelper.try_simple_get(oauth_data,example_collection_uri)["code"]=="200") then
      OutputHelper.puts_opt("Access Token Valid","progress")
      return true
    else
      # Current access token is not good enough, try using the refresh token.
      OutputHelper.puts_opt("Access Token Missing or Invalid ... trying to refresh","progress")
      # Note, if successful this method writes out the new information into the control file
      at=get_at_using_rt(oauth_data)
      if(at) then
        OutputHelper.puts_opt("Access Token Refreshed","progress")
        return true
      else
        # Finally, try the client code to get an access token.
        OutputHelper.puts_opt("Could not Refresh due to invalid or Missing Refresh Token .. seeing if Code has been supplied","progress")
        at=get_at_using_code(oauth_data)
        if(at) then
          OutputHelper.puts_opt("Access token obtained via code","progress")
          return true
        else
          get_code_url = get_code_url(oauth_data)
          OutputHelper.puts_opt("Could not verify access token or use refesh token or code. Visit #{get_code_url} to get a new code","progress")
          return false
        end
      end
    end
    
  end

  ##############################################################################
  # This method simply uses the supplied OAuth data to construct the URL needed#
  # to fetch a new client code, with which the OAuth data for the run can be   #
  # updated so that the compliance check can be executed.                      #
  ##############################################################################
  def self.get_code_url(oauth_data)
    return "#{oauth_data['base_uri']+oauth_data['authorize_endpoint']}?client_id=#{oauth_data['client_id']}&scope=#{oauth_data['scope']}&redirect_uri=#{oauth_data['callback_uri']}&response_type=code"
  end

end
