#==============================================================================
# ■ "New" Item Indication (without image)
#    Ver 0.01　2014/11/05 | English translation: tale 2017/03/27
#    http://fweb.midi.co.jp/~mikagami/atelier/
#------------------------------------------------------------------------------
#
# Displays "New" on the item icon when it's obtained for 2 minutes.
#
# ※Attention！
# ・Save Data before adding this script can still be used.
# ・Existing script that are defined or overwritten might cause problems to other scripts.
# ・The author holds the copyrights to this script. 水鏡幻姿 (Mikagami Atelier)
# 　However, you do not need the author's permission to use, revise, or redistribute this script. 
# 　The author does not have an obligation to fulfill requests to revise the script or complete its unfinished parts.
# 　Instead of asking another person to revise the script, everybody will be happy if you revise it yourself. 
#
#==============================================================================

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ★ Add New item
  #--------------------------------------------------------------------------
  def add_newitem(item)
    @new_items = [] if @new_items == nil
    bitem = Game_BaseItem.new
    bitem.object = item
    @new_items.push([Time.now, bitem])
  end
  #--------------------------------------------------------------------------
  # ★ New item detection？
  #--------------------------------------------------------------------------
  def newitem?(item)
    @new_items = [] if @new_items == nil
    for newitem in @new_items
      res = Time.now - newitem[0]
      if res < 0 || res > 60 * 2 # remove New about 2 minutes (can be adjustable)
        @new_items.delete(newitem)
        next
      end
      return true if newitem[1].object == item
    end
    return false
  end
  #--------------------------------------------------------------------------
  # ◎ Increments of items （decrease）
  #     include_equip : Equipment is affected
  #--------------------------------------------------------------------------
  alias _old001_gain_item gain_item
  def gain_item(item, amount, include_equip = false, new = true)
    _old001_gain_item(item, amount, include_equip)
    add_newitem(item) if new && item && amount > 0
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ◎ Exchange items within party
  #     new_item : Remove item from the party
  #     old_item : Return item to the party
  #--------------------------------------------------------------------------
  def trade_item_with_party(new_item, old_item)
    return false if new_item && !$game_party.has_item?(new_item)
    $game_party.gain_item(old_item, 1, false, false) # ★Prevents "New" from being attached to equipment that's removed.
    $game_party.lose_item(new_item, 1)
    return true
  end
end

class Window_Base < Window
  #--------------------------------------------------------------------------
  # ★ Display "NEW!" on the item icon
  #--------------------------------------------------------------------------
  def draw_new_icon(x, y, enabled = true)
    cy = Color.new(255, 255, 0, enabled ? 255 : translucent_alpha)
    cb = Color.new(0, 0, 0, enabled ? 255 : translucent_alpha)
    for pos in [[3,17],[3,18],[3,19],[3,20],[3,21],[4,18],[5,19],[6,20],[7,17],
      [7,18],[7,19],[7,20],[7,21],[9,17],[9,18],[9,19],[9,20],[9,21],[10,17],
      [10,19],[10,21],[11,17],[11,19],[11,21],[12,17],[12,19],[12,21],[14,17],
      [14,18],[14,19],[15,20],[15,21],[16,18],[16,19],[17,20],[17,21],[18,17],
      [18,18],[18,19],[20,17],[20,18],[20,19],[20,21]]
      contents.set_pixel(x + pos[0],y + pos[1],cy)
    end
    for pos in [[2,16],[2,17],[2,18],[2,19],[2,20],[2,21],[2,22],[3,16],[3,22],
      [4,16],[4,17],[4,19],[4,20],[4,21],[4,22],[5,17],[5,18],[5,20],[5,21],
      [6,16],[6,17],[6,18],[6,19],[6,21],[6,22],[7,16],[7,22],[8,16],[8,17],
      [8,18],[8,19],[8,20],[8,21],[8,22],[9,16],[9,22],[10,16],[10,18],[10,20],
      [10,22],[11,16],[11,18],[11,20],[11,22],[12,16],[12,18],[12,20],[12,22],
      [13,16],[13,17],[13,18],[13,19],[13,20],[13,21],[13,22],[14,16],[14,20],
      [14,21],[14,22],[15,16],[15,17],[15,18],[15,19],[15,22],[16,17],[16,20],
      [16,21],[16,22],[17,16],[17,17],[17,18],[17,19],[17,22],[18,16],[18,20],
      [18,21],[18,22],[19,16],[19,17],[19,18],[19,19],[19,20],[19,21],[19,22],
      [20,16],[20,20],[20,22],[21,16],[21,17],[21,18],[21,19],[21,20],[21,21],
      [21,22]]
      contents.set_pixel(x + pos[0], y + pos[1], cb)
    end
  end
  #--------------------------------------------------------------------------
  # ◎ Item name display
  #     enabled : Valid flag. If false, it's rendered transparent
  #--------------------------------------------------------------------------
  alias _old001_draw_item_name draw_item_name
  def draw_item_name(item, x, y, enabled = true, width = 172)
    return unless item
    _old001_draw_item_name(item, x, y, enabled, width)
    draw_new_icon(x, y, enabled) if $game_party.newitem?(item)
  end
end