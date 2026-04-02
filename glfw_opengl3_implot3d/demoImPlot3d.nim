import std/math
import imguin/[cimgui]
import ../utils/[vecs,fonticon/IconsFontAwesome6]
import ./implot3dFuncs

#----------------------
# ImPlot3D demo window
#----------------------
proc demoImPlot3D*() =
  igSetNextWindowPos(vec2(880, 260), ImGui_Cond_FirstUseEver.cint, vec2(0, 0))
  igSetNextWindowSize(vec2(460,750), ImGui_Cond_once.cint)
  block:
    igBegin("ImPlot3D demo surface " & ICON_FA_CUBES, nil, 0)
    defer: igEnd()

    const N = 20
    var xs {.global.}: array[N * N, cfloat]
    var ys {.global.}: array[N * N, cfloat]
    var zs {.global.}: array[N * N, cfloat]
    var t {.global.}: cfloat = 0.0

    var selectedFill {.global.}: cint = 1
    var selColormap {.global.}: cint = 5
    var solidColor {.global.} = [0.8.cfloat, 0.8, 0.2, 0.6]
    var colormaps {.global.} = [
      "Viridis".cstring, "Plasma", "Hot", "Cool", "Pink",
      "Jet", "Twilight", "RdBu", "BrBG", "PiYG", "Spectral", "Greys"]
    var customRange {.global.} = false
    var rangeMin {.global.}: cfloat = -1.0
    var rangeMax {.global.}: cfloat = 1.0

    t += igGetIO_Nil().DeltaTime

    # Define the range for X and Y
    const minVal: cfloat = -1.0
    const maxVal: cfloat = 1.0
    let step = (maxVal - minVal) / (N - 1).cfloat

    # Populate xs, ys, zs arrays
    for i in 0..<N:
      for j in 0..<N:
        let idx = i * N + j
        xs[idx] = minVal + j.cfloat * step
        ys[idx] = minVal + i.cfloat * step
        zs[idx] = sin(2.0 * t + sqrt(xs[idx] * xs[idx] + ys[idx] * ys[idx]))

    # Choose fill color
    igText("Fill color")
    igIndent(0.0)
    igRadioButton_IntPtr("Solid", addr selectedFill, 0)
    if selectedFill == 0:
      igSameLine(0, 0)
      igColorEdit4("##SurfaceSolidColor", solidColor, 0.ImGuiColorEditFlags)
    igRadioButton_IntPtr("Colormap", addr selectedFill, 1)
    if selectedFill == 1:
      igSameLine(0, 0)
      igCombo_Str_arr("##SurfaceColormap", addr selColormap, cast[ptr UncheckedArray[cstring]](addr colormaps), colormaps.len.cint, 0)
    igUnindent(0.0)

    # Choose range
    igCheckbox("Custom range", addr customRange)
    igIndent(0.0)
    if not customRange:
      igBeginDisabled(true)
    igSliderFloat("Range min", addr rangeMin, -1.0, rangeMax - 0.01, "%.3f", 0.ImGuiSliderFlags)
    igSliderFloat("Range max", addr rangeMax, rangeMin + 0.01, 1.0, "%.3f", 0.ImGuiSliderFlags)
    if not customRange:
      igEndDisabled()
    igUnindent(0.0)

    # Begin the plot
    if selectedFill == 1:
      imPlot3D_PushColormap(colormaps[selColormap])
    if imPlot3D_BeginPlot("Surface Plots", vec2(-1, 400), NoClip):
      imPlot3D_SetupAxesLimits(-1, 1, -1, 1, -1.5, 1.5, Once)
      imPlot3D_PushStyleVar(FillAlpha, 0.8)
      const IMPLOT3D_AUTO = -1.cfloat
      if selectedFill == 0:
        imPlot3D_SetNextFillStyle(vec4(solidColor[0], solidColor[1], solidColor[2], solidColor[3]), IMPLOT3D_AUTO)
      var vec4var:ImVec4
      imPlot3D_GetColormapColorNonUDT(addr vec4var, 1)
      imPlot3D_SetNextLineStyle(vec4var)

      # Plot the surface
      if customRange:
        imPlot3D_PlotSurface("Wave Surface", addr xs[0], addr ys[0], addr zs[0], N, N, rangeMin, rangeMax)
      else:
        imPlot3D_PlotSurface("Wave Surface", addr xs[0], addr ys[0], addr zs[0], N, N)

      imPlot3D_PopStyleVar(1)
      imPlot3D_EndPlot()

    if selectedFill == 1:
      imPlot3D_PopColormap(1)
