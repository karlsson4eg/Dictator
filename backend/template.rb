class Template
  
###############################################################################  

  def initialize(fname)
    raise "Template file not found!" unless File.exist?(fname)
    @tpl = IO.read(fname)
  end
  
###############################################################################  

  def render(data)
    output = @tpl.clone
    return output if data.nil? or data.empty?
    data.each_pair{|key, value|
      output = output.gsub("{{#{key.to_s}}}", value)
    }
    return output
  end
  
###############################################################################  

  def parse(text_to_parse)
    output = {}
    tpl_parts = @tpl.split(/\{\{(.*)\}\}/)
    i = 0
    n = tpl_parts.size

    while (i < n - 2 ) 
      part1 = ltrim(tpl_parts[i])
      key   = tpl_parts[i+1]
      part2 = ltrim(tpl_parts[i+2])
      
      start_index  = text_to_parse.index(part1)
      finish_index = text_to_parse.index(part2)
      
      raise "Parser error: Data doesn't match template." if start_index.nil? or finish_index.nil?
      
      if finish_index > start_index
        output[key.to_sym] = text_to_parse[(start_index + part1.length)..(finish_index - 1)]
      else
        output[key.to_sym] = ""
      end
      i+=2
    end
    
    return output
  end
  
###############################################################################  

  def ltrim(str)
    new_str = str.reverse
    while (new_str.chomp!)
#      
    end
    return new_str.reverse
  end

###############################################################################  

end