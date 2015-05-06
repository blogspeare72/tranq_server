#TODO tidy this code
#TODO at least one line comment of what method does
#TODO pass flags as options

module ReportHelper

  def self.html_row_compliance_table(context_cell,version_cell,resource_cell,required_checks_cell,resolved_checks_cell,not_resolved_checks_cell,violations_cell,must_fix_cell)

    html = ""
    html << "<tr>"
    html << "<td>#{context_cell}</td>"
    html << "<td>#{version_cell}</td>"
    html << "<td>#{resource_cell}</td>"
    #html << "<td>#{required_checks_cell}</td>"
    html << "<td>#{resolved_checks_cell}</td>"
    html << "<td>#{not_resolved_checks_cell}</td>"
    html << "<td>#{violations_cell}</td>"
    html << "<td>#{must_fix_cell}</td>"
    html << "</tr>"
    return html


  end

  def self.format_for_scr_col(standard_checks_required)
    txt = ""
    if (standard_checks_required) then
      for scr in standard_checks_required
        txt << " #{scr['id']} "
      end 
    end
    return txt  
  end

  def self.format_for_r_col(standard_checks_required)
    txt = ""
    if (standard_checks_required) then
      
      for scr in standard_checks_required
        if (scr["checking_status"]=='resolved')
          css_class = 'unknown' 
          css_class = 'true' if (scr["compliant"]=='Y')
          css_class = 'false' if   (scr["compliant"]=='N' )
          txt << " <div class='#{css_class}'> #{scr['id']} </div> [#{scr["how_resolved"]}] <br>"
        end
      end 
    end
    return txt  
  end

  def self.format_for_nr_col(standard_checks_required)
    txt = ""
    if (standard_checks_required) then
      #    puts "ffnr"
      for scr in standard_checks_required
        #    puts scr
        txt << " #{scr['id']} <br>" if (scr["checking_status"]=='unresolved')
      end 
    end
    return txt  
  end

  def self.must_fix(s,releases)


    if  ControlHelper.data['must_fix_conditions']['levels'].include?(s["level"]) then
      return true
    end
    return false
  end




  def self.format_for_v_col(standard_checks_required,standards,show_all,releases)

    txt = ""
    #  puts "ffvc"
    if (standard_checks_required) then
      #  puts "here"

      for scr in standard_checks_required
        #      puts "V count #{scr['violation_count']} #{show_all}"
        if (scr['violation_count'].to_i>0) then
          s = StandardsHelper.get_standard_by_id(scr["id"])
          if(must_fix(s,releases)||show_all) then
            
            txt << " #{scr["id"]} [ severity=#{s["level"]} ] <br>" 
            for v in scr['violations']
              #          puts "violation"
              txt << "- #{v['message']} <br><hr>" 
              #          puts txt
            end
          end
        end
      end 
    end
    
    return txt  

  end

  def self.write_html_report(metadata,standards,releases,stamp,link_style)
    
    html = "<!DOCTYPE html><html><head><link rel='stylesheet' type='text/css' href='#{ControlHelper.location_relative_to('html_report','report_dist_css')}'>"
    html << "<body>"
    html << "<h1>tranquilize Compliance Report </h1>"

    html << "<table class='gridtable'>"
    html << "<tr> <th>Timestamp</th> <th>ControlHelper.File</th> <th>API Metadata File</th>  <th>StandardsHelper.File</th> <th>Log File</th>   <th>Must Fix Criteria</th></tr>"
    html << "<td>#{Time.now.getutc}</td>"
    if (link_style=='web_server')
      html << "<td><a href='#{ControlHelper.uri_of('copy_of_control_file')}'>ControlHelper.File</a></td>"
      html << "<td><a href='#{ControlHelper.uri_of('copy_of_api_descriptor')}'>API Description File</a></td>"
      html << "<td><a href='#{ControlHelper.uri_of('copy_of_standards')}'>StandardsHelper.File</a></td>"
      html << "<td><a href='#{ControlHelper.uri_of('log_file')}'>Log File</a></td>"
    else
      html << "<td><a href='file:#{ControlHelper.location_relative_to('html_report','copy_of_control_file')}'>ControlHelper.File</a></td>"
      html << "<td><a href='file:#{ControlHelper.location_relative_to('html_report','copy_of_api_descriptor')}'>API Description File</a></td>"
      html << "<td><a href='file:#{ControlHelper.location_relative_to('html_report','copy_of_standards')}'>StandardsHelper.File</a></td>"
      html << "<td><a href='file:#{ControlHelper.location_relative_to('html_report','log_file')}'>Log File</a></td>"
    end
    html << "<td>Any StandardsHelper.with these severity levels: #{ControlHelper.data()['must_fix_conditions']['levels']}</td>"
    html << "</tr>"
    html << "</table>"
    html << "<br>"



    html << "<table class='gridtable'>"
    html << "<tr> <th>Context</th> <th>Version</th> <th>Resource</th>  <th>Resolved</th> <th>Not Resolved <br>(Explicitly State Compliance in API Description File)</th> <th>All Violations</th> <th>Must Fix Violations</th></tr>"

    for context in metadata["contexts"]
      #       puts("context ... #{context['context']}")
      html << html_row_compliance_table(context["context"],"","",format_for_scr_col(context["standard_checks_required"]), format_for_r_col(context["standard_checks_required"]),format_for_nr_col(context["standard_checks_required"]),format_for_v_col(context["standard_checks_required"],standards,true,releases),format_for_v_col(context["standard_checks_required"],standards,false,releases))
      
      
      for version in context["versions"]
        #puts(">>>>version ... #{version['version']}")  
        #puts version["standard_checks_required"]
        html << html_row_compliance_table("",version["version"],"",format_for_scr_col(version["standard_checks_required"]),format_for_r_col(version["standard_checks_required"]),  format_for_nr_col(version["standard_checks_required"]),format_for_v_col(version["standard_checks_required"],standards,true,releases),format_for_v_col(version["standard_checks_required"],standards,false,releases))
        
        
        
        for r in version["resources"]
          if (r["resource_type"]=="collecton") then
            html << html_row_compliance_table("","","",r["resource"],format_for_scr_col(r["standard_checks_required"]),format_for_r_col(r["standard_checks_required"]),  format_for_nr_col(r["standard_checks_required"]),format_for_v_col(r["standard_checks_required"],standards,true,releases),format_for_v_col(r["standard_checks_required"],standards,false,releases))
            
          end
          html << html_row_compliance_table("","",r["resource"],format_for_scr_col(r["standard_checks_required"]),format_for_r_col(r["standard_checks_required"]),  format_for_nr_col(r["standard_checks_required"]),format_for_v_col(r["standard_checks_required"],standards,true,releases),format_for_v_col(r["standard_checks_required"],standards,false,releases))
          
          
        end
        
      end
      
    end
    html << "</table>"


    html << "</body></html>"  


    File.write(ControlHelper.location_of('html_report'),html)
    FileUtils.cp(ControlHelper.location_of('report_css'), ControlHelper.location_of('report_dist_css'))
  end

end
