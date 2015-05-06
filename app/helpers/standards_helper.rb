#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options
  module StandardsHelper
    
    DEPENDENCY__TRIGGERING = "triggering"
    DEPENDENCY__DEPENDENT = "dependent"
    TRIGGER_LEVEL__CONTEXT = "context"
    TRIGGER_LEVEL__VERSION = "version"
    TRIGGER_LEVEL__COLLECTION_RESOURCE = "collection_resource"
    TRIGGER_LEVEL__RESOURCE = "resource"
    TRIGGER_LEVEL__SINGULAR_RESOURCE = "singular_resource"
    LEVEL__MUST = 'must'
    LEVEL__SHOULD = "should"
    LEVEL__MIGHT = 'might'
    AUTOMATED_CHECKING__MANUAL = "Manual"
    AUTOMATED_CHECKING__AUTOMATED = "Automated"
    AUTOMATED_CHECKING__HELPER ="Helper"
    SCOPE__COLLECTION_RESOURCE ="collection_resource"
    SCOPE__SINGULAR_RESOURCE = "singular_resource"
    SCOPE__RESOURCE = "resource"
    
    @@standards 
    @@control
    
  def self.set_standards(standards)
    @@standards=standards
  end
  
  
  def self.standards
    @@standards
  end
  
  def self.get_standard_by_id(s_id)
     for s in @@standards
       return s if (s["id"]==s_id)
       end
       
       Output.fatal_msg("No such standard #{s_id} - check your api metadata!")
  end
  
  def self.json_to_csv
  
      Output.puts_opt("Writing .csv of standards ...","progress",control) 
      standards_data=JsonHelper.load_data_with_schema_validation(Control.location_of('standards_schema'), Control.location_of('standards_data'),true)
      standards=standards_data["standards"]
      csv_string = CSV.generate do |csv|
        csv << standards.first.collect {|k,v| k}
        standards.collect {|standard| csv << standard.collect{|k,v| v} }
     end
      
    
      File.write(Control.location_of('standards_as_csv'),csv_string)
    end
    
# loads a csv file containing standards info and turns it into the json used by tranq    
  def self.csv_to_json
#     standards_data=JsonHelper.load_data_with_schema_validation(control.location_of('standards_schema'), control.location_of('standards_data'),true)
#     standards=standards_data["standards"]
     
     Output.puts_opt("Converting .csv of standards to .json format ...","progress",control) 
     csv_standards = File.read(control.location_of('standards_as_csv'))
   
     CSV::Converters[:blank_to_nil] = lambda do |field|
       field && field.empty? ? nil : field
     end
     csv = CSV.new(csv_standards, :headers => true, :header_converters => :symbol, :converters => [:all, :blank_to_nil])
     standards_array = csv.to_a.map {|row| row.to_hash }
     
# some further augmentation and formatting
     standards_array.each do |standard|
# - form an id from the short_id and the code     
       standard["id"]="#{standard[:short_id]}_#{standard[:code]}"
# - parse data which is serialized as a JSON object in the csv    
       standard[:data]=JSON.parse(standard[:data]) if standard[:data] 
# - parse scopes which is serialized as a JSON object in the csv   
       standard[:scopes]=JSON.parse(standard[:scopes])   if standard[:scopes]
# - ensure some columns are always strings
       standard[:v11_section]=standard[:v11_section].to_s
       standard[:v12_section]=standard[:v12_section].to_s
# if change log or description are 0 - make them nil instead
       standard[:description]=nil if standard[:description]==0
       standard[:change_log]=nil if standard[:change_log]==0
     end

# now add some extra info that we keep in the standards file.
     standards = Hash.new
     standards["standards"] = standards_array
     standards["standards_metadata"] = { "total" => standards_array.size }

    
     json_standards = JSON.pretty_generate(standards)
     
     File.write(control.location_of('standards_as_json'),json_standards)
# finally - lets check what we wrote is valid against the standards schema     
     JsonHelper.load_data_with_schema_validation(control.location_of('standards_schema'),control.location_of('standards_as_json'),true)
  end
      
  
  def self.dump_standards(standards)
  for standard in standards
    if (standard["dependency"]=="triggering") then
      
      puts standard['id']
      
      for child_standard in standards
        if (child_standard["dependency_on"]==standard['id']) then
           puts "  #{child_standard['id']}"
        end
      end
      
    elsif (standard["dependency"]==nil) then
      puts standard['id']
      
    elsif  (standard["dependency"]=="dependent") then
#      puts("skipping #{standard['id']}")
       exists = false
       
       for x_standard in standards
        exists = true if  (standard["dependency_on"]==x_standard['id']) 
       end
       
       if !exists then
         puts ("#{standard['id']} has dependency on non existant standard")
        exit
       end
       
    end
  end
end
    
  
    
# returns data from a standard and errors if that data is not present    
  def self.data(standards,s_id,name)
   
  standard=StandardsHelper.get_standard_by_id(s_id)
  if (!standard["data"])  then   
    Output.fatal_msg("Standard #{standard["id"]} does not have any assocated data")
  else
    return TranquilizeHelper.select_property_from_hash_array(standard["data"],"name",name,"value",true)
  end

  end
  
end
