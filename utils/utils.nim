import imguin/[cimgui]
import ../utils/themes/[themeMicrosoft]

#---------------
#--- setTooltip
#---------------
proc setTooltip*(str:string, delay=Imgui_HoveredFlags_DelayNormal.ImguiHoveredFlags, color=ImVec4(x: 1.0, y: 1.0, z: 1.0, w: 1.0)) =
  if igIsItemHovered(delay):
    if igBeginTooltip():
      igPushStyleColorVec4(ImGuiCol_Text.cint, color)
      igText(str)
      igPopStyleColor(1)
      igEndTooltip()

type
  Theme* = enum
    light, dark, classic ,microsoft

# Forward definition
#----------
# setTheme
#----------
proc setTheme*(themeName: Theme) =
  case themeName
  of light:
    igStyleColorsLight(nil)
  of dark:
    igStyleColorsDark(nil)
  of classic:
    igStyleColorsClassic(nil)
  of microsoft:
    themeMicrosoft()
