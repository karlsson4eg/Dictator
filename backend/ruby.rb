require 'backend/base'
require 'backend/template'
require 'pp'

module Backend 

  class Ruby < Base
  
  ############################################################################### 
    
    def read_data(fname, opts = {})
      File.exist?(fname) ? eval(IO.read(fname), binding, fname) : {}
    rescue 
      return {}
    end
    
  ###############################################################################  
  
    def write_data(fname, data, opts = {})
      
      data = {opts[:locale] => data} unless opts[:locale].nil?
      
      File.open(fname, 'w'){|out| 
        out.puts( get_header() ) if opts[:export] == true        
        PP.pp(data, out) 
      }
    end
  
  ############################################################################### 
  end
end