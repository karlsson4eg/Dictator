require 'backend/base'
require 'backend/template'
require 'json'

module Backend 

  class Json < Base

  ###############################################################################  
  
    def initialize(app_name)
      super(app_name)
      @comment_sign = "//"
    end
  
  ###############################################################################  
  
    def read_data(fname, opts = {})
      return {} unless File.exist?(fname)
      json = IO.read(fname)

      return {} if json.empty?
      
      if opts[:import] == true
        parse_result = Template.new('backend/json.tpl').parse(json)
        
        locale_name = File.basename(fname, File.extname(fname))
        return {locale_name.to_sym => JSON.parse(parse_result[:data])}
      else
        return JSON.parse(json)
      end
    end
    
  ###############################################################################  
  
    def write_data(fname, data, opts = {})

      File.open(fname, 'w'){|out|
        if opts[:export] == true
          
          json = Template.new('backend/json.tpl').render({
            :header => get_header(),
            :data   => (opts[:minimize] == true) ? JSON.generate(data) : JSON.pretty_generate(data)
          })
        else
          json = JSON.pretty_generate(data)
        end
        
        out.puts(json) 
      }
    end
  
  ###############################################################################  
    
  end
end