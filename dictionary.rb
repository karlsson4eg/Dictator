require 'pathname'

class Dictionary
  attr_reader :token_tree, :locales
  
  attr_accessor :format, :import_path, :export_path, :modified

###############################################################################  

  def initialize(format_data, app_name="")
    super()
    self.reset()
    
    @format = format_data
    @app_name = app_name
    init_backend()
  end
  
###############################################################################  

  def init_backend
    require "backend/#{@format[:name]}"
    @backend = eval("Backend::#{@format[:name].to_s.capitalize}").new(@app_name)
  rescue LoadError
    raise "Unable to load an appropriate backend for '#{@format[:name].to_s.capitalize}' format."
  end
  
###############################################################################  

  def load!(fname)
    loaded_data = @backend.read_data(fname || "")
    
    if loaded_data.is_a? Array
      data_array = loaded_data
    else
      data_array   = loaded_data[:data]        || loaded_data["data"]
      @import_path = loaded_data[:import_path] || loaded_data["import_path"]
      @export_path = loaded_data[:export_path] || loaded_data["export_path"]
    end
    
    self.__array_to_hash(data_array, @token_tree)
    self.__get_locales(@token_tree)
    @modified   = false
    return {:success => true}
  rescue Exception => e
    return {:success => false, :error => e.message}
  end

###############################################################################  

  def save!(fname)
    data_array = []
    self.__hash_to_array(@token_tree, data_array, self.__get_sorter)

    fname << ".#{@format[:extname]}" unless File.extname(fname) == ".#{@format[:extname]}" 

    pImport = __get_relative_path(fname, @import_path) unless @import_path.nil?
    pExport = __get_relative_path(fname, @export_path) unless @export_path.nil?

    @backend.write_data(fname, {
      :data        => data_array,
      :import_path => pImport.to_s,
      :export_path => pExport.to_s,
    })
    
    @modified = false
    return {:success => true}
  rescue => e
    return {:success => false, :error => e.message}
  end

###############################################################################  

  def reset
    @token_tree = {}
    @locales    = []
    @modified   = false      
    @format      = nil 
    @import_path = nil
    @export_path = nil
  end
  
###############################################################################  

  def change_format(format_data)
    @format = format_data
    init_backend()
  end

###############################################################################  

  def add_locale(locale)
    unless @locales.include? locale
      @locales << locale 
      __add_locale(@token_tree, locale)
      @modified = true      
    end
  end
  
###############################################################################  

  def remove_locale(index)
    locale = @locales.delete_at(index)
    unless locale.nil?
      __remove_locale(@token_tree, locale)
      @modified = true
    end
  end
  
###############################################################################  

  def add(path, token)
    data = __find(path)
    @locales.each{|l| data.delete(l)}
    data[token] = {} 
    @modified = true
    
    return {:success => true}
  rescue 
    return {:success => false, :error => "Key not found" }
  end
  
###############################################################################  

  def edit(path, new_label)    
    data = __find(path, path.length - 2)
    
    data[new_label] = data[path.last].clone
    data.delete(path.last)
    @modified = true

    return {:success => true}
  rescue
    return {:success => false, :error => "Key not found" }
  end

###############################################################################  

  def delete(path)
    data = __find(path, path.length - 2)
    data.delete(path.last)
    @modified = true
    
    return {:success => true}
  rescue
    return {:success => false, :error => "Key not found"}
  end

###############################################################################  
  
  def get_count
    @token_tree.size
  end

###############################################################################  
  
  def clear_data
    @token_tree.clear
    @modified = true
    
    return {:success => true}
  end

###############################################################################  

  def set(path, values)
    unless (data = __find(path)).nil?
      values.each_key{|key|
        unless data[key] == values[key]
          data[key] = values[key]
          @modified = true
        end
      }
    end
    
  end
  
###############################################################################  

  def get(path)
    return __find(path)
  end
  
###############################################################################  

  def get_copy(path)
    obj = __find(path)
    res = {}
    
    return res if obj.nil?
    
    obj.each{|k,v|
      if (v.is_a? Hash)
        res[k] = get_copy(path << k)        
      end
      res[k] = v.clone
    }
    return res
  end
  
###############################################################################  

  def correct?(path)
    data = __find(path)
    if data.is_a? Hash
      data.each_value{|value|
        return false if value.nil? or value.to_s.empty?
      }
    end
    return true
  end
  
###############################################################################  
#  Export functions
###############################################################################  
  
  def export
    raise "Export path is not specified" if @export_path.nil? or @export_path.empty?
    output_dir = Pathname.new(@export_path)
    output_dir.mkpath unless output_dir.exist?
    
    @locales.each{|l|
      output_data = {}
      __prepare_to_export(@token_tree.clone, output_data, l)
      
      @format[:export] ||= {}
      extname = (@format[:export][:extname].nil?) ? @format[:extname] : @format[:export][:extname] 
      
      fname = File.join(output_dir, [l, extname].join('.'))
      
      @backend.write_data(fname, output_data, {
        :locale   => l, 
        :export   => true, 
        :minimize => @format[:export][:minimize]
      })
    }
    return {:success => true}
  rescue => e
    return {:success => false, :error => e.message}
  end
      
###############################################################################  
#  Import functions
###############################################################################  

  def import_file(fname)
    data = @backend.read_data(fname, {:import => true})
    
    loc_name = data.keys[0]
    loc_data = data[loc_name]
    
    raise "Cannot parse data from '#{fname}' file!" if loc_data.nil? or !loc_data.is_a? Hash
    
    __prepare_to_import(loc_data, loc_name)

    add_locale(loc_name) 
    
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    @token_tree.merge!(loc_data, &merger)
    @modified = true
    
    return {:success => true}
  rescue => e
    return {:success => false, :error => e.message}      
  end

###############################################################################  

  def import_many_files(flist, root_dir=nil)
    res = {:success => true}
    flist.each { |fname| 
      res = import_file(root_dir.nil? ? fname : File.join(root_dir, fname))
      break unless res[:success]
    }
    res
  end

###############################################################################  
  
  def import_dir
    raise "Import path is not specified" if @import_path.nil? or @import_path.empty?
    file_list = Dir[ File.join(File.expand_path(@import_path), "*.#{@format[:extname]}") ]
    file_list.flatten!
    
    return import_many_files(file_list)
  rescue => e
    return {:success => false, :error => e.message}      
  end

###############################################################################  
# Protected functions
###############################################################################  

#  Converts a hash to an array, sorting items on each level inclusion
  def __hash_to_array(source, dest, proc)
    source.each{|key, value|
      if Hash === value
        array = []
        self.__hash_to_array(value, array, proc)
        dest << {key => array}
      else
        dest << {key => value}
      end
    }
    dest.sort!(&proc)
  rescue
    raise "Unable to parse data.\nWrong data format!"    
  end

###############################################################################  
  
#  Converts an array to a hash
  def __array_to_hash(source, dest)
    source.each{|hash|
      key = hash.keys.first
      value = hash[key]

      if Array === value
        h = {}
        __array_to_hash(value, h)
        dest[key] = h
      else
        dest[key] = value
      end
    }
  rescue
    raise "Unable to parse data.\nWrong data format!"    
  end
  
###############################################################################  
  
#  Gets a sorter procedure used for an array sort
  def __get_sorter
    return proc { |v1, v2| Hash === v1 && Hash === v2 ? v1.keys.first.to_s <=> v2.keys.first.to_s : v1.to_s <=> v2.to_s}
  end

###############################################################################  

#  Gets a list of locales stored in data tree
  def __get_locales(data)
    data.each_pair {|key, value|
      if value.is_a? Hash
        __get_locales(value)
      else
        @locales << key unless @locales.include? key
      end
    }
  end
  
###############################################################################  

  def __add_locale(data, locale_name)
    data.each_value{|value|
      if __is_leaf(value)
        value[locale_name] = ""
      else
        __add_locale(value, locale_name)
      end
    }
  end
  
###############################################################################  

  def __remove_locale(data, locale_name)
    data.each_value{|value|
      if __is_leaf(value)
        value.delete(locale_name)
      else
        __remove_locale(value, locale_name)
      end
    }
  end
  
###############################################################################  

#  Finds an item in data tree
  def __find(path, depth=nil)
    depth ||= path.length - 1

    data = @token_tree
    0.upto(depth){|i|
      data = data[path[i]]
      break if data.nil?
    }
    return data
  end
  
###############################################################################  

#  Checks if an item is a leaf (i.e. a hash that contains no other hashes inside)
  def __is_leaf(item)
    return true unless item.is_a? Hash
    item.each_value{|v|
      return false if v.is_a? Hash
    }
    return true
  end
  
###############################################################################  

#  Formats exported data
  def __prepare_to_export(source, dest, locale)
    source.each_pair{|key, value|
      if __is_leaf(value)
        dest[key] = value[locale]
      else
        dest[key] = {}
        __prepare_to_export(value, dest[key], locale)
      end
    }
  end
  
###############################################################################  
  
#  Formats data before import 
  def __prepare_to_import(data, locale)
    return unless data.is_a? Hash
    data.each_pair{|key, value|
      if  !value.is_a? Hash
        data[key] = {locale => value}
      else
        __prepare_to_import(data[key], locale)
      end
    }
  end
  
###############################################################################  

  def __get_relative_path(from, to)
    
    if !from.is_a? Pathname
      from = Pathname.new(from.to_s.gsub('\\', '/'))      
    end
    
    from = from.dirname.realpath
    
    if !to.is_a? Pathname
      to = Pathname.new(to.to_s.gsub('\\', '/'))
    end

    return to.relative_path_from(from)
  rescue ArgumentError
    return to    
  end
  
###############################################################################  

  protected :__find, :__is_leaf, 
            :__prepare_to_export, :__prepare_to_import, 
            :__array_to_hash, :__hash_to_array, :__get_sorter,
            :__get_relative_path
  
###############################################################################  

end
