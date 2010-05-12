#!/usr/bin/ruby
require 'rubygems'
require 'wx'
require 'DictatorGUI' 
require 'dictionary'
require 'google_translate'
require 'optparse'
require 'pathname'

class MyTextCtrl < Wx::TextCtrl
  attr_accessor :locale
end


include Wx

class MainFrame < DictMainForm

###############################################################################  

  def initialize(options)
    @start_up = options
    
    @app_path = File.expand_path(File.dirname(__FILE__))
    @app_name = 'Dictator'
    @def_name = 'MyStorage'
    
    @already_found = []
    @clipboard = nil

    super()

#   Defining event handlers
#    Application
    evt_close() {|event| on_close(event)}
    
#    Tree
    evt_tree_sel_changed(@tree)    { |event| on_tree_item_selected(event) }
    evt_tree_item_activated(@tree) { |event| 
      sItem = event.get_item
      return if sItem.zero?
      @tree.edit_label(sItem)
    }
    
    evt_tree_end_label_edit(@tree) { |event| on_tree_item_edited(event)  }
    
#    evt_tree_begin_drag(@tree)  {|event| on_tree_item_drag(event)}
#    evt_tree_end_drag(@tree)    {|event| on_tree_item_drop(event)}
  
#    Toolbar
    evt_menu(@tlbnewdata)      { | event |  on_new_data_click(event)     }
    evt_menu(@tlbopendata)     { | event |  on_open_data_click(event)    }
    evt_menu(@tlbsavedata)     { | event |  on_save_data_click(event)    }
    
    evt_menu(@tlbnewdict)      { | event |  on_new_dict_click(event)     }
    evt_menu(@tlbremovedict)   { | event |  on_remove_dict_click(event)  }

    evt_menu(@tlbinsertkey)    { | event |  on_new_key_click(event)      }
    evt_menu(@tlbcutkey)       { | event |  on_cut_key_click(event)      }
    evt_menu(@tlbcopykey)      { | event |  on_copy_key_click(event)     }
    evt_menu(@tlbpastekey)     { | event |  on_paste_key_click(event)    }
#    evt_menu(@tlbmoveup)       { | event |  on_moveup_key_click(event)   }
    evt_menu(@tlbremovekey)    { | event |  on_remove_key_click(event)   }

    evt_menu(@tlbimportfiles)  { | event |  on_import_files_click(event) }
    evt_menu(@tlbimportdir)    { | event |  on_import_dir_click(event)   }
    evt_menu(@tlbexport)       { | event |  on_export_click(event)       }

    evt_text_enter(@txtsearch) { | event |  on_search(event)             }
    evt_text(@txtsearch)       { | event |  @already_found = []          }
    evt_menu(@tlbtranslate)    { | event |  on_translate_click(event)    }

#    Menu
    evt_menu(@mnewdata)    { | event |  on_new_data_click(event)    }
    evt_menu(@mopendata)   { | event |  on_open_data_click(event)   }
    evt_menu(@msavedata)   { | event |  on_save_data_click(event)   }
    evt_menu(@msaveasdata) { | event |  on_save_as_data_click(event)}

    evt_menu(@mnewdict)    { | event |  on_new_dict_click(event)    }
    evt_menu(@mremovedict) { | event |  on_remove_dict_click(event) }

    evt_menu(@minsertkey)  { | event |  on_new_key_click(event)      }
    evt_menu(@mcutkey)     { | event |  on_cut_key_click(event)      }
    evt_menu(@mcopykey)    { | event |  on_copy_key_click(event)     }
    evt_menu(@mpastekey)   { | event |  on_paste_key_click(event)    }
#    evt_menu(@mmoveup)     { | event |  on_moveup_key_click(event)   }
    evt_menu(@mremovekey)  { | event |  on_remove_key_click(event)   }
    
    evt_menu(@mimportfiles)  { | event |  on_import_files_click(event)  }
    evt_menu(@mimportdir)    { | event |  on_import_dir_click(event)    }
    evt_menu(@mexport)       { | event |  on_export_click(event)        }

    evt_menu(@mabout)        { | event |  on_about_click(event)         }
    evt_menu(@mexit)         { | event |  on_exit_click(event)          }

  end
  
