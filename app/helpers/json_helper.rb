#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options
module JsonHelper
  
  def self.load_and_validate(schema_file, data_file, options)

    # check both files and stop if either is not found
    OutputHelper.fatal_msg("Schema file #{schema} does not exist!") if !File.file?(schema_file)
    OutputHelper.fatal_msg("Data file #{data} does not exist!") if !File.file?(data_file)

    data = JSON.load(File.new(data_file))
    schema = JSON.load(File.new(schema_file));

    errors = JSON::Validator.fully_validate(schema, data, :errors_as_objects => true, :validate_schema => true)
    OutputHelper.fatal_msg("Errors validating #{data} against #{schema}. Errors: #{errors}") if( errors.size > 0 && (options[:stop_on_errors]==true) )
  
    return data
  
  end
  # load validated json data from a file into a ruby object format
  # options: 
  #    stop_on_errors: stop execution if json data does not validate against schema
   
  def self.load_data_with_schema_validation(schema,data,options)
    
    # check both files and stop if either is not found
    OutputHelper.fatal_msg("Schema file #{schema} does not exist!") if !File.file?(schema)
    OutputHelper.fatal_msg("Data file #{data} does not exist!") if !File.file?(data)

    errors = JSON::Validator.fully_validate(schema, data, :errors_as_objects => true, :validate_schema => true)
    OutputHelper.fatal_msg("Errors validating #{data} against #{schema}. Errors: #{errors}") if( errors.size > 0 && (options[:stop_on_errors]==true) )
  
    return load_data(data)
  
  end

  # load json data from a file into a ruby object format
  def self.load_data(data)
    JSON.parse(File.read(data))
  end


  # write json data to a file from a ruby object format
  def self.write_file(file,data)
    File.write(file,JSON.pretty_generate(data))
  end

end
