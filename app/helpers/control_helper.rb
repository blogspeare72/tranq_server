#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options
#class to represent the control object that determines the behaviour of tranquilize 
  module ControlHelper
  
  attr_reader :data,:stamp  
     
        
# returns proxy information in format that can be inserted into curl command        
   def self.proxy_if_needed()
     (@@data["use_proxy"]=="true") ? " -x #{@@data["proxy"]} " : "" 
   end   
    
   def self.form_stamp()
      @@stamp = Time.now().to_i.to_s
   end    
  
  
   def self.set_tranquilizer_root(root)
     @@data['tranquilize_root'] = root
   end
   def self.data?
     return defined? @@data
   end
   def self.data
     @@data
   end
   def self.stamp
     @@stamp
   end
   ###############################################################
   # This method is used to initialize the control helper data
   # control_file is the absolute path to the control file to load
   # tranquilizer_root is the home directory of the application
   # run_id the id of the run that we are executing
   ###############################################################
   def self.load_from_file(control_file,tranquilizer_root,run_id)  
     # Ensure we always have access to the run id
     if (run_id)
       @@stamp = run_id
     else
       self.form_stamp
     end
     # Should be able to put this here, as we'll never need it anywhere else, will we?
     control_file_schema = Rails.root.join('app').join('assets').join('json_schema').join('rest_checker').join('run_file_schema.json')
     puts control_file_schema
     @@data=JsonHelper.load_and_validate(control_file_schema,control_file,:stop_on_errors=>true)
     set_tranquilizer_root(tranquilizer_root)
#     FileUtils.mkdir_p("#{get_data('run_root')}#{get_data('output_directory')}/reports/")
   end
 
   def self.debug_options
     return @@data['debug']
   end
   
   def self.action
     return @@data['action']
   end
   
   
   def self.location_relative_to(base_location,relative_location)
     file_base = Pathname.new(self.location_of(base_location))
     file_relative = Pathname.new(self.location_of(relative_location))
     relative = file_relative.dirname.relative_path_from file_base.dirname
     puts file_base
     puts file_relative
     puts relative+Pathname.new(self.location_of(relative_location)).basename
   
     return relative+Pathname.new(self.location_of(relative_location)).basename
   end 
   
   # convenience method for getting location of files based on data in control file. 
   # Centralizes all this implicit structure of filesystem and 
   # abstracts from calling code
   def self.create_output_dirs
     FileUtils.mkdir_p("#{get_data('run_root')}#{get_data('output_directory')}/reports/")
     FileUtils.mkdir_p(File.dirname(location_of('copy_of_api_descriptor')))
     FileUtils.mkdir_p(File.dirname(location_of('copy_of_standards')))
     FileUtils.mkdir_p(File.dirname(location_of('augmented_api_descriptor_data')))
     FileUtils.mkdir_p(File.dirname(location_of('copy_of_standards')))
     FileUtils.mkdir_p(File.dirname(location_of('html_report')))
     FileUtils.mkdir_p(File.dirname(location_of('copy_of_control_file')))
   end

def self.get_data(element)
   Output.fatal_msg "No such data element #{element}. Exiting" if !@@data.has_key?(element)
   @@data[element]
end  

#   def self.get_server_root
#   "http://slc06wze.us.oracle.com:4567"
#   end

   def self.uri_of(location)
case location
     when 'log_file'
        "#{get_data('output_directory')}/reports/run_#{@@stamp}.txt"
     when 'copy_of_standards'
       "#{get_data('output_directory')}/input/standards/standards_#{@@stamp}.json"
      when 'copy_of_api_descriptor'
       "#{get_data('output_directory')}/input/api_descriptor/api_descriptor_#{@@stamp}.json"  
     when 'copy_of_control_file'
       "#{get_data('output_directory')}/input/run_file/run_file_#{@@stamp}.json"
 
else

       Output.fatal_msg "You asked for the uri: #{location} -- I don't know that uri. Exiting"
     
    end
   end

   def self.location_of(location)
     case location
     when 'api_descriptor_schema'
       "#{get_data('tranquilize_root')}/app/assets/json_schema/rest_checker/api_descriptor_schema.json"
     when 'report_dist_css'
       "#{get_data('run_root')}#{get_data('output_directory')}/reports/compliance_report.css"
     when 'output_directory'
       "#{get_data('run_root')}#{get_data('output_directory')}"
     when 'log_file'
       "#{get_data('run_root')}#{get_data('output_directory')}/reports/run_#{@@stamp}.txt"
     when 'html_report'
       "#{get_data('run_root')}#{get_data('output_directory')}/reports/report.html"
     when 'report_css'
       "#{get_data('tranquilize_root')}/app/assets/stylesheets/compliance_report.css"   
     when 'augmented_api_descriptor_data'   
       "#{get_data('run_root')}#{get_data('output_directory')}/augmented/api_descriptor_#{@@stamp}.json"
     when 'run_file_schema'
       "#{get_data('tranquilize_root')}/json_schema/rest_checker/run_file_schema.json"
     when 'copy_of_api_descriptor'
       "#{get_data('run_root')}#{get_data('output_directory')}/input/api_descriptor/api_descriptor_#{@@stamp}.json"  
     when 'copy_of_standards'
       "#{get_data('run_root')}#{get_data('output_directory')}/input/standards/standards_#{@@stamp}.json"
     when 'copy_of_control_file'
       "#{get_data('run_root')}#{get_data('output_directory')}/input/run_file/run_file_#{@@stamp}.json"
     when 'standards_as_csv'
       "#{get_data('run_root')}#{get_data('output_directory')}/standards_as_csv.csv"
     when 'standards_as_json'
       "#{get_data('run_root')}#{get_data('output_directory')}/standards_as_json.json"
     when 'oauth_schema'
       "#{get_data('tranquilize_root')}/app/assets/json_schema/rest_checker/oauth_file_schema.json"
     when 'oauth'
       "#{get_data('run_root')}#{get_data('oauth_file')}"
     when 'api_descriptor'   
       "#{get_data('run_root')}#{get_data('api_descriptor_file')}"
     when 'rest_checker_schemas'
       "#{get_data('tranquilize_root')}/json_schema/rest_checker/"
     when 'standards_data'
       "#{get_data('tranquilize_root')}/app/assets/standards/standards.json"
     when 'standards_schema'
       "#{get_data('tranquilize_root')}/app/assets/json_schema/rest_checker/standards_schema.json"
     when 'rest-schemas/exception#'
       "#{get_data('tranquilize_root')}/app/assets/json_schema/oracle_rest/rest_schemas_exception.json"
     when 'rest-schemas/singularResource#'
       "#{get_data('tranquilize_root')}/app/assets/json_schema/oracle_rest/singularResource.json"
     when 'rest-schemas/collectionResource#'
       "#{get_data('tranquilize_root')}/app/assets/json_schema/oracle_rest/collectionResource.json"
    else
       Output.fatal_msg "You asked for the location: #{location} -- I don't know that location. Exiting"
     
    end
     
   end

 end
