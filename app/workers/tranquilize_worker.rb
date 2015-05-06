# app/workers/tranquilize_worker.rb
class TranquilizeWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  ##############################################################################

  ##############################################################################

  def perform(run_id)
    # Grab the run object based on the id
    @run = Run.find(run_id)

    # Need the control file, before we can do anything, so
    # load it.  We assume we're running as part of the
    # tranq server application, so we can use rails root
    # and the run id to locate the control file to use
    control_file_name = "#{Run::OUTPUT}/#{@run.id}/#{@run.id}_control.json"
    ControlHelper.load_from_file(control_file_name,Rails.root,run_id)
    ControlHelper.create_output_dirs

    OutputHelper.puts_opt("Entered perform...","worker")
    # Now test the action defined in the control file
    # and call the appropriate method
    OutputHelper.puts_opt("Action defined in the control file is: #{ControlHelper.action}","worker")
    # Works out what to do
    case ControlHelper.action
    when 'check_compliance'
      self.checker
    when 'standards_json_to_csv'
      StandardsHelper.json_to_csv
    when 'standards_csv_to_json'
      StandardsHelper.csv_to_json
    end

    # Finally update the run details
    # So that we know the job has
    # completed

    @run.status = 'Completed'
    @run.save

    OutputHelper.puts_opt("Leaving perform...","worker")
  end

  ##############################################################################

  ##############################################################################

  def checker
    OutputHelper.puts_opt("Entered checker...","worker")

    OutputHelper.puts_opt("Loading and Validating Standards File ...","progress")
    standards_data=JsonHelper.load_data_with_schema_validation(ControlHelper.location_of('standards_schema'), ControlHelper.location_of('standards_data'),true)
    standards=standards_data["standards"]
    standards_metadata=standards_data["standards_metadata"]
    StandardsHelper.set_standards(standards)

    OutputHelper.puts_opt("Loading and Validating API Compliance Metadata ... ","progress")
    api_metadata=JsonHelper.load_data_with_schema_validation(ControlHelper.location_of('api_descriptor_schema'),ControlHelper.location_of('api_descriptor'),:stop_on_errors=>true)

    OutputHelper.puts_opt("Loading OAuth Info ... ","progress")
    OutputHelper.puts_opt("Loading OAuth information with new schema validation.","detail_debug")
    oauth_data=JsonHelper.load_data_with_schema_validation(ControlHelper.location_of('oauth_schema'),ControlHelper.location_of('oauth'),:stop_on_errors=>true)
    OutputHelper.puts_opt("Successfully loaded the oauth data with schema validation.","detail_debug")
    OutputHelper.puts_opt(oauth_data,"debug")

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
    OutputHelper.puts_opt("Validating api metadata file ... ","progress")
    ApiMetadataHelper.verify_trigger_info(standards,api_metadata)

    # Initialize violations to be empty hash
    violations = Hash.new
    for standard in standards
      violations[standard["id"]]=[];
    end

    # Enrich the api metadata with the standard_checks_required element
    # to keep track of the things we must check.
    # TODO: once we have the OAuth working again, move this to the
    # if(at) check.
    #
    OutputHelper.puts_opt("Noting standards requiring validation ...","progress")
    ApiMetadataHelper.update_with_standards_to_check(api_metadata,violations,standards)

    # rules object containst all the necessary logic and data to do rule evaluation
    OutputHelper.puts_opt("Constructing new rules object... ","progress")
    rules = Rules.new(api_metadata,violations,o_rest_schemas,oauth_data,standards)
    OutputHelper.puts_opt("Constructed new rules object... ","progress")

    # make sure we have a valid access token (OAuth.get_at will try to refresh or exchange code for tokens if possible). Exit nothing works and we don't have
    # access token
    if (ControlHelper.data["authorization"]=="oauth") then
      OutputHelper.puts_opt("OAuth Code URL: #{OauthHelper.get_code_url(oauth_data)}","progress")
      OutputHelper.puts_opt("Verifying a valid access token ...","progress")
      at = OauthHelper.get_at(oauth_data,'/'+rules.first_collection_uri(api_metadata))
    end

    if(at)
      OutputHelper.puts_opt("We have a valid access token, continuing to check the standards.","worker")
      begin
#        OutputHelper.puts_opt("  check_metadata_catalog_valid_against_catalog_schema","rules")
#        rules.check_metadata_catalog_valid_against_catalog_schema
#        OutputHelper.puts_opt("  check_singular_valid_against_base_singular_schema","rules")
#        rules.check_singular_valid_against_base_singular_schema
#        OutputHelper.puts_opt("  check_collection_valid_against_base_collection_schema","rules")
#        rules.check_collection_valid_against_base_collection_schema
#        OutputHelper.puts_opt("  check_get_context_valid_against_collection_schema_and_get_version_valid_against_version_schema","rules")
#        rules.check_get_context_valid_against_collection_schema_and_get_version_valid_against_version_schema
#        OutputHelper.puts_opt("  check_options_collection_uri_references_metadata_in_header","rules")
#        rules.check_options_collection_uri_references_metadata_in_header
#        OutputHelper.puts_opt("  check_boolean_fields","rules")
#        rules.check_boolean_fields
#        OutputHelper.puts_opt("  check_user_fields","rules")
#        rules.check_user_fields
#        OutputHelper.puts_opt("  check_resource_uri_case","rules")
#        rules.check_resource_uri_case
#        OutputHelper.puts_opt("  check_resource_uris","rules")
#        rules.check_resource_uris
#        OutputHelper.puts_opt("  check_collections_plural","rules")
#        rules.check_collections_plural
#        OutputHelper.puts_opt("  check_version_naming","rules")
#        rules.check_version_naming
#        OutputHelper.puts_opt("  check_identifier_naming","rules")
#        rules.check_identifier_naming
#        OutputHelper.puts_opt("  check_resource_metadata_application_json","rules")
#        rules.check_resource_metadata_application_json
#        OutputHelper.puts_opt("  check_query_parameter_total_count","rules")
#        rules.check_query_parameter_total_count
#        OutputHelper.puts_opt("  check_collection_pagination_behaviour","rules")
#        rules.check_collection_pagination_behaviour
      rescue
      end

      OutputHelper.puts_opt("Running dynamic rules","rules")
      Rule.find(:all, :order => "sequence").each {|r| rules.run_rule(r)}

      OutputHelper.puts_opt("writing augmented api metadata file to #{ControlHelper.location_relative_to('output_directory',"augmented_api_descriptor_data")}. Contains information on standards checked and violations found","progress")
      JsonHelper.write_file(ControlHelper.location_of("augmented_api_descriptor_data"),api_metadata)
      OutputHelper.puts_opt("mining data to produce formatted html report at #{ControlHelper.location_relative_to('output_directory','html_report')} ","progress")

      ReportHelper.write_html_report(api_metadata,standards,nil,ControlHelper.stamp,'web_server')
    else
      OutputHelper.puts_opt("We are not authorized to call the API, thus stopping.  Update the access credential information and try again.","worker")

      OutputHelper.puts_opt("Running dynamic rule","rules")
      Rule.find(:all, :order => "sequence").each {|r| rules.run_rule(r)}
    end

    OutputHelper.puts_opt("Leaving checker...","worker")
  end

end
