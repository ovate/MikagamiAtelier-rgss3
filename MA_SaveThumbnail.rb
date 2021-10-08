#==============================================================================
# ■ save & load screen customization
#    Ver 0.02　2012/01/21　Fixed scene for event command “Save screen”
#                          Fixed a bug that was not compatible with "Open"
#    Ver 0.01　2011/12/25
#    http://fweb.midi.co.jp/~mikagami/atelier/
#------------------------------------------------------------------------------
#
# Change the appearance of the save screen and load screen with thumbnail.
# Save location (map display name) in the save file and the game screen.
#
# ※Note!
# ・Save files that are used before installing this script can no longer be used.
# ・Because the thumbnail of the game screen is converted and saved,
#  Save file size is relatively large. Also, the preview display speed is slow.
# ・Although we have confirmed functionality, we do not guarantee zero defects.
# ・The author holds the copyrights to this script. 水鏡幻姿 (Mikagami Atelier)
# 　However, you do not need the author's permission to use, revise, or redistribute this script.
# 　The author does not have an obligation to fulfill requests to revise the script or complete its unfinished parts.
# 　Instead of asking another person to revise the script, everybody will be happy if you revise it yourself. 
#
#==============================================================================

module DataManager
  #--------------------------------------------------------------------------
  # ◎ Maximum number of save files (overwrite definition)
  #--------------------------------------------------------------------------
  def self.savefile_max
    return 20 # Set a reasonable amount
  end
  #--------------------------------------------------------------------------
  # ● Get save folder name
  #--------------------------------------------------------------------------
  def self.save_folder_name
    return "Save"
  end
  #--------------------------------------------------------------------------
  # ◎ Save file existence judgment (overwrite definition)
  #--------------------------------------------------------------------------
  def self.save_file_exists?
    if save_folder_name == ""
      path = 'Save*.rvdata2'
    else
      path = save_folder_name + '/Save*.rvdata2'
    end
    !Dir.glob(path).empty?
  end
  #--------------------------------------------------------------------------
  # ◎ Create file name (overwrite definition)
  #     index : File index
  #--------------------------------------------------------------------------
  def self.make_filename(index)
    file_name = sprintf("Save%03d.rvdata2", index + 1)
    if save_folder_name == ""
      return file_name
    else
      return save_folder_name + '/' + file_name
    end
  end
  #--------------------------------------------------------------------------
  # ● Execution of save / preview
  #--------------------------------------------------------------------------
  def self.save_game_with_preview(index)
    begin
      save_game_without_rescue2(index)
    rescue
      delete_save_file(index)
      false
    end
  end
  #--------------------------------------------------------------------------
  # ● Load execution and preview available
  #--------------------------------------------------------------------------
  def self.load_game2(index)
    load_game_without_rescue2(index) rescue false
  end
  #--------------------------------------------------------------------------
  # ● Load preview
  #--------------------------------------------------------------------------
  def self.load_preview(index)
    load_preview_without_rescue(index) rescue nil
  end
  #--------------------------------------------------------------------------
  # ● Execution of save and preview (no exception handling)
  #--------------------------------------------------------------------------
  def self.save_game_without_rescue2(index)
    unless FileTest.directory?(save_folder_name)
      if FileTest.exist?(save_folder_name)
        msgbox "An error occurred during the save process. Please restart."
        return false
      end
      Dir::mkdir(save_folder_name)
      unless FileTest.directory?(save_folder_name)
        msgbox "Save failed. Check your HDD/SSD free space, etc."
        return false
      end
    end
    File.open(make_filename(index), "wb") do |file|
      $game_system.on_before_save
      Marshal.dump(make_save_header2, file)
      Marshal.dump(make_save_preview, file)
      Marshal.dump(make_save_contents, file)
      @last_savefile_index = index
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● Load execution with preview (no exception handling)
  #--------------------------------------------------------------------------
  def self.load_game_without_rescue2(index)
    File.open(make_filename(index), "rb") do |file|
      Marshal.load(file)
      Marshal.load(file)
      extract_save_contents(Marshal.load(file))
      reload_map_if_updated
      @last_savefile_index = index
    end
    return true
  end
  #--------------------------------------------------------------------------
  # ● Create / extend save header
  #--------------------------------------------------------------------------
  def self.make_save_header2
    header = {}
    header[:characters] = $game_party.characters_for_savefile
    header[:playtime_s] = $game_system.playtime_s
    header[:savetitle]  = $game_map.display_name
    header
  end
  #--------------------------------------------------------------------------
  # ● Load preview (no exception handling)
  #--------------------------------------------------------------------------
  def self.load_preview_without_rescue(index)
    File.open(make_filename(index), "rb") do |file|
      Marshal.load(file)
      return array_to_bitmap(Marshal.load(file))
    end
    return nil
  end
  #--------------------------------------------------------------------------
  # ● Create preview
  #--------------------------------------------------------------------------
  def self.make_save_preview
    preview = bitmap_to_array($game_temp.save_preview_bmp)
    preview
  end
  #--------------------------------------------------------------------------
  # ● Convert preview bitmap to saveable array format
  #     bitmap
  #--------------------------------------------------------------------------
  def self.bitmap_to_array(bitmap)
    return unless bitmap
    data = []
    for i in 0...bitmap.width
      data[i] = []
      for j in 0...bitmap.height
        color = bitmap.get_pixel(i, j)
        value = (color.red.floor << 16) + (color.green.floor << 8) + color.blue.floor
        data[i][j] = value
      end
    end
    return data
  end
  #--------------------------------------------------------------------------
  # ● Restore preview bitmap from array format to bitmap
  #--------------------------------------------------------------------------
  def self.array_to_bitmap(data)
    return unless data
    bitmap = Bitmap.new(data.size, data[0].size)
    for i in 0...data.size
      for j in 0...data[0].size
        red   = (data[i][j] >> 16) & 0xff
        green = (data[i][j] >> 8) & 0xff
        blue  = data[i][j] & 0xff
        color = Color.new(red, green, blue)
        bitmap.set_pixel(i, j, color)
      end
    end
    return bitmap
  end
