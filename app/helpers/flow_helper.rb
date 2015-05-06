#TODO remove explicit logging statements - when you call a rule we should have some automated logging. Probably write an call_rule method on the rule class that takes care of logging and other generic stuff (could be to resolve any standard the rule is supposed to take care of etc)
  
module FlowHelper
      
# checks command line params and calls the checker with the control file
def self.process_command(cmd,tranquilizer_home)
  
  args = Array(cmd)

  Output.fatal_msg("There should be two command line arguments: the control file and run id") if (args.size!=2)
  Output.fatal_msg("The environment variable TRANQ_HOME must be set") if (!tranquilizer_home)
 
 #   puts RESTChecker.methods
#     ControlHelper.form_stamp()
  puts args[0]
  ControlHelper.load_from_file(args[0],tranquilizer_home,args[1])

  ControlHelper.create_output_dirs
 
#  puts ControlHelper.debug_options
#  puts ControlHelper.stamp
#  exit
  case ControlHelper.action
  when 'check_compliance'
     checker
  when 'standards_json_to_csv'
     Standards.json_to_csv
  when 'standards_csv_to_json'
     Standards.csv_to_json
  end

end

def self.process(control_file, run_id, tranquilizer_home)
  
  ControlHelper.load_from_file(control_file,tranquilizer_home,run_id)

  ControlHelper.create_output_dirs
 
  case ControlHelper.action
  when 'check_compliance'
     checker
  when 'standards_json_to_csv'
     Standards.json_to_csv
  when 'standards_csv_to_json'
     Standards.csv_to_json
  end

end


# main procedure for the checker - uses the control file options to determine what to do and checks APIs described in the API Metadata file for compliance. 
def self.checker

Output.puts_opt("Loading and Validating Standards File ...","progress")
standards_data=JsonHelper.load_data_with_schema_validation(ControlHelper.location_of('standards_schema'), ControlHelper.location_of('standards_data'),true)
standards=standards_data["standards"]
standards_metadata=standards_data["standards_metadata"]
Standards.set_standards(standards)

Output.puts_opt("Loading and Validating API Compliance Metadata ... ","progress")
api_metadata=JsonHelper.load_data_with_schema_validation(ControlHelper.location_of('api_descriptor_schema'),ControlHelper.location_of('api_descriptor'),:stop_on_errors=>true) 

Output.puts_opt("Loading OAuth Info ... ","progress")
Output.puts_opt("Loading OAuth information with new schema validation.","detail_debug")
oauth_data=JsonHelper.load_data_with_schema_validation(ControlHelper.location_of('oauth_schema'),ControlHelper.location_of('oauth'),:stop_on_errors=>true) 
Output.puts_opt("Successfully loaded the oauth data with schema validation.","detail_debug")

#oauth_data=JsonHelper.load_data(ControlHelper.location_of('oauth'))
#puts oauth_data
Output.puts_opt(oauth_data,"debug")

# set a hash up with locations of oracle REST schemas for use in rules
o_rest_schemas = Hash.new
o_rest_schemas["rest-schemas/exception#"] = ControlHelper.location_of('rest-schemas/exception#')
o_rest_schemas["rest-schemas/singularResource#"] = ControlHelper.location_of("rest-schemas/singularResource#")
o_rest_schemas["rest-schemas/collectionResource#"] = ControlHelper.location_of("rest-schemas/collectionResource#")

#write out copies of input data
JsonHelper.write_file(ControlHelper.location_of('copy_of_api_descriptor'),api_metadata)
JsonHelper.write_file(ControlHelper.location_of('copy_of_standards'),standards)
JsonHelper.write_file(ControlHelper.location_of('copy_of_control_file'),ControlHelper.data)

#for each triggering standards (a standard that if supported, triggers other standards) make sure that 'supported' or 'unsupported' is noted in the 
#api metadata. If this info is missing for any triggering standard then exit stating the problem
Output.puts_opt("Validating api metadata file ... ","progress")
ApiMetadata.verify_trigger_info(standards,api_metadata)  
      
# Initialize violations to be empty hash
violations = Hash.new
for standard in standards
  violations[standard["id"]]=[];
end
      
# rules object containst all the necessary logic and data to do rule evaluation      
rules = Rules.new(api_metadata,violations,o_rest_schemas,oauth_data,standards)            
      
# make sure we have a valid access token (OAuth.get_at will try to refresh or exchange code for tokens if possible). Exit nothing works and we don't have
# access token
puts OAuth.get_code_url(oauth_data)        
if (ControlHelper.data["authorization"]=="oauth") then 
  Output.puts_opt("Verifying a valid access token ...","progress")  
  OAuth.get_at(oauth_data,'/'+rules.first_collection_uri(api_metadata)) 
end 

Output.puts_opt("Noting standards requiring validation ...","progress")  
# update the metadata with the set of standards to check for each object (context, version, resource).
# to do this we check the standards file and add the standard to each object with a scope that matches the scopes of the standard
# Where a triggering standard has been noted as not being supported we do NOT add the dependent standards add standards needing checking
ApiMetadata.update_with_standards_to_check(api_metadata,violations,standards)

Output.puts_opt("Checking Standards ...","progress")  
begin
Output.puts_opt("  check_metadata_catalog_valid_against_catalog_schema","rules")
rules.check_metadata_catalog_valid_against_catalog_schema
Output.puts_opt("  check_singular_valid_against_base_singular_schema","rules")
rules.check_singular_valid_against_base_singular_schema
Output.puts_opt("  check_collection_valid_against_base_collection_schema","rules")
rules.check_collection_valid_against_base_collection_schema
Output.puts_opt("  check_get_context_valid_against_collection_schema_and_get_version_valid_against_version_schema","rules")
rules.check_get_context_valid_against_collection_schema_and_get_version_valid_against_version_schema
Output.puts_opt("  check_options_collection_uri_references_metadata_in_header","rules")
rules.check_options_collection_uri_references_metadata_in_header
Output.puts_opt("  check_boolean_fields","rules")
rules.check_boolean_fields
Output.puts_opt("  check_user_fields","rules")
rules.check_user_fields
Output.puts_opt("  check_resource_uri_case","rules")
rules.check_resource_uri_case
Output.puts_opt("  check_resource_uris","rules")
rules.check_resource_uris
Output.puts_opt("  check_collections_plural","rules")
rules.check_collections_plural
Output.puts_opt("  check_version_naming","rules")
rules.check_version_naming
Output.puts_opt("  check_identifier_naming","rules")
rules.check_identifier_naming
Output.puts_opt("  check_resource_metadata_application_json","rules")
rules.check_resource_metadata_application_json
Output.puts_opt("  check_query_parameter_total_count","rules")
rules.check_query_parameter_total_count
Output.puts_opt("  check_collection_pagination_behaviour","rules")
rules.check_collection_pagination_behaviour 
rescue
end

Output.puts_opt("writing augmented api metadata file to #{ControlHelper.location_relative_to('output_directory',"augmented_api_descriptor_data")}. Contains information on standards checked and violations found","progress")
JsonHelper.write_file(ControlHelper.location_of("augmented_api_descriptor_data"),api_metadata)
Output.puts_opt("mining data to produce formatted html report at #{ControlHelper.location_relative_to('output_directory','html_report')} ","progress")

Report.write_html_report(api_metadata,standards,nil,ControlHelper.stamp,'web_server')
Output.puts_opt("All done!","progress")
exit

end


end

