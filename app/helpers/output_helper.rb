#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options

  module OutputHelper
    
    def self.out(msg)
      puts msg
      if ControlHelper.data?
        open(ControlHelper.location_of('log_file'), 'a') { |f|
          f.puts msg
        }
      end
    end
    
    def self.puts_opt(msg,opt)
      if (ControlHelper.debug_options[opt]=="true")    
        out("-----> #{opt}:")
        self.out(msg)
      end
    end

    def self.fatal_msg(msg)
      self.out("---- FATAL ERROR: Stopping Exection -----")
      self.out msg
      self.out "-----------------------------------------"
      raise "fatal_traquilize"
    end
  
# outputs info via puts and also to log file  
  
    
  end
