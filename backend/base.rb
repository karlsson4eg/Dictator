module Backend 
  class Base
  
  ###############################################################################
  
    def initialize(app_name)
      super()
      @comment_sign = '#'
  
      @header = [
        "This file has been automatically generated by #{app_name}.",
        "It is not recommended that this file is edited directly." ,
        "Generated at: "
      ]
    end
  
  ###############################################################################
  
    def get_header
      text = @header.map{|line| "#{@comment_sign}#{line}"}.join("\n")
      text << Time.now.strftime("%Y-%m-%d %H:%M:%S") << "\n"
      return text
    end
    
  ###############################################################################
  #  Abstract methods
  ###############################################################################
    
    def read_data(fname, opts = {})
      return {}
    end
  
  ###############################################################################
  
    def write_data(fname, data, opts = nil)
      return true
    end
    
  ###############################################################################
  
  end
end
