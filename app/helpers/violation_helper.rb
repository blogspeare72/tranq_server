#TODO tidy this code
#TODO at least one line comment of what method does
#TODO fix indentation
#TODO pass flags as options
module ViolationHelper

  def self.add_violation(object,violations,s_id,msg)
    StandardsHelper.get_standard_by_id(s_id)
    violations[s_id] << msg
    scrs = object["standard_checks_required"]
    for scr in scrs
      if (scr["id"]==s_id) then
        scr["violation_count"]=scr["violation_count"]+1
        if (!scr["violations"]) then
          scr["violations"] = []
        end
        violation =  Hash.new
        violation["message"]= msg
        scr["violations"] <<violation
      end
    end
  end
end
