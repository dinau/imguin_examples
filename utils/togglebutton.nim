import imguin/cimgui
import ../utils/vecs

#--------------------------------------------------------
# This is very simple toggle button implement from
#  https://github.com/sonoro1234/anima/blob/09901c69586bddd6d0463e8b7460eb251a1837e2/anima/igwidgets.lua#L6-L30
# Refer to
#  https://github.com/ocornut/imgui/issues/1537
#--------------------------------------------------------

# If you'd like to use customizable toggle button, refer to
# examples/glfw_opengl3_imgui_toggle

#----------
# IM_COL32
#----------
proc IM_COL32*(a,b,c,d:uint32): ImU32  =
  return igGetColorU32_Vec4(vec4(a.cfloat/255,b.cfloat/255,c.cfloat/255,d.cfloat/255))

#----------------
# igToggleButton
#----------------
proc igToggleButton*(str_id:string, v: var bool): bool =
  var pos: ImVec2
  igGetCursorScreenPos(addr pos)
  let draw_list = igGetWindowDrawList()
  let height = igGetFrameHeight()
  let width = height * 1.55
  let radius = height * 0.50

  var ret = false
  if igInvisibleButton(str_id.cstring, vec2(width, height), 0.ImGuiButtonFlags):
    v = not v
    ret = true
  var col_bg, col_base: ImU32
  if igIsItemHovered(0.ImGuiHoveredFlags):
    col_base = IM_COL32(218-20, 218-20, 218-20, 255)
    col_bg = col_base
    if v:
      col_bg = col_base or igGetColorU32_U32(ImGuiCol_ButtonHovered.ImU32, 1)
  else:
    col_base = IM_COL32(218, 218, 218, 255)
    col_bg = col_base
    if v:
      col_bg = col_base or igGetColorU32_U32(ImGuiCol_Button.ImU32, 1)

  draw_list.ImDrawList_AddRectFilled(pos, vec2(pos.x + width, pos.y + height), col_bg, height * 0.5, 0.ImDrawFlags)
  var m:cfloat
  if v:
    m = pos.x + width - radius
  else:
    m = pos.x + radius
  draw_list.ImDrawList_AddCircleFilled(vec2(m , pos.y + radius) ,radius - 1.5 ,IM_COL32(255, 255, 255, 255) ,0)
  igSameLine(0.0, -1.0)
  igText(str_id)
  return ret
