import imguin/[cimgui]
import ../utils/themes/[themeMicrosoft]

#---------------
#--- setTooltip
#---------------
proc setTooltip*(str:string, delay=Imgui_HoveredFlags_DelayNormal.ImguiHoveredFlags) =
  if igIsItemHovered(delay):
    if igBeginTooltip():
      igText(str)
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