###############################################################################  
  
  def on_init
    self.set_icon(Wx::Icon.new(File.join(@app_path,'images','dictator_logo.ico'), Wx::BITMAP_TYPE_ICO, 16,16))

    @config       = YAML.load_file(File.join(@app_path, "config.yml")) || Hash.new
    @dict_formats = @config[:formats_available]
    
    @start_up[:load] ||= @config[:last_storage] unless @config[:last_storage].nil?
    
    if @start_up[:format].nil?
      @start_up[:format] = @dict_formats.first
    else
      @start_up[:format] = self.get_format_data(@start_up[:format])
    end
    
    # Create new dictionary and import data from a dir specified  
    imp_path = Pathname.new(@start_up[:import_from].to_s)
    if imp_path.exist? and imp_path.directory? 
      self.new_data(@start_up[:format])
      self.import_from_dir(imp_path.realpath.to_s)
    end
    
    # Load dictionary data if dictionary file specified
    load_path = Pathname.new(@start_up[:load].to_s)
    if @dictionary.nil? and load_path.exist? and load_path.file? 
      self.load_data(@start_up[:load])
    end
    

    # Create new dictionary data if it is not yet created
    self.new_data(@start_up[:format]) if @dictionary.nil?
    
    # Specify a default export path to the dictionary if path is provided
    exp_path = Pathname.new(@start_up[:export_to].to_s)
    @dictionary.export_path = exp_path.realpath.to_s if exp_path.exist? and exp_path.directory? 
  end
  
###############################################################################  

  def on_tree_item_selected(event)
    oItem = event.get_old_item
    nItem = event.get_item
    
    self.update_store(oItem)
    
    if nItem.nonzero?  
      nItemData = @tree.get_item_data(nItem) 
      self.updatePath(nItemData)

      if @tree.get_children_count(nItem).zero?
        self.enable_texts(true)
        self.set_text_values(@dictionary.get(nItemData[:path])) unless nItemData.nil?
      else
        self.clear_texts()
        self.enable_texts(false)
      end
    end
  end
  
###############################################################################  

  def on_tree_item_edited(event)
    return if event.is_edit_cancelled

    root = @tree.get_root_item
    item = event.get_item

    return if item == root
    
    data = @tree.get_item_data(item)
    
    old_label = data[:path].last
    new_label = event.get_label().to_sym
    run_proc({
      :proc      => lambda {@dictionary.edit(data[:path], new_label)},
      :onSuccess => lambda {
        data[:path].delete(old_label)
        data[:path] << new_label
        @tree.set_item_data(item, data)
        self.updatePath(data)
      }
    })
  end
  
  def on_tree_item_drag(event)
    puts 1
  end
  
  def on_tree_item_drop(event)
    puts 2
  end
  
###############################################################################  

  def on_exit_click(event)
    self.close
  end
  
###############################################################################  

  def create_dictionary(format_data)
    @dictionary = Dictionary.new(format_data, @app_name)
    return true
  rescue => e
    self.set_cursor(Wx::STANDARD_CURSOR)
    Wx::message_box(e.message, "Error", Wx::ICON_ERROR + Wx::OK)
    return false
  end

###############################################################################  
  
  def new_data(format_data)
    @current_file = File.join(@app_path, [@def_name, format_data[:extname]].join('.'))
    @config.delete(:last_storage)
    
    return unless create_dictionary(format_data)

    @new_file = true
    self.updateGUI()    
  end
  
###############################################################################  

  def load_data(fname)
    @current_file = File.expand_path(fname) unless fname.nil?
    
    format_data = self.get_format_data(File.extname(@current_file).tr('.', '').downcase)  
    
    return unless create_dictionary(format_data)
    
    run_proc({
      :proc      => lambda { @dictionary.load!(@current_file) },
      :onSuccess => lambda {
        @new_file = false
        @config[:last_storage] = @current_file
        self.updateGUI() 
      }
    })
  end
  
###############################################################################  

  def save_data(fname)
    return if @dictionary.nil?
    
    @current_file = File.expand_path(fname) unless fname.nil?
    
    run_proc({
      :proc      => lambda { @dictionary.save!(@current_file) },
      :onSuccess => lambda {
        @new_file = false
        @config[:last_storage] = @current_file
        self.update_title()
        self.update_sbar('Saved') 
      }
    })
    
  end
  
###############################################################################  

  def close_data()
    return true if @dictionary.nil?
    if (@dictionary.modified)
      case Wx::message_box("Current data has been modified.\nDo you want to save the changes?", 
                           "Save data", Wx::ICON_QUESTION + Wx::YES_NO + Wx::CANCEL)
        when Wx::YES    then @dictionary.save!(@current_file)
        when Wx::CANCEL then return false
        when Wx::NO     then # do nothing
      end
    end
    return true
  end
  
###############################################################################  

  def import_from_dir(dirname)
    run_proc({
      :proc      => lambda {
        @dictionary.import_path = dirname
        @dictionary.import_dir()
      }, 
      :onSuccess => lambda {
        self.update_tree() 
        self.update_texts()
      }
    })
  end
  
###############################################################################  

  def update_store(sItem=nil)
    sItem ||= @tree.get_selection
    if sItem.nonzero? and @tree.get_children_count(sItem).zero?
      data = @tree.get_item_data(sItem) 
      @dictionary.set(data[:path], self.get_text_values)
      self.set_color(sItem)
    end            
  end
  
###############################################################################  
  
  def on_close(event)
    return unless close_data()
    
    fname = File.join(@app_path, "config.yml")
    File.open(fname, 'w'){|out|
      YAML.dump(@config, out) 
    }
    Wx::get_app().exit_main_loop()
  end
  
###############################################################################  

  def on_new_data_click(event)
    return unless close_data()
    
    dlg = Wx::SingleChoiceDialog.new(self, 
      "Choose dictionary format", 
      "New dictionary", 
      @dict_formats.map{|df| "#{df[:caption]} (.#{df[:extname]})"}
    )
    
    return unless dlg.show_modal == Wx::ID_OK
    index = dlg.get_selection()
    
    return if index.nil?
    self.new_data(@dict_formats[index])
  end
  
###############################################################################  

  def on_open_data_click(event)
    return unless close_data()
    
    wildcard = "All supported formats|" << @dict_formats.map{|df| "*.#{df[:extname]}"}.join(';') << "|"
    wildcard << @dict_formats.map{|df| "#{df[:caption]} (*.#{df[:extname]})|*.#{df[:extname]}"}.join("|")
    
    fileDlg  = Wx::FileDialog.new(self,nil, @app_path, nil, wildcard, Wx::FD_OPEN + Wx::FD_FILE_MUST_EXIST)
    
    return unless fileDlg.show_modal == Wx::ID_OK
    
    self.load_data(fileDlg.get_path)
  end
  
###############################################################################  

  def on_save_data_click(event)
    fname = @current_file
    if @new_file
      df = @dictionary.format
      wildcard = "#{df[:caption]} (*.#{df[:extname]})|*.#{df[:extname]}" 
      fileDlg  = Wx::FileDialog.new(self, nil, @app_path, @def_name, wildcard, Wx::FD_SAVE + Wx::FD_OVERWRITE_PROMPT)
  
      return unless fileDlg.show_modal == Wx::ID_OK
      fname = fileDlg.get_path()
    end    
  
    self.update_store()
    self.save_data(fname)
  end
  
###############################################################################  

  def on_save_as_data_click(event)
    df      = @dictionary.format
    formats = @dict_formats.clone
    formats.delete(df)
    formats.insert(0, df)

    wildcard = formats.map{|f| "#{f[:caption]} (*.#{f[:extname]})|*.#{f[:extname]}"}.join("|")
    fname    = File.basename(@current_file)
    fileDlg  = Wx::FileDialog.new(self, nil, @app_path, fname, wildcard, Wx::FD_SAVE + Wx::FD_OVERWRITE_PROMPT)

    return unless fileDlg.show_modal == Wx::ID_OK
    fname = fileDlg.get_path()
    
    format_data = self.get_format_data(File.extname(fname).tr('.', '').downcase)
    @dictionary.change_format(format_data)
    @dictionary.import_path = nil
    @dictionary.export_path = nil
    
    self.update_store()
    self.save_data(fname)
  end

###############################################################################  
  
  def on_new_dict_click(event)
    locale_name = Wx::get_text_from_user("Enter new language code name (t.ex 'en')", "New language","",self)
    unless locale_name.nil? or locale_name.empty?
      @dictionary.add_locale(locale_name.to_sym) 
      self.update_tree
      self.update_texts
      self.update_sbar('Done')
    end
  end
  
###############################################################################  
  
  def on_remove_dict_click(event)
    dlg = Wx::MultiChoiceDialog.new(self, "Choose languages to be removed", "Remove language", @dictionary.locales.map{|l| l.to_s})
    
    return unless dlg.show_modal == Wx::ID_OK
    to_remove = dlg.get_selections()
    
    unless to_remove.nil? or to_remove.empty?
      return unless Wx::message_box("Are you sure?", "Remove language", Wx::ICON_QUESTION + Wx::YES_NO) == Wx::YES
      to_remove.sort! {|x,y| y <=> x }
      to_remove.each{|ind| @dictionary.remove_locale(ind)} 
      self.update_tree
      self.update_texts
      self.update_sbar('Done')
    end    
  end

###############################################################################  

  def on_new_key_click(event)
    selected_item = @tree.get_selection || @tree.get_root_item
    
    data = @tree.get_item_data(selected_item)
    
    new_item_name = "new_key" << (@tree.get_count() + 1).to_s
    
    run_proc({
      :proc      => lambda { @dictionary.add(data[:path], new_item_name.to_sym) },
      :onSuccess => lambda {
        path = data[:path].clone
        path << new_item_name.to_sym    
        new_item = @tree.append_item(selected_item, new_item_name, -1, -1, {:type => :token, :path => path})
        @tree.expand(selected_item)
        @tree.select_item(new_item) 
        self.set_color(new_item)
      }
    })
  end
  
###############################################################################  
  
  def on_cut_key_click(event)
    on_copy_key_click(event)
    on_remove_key_click(event)
  end
  
###############################################################################  

  def on_copy_key_click(event)
    sItem = @tree.get_selection
    return if sItem.zero?
    
    data = @tree.get_item_data(sItem)
    return if data[:type] == :root
    
    path = data[:path]
    @clipboard = {path.last => @dictionary.get_copy(path)}
    
    self.update_sbar('Copied')
  end
  
###############################################################################  

  def on_paste_key_click(event)
    return if @clipboard.nil? or @clipboard.empty?
    
    sItem = @tree.get_selection
    return if sItem.zero?
    
    clip_data = @clipboard.clone
    data = @tree.get_item_data(sItem)
    @dictionary.set(data[:path], clip_data)
    
    self.fill_tree(@tree, sItem, clip_data)
    @tree.expand(sItem)
    @tree.select_item(@tree.get_last_child(sItem))
    @tree.expand(@tree.get_last_child(sItem))
  end
  
###############################################################################  

#  def on_moveup_key_click(event)
#    sItem = @tree.get_selection
#    @tree.edit_label(sItem)
#  end

###############################################################################  

  def on_remove_key_click(event)
#    return unless Wx::message_box("Are you sure?", "Delete key", Wx::ICON_QUESTION + Wx::YES_NO) == Wx::YES
    
    selected_item = @tree.get_selection 
    data = @tree.get_item_data(selected_item)
    
    if data[:type] == :root
      proc        = lambda { @dictionary.clear_data() }
      success     = lambda { 
        @tree.delete_all_items
        @tree.select_item(create_root) 
      }
    else
      parent_item = @tree.get_item_parent(selected_item)
      proc        = lambda { @dictionary.delete(data[:path]) }
      success     = lambda { 
        @tree.delete(selected_item) 
        @tree.select_item(parent_item)
        self.set_color(parent_item)
      }
    end

    run_proc({
      :proc      => proc,
      :onSuccess => success
    })
  end
  
###############################################################################  
  
  def on_search(event)
    search_str = event.get_string.upcase
    found      = false

    @tree.traverse { |item_id|
      # searching in the treenode text 
      if (@tree.get_item_text(item_id).upcase.include? search_str)
        next if @already_found.include? item_id
        found = item_id
      end
      
      next if @tree.item_has_children(item_id)

      # searching in the treenode data
      data = @tree.get_item_data(item_id)

      unless data.nil?
        values = @dictionary.get(data[:path])
        values.each_value{|value|  
          next if value.nil? or value.to_s.empty?
          
          if (value.upcase.include? search_str)
            next if @already_found.include? item_id
            found = item_id
            break
          end        
        }
      end
      break if found
    }
    
    if found
      @tree.select_item(found)    
      @tree.ensure_visible(found)
      @tree.expand(found)
      @already_found << found
    else
      @already_found = []
      Wx::message_box("Finished searching through the keys tree", 
                      "Search", Wx::ICON_INFORMATION + Wx::OK)
    end
  end
  
###############################################################################  
  
  def on_export_click(event)
    dir = Pathname.new(@dictionary.export_path || @app_path)
    
    if dir.relative?
      dir = File.expand_path(dir.to_s, File.dirname(@current_file))
    end
    
    dirDlg = Wx::DirDialog.new(self, "Select an output directory for export", dir.to_s)
    
    return unless dirDlg.show_modal == Wx::ID_OK
    
    self.update_store()
    
    run_proc({
      :proc      => lambda {
        @dictionary.export_path = dirDlg.get_path()
        @dictionary.export
      }, 
      :onSuccess => lambda {
        Wx::message_box("Data has been successfully exported", "Export data", Wx::ICON_INFORMATION + Wx::OK)
        self.update_sbar('Done')
      }
    })
  end
  
###############################################################################  
  
  def on_import_files_click(event)
    wildcard = "All supported formats|" << @dict_formats.map{|df| "*.#{df[:extname]}"}.join(';') << "|"
    wildcard << @dict_formats.map{|df| "#{df[:caption]} (*.#{df[:extname]})|*.#{df[:extname]}"}.join("|")

    fileDlg = Wx::FileDialog.new(self, nil, @app_path, nil, wildcard, Wx::FD_OPEN + Wx::FD_FILE_MUST_EXIST + Wx::FD_MULTIPLE)
    
    return unless fileDlg.show_modal == Wx::ID_OK

    run_proc({
      :proc      => lambda {@dictionary.import_many_files(fileDlg.get_filenames, fileDlg.get_directory())}, 
      :onSuccess => lambda {
        self.update_tree()
        self.update_texts()
      }
    })
  end
  
###############################################################################  
  
  def on_import_dir_click(event)
    dir = Pathname.new(@dictionary.import_path || @app_path)
    
    if dir.relative?
      dir = File.expand_path(dir.to_s, File.dirname(@current_file))
    end

    dirDlg = Wx::DirDialog.new(self, nil, dir.to_s)
    
    return unless dirDlg.show_modal == Wx::ID_OK
    
    self.import_from_dir(dirDlg.get_path())
  end

###############################################################################  

  def on_about_click(event)
    Wx::about_box( :name        => @app_name,
                   :version     => '0.6.3', 
                   :developers  => ['Alexey Stryi @ Ibissoft AB'],
                   :description => "\nA locale dictionaries editor for the Ruby I18n framework",
                   :icon        => Wx::Icon.new(File.join(@app_path,'images','dictator_logo.png'), Wx::BITMAP_TYPE_PNG))
  end

###############################################################################  
  
  def on_text_enter(event, txt)
    text = txt.get_value()
    loc = txt.locale
    
    self.set_cursor(Wx::HOURGLASS_CURSOR)
    @text_container.get_children.each{|ctrl|
      next unless ctrl.is_a? MyTextCtrl
      next if ctrl.locale.nil?
      next if ctrl.locale == loc
      next unless ctrl.get_value().empty?
      
      new_value = Translate.t(text, loc.to_s[0..1], ctrl.locale.to_s[0..1])
      ctrl.set_value(new_value)
    }
    self.set_cursor(Wx::STANDARD_CURSOR)
  end
  
###############################################################################

  def on_translate_click(event) 
    values_translated = 0
    items_traversed   = 0
    items_count       = @tree.get_count()
    
    
    unless Ping.pingecho("www.google.com", 10, 80)
      Wx::message_box("Unable to contact GoogleTranslate server. Check the network connection...", "Google Translate", Wx::ICON_WARNING + Wx::OK)
      return
    end
    
    pd = Wx::ProgressDialog.new(
      "Google Translate", 
      "Wait while values are being translated...", 
      items_count, 
      self, 
      Wx::PD_AUTO_HIDE + Wx::PD_ELAPSED_TIME + Wx::PD_SMOOTH + Wx::PD_REMAINING_TIME)
    
    @tree.traverse{|items_id|
      items_traversed += 1
      pd.update(items_traversed)
      
      next unless @tree.get_children_count(items_id).zero?
 
      itemData = @tree.get_item_data(items_id) 
      next if @dictionary.correct?(itemData[:path])
      
      text_values = @dictionary.get(itemData[:path])

      non_empty_values = text_values.select{|k,v| !v.nil? and !v.empty?}
      next if non_empty_values.empty?
      
      from = non_empty_values[0][0]
      text = non_empty_values[0][1]
      
      text_values.each_key{|key|
        next unless text_values[key].nil? or text_values[key].empty?
        
        text_values[key] = Translate.t(text, from.to_s[0..1], key.to_s[0..1])
        values_translated += 1
      }
      
      @dictionary.set(itemData[:path], text_values)
    }

    if (values_translated > 0)
      self.update_tree
      @dictionary.modified = true
      Wx::message_box("#{values_translated} values have been translated", "Google Translate", Wx::ICON_INFORMATION + Wx::OK)
    else
      Wx::message_box("There is nothing to translate", "Google Translate", Wx::ICON_INFORMATION + Wx::OK)
    end
    
  end
  
###############################################################################  
  
  def update_tree
    @tree.delete_all_items
    root = self.create_root()
    self.fill_tree(@tree, root, @dictionary.token_tree)
    
    @tree.sort_children(root)
    @tree.expand(root)
    @tree.select_item(root)
  end
  
###############################################################################  

  def create_root
    @tree.add_root('Keys', -1,-1, {:type => :root, :path => []} )
  end

###############################################################################  

  def fill_tree(tree, root, data)
    root_data = tree.get_item_data(root)
    data.each_key{|key|
      if data[key].is_a? Hash
        path = root_data[:path].clone
        path << key
        
        new_item = tree.append_item(root, key.to_s, -1, -1, {:type => :token, :path => path})
        self.fill_tree(tree, new_item, data[key])
        
        tree.sort_children(new_item)
        tree.set_item_data(root, root_data)
        
        if @tree.get_children_count(new_item).zero?
          self.set_color(new_item)
        end
      end
    }    
  end
  
###############################################################################  

  def set_color(node)
    data = @tree.get_item_data(node) 
    return if data.nil?

    root = @tree.get_root_item()

    if @dictionary.correct?(data[:path])
      self.mark_branch_valid(node, root)
    else
      self.mark_branch_invalid(node, root)
    end
    
  end
  
###############################################################################  
      
  def mark_branch_valid(node, root)
    while (node.nonzero? and node != root) do
        @tree.set_item_text_colour(node, Wx::NULL_COLOUR)
        node = @tree.get_item_parent(node)
        
        #check if there is another invalid children
        flag = false
        @tree.get_children(node).each{|child|
          if @tree.get_item_text_colour(child) == Wx::RED
            flag = true
            break
          end
        } 
        break if flag  #if found another invalid -> break, i.e. don't change parents' color
    end
  end

###############################################################################  
  
  def mark_branch_invalid(node, root)
    while (node.nonzero? and node != root) do
        @tree.set_item_text_colour(node, Wx::RED)
        node = @tree.get_item_parent(node)
    end
  end

###############################################################################  
  
  def update_texts
    text_values = self.get_text_values
    
    @text_container.destroy_children()
    
    main_ps = Wx::FlexGridSizer.new( 2, 2, 0, 0 )
    main_ps.add_growable_col( 1 )
    
    locales = @dictionary.locales.sort{|l1, l2| l1.to_s <=> l2.to_s}
    locales.each{|l|
      lbl = Wx::StaticText.new(@text_container,  Wx::ID_ANY,  l.to_s.capitalize)
      main_ps.add(lbl, 0, Wx::ALL , 5)
      
      txt = MyTextCtrl.new(@text_container,  Wx::ID_ANY, "", 
                           Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE, 
                           Wx::TE_PROCESS_ENTER)
      txt.locale = l
      
      evt_text_enter(txt) { | event | on_text_enter(event, txt) }

      txt_sizer = Wx::BoxSizer.new Wx::HORIZONTAL
      txt_sizer.add(txt, 1,  Wx::LEFT, 5)
      
      main_ps.add(txt_sizer, 0, Wx::ALL + Wx::EXPAND, 5 )
    }
    
    @text_container.set_sizer main_ps
    @text_container.layout

    self.set_text_values(text_values)
  end
  
###############################################################################  

  def get_text_values
    res = {}
    @text_container.get_children.each{|ctrl|
      next unless ctrl.is_a? MyTextCtrl
      res[ctrl.locale] = ctrl.get_value()
    }
    res
  end

###############################################################################  
  
  def set_text_values(data)
    return if data.nil?
    
    @text_container.get_children.each{|ctrl|
      next unless ctrl.is_a? MyTextCtrl
      ctrl.set_value(data[ctrl.locale] || '')
    }
  end
  
###############################################################################  

  def enable_texts(enable=true)
    @text_container.get_children.each{|ctrl|
      next unless ctrl.is_a? MyTextCtrl
      ctrl.enable(enable)
    }
  end

###############################################################################  

  def clear_texts()
    @text_container.get_children.each{|ctrl|
      next unless ctrl.is_a? MyTextCtrl
      ctrl.clear
    }    
  end
  
###############################################################################  
#  Executes a Proc and if its result has :success == true, executes a onSuccess method

  def run_proc(opts)
    proc    = opts[:proc]
    success = opts[:onSuccess]
    return if proc.nil? or !proc.is_a? Proc
    
    self.set_cursor(Wx::HOURGLASS_CURSOR)
    res = proc.call
    if res[:success]
      self.update_sbar('Done')
      success.call if !success.nil? and success.is_a? Proc
      self.set_cursor(Wx::STANDARD_CURSOR)
    else
      self.set_cursor(Wx::STANDARD_CURSOR)
      Wx::message_box(res[:error], "Error", Wx::ICON_ERROR + Wx::OK)
    end
  end

###############################################################################
  
  def updateGUI
    self.update_tree()
    self.update_texts()
    self.update_title()
    self.update_sbar('')    
  end
  
###############################################################################

  def update_sbar(txt)
    @statusbar.push_status_text(txt,0)
    @statusbar.push_status_text("Keys: #{@dictionary.get_count()}", 1)
    @statusbar.push_status_text((@dictionary.modified) ? "Modified" : "", 2)
    @statusbar.push_status_text("New", 2) if @new_file
  end
  
###############################################################################  

  def update_title
    self.set_label("#{@app_name} - #{@current_file}")
  end

###############################################################################  
  
  def updatePath(data)
    path = data[:path][0..data[:path].size-2]
    
#    @pathtext.set_label('Scope: ' + path.join('.'))
    @pathedit.set_label(path.join('.'))
  end
  
###############################################################################  

  def get_format_data(extname)
    found = @dict_formats.select{|df| df[:extname] == extname}
    return (found.nil? or found.empty?) ? @dict_formats.first : found[0]  
  end

###############################################################################  
  
end


  
  options = {}
  
  oParser = OptionParser.new
  oParser.on("--load=<VALUE>", String, "A dictionary file to load on start up")  {|val| 
    options[:load] = val
  }
  
  oParser.on("--import_from=<VALUE>", String, "A path to folder to import data from on start up")  {|val| 
    options[:import_from] = val
  }
  
  oParser.on("--format=<VALUE>", String, "A default dictionary format")  {|val| 
    options[:format] = val
  }
  
  oParser.on("--export_to=<VALUE>", String, "A default path to export data to")  {|val| 
    options[:export_to] = val
  }
  
  begin
    rest = oParser.parse(*ARGV)
    raise "Wrong arguments" if !rest.empty?
  rescue => e
    puts e.message unless e.message.empty?
    puts oParser.to_s
    exit
  end
  
  Wx::App.run do
    MainFrame.new(options).show
  end
