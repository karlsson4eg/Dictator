require 'backend/base'
require 'backend/template'
require 'yaml'

module Backend 
  class Yaml < Base
  
  ###############################################################################  
  
    def read_data(fname, opts = {})
      File.exist?(fname) ? YAML::load(IO.read(fname)) : {}    
    rescue 
      return {}
    end
    
  ###############################################################################  
  
    def write_data(fname, data, opts = {})
      
      data = {opts[:locale] => data} unless opts[:locale].nil?
      
      File.open(fname, 'w'){|out| 
        out.puts( get_header() ) if opts[:export] == true
        YAML.dump(data, out) 
      }
    end
  
  ###############################################################################  
  end  
end