import imguin/[cimgui, simple]
import ../fonticon/IconsFontAwesome6

#--------------
#--- zoomGlass
#--------------
proc zoomGlass*(textureID: ImTextureID, itemWidth, itemHeight:int, itemPosTop:ImVec2) =
  # itemPosTop : absolute position in main window.
  if igBeginItemTooltip():
    defer: igEndTooltip()
    let my_tex_w = itemWidth.float
    let my_tex_h = itemHeight.float
    let pio = igGetIO()
    let region_sz = 32.0f
    var region_x = pio.MousePos.x - itemPosTop.x - region_sz * 0.5f
    var region_y = pio.MousePos.y - itemPosTop.y - region_sz * 0.5f
    let zoom = 4.0f
    if region_x < 0.0f:
      region_x = 0.0f
    elif region_x > (my_tex_w - region_sz):
      region_x = my_tex_w - region_sz
    if region_y < 0.0f:
      region_y = 0.0f
    elif region_y > my_tex_h - region_sz:
      region_y = my_tex_h - region_sz
    let uv0 = ImVec2(x: (region_x) / my_tex_w, y: (region_y) / my_tex_h)
    let uv1 = ImVec2(x: (region_x + region_sz) / my_tex_w, y: (region_y + region_sz) / my_tex_h)
    let tint_col =  ImVec4(x: 1.0f, y: 1.0f, z: 1.0f, w: 1.0f) #// No tint
    let border_col = ImVec4(x: 0.22f, y: 0.56f, z: 0.22f, w: 1.0f) # Green
    igText(ICON_FA_MAGNIFYING_GLASS & " 4 x")
    igImage(ImTextureRef(internal_TexData: nil, internal_TexID: textureID), ImVec2(x: region_sz * zoom, y: region_sz * zoom), uv0, uv1) #, tint_col, border_col)
