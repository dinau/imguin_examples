import ../utils/[appImGui]


#---------------------
# imgui_toggle_simple
#---------------------
proc imgui_toggle_simple*() =
  var value_index = 0
  var values{.global.} = [ true, true, true, true, true, true, true, true ]

  let green        = vec4(0.16f, 0.66f, 0.45f, 1.0f)
  let green_hover  = vec4(0.0f, 1.0f, 0.57f, 1.0f)
  let green_shadow = vec4(0.0f, 1.0f, 0.0f, 0.4f)

  #let sz = vec2(40.0, 20.0)
  let sz = vec2(0.0, 0.0)
  # a default and default animated toggle
  Toggle("Default Toggle", addr values[value_index], sz)
  inc value_index
  ToggleAnim("Animated Toggle", addr values[value_index], ImGuiToggleFlags_Animated.cint, 1.0f,  sz)
  inc value_index

  # this toggle draws a simple border around it's frame and knob
  ToggleAnim("Bordered Knob", addr values[value_index], ImGuiToggleFlags_Bordered.cint, 1.0f, sz)
  inc value_index

  # this toggle draws a simple shadow around it's frame and knob
  igPushStyleColor(ImGuiCol_BorderShadow.ImGuiCol, green_shadow)
  ToggleAnim("Shadowed Knob", addr values[value_index], ImGuiToggleFlags_Shadowed.cint, 1.0f, sz)
  inc value_index

  # this toggle draws the shadow addr  and the border around it's frame and knob.
  ToggleAnim("Bordered + Shadowed Knob", addr values[value_index], ImGuiToggleFlags_Bordered.cint or ImGuiToggleFlags_Shadowed.cint, 1.0f, sz)
  inc value_index
  igPopStyleColor(1)

  # this toggle uses stack-pushed style colors to change the way it displays
  igPushStyleColor(ImGuiCol_Button.cint, green)
  igPushStyleColor(ImGuiCol_ButtonHovered.cint, green_hover)
  Toggle("Green Toggle", addr values[value_index], sz)
  inc value_index
  igPopStyleColor(2)

  ToggleFlag("Toggle with A11y Labels", addr values[value_index], ImGuiToggleFlags_A11y.cint, sz)
  inc value_index

  # this toggle shows no label
  Toggle("##Toggle With Hidden Label", addr values[value_index], sz)
  inc value_index

#--------------------
# imgui_toggle_state
#--------------------
proc imgui_toggle_state*(config: ImGuiToggleConfig , state: var ImGuiToggleStateConfig ) =
  # some values to use for slider limits
  const border_thickness_max_pixels = 50.0.cfloat
  let max_height = if config.Size.y > 0 : config.Size.y else: igGetFrameHeight()
  let half_max_height = max_height * 0.5

  # knob offset controls how far into or out of the frame the knob should draw.
  var ary2 = [state.KnobOffset.x, state.KnobOffset.y]
  igSliderFloat2("Knob Offset (px: x, y)", ary2 , -half_max_height, half_max_height, "%.3f", 0)
  state.KnobOffset.x = ary2[0]
  state.KnobOffset.y = ary2[1]

  # knob inset controls how many pixels the knob is set into the frame. negative values will cause it to grow outside the frame.
  # for circular knobs, we will just use a single value, while for we will use top/left/bottom/right offsets.
  let is_rounded = config.KnobRounding >= 1.0.cfloat
  if is_rounded:
    let inset_average = ImOffsetRect_GetAverage(addr state.KnobInset)
    igSliderFloat("Knob Inset (px)", addr inset_average, -half_max_height, half_max_height, "%.3f", 0)
    state.KnobInset.anon0.anon0.Top    = inset_average
    state.KnobInset.anon0.anon0.Left   = inset_average
    state.KnobInset.anon0.anon0.Right  = inset_average
    state.KnobInset.anon0.anon0.Bottom = inset_average
  else:
    igSliderFloat4("Knob Inset (px: t, l, b, r)", state.KnobInset.anon0.Offsets, -half_max_height, half_max_height, "%.3f", 0)

  # how thick should the frame border be (if enabled)
  igSliderFloat("Frame Border Thickness (px)", addr state.FrameBorderThickness, 0.0.cfloat, border_thickness_max_pixels, "%.3f", 0)

  # how thick should the knob border be (if enabled)
  igSliderFloat("Knob Border Thickness (px)", addr state.KnobBorderThickness, 0.0.cfloat, border_thickness_max_pixels, "%.3f", 0)

#---------------------
# imgui_toggle_custom
#---------------------
proc imgui_toggle_custom() =
  var toggle_custom{.global.} = true
  var config{.global.}: ImGuiToggleConfig
  var fInitReq{.global.} = true

  if(fInitReq):
    fInitReq = false
    ImGuiToggleConfig_init(addr config)

  igNewLine()
  ToggleCfg("Customized Toggle", addr toggle_custom, config)

  igNewLine()

  # these first settings are used no matter the toggle's state.
  igText("Persistent Toggle Settings")

  # animation duration controls how long the toggle animates, in seconds. if set to 0, animation is disabled.
  if igSliderFloat("Animation Duration (seconds)", addr config.AnimationDuration, ImGuiToggleConstants_AnimationDurationMinimum, 2.0f, "%.3f", 0):
    # if the user adjusted the animation duration slider, go ahead and turn on the animation flags.
    config.Flags = config.Flags or ImGui_ToggleFlags_Animated.cint

  # frame rounding sets how round the frame is when drawn, where 0 is a rectangle, and 1 is a circle.
  igSliderFloat("Frame Rounding (scale)", addr config.FrameRounding, ImGuiToggleConstants_FrameRoundingMinimum, ImGuiToggleConstants_FrameRoundingMaximum, "%.3f", 0)

  # knob rounding sets how round the knob is when drawn, where 0 is a rectangle, and 1 is a circle.
  igSliderFloat("Knob Rounding (scale)", addr config.KnobRounding, ImGuiToggleConstants_KnobRoundingMinimum, ImGuiToggleConstants_KnobRoundingMaximum, "%.3f", 0)

  # size controls the width and the height of the toggle frame
  #igSliderFloat2(const char* label, float v[2]    ,float v_min, float v_max,const char* format,ImGuiSliderFlags flags)
  var ary2 = [config.Size.x, config.Size.y]
  igSliderFloat2("Size (px: w, h)", ary2, 0.0f, 200.0f, "%.0f",0)
  config.Size.x = ary2[0]
  config.Size.y = ary2[1]

  # width ratio sets how wide the toggle is with relation to the frame height. if Size is non-zero, this is unused.
  igSliderFloat("Width Ratio (scale)", addr config.WidthRatio, ImGuiToggleConstants_WidthRatioMinimum, ImGuiToggleConstants_WidthRatioMaximum, "%.3f", 0)

  # a11y style sets the type of additional on/off indicator drawing
  if igCombo_Str("A11y Style", addr config.A11yStyle,
    "Label\0" &
    "Glyph\0" &
    "Dot\0"   &
    "\0", -1):
    # if the user adjusted the a11y style combo, go ahead and turn on the a11y flag.
    config.Flags = config.Flags or ImGui_ToggleFlags_A11y.cint

  # some tabs to adjust the "state" settings of the toggle (configuration dependent on if the toggle is on or off.)
  if igBeginTabBar("State", 0):
    defer: igEndTabBar()
    if igBeginTabItem("\"Off State\" Settings", nil, 0):
      imgui_toggle_state(config, config.Off)
      igEndTabItem()

    if igBeginTabItem("\"On State\"Settings", nil, 0):
      imgui_toggle_state(config, config.On)
      igEndTabItem()

  igSeparator()

  # flags for various toggle features
  igText("Flags")
  igColumns(2, nil, true)
  igText("Meta Flags")
  igNextColumn()
  igText("Individual Flags")
  igSeparator()
  igNextColumn()

  # should the toggle have borders (sets all border flags)
  igCheckboxFlags_IntPtr("Bordered", addr config.Flags, ImGui_ToggleFlags_Bordered.cint)

  # should the toggle have shadows (sets all shadow flags)
  igCheckboxFlags_IntPtr("Shadowed", addr config.Flags, ImGui_ToggleFlags_Shadowed.cint)

  igNextColumn()

  # should the toggle animate
  igCheckboxFlags_IntPtr("Animated", addr config.Flags, ImGuiToggleFlags_Animated.cint)

  # should the toggle have a bordered frame
  igCheckboxFlags_IntPtr("BorderedFrame", addr config.Flags, ImGuiToggleFlags_BorderedFrame.cint)

  # should the toggle have a bordered knob
  igCheckboxFlags_IntPtr("BorderedKnob", addr config.Flags, ImGuiToggleFlags_BorderedKnob.cint)

  # should the toggle have a shadowed frame
  igCheckboxFlags_IntPtr("ShadowedFrame", addr config.Flags, ImGuiToggleFlags_ShadowedFrame.cint)

  # should the toggle have a shadowed knob
  igCheckboxFlags_IntPtr("ShadowedKnob", addr config.Flags, ImGuiToggleFlags_ShadowedKnob.cint)

  # should the toggle draw a11y glyphs
  igCheckboxFlags_IntPtr("A11y", addr config.Flags, ImGuiToggleFlags_A11y.cint)
  igColumns(2, nil, true)

  igSeparator()

  # what follows are some configuration presets. check the source of those functions to see how they work.
  igText("Configuration Style Presets")
  let bsz = vec2(0,0)
  if igButton("Reset to Default", bsz):
    config = ImGuiTogglePresets_DefaultStyle()
  igSameLine(0.0f, -1.0f)

  if igButton("Rectangle", bsz):
    config = ImGuiTogglePresets_RectangleStyle()
  igSameLine(0.0f, -1.0f)

  if igButton("Glowing", bsz):
    config = ImGuiTogglePresets_GlowingStyle()
  igSameLine(0.0f, -1.0f)

  if igButton("iOS", bsz):
    config = ImGuiTogglePresets_iOSStyle(1.0f, false)
  igSameLine(0.0f, -1.0f)

  if igButton("Material", bsz):
    config = ImGuiTogglePresets_MaterialStyle(1.0)
  igSameLine(0.0f, -1.0f)

  if igButton("Minecraft", bsz):
    config = ImGuiTogglePresets_MinecraftStyle(1.0)

#----------------------
# imgui_toggle_example
#----------------------
proc imgui_toggle_example*() =
  # use some lovely gray backgrounds for "off" toggles
  # the default would otherwise use your theme's frame background colors.
  let colbg = vec4(0.45f, 0.45f, 0.45f, 1.0f)
  igPushStyleColor(ImGuiCol_FrameBg.cint, colbg)
  let colHovered = vec4(0.65f, 0.65f, 0.65f, 1.0f)
  igPushStyleColor(ImGuiCol_FrameBgHovered.cint, colHovered)

  # a toggle that will allow the user to view the demo for simple toggles or a custom toggle
  var show_custom_toggle{.global.} = false
  let sz = vec2(40.0f, 20.0f)
  Toggle( if show_custom_toggle: "Showing Custom Toggle".cstring else: "Showing Simple Toggles".cstring , addr show_custom_toggle, sz)
  igSeparator()

  if show_custom_toggle:
    imgui_toggle_custom()
  else:
    imgui_toggle_simple()
  # pop the color styles
  igPopStyleColor(2)
