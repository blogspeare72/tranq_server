class Rules

  def initialize(api_metadata,violations,o_rest_schemas,oauth_data,standards)
    @api_metadata = api_metadata
    @violations = violations
    @o_rest_schemas=o_rest_schemas
    @oauth_data = oauth_data
    @standards = standards
  end


  def add_additional_get_parameters(uri,resource)

    if (resource["supported_operations"])
      puts "has supported ops"
      if resource["supported_operations"].has_key?("GET")
        get = resource["supported_operations"]["GET"]
        if get["additional_parameters"]
          puts "has additional params"
          if uri.include?("?")
            return uri+"&"+get["additional_parameters"]
          else
            return uri+"?"+get["additional_parameters"]
          end
        end


      end

    end

    return uri

  end

  def validate_body_against_schema(resource,response,schema_name,s_id)
    OutputHelper.puts_opt("Validating  #{response["body"]} against #{@o_rest_schemas[schema_name]}","show_validation")
    errors = JSON::Validator.fully_validate(@o_rest_schemas[schema_name], response["body"], :errors_as_objects => true, :validate_schema => true)
    puts errors
    ApiMetadataHelper.resolve_standard_with_violation(resource,@violations,s_id,"Error: #{response["body"]} not valid against #{schema_name}",ApiMetadataHelper::HOW_RESOLVED__AUTOMATED) if errors.size>0


  end

  def self.uri_differs_msg(resource,uri)
    msg = "Resource URI Given as #{resource["documented_uri"]} but calculated to be #{uri} based on metadata"
    return msg
  end


  def self.singular_in_collection(resource_name)
    resource_name.pluralize+'/'+":ID"
  end


  def self.context_version(resource)
    return resource["context"]+'/'+resource["version"]
  end


  def self.compare_uris_log_violation(uri1,uri2,resource,violations,s_id)
    if (uri1 != uri2) then
      msg = uri_differs_msg(resource,uri1)

      ViolationHelper.add_violation(resource,violations,s_id,msg)
      ApiMetadataHelper.update_standard_checks_required(s_id,resource,"resolved","automated","N")

    else
      ApiMetadataHelper.update_standard_checks_required(s_id,resource,"resolved","automated","Y")
    end
  end


  def standard_supported(resource,s_id)
    StandardsHelper.get_standard_by_id(s_id)
    selected = resource["triggering_standards"].select{ |ts| ts['id']==s_id&&ts['value']==ApiMetadataHelper::TRIGGERING_STANDARD__SUPPORTED}
    return true if selected.size ==1
    return false
  end

  def resource_metadata_endpoint(resource)
    return resource["documented_uri"].gsub(/#{resource["resource"]}/,"metadata-catalog/#{resource["resource"]}")
  end


  def resources_of_types(type)

    @rs = []
    @api_metadata["contexts"].each{|context| context["versions"].each{ |version| version["resources"].each{ |resource| @rs << resource if type.include?(resource["resource_type"])} } }
    return  @rs

  end

  def version_lookup(context_name,version_name)
    for context in  @api_metadata["contexts"]
      if (context['context']==context_name)
        for version in context["versions"]

          if (version['version']==version_name)
            return version
          end

        end
      end
    end
    OutputHelper.fatal_msg("Version not found #{context_name} #{version_name}")
  end


  def resolve_standard_on_codes_with_violation(r,s_id,value,msg_hash,how_resolved)
    puts "add v on codes #{value} #{msg_hash}"
    if msg_hash.key?(value)

      ApiMetadataHelper.resolve_standard_with_violation(r,@violations,s_id,msg_hash[value],how_resolved)

      puts "added violation"
      return true
    end
    return false
  end

  def validate_error_against_exception_schema(r,http_status_code,http_status_codes_in,http_status_codes_not_in,error)

    OutputHelper.puts_opt("validate error against exception schema","rules")
    code_matches_in_list = http_status_codes_in ?  http_status_codes_in.include?(http_status_code)  : false
    code_matches_not_in_list = http_status_codes_not_in ?  !http_status_codes_not_in.include?(http_status_code)  : false
    OutputHelper.puts_opt("validate error. matches (#{code_matches_in_list })in list (#{http_status_codes_in}) . matches(#{code_matches_not_in_list }) not in list (#{http_status_codes_not_in})","rules")
    if (code_matches_in_list  || code_matches_not_in_list ) then
      OutputHelper.puts_opt("Validating Error #{error} against #{@o_rest_schemas["rest-schemas/exception#"]}","detail_debug")
      errors = JSON::Validator.fully_validate(@o_rest_schemas["rest-schemas/exception#"], error, :errors_as_objects => true, :validate_schema => true)
      ApiMetadataHelper.resolve_standard_with_violation(r,@violations,'B010_ADD_ERROR_IN_BODY_AND_EXCEPTION_TYPE',"Error: '#{error}' not valid against oracle exception schema.  #{ApiHelper.last_request_msg()}. Detailed Error #{errors}",ApiMetadataHelper::HOW_RESOLVED__AUTOMATED) if errors.size > 0
    end

  end

  def check_singular_resource_fields_of_type_match_pattern(type,pattern,s_id)
    resources_of_types([ApiMetadataHelper::RESOURCE_TYPE__SINGULAR]).each { |sr| check_fields_match_pattern(sr,type,pattern,s_id) }
  end

  def check_fields_match_pattern(sr,type,pattern,s_id)
    msg_missing = "Update the metadata file to indicate which fields are #{type} for #{sr["resource"]}"
    if !sr[type] then
      ApiMetadataHelper.resolve_standard_with_violation(sr,@violations,s_id,msg_missing,ApiMetadataHelper::HOW_RESOLVED__AUTOMATED)
    else
      msg_matching = "#{type} does not match pattern #{pattern} for #{sr["resource"]} for fields #{sr[type]}"
      sr[type].each { |field| ApiMetadataHelper.resolve_standard_with_violation(sr,@violations,s_id,msg_matching,ApiMetadataHelper::HOW_RESOLVED__AUTOMATED) if !(/#{pattern}/=~field) }
    end
  end

  def first_collection_uri(resources)

    @cr_url = []
    (resources["contexts"].each{|context| context["versions"].each{ |version| version["resources"].each{ |resource| @cr_url << resource["documented_uri"] if resource["resource_type"]==ApiMetadataHelper::RESOURCE_TYPE__COLLECTION } } })

    return @cr_url.first

  end

  def pagination_dimensions(response)
    page_dim=Hash.new
    body = JSON.parse(response["body"])
    page_dim["totalResults"] = body["totalResults"]
    page_dim["limit"] = body["limit"]
    return page_dim
  end

  def verify_pagination_links(response,resource,links_to_verify)
    #  if header_or_body=='header'
    codes = { 'first'=>'G013_PAGE_FIRST_LINK', 'next'=>'G011_PAGE_NEXT_LINK', 'prev'=>"G012_PAGE_PREV_LINK" ,'last'=>'G014_PAGE_LAST_LINK'}
    err_msgs = { 'first' => "First link may be provided if pagination is enabled. If provided, rel must be 'first'.",
      'next' =>"Next link must be provided if pagination is enabled and there is a next page. rel must be 'next'.",
      'prev' =>"Previous link must be provided if pagination is enabled and there is a previous page. rel must be 'prev'.",
      'last' =>"Last link may be provided if pagination is enabled. If provided, rel must be 'last'. " }
    links = Hash.new
    loc_pagination_links = resource["pagination_links_location"]
    OutputHelper.fatal_msg("Resource #{resource["documented_uri"]} supports pagination but metadata does not indicate if pagination links are in header or body") if !loc_pagination_links
    if (loc_pagination_links == ApiMetadataHelper::RESOURCE_PAGE_LINKS__HEADER)
      OutputHelper.fatal_msg("Links in Header not yet supported by checker")
    end
    if  (loc_pagination_links == ApiMetadataHelper::RESOURCE_PAGE_LINKS__BODY)
      links_to_verify.each do |link_to_verify|
        #    puts "links"

        selected_links = JSON.parse(response["body"])["links"].select{ |link| link["rel"]==link_to_verify}
        puts selected_links
        if (selected_links.size==0 || selected_links.size>1)
          puts "couldnt find link #{link_to_verify}- logging violation"
          ApiMetadataHelper.resolve_standard_with_violation(resource,@violations,codes[link_to_verify],err_msgs[link_to_verify],ApiMetadataHelper::HOW_RESOLVED__AUTOMATED)
        elsif (selected_links.size==1)
          #      puts "found link- all ok"
          links[link_to_verify]=selected_links[0]["href"]
        end

      end
    end

    return links
  end

  def run_rule(arule)

    OutputHelper.puts_opt("Running rule: #{arule.code}",'rules');
    eval(arule.rule_code)
    OutputHelper.puts_opt("Finished rule: #{arule.code}",'rules');

  end

end
