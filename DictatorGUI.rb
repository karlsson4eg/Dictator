
# This class was automatically generated from XRC source. It is not
# recommended that this file is edited directly; instead, inherit from
# this class and extend its behaviour there.  
#
# Source file: DictatorGUI.xrc 
# Generated at: Sat Apr 17 15:42:12 +0200 2010

class DictMainForm < Wx::Frame
	
	attr_reader :menubar, :mfile, :mnewdata, :mopendata, :msavedata,
              :msaveasdata, :mimport, :mimportfiles, :mimportdir,
              :mexport, :mexit, :medit, :mnewdict, :mremovedict,
              :minsertkey, :mcutkey, :mcopykey, :mpastekey, :mmoveup,
              :mremovekey, :mhelp, :mabout, :toolbar, :tlbnewdata,
              :tlbopendata, :tlbsavedata, :tlbnewdict, :tlbremovedict,
              :tlbtranslate, :txtsearch, :tlbimportfiles,
              :tlbimportdir, :tlbexport, :statusbar, :main_container,
              :keys_toolbar, :tlbinsertkey, :tlbcutkey, :tlbcopykey,
              :tlbpastekey, :tlbremovekey, :tree, :pathtext,
              :pathedit, :text_container
	
	def initialize(parent = nil)
		super()
		xml = Wx::XmlResource.get
		xml.flags = 2 # Wx::XRC_NO_SUBCLASSING
		xml.init_all_handlers
		xml.load("DictatorGUI.xrc")
		xml.load_frame_subclass(self, parent, "dictMain")

		finder = lambda do | x | 
			int_id = Wx::xrcid(x)
			begin
				Wx::Window.find_window_by_id(int_id, self) || int_id
			# Temporary hack to work around regression in 1.9.2; remove
			# begin/rescue clause in later versions
			rescue RuntimeError
				int_id
			end
		end
		
		@menubar = finder.call("menubar")
		@mfile = finder.call("mFile")
		@mnewdata = finder.call("mNewData")
		@mopendata = finder.call("mOpenData")
		@msavedata = finder.call("mSaveData")
		@msaveasdata = finder.call("mSaveAsData")
		@mimport = finder.call("mImport")
		@mimportfiles = finder.call("mImportFiles")
		@mimportdir = finder.call("mImportDir")
		@mexport = finder.call("mExport")
		@mexit = finder.call("mExit")
		@medit = finder.call("mEdit")
		@mnewdict = finder.call("mNewDict")
		@mremovedict = finder.call("mRemoveDict")
		@minsertkey = finder.call("mInsertKey")
		@mcutkey = finder.call("mCutKey")
		@mcopykey = finder.call("mCopyKey")
		@mpastekey = finder.call("mPasteKey")
		@mmoveup = finder.call("mMoveUp")
		@mremovekey = finder.call("mRemoveKey")
		@mhelp = finder.call("mHelp")
		@mabout = finder.call("mAbout")
		@toolbar = finder.call("toolBar")
		@tlbnewdata = finder.call("tlbNewData")
		@tlbopendata = finder.call("tlbOpenData")
		@tlbsavedata = finder.call("tlbSaveData")
		@tlbnewdict = finder.call("tlbNewDict")
		@tlbremovedict = finder.call("tlbRemoveDict")
		@tlbtranslate = finder.call("tlbTranslate")
		@txtsearch = finder.call("txtSearch")
		@tlbimportfiles = finder.call("tlbImportFiles")
		@tlbimportdir = finder.call("tlbImportDir")
		@tlbexport = finder.call("tlbExport")
		@statusbar = finder.call("statusBar")
		@main_container = finder.call("main_container")
		@keys_toolbar = finder.call("keys_toolbar")
		@tlbinsertkey = finder.call("tlbInsertKey")
		@tlbcutkey = finder.call("tlbCutKey")
		@tlbcopykey = finder.call("tlbCopyKey")
		@tlbpastekey = finder.call("tlbPasteKey")
		@tlbremovekey = finder.call("tlbRemoveKey")
		@tree = finder.call("tree")
		@pathtext = finder.call("pathText")
		@pathedit = finder.call("pathEdit")
		@text_container = finder.call("text_container")
		if self.class.method_defined? "on_init"
			self.on_init()
		end
	end
end


