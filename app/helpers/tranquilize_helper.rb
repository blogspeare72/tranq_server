#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options
  module TranquilizeHelper
    
# takes an array of hashes and returns the select_property from the hash where key_property == key
# if error_if_absent is true then raise fatal msg if no hash has key_property = key    
# if error_if_multi is true  then fatal msg if multiple hashes have key_property = key
    def self.collect_property_from_hash_array(array,key_property,key,select_property,error_if_absent,error_if_multi)
      puts array
      
        
      matching=array.select{ |a| a.has_key?(key_property) ? (a[key_property]==key && a.has_key?(select_property) ) : false }
      
      results = matching.collect{|m| m[select_property]}
      OutputHelper.fatal_msg("collect_property_from_hash_array: no value found! (key_property=#{key_property},key=#{key})") if error_if_absent && results.size==0
      OutputHelper.fatal_msg("collect_property_from_hash_array: multiple values found! (key_property=#{key_property},key=#{key})") if error_if_multi && results.size > 1
      
      return results
    end
    
    def self.select_property_from_hash_array(array,key_property,key,select_property,error_if_absent)
      self.collect_property_from_hash_array(array,key_property,key,select_property,error_if_absent,true)[0]
    end
    
    def self.select_entry_from_hash_array(array,key_property,key,error_if_absent)
      results=array.select{ |a| a.has_key?(key_property) ? (a[key_property]==key  ) : false }
   
      OutputHelper.fatal_msg("select_entry_from_hash_array: no value found! (key_property=#{key_property},key=#{key})")  if error_if_absent && results.size==0
      OutputHelper.fatal_msg("select_entry_from_hash_array: multiple values found! (key_property=#{key_property},key=#{key})")  if error_if_absent && results.size > 1
      return results[0]
    end
    
  end
