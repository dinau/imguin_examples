import imguin/[cimgui, simple]
import ../utils/vecs

var showKnobsWindow = true

proc demoKnobs*(val1, val2, val3, val4: var cfloat, val5: var cint, val6: var cfloat) =
  #-----------------------
  # Show ImGui-Knobs demo
  #-----------------------

  if showKnobsWindow:
    igBegin("ImGui-knobs / CImGui-Knobs Demo", addr showKnobsWindow, 0)
    defer: igEnd()

    if IgKnobEx("Gain", addr val1, 0.0, 1.0, 0.01, "%.1fdB", IgKnobVariant_Tick.IgKnobVariant
      , 0 # size
      , cast[IgKnobFlags](0)
      , 10 # steps
      , -1 # angle_min
      , -1 # angle_max
    ):
      # value was changed
      discard

    igSameLine(0, -1.0)
    if IgKnobEx("Mix", addr val2, 0.0, 1.0, 0.01, "%.1f", IgKnobVariant_Stepped.IgKnobVariant
      , 0 # size
      , cast[IgKnobFlags](0)
      , 10 # steps
      , -1 # angle_min
      , -1 # angle_max
    ):
      #value was changed
      discard
    # Double click to reset
    if igIsItemActive() and igIsMouseDoubleClicked_Nil(0):
      val2 = 0

    igSameLine(0, -1.0)

    # Custom colors
    igPushStyleColor_Vec4(ImGuiCol_ButtonActive.cint, vec4(255, 0, 0, 0.7))
    igPushStyleColor_Vec4(ImGuiCol_ButtonHovered.cint, vec4(255, 0, 0, 1))
    igPushStyleColor_Vec4(ImGuiCol_Button.cint, vec4(0, 255, 0, 1))
    #// Push/PopStyleColor() for each colors used (namely ImGuiCol_ButtonActive and ImGuiCol_ButtonHovered for primary and ImGuiCol_Framebg for Track)
    if IgKnobEx("Pitch", addr val3, 0.0, 1.0, 0.01, "%.1f", IgKnobVariant_WiperOnly.IgKnobVariant
      , 0 # size
      , cast[IgKnobFlags](0)
      , 10 # steps
      , -1 # angle_min
      , -1 # angle_max
    ):
      # value was changed
      discard

    igPopStyleColor(3)
    igSameLine(0, -1.0)

    # Custom min/max angle
    if IgKnobEx("Dry", addr val4, 0.0, 1.0, 0.01, "%.1f", IgKnobVariant_Stepped.IgKnobVariant
      , 0 # Size
      , cast[IgKnobFlags](0)
      , 10 # steps
      , 1.570796 # angle_min
      , 3.141592 # angle_max
    ):
      # value was changed
      discard
    igSameLine(0, -1.0)

    # Int value
    if IgKnobInt("Wet", addr val5, 1, 10, 0.1, "%i", IgKnobVariant_Stepped.IgKnobVariant
      , 0 # size
      , cast[IgKnobFlags](0)
      , 10 # steps
      , -1 # angel_min
      , -1 # angel_max
      ):
    #value was changed
      discard
    igSameLine(0, -1.0)

    # Vertical drag only
    if IgKnobEx("Vertical", addr val6, 0.0, 10, 0.1, "%.1f", IgKnobVariant_Space.IgKnobVariant
      , 0
      , IgKnobFlags_DragVertical.IgKnobFlags
      , 10 # steps
      , -1 # angel_min
      , -1 # angel_max
      ):
    #value was changed
      discard