end

class Game_Temp
  #--------------------------------------------------------------------------
  # ● Public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :save_preview_bmp               # BMP for save preview
  #--------------------------------------------------------------------------
  # ● Object initialization
  #--------------------------------------------------------------------------
  alias _old001_initialize initialize
  def initialize
    _old001_initialize
    @save_preview_bmp = Bitmap.new(1, 1)
  end
  #--------------------------------------------------------------------------
  # ● BMP for save preview
  #--------------------------------------------------------------------------
  def create_save_preview
    @save_preview_bmp.dispose if @save_preview_bmp
    @save_preview_bmp = Bitmap.new(224, 160)
    rect = Rect.new(0, 0, 224, 160)
    rect.x = $game_player.screen_x - 112
    rect.y = $game_player.screen_y - 80 - 16
    bitmap = Graphics.snap_to_bitmap
    @save_preview_bmp.blt(0, 0, bitmap, rect)
    bitmap.dispose
  end
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ◎ Character image information for save file display (overwrite definition)
  #--------------------------------------------------------------------------
  def characters_for_savefile
    battle_members.collect do |actor|
      [actor.character_name, actor.character_index, actor.level, actor.name]
    end
  end
end

#==============================================================================
# ■ Window_SaveFileList
#------------------------------------------------------------------------------
# 　Save file list window displayed on the save & load screen.
#==============================================================================
class Window_SaveFileList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● Object initialization
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, (Graphics.width - x) / 2, Graphics.height - y)
    load_savefileheader
    refresh
    activate
  end
  #--------------------------------------------------------------------------
  # ● Get number of items
  #--------------------------------------------------------------------------
  def item_max
    DataManager.savefile_max
  end
  #--------------------------------------------------------------------------
  # ● Get item height
  #--------------------------------------------------------------------------
  def item_height
    (height - standard_padding * 2) / 5
  end
  #--------------------------------------------------------------------------
  # ● Drawing items
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect_for_text(index)
    text_h = rect.y + (rect.height - line_height * 2) / 2
    name = Vocab::File + " #{index + 1}"
    change_color(system_color)
    draw_text(rect.x, text_h, rect.width, line_height, name)
    return unless @data[index]
    change_color(normal_color)
    draw_playtime(rect.x, text_h, rect.width, line_height, index)
    draw_savetitle(rect.x, text_h + line_height, rect.width, line_height, index)
  end
  #--------------------------------------------------------------------------
  # ● Processing when the enter button is pressed
  #--------------------------------------------------------------------------
  def process_ok
    call_ok_handler # Process with scene class
  end
  #--------------------------------------------------------------------------
  # ● Read all save file headers
  #--------------------------------------------------------------------------
  def load_savefileheader
    @data = []
    for i in 0...item_max do @data[i] = DataManager.load_header(i) end
  end
  #--------------------------------------------------------------------------
  # ● Drawing play time
  #--------------------------------------------------------------------------
  def draw_playtime(x, y, width, height, i)
    draw_text(x, y, width, height, @data[i][:playtime_s], 2)
  end
  #--------------------------------------------------------------------------
  # ● Drawing save titles
  #--------------------------------------------------------------------------
  def draw_savetitle(x, y, width, height, i)
    title = @data[i][:savetitle]
    title = "＜ＮＯ ＴＩＴＬＥ＞" if title == ""
    draw_text(x, y, width, height, title)
  end
