import imguin/[cimgui]

#---------------
#--- setTooltip
#---------------
proc setTooltip*(str:string, delay=Imgui_HoveredFlags_DelayNormal.ImguiHoveredFlags) =
  if igIsItemHovered(delay):
    if igBeginTooltip():
      igText(str)
      igEndTooltip()
