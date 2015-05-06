class Run < ActiveRecord::Base
  attr_accessible :status, :control_file, :api_descriptor, :oauth, :name , :description
  validate :control_file_is_valid_json, :oauth_is_valid_json,:api_descriptor_is_valid_json


  REPORT_SERVER = 'http://localhost:3000'
#  OUTPUT = "/scratch/aioannou/tranq/tranq_app/public/"
  OUTPUT = Rails.root.join('public')
  RUN_STATUS = {'CREATED'=>'Created', 'RUNNING'=>'Completed', 'COMPLETED'=>'Completed'}

  def control_file_is_valid_json
    
    begin
      JSON.parse(control_file)
    rescue
      errors.add(:control_file,"Control File is not valid json")
    end
    
  end
def api_descriptor_is_valid_json
    
    begin
      JSON.parse(api_descriptor)
    rescue
      errors.add(:api_descriptor,"api descriptor is not valid json")
    end
    
  end
def oauth_is_valid_json
    
    begin
      JSON.parse(oauth)
    rescue
      errors.add(:oauth,"oauth is not valid json")
    end
    
  end

  def duplicatable
#   status == 'Created' ? true : false
    true
  end

  def editable
#   status == 'Created' ? true : false
    true
  end

  def runnable
# status == 'Created' ? true : false
  true
  end
  
  def deletable 
   true 
  end


   
  def reports_available
    location = "#{OUTPUT}/#{self.id}/reports/report.html"
    (status == 'Completed' && File.exists?(location)) ? true : false
  end

  def log_available
    (status == 'Completed' && File.exists?("#{OUTPUT}/#{self.id}/reports/run_#{self.id}.txt")) ?  true : false
  end

  def only_log_available
    log_available && ! reports_available
  end
end