end

#==============================================================================
# ■ Window_SaveFilePreview
#------------------------------------------------------------------------------
# 　This is the save file window displayed during save & load screen.
#==============================================================================
class Window_SaveFilePreview < Window_Base
  #--------------------------------------------------------------------------
  # ● Object initialization
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, Graphics.width - x, Graphics.height - y)
    @file_no = -1
    @bmps = []
    @data = []
  end
  #--------------------------------------------------------------------------
  # ● Dispose
  #--------------------------------------------------------------------------
  def dispose
    for bmp in @bmps
      next if bmp == nil or bmp.disposed?
      bmp.dispose
    end
    super
  end
  #--------------------------------------------------------------------------
  # ● Load save file and display preview
  #     file_no : Save file number
  #--------------------------------------------------------------------------
  def set_preview(file_no)
    return if @file_no == file_no
    @file_no = file_no
    refresh
  end
  #--------------------------------------------------------------------------
  # ● Refresh
  #--------------------------------------------------------------------------
  def refresh
    self.contents.clear
    load_preview(@file_no)
    return unless @data[@file_no]
    bitmap = @bmps[@file_no]
    start_x = (contents.width - bitmap.width) / 2
    contents.fill_rect(start_x - 1, 7, bitmap.width + 2, bitmap.height + 2, Color.new(0, 0, 0))
    contents.blt(start_x, 8, bitmap, bitmap.rect)
    header = @data[@file_no]
    header[:characters].each_with_index do |data, i|
      break if i >= 4
      character_y = bitmap.height + 22 + i * 40
      draw_character(data[0], data[1], start_x + 16, character_y + 28)
      draw_level_for_preview(data[2], start_x + 40, character_y)
      draw_name_for_preview(data[3], start_x + 100, character_y, bitmap.width - start_x - 100)
    end
  end
  #--------------------------------------------------------------------------
  # ● Load preview data
  #--------------------------------------------------------------------------
  def load_preview(file_no)
    return if @data[file_no]
    @bmps[file_no] = DataManager.load_preview(file_no)
    return unless @bmps[file_no]
    @data[file_no] = DataManager.load_header(file_no)
  end
  #--------------------------------------------------------------------------
  # ● Level drawing
  #--------------------------------------------------------------------------
  def draw_level_for_preview(level, x, y)
    change_color(system_color)
    draw_text(x, y, 24, line_height, Vocab::level_a)
    change_color(normal_color)
    draw_text(x + 24, y, 24, line_height, level, 2)
  end
  #--------------------------------------------------------------------------
  # ● Actor name drawing
  #--------------------------------------------------------------------------
  def draw_name_for_preview(name, x, y, width)
    change_color(normal_color)
    draw_text(x, y, width, line_height, name)
  end
end

class Scene_File < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ◎ Start processing (overwrite definition)
  #--------------------------------------------------------------------------
  def start
    super
    create_help_window
    @filelist_window = Window_SaveFileList.new(0, @help_window.height)
    @filelist_window.set_handler(:ok,     method(:on_savefile_ok))
    @filelist_window.set_handler(:cancel, method(:on_savefile_cancel))
    @preview_window = Window_SaveFilePreview.new(@filelist_window.width, @help_window.height)
    init_selection
  end
  #--------------------------------------------------------------------------
  # ◎ End processing (overwrite definition)
  #--------------------------------------------------------------------------
  def terminate
    super
  end
  #--------------------------------------------------------------------------
  # ◎ Initialize selected state (overwrite definition)
  #--------------------------------------------------------------------------
  def init_selection
    index = first_savefile_index
    @filelist_window.select(index)
    @preview_window.set_preview(index)
  end
  #--------------------------------------------------------------------------
  # ◎ Frame update (overwrite definition)
  #--------------------------------------------------------------------------
  def update
    super
    @preview_window.set_preview(@filelist_window.index)
  end
end

class Scene_Save < Scene_File
  #--------------------------------------------------------------------------
  # ◎ Save file (overwrite definition)
  #--------------------------------------------------------------------------
  def on_savefile_ok
    super
    if DataManager.save_game_with_preview(@filelist_window.index)
      on_save_success
    else
      Sound.play_buzzer
    end
  end
end

class Scene_Load < Scene_File
  #--------------------------------------------------------------------------
  # ◎ Save file (overwrite definition)
  #--------------------------------------------------------------------------
  def on_savefile_ok
    super
    if DataManager.load_game2(@filelist_window.index)
      on_load_success
    else
      Sound.play_buzzer
    end
  end
end

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ◎ End processing
  #--------------------------------------------------------------------------
  alias _old001_terminate terminate
  def terminate
    $game_temp.create_save_preview
    _old001_terminate
  end
end