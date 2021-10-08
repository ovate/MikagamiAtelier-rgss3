#==============================================================================
# ■ Mosaic Effect Transfer
#    Ver 0.01　2012/04/22
#    http://fweb.midi.co.jp/~mikagami/atelier/
#------------------------------------------------------------------------------
#
# Uses a pixelated transition effect when using "Transfer Player" command.
#
# How to use-
#   Use this script call before "Transfer Player" command
#   $game_temp.me_mosaic
#
# ※Note！
# ・Default fade effect for "Transfer Player" command will be ignored
# ・It's not guaranteed to work correctly with other scripts
# ・The author holds the copyrights to this script. 水鏡幻姿 (Mikagami Atelier)
# 　However, you do not need the author's permission to use, revise, or redistribute this script.
# 　The author does not have an obligation to fulfill requests to revise the script or complete its unfinished parts.
# 　Instead of asking another person to revise the script, everybody will be happy if you revise it yourself.
#
#==============================================================================

class Game_Temp
  #--------------------------------------------------------------------------
  # ● Transfer effect
  #--------------------------------------------------------------------------
  def me_clear;   @fade_type2 = 0;  end # clear
  def me_mosaic;  @fade_type2 = 1;  end # Mosaic effect
  def me_mosaic?; @fade_type2 == 1; end # Mosaic?
  def me_active?                        # whether or not active
    @fade_type2 = 0 if @fade_type2 == nil
    @fade_type2 >= 1
  end
end

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # ◎ Process before transfer location
  #--------------------------------------------------------------------------
  def pre_transfer
    @map_name_window.close
    if $game_temp.me_active?
      mosaicout if $game_temp.me_mosaic?
    else
      case $game_temp.fade_type
      when 0
        fadeout(fadeout_speed)
      when 1
        white_fadeout(fadeout_speed)
      end
    end
  end
  #--------------------------------------------------------------------------
  # ◎ Process after transfer location
  #--------------------------------------------------------------------------
  def post_transfer
    if $game_temp.me_active?
      update_for_fade
      mosaicin if $game_temp.me_mosaic?
      $game_temp.me_clear
    else
      case $game_temp.fade_type
      when 0
        Graphics.wait(fadein_speed / 2)
        fadein(fadein_speed)
      when 1
        Graphics.wait(fadein_speed / 2)
        white_fadein(fadein_speed)
      end
    end
    @map_name_window.open
  end
  #--------------------------------------------------------------------------
  # ● Mosaic screen in
  #     duration : consists of 16 patterns
  #                real time is 16 frames
  #--------------------------------------------------------------------------
  def mosaicin(duration = 2)
    Graphics.brightness = 255
    bmps = create_mosaic_bmp_arr
    spt = Sprite.new
    spt.z = 255
    spt.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    for i in 0...16
      spt.bitmap.stretch_blt(spt.bitmap.rect, bmps[15 - i], bmps[15 - i].rect)
      spt.color.set(0, 0, 0, (16 - i) ** 2)
      for j in 0...duration do update_basic end
    end
    for i in 0...16 do bmps[i].dispose end
    spt.dispose
  end
  #--------------------------------------------------------------------------
  # ● Mosaic screen out
  #     duration : consists of 16 patterns
  #                real time is 16 frames
  #--------------------------------------------------------------------------
  def mosaicout(duration = 2)
    bmps = create_mosaic_bmp_arr
    spt = Sprite.new
    spt.z = 255
    spt.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    for i in 0...16
      spt.bitmap.stretch_blt(spt.bitmap.rect, bmps[i], bmps[i].rect)
      spt.color.set(0, 0, 0, i ** 2)
      for j in 0...duration do update_basic end
    end
    Graphics.brightness = 0
    for i in 0...16 do bmps[i].dispose end
    spt.dispose
  end
  #--------------------------------------------------------------------------
  # ● Creating a mosaic pattern
  #--------------------------------------------------------------------------
  def create_mosaic_bmp_arr
    bmp = Graphics.snap_to_bitmap
    bmps = []
    for i in 0...16
      bmps[i] = Bitmap.new(Graphics.width / (i * 2 + 2), Graphics.height / (i * 2 + 2))
      bmps[i].stretch_blt(bmps[i].rect, bmp, bmp.rect)
    end
    bmp.dispose
    return bmps
  end
end