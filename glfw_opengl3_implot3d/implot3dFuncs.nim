import imguin/cimgui

import ./implotFuncs
export implotFuncs


# Enums
type
  ImAxis3D* {.pure, size: int32.sizeof.} = enum
    X = 0
    Y = 1
    Z = 2
    COUNT = 3
  ImPlane3D* {.pure, size: int32.sizeof.} = enum
    YZ = 0
    XZ = 1
    XY = 2
    COUNT = 3
  ImPlot3DAxisFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLabel = 1
    NoGridLines = 2
    NoTickMarks = 4
    NoTickLabels = 8
    NoDecorations = 11
    LockMin = 16
    LockMax = 32
    Lock = 48
    AutoFit = 64
    Invert = 128
  ImPlot3DCol* {.pure, size: int32.sizeof.} = enum
    Line = 0
    Fill = 1
    MarkerOutline = 2
    MarkerFill = 3
    TitleText = 4
    InlayText = 5
    FrameBg = 6
    PlotBg = 7
    PlotBorder = 8
    LegendBg = 9
    LegendBorder = 10
    LegendText = 11
    AxisText = 12
    AxisGrid = 13
    AxisTick = 14
    COUNT = 15
  ImPlot3DColormap* {.pure, size: int32.sizeof.} = enum
    Deep = 0
    Dark = 1
    Pastel = 2
    Paired = 3
    Viridis = 4
    Plasma = 5
    Hot = 6
    Cool = 7
    Pink = 8
    Jet = 9
    Twilight = 10
    RdBu = 11
    BrBG = 12
    PiYG = 13
    Spectral = 14
    Greys = 15
  ImPlot3DCond* {.pure, size: int32.sizeof.} = enum
    None = 0
    Always = 1
    Once = 2
  ImPlot3DFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoTitle = 1
    NoLegend = 2
    NoMouseText = 4
    CanvasOnly = 7
    NoClip = 8
    NoMenus = 16
  ImPlot3DItemFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2
  ImPlot3DLegendFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoButtons = 1
    NoHighlightItem = 2
    Horizontal = 4
  ImPlot3DLineFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2
    Segments = 1024
    Loop = 2048
    SkipNaN = 4096
  ImPlot3DLocation* {.pure, size: int32.sizeof.} = enum
    Center = 0
    North = 1
    South = 2
    West = 4
    NorthWest = 5
    SouthWest = 6
    East = 8
    NorthEast = 9
    SouthEast = 10
  ImPlot3DMarker* {.pure, size: int32.sizeof.} = enum
    None = -1
    Circle = 0
    Square = 1
    Diamond = 2
    Up = 3
    Down = 4
    Left = 5
    Right = 6
    Cross = 7
    Plus = 8
    Asterisk = 9
    COUNT = 10
  ImPlot3DMeshFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2
  ImPlot3DQuadFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2
  ImPlot3DScatterFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2
  ImPlot3DStyleVar* {.pure, size: int32.sizeof.} = enum
    LineWeight = 0
    Marker = 1
    MarkerSize = 2
    MarkerWeight = 3
    FillAlpha = 4
    PlotDefaultSize = 5
    PlotMinSize = 6
    PlotPadding = 7
    LabelPadding = 8
    LegendPadding = 9
    LegendInnerPadding = 10
    LegendSpacing = 11
    COUNT = 12
  ImPlot3DSurfaceFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2
  ImPlot3DTriangleFlags* {.pure, size: int32.sizeof.} = enum
    None = 0
    NoLegend = 1
    NoFit = 2

# TypeDefs
type
  ImPlot3DFormatter* = proc(value: float32, buff: cstring, size: int, user_data: pointer): int {.cdecl, varargs.}

  ImPlot3DBox* {.importc: "ImPlot3DBox".} = object
    min* {.importc: "Min".}: ImPlot3DPoint
    max* {.importc: "Max".}: ImPlot3DPoint
  ImPlot3DPlane* {.importc: "ImPlot3DPlane".} = object
    point* {.importc: "Point".}: ImPlot3DPoint
    normal* {.importc: "Normal".}: ImPlot3DPoint
  ImPlot3DPoint* {.importc: "ImPlot3DPoint".} = object
    x* {.importc: "x".}: float32
    y* {.importc: "y".}: float32
    z* {.importc: "z".}: float32
  ImPlot3DQuat* {.importc: "ImPlot3DQuat".} = object
    x* {.importc: "x".}: float32
    y* {.importc: "y".}: float32
    z* {.importc: "z".}: float32
    w* {.importc: "w".}: float32
  ImPlot3DRange* {.importc: "ImPlot3DRange".} = object
    min* {.importc: "Min".}: float32
    max* {.importc: "Max".}: float32
  ImPlot3DRay* {.importc: "ImPlot3DRay".} = object
    origin* {.importc: "Origin".}: ImPlot3DPoint
    direction* {.importc: "Direction".}: ImPlot3DPoint
  ImPlot3DStyle* {.importc: "ImPlot3DStyle".} = object
    lineWeight* {.importc: "LineWeight".}: float32
    marker* {.importc: "Marker".}: int
    markerSize* {.importc: "MarkerSize".}: float32
    markerWeight* {.importc: "MarkerWeight".}: float32
    fillAlpha* {.importc: "FillAlpha".}: float32
    plotDefaultSize* {.importc: "PlotDefaultSize".}: ImVec2
    plotMinSize* {.importc: "PlotMinSize".}: ImVec2
    plotPadding* {.importc: "PlotPadding".}: ImVec2
    labelPadding* {.importc: "LabelPadding".}: ImVec2
    legendPadding* {.importc: "LegendPadding".}: ImVec2
    legendInnerPadding* {.importc: "LegendInnerPadding".}: ImVec2
    legendSpacing* {.importc: "LegendSpacing".}: ImVec2
    colors* {.importc: "Colors".}: array[15, ImVec4]
    colormap* {.importc: "Colormap".}: ImPlot3DColormap

# Procs

type
  ImPlotPointGetter* = proc (data: pointer; idx: cint; point: ptr ImPlotPoint): pointer {.cdecl.}

proc clipLineSegment*(self: ptr ImPlot3DBox, p0: ImPlot3DPoint, p1: ImPlot3DPoint, p0_clipped: ptr ImPlot3DPoint, p1_clipped: ptr ImPlot3DPoint): bool {.importc: "ImPlot3DBox_ClipLineSegment".}
proc contains*(self: ptr ImPlot3DBox, point: ImPlot3DPoint): bool {.importc: "ImPlot3DBox_Contains".}
proc expand*(self: ptr ImPlot3DBox, point: ImPlot3DPoint): void {.importc: "ImPlot3DBox_Expand".}
proc newImPlot3DBox*(): void {.importc: "ImPlot3DBox_ImPlot3DBox_Nil".}
proc newImPlot3DBox*(min: ImPlot3DPoint, max: ImPlot3DPoint): void {.importc: "ImPlot3DBox_ImPlot3DBox_Plot3DPoInt".}
proc destroy*(self: ptr ImPlot3DBox): void {.importc: "ImPlot3DBox_destroy".}
proc crossNonUDT*(pOut: ptr ImPlot3DPoint, self: ptr ImPlot3DPoint, rhs: ImPlot3DPoint): void {.importc: "ImPlot3DPoint_Cross".}
proc dot*(self: ptr ImPlot3DPoint, rhs: ImPlot3DPoint): float32 {.importc: "ImPlot3DPoint_Dot".}
proc newImPlot3DPoint*(): void {.importc: "ImPlot3DPoint_ImPlot3DPoint_Nil".}
proc newImPlot3DPoint*(x: float32, y: float32, z: float32): void {.importc: "ImPlot3DPoint_ImPlot3DPoint_Float".}
proc isNaN*(self: ptr ImPlot3DPoint): bool {.importc: "ImPlot3DPoint_IsNaN".}
proc length*(self: ptr ImPlot3DPoint): float32 {.importc: "ImPlot3DPoint_Length".}
proc lengthSquared*(self: ptr ImPlot3DPoint): float32 {.importc: "ImPlot3DPoint_LengthSquared".}
proc normalize*(self: ptr ImPlot3DPoint): void {.importc: "ImPlot3DPoint_Normalize".}
proc normalizedNonUDT*(pOut: ptr ImPlot3DPoint, self: ptr ImPlot3DPoint): void {.importc: "ImPlot3DPoint_Normalized".}
proc destroy*(self: ptr ImPlot3DPoint): void {.importc: "ImPlot3DPoint_destroy".}
proc conjugateNonUDT*(pOut: ptr ImPlot3DQuat, self: ptr ImPlot3DQuat): void {.importc: "ImPlot3DQuat_Conjugate".}
proc dot*(self: ptr ImPlot3DQuat, rhs: ImPlot3DQuat): float32 {.importc: "ImPlot3DQuat_Dot".}
proc fromTwoVectorsNonUDT*(pOut: ptr ImPlot3DQuat, v0: ImPlot3DPoint, v1: ImPlot3DPoint): void {.importc: "ImPlot3DQuat_FromTwoVectors".}
proc newImPlot3DQuat*(): void {.importc: "ImPlot3DQuat_ImPlot3DQuat_Nil".}
proc newImPlot3DQuat*(x: float32, y: float32, z: float32, w: float32): void {.importc: "ImPlot3DQuat_ImPlot3DQuat_FloatFloat".}
proc newImPlot3DQuat*(angle: float32, axis: ImPlot3DPoint): void {.importc: "ImPlot3DQuat_ImPlot3DQuat_FloatPlot3DPoInt".}
proc inverseNonUDT*(pOut: ptr ImPlot3DQuat, self: ptr ImPlot3DQuat): void {.importc: "ImPlot3DQuat_Inverse".}
proc length*(self: ptr ImPlot3DQuat): float32 {.importc: "ImPlot3DQuat_Length".}
proc normalize*(self: ptr ImPlot3DQuat): ptr ImPlot3DQuat {.importc: "ImPlot3DQuat_Normalize".}
proc normalizedNonUDT*(pOut: ptr ImPlot3DQuat, self: ptr ImPlot3DQuat): void {.importc: "ImPlot3DQuat_Normalized".}
proc slerpNonUDT*(pOut: ptr ImPlot3DQuat, q1: ImPlot3DQuat, q2: ImPlot3DQuat, t: float32): void {.importc: "ImPlot3DQuat_Slerp".}
proc destroy*(self: ptr ImPlot3DQuat): void {.importc: "ImPlot3DQuat_destroy".}
proc contains*(self: ptr ImPlot3DRange, value: float32): bool {.importc: "ImPlot3DRange_Contains".}
proc expand*(self: ptr ImPlot3DRange, value: float32): void {.importc: "ImPlot3DRange_Expand".}
proc newImPlot3DRange*(): void {.importc: "ImPlot3DRange_ImPlot3DRange_Nil".}
proc newImPlot3DRange*(min: float32, max: float32): void {.importc: "ImPlot3DRange_ImPlot3DRange_Float".}
proc size*(self: ptr ImPlot3DRange): float32 {.importc: "ImPlot3DRange_Size".}
proc destroy*(self: ptr ImPlot3DRange): void {.importc: "ImPlot3DRange_destroy".}
proc newImPlot3DStyle*(): void {.importc: "ImPlot3DStyle_ImPlot3DStyle".}
proc destroy*(self: ptr ImPlot3DStyle): void {.importc: "ImPlot3DStyle_destroy".}
proc imPlot3D_AddColormap*(name: cstring, cols: ptr ImVec4, size: int, qual: bool = true): ImPlot3DColormap {.importc: "ImPlot3D_AddColormap_Vec4Ptr".}
proc imPlot3D_AddColormap*(name: cstring, cols: ptr uint32, size: int, qual: bool = true): ImPlot3DColormap {.importc: "ImPlot3D_AddColormap_U32Ptr".}
proc imPlot3D_BeginPlot*(title_id: cstring, size: ImVec2 = ImVec2(x: -1, y: 0), flags: ImPlot3DFlags = 0.ImPlot3DFlags): bool {.importc: "ImPlot3D_BeginPlot".}
proc imPlot3D_CreateContext*(): ptr ImPlot3DContext {.importc: "ImPlot3D_CreateContext".}
proc imPlot3D_DestroyContext*(ctx: ptr ImPlot3DContext = nullptr): void {.importc: "ImPlot3D_DestroyContext".}
proc imPlot3D_EndPlot*(): void {.importc: "ImPlot3D_EndPlot".}
proc imPlot3D_GetColormapColorNonUDT*(pOut: ptr ImVec4, idx: int, cmap: ImPlot3DColormap = cast[ImPlot3DColormap](-1)): void {.importc: "ImPlot3D_GetColormapColor".}
proc imPlot3D_GetColormapCount*(): int {.importc: "ImPlot3D_GetColormapCount".}
proc imPlot3D_GetColormapIndex*(name: cstring): ImPlot3DColormap {.importc: "ImPlot3D_GetColormapIndex".}
proc imPlot3D_GetColormapName*(cmap: ImPlot3DColormap): cstring {.importc: "ImPlot3D_GetColormapName".}
proc imPlot3D_GetColormapSize*(cmap: ImPlot3DColormap = cast[ImPlot3DColormap](-1)): int {.importc: "ImPlot3D_GetColormapSize".}
proc imPlot3D_GetCurrentContext*(): ptr ImPlot3DContext {.importc: "ImPlot3D_GetCurrentContext".}
proc imPlot3D_GetPlotDrawList*(): ptr ImDrawList {.importc: "ImPlot3D_GetPlotDrawList".}
proc imPlot3D_GetPlotPosNonUDT*(pOut: ptr ImVec2): void {.importc: "ImPlot3D_GetPlotPos".}
proc imPlot3D_GetPlotSizeNonUDT*(pOut: ptr ImVec2): void {.importc: "ImPlot3D_GetPlotSize".}
proc imPlot3D_GetStyle*(): ptr ImPlot3DStyle {.importc: "ImPlot3D_GetStyle".}
proc imPlot3D_GetStyleColorU32*(idx: ImPlot3DCol): uint32 {.importc: "ImPlot3D_GetStyleColorU32".}
proc imPlot3D_GetStyleColorVec4NonUDT*(pOut: ptr ImVec4, idx: ImPlot3DCol): void {.importc: "ImPlot3D_GetStyleColorVec4".}
proc imPlot3D_NextColormapColorNonUDT*(pOut: ptr ImVec4): void {.importc: "ImPlot3D_NextColormapColor".}
proc imPlot3D_PixelsToPlotPlaneNonUDT*(pOut: ptr ImPlot3DPoint, pix: ImVec2, plane: ImPlane3D, mask: bool = true): void {.importc: "ImPlot3D_PixelsToPlotPlane_Vec2".}
proc imPlot3D_PixelsToPlotPlaneNonUDT2*(pOut: ptr ImPlot3DPoint, x: cdouble, y: cdouble, plane: ImPlane3D, mask: bool = true): void {.importc: "ImPlot3D_PixelsToPlotPlane_double".}
proc imPlot3D_PixelsToPlotRay*(pix: ImVec2): ImPlot3DRay {.importc: "ImPlot3D_PixelsToPlotRay_Vec2".}
proc imPlot3D_PixelsToPlotRay*(x: cdouble, y: cdouble): ImPlot3DRay {.importc: "ImPlot3D_PixelsToPlotRay_double".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr float32, ys: ptr float32, zs: ptr float32, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(float32).int32): void {.importc: "ImPlot3D_PlotLine_FloatPtr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr cdouble, ys: ptr cdouble, zs: ptr cdouble, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(cdouble).int32): void {.importc: "ImPlot3D_PlotLine_doublePtr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr int8, ys: ptr int8, zs: ptr int8, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(int8).int32): void {.importc: "ImPlot3D_PlotLine_S8Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr uint8, ys: ptr uint8, zs: ptr uint8, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(uint8).int32): void {.importc: "ImPlot3D_PlotLine_U8Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr int16, ys: ptr int16, zs: ptr int16, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(int16).int32): void {.importc: "ImPlot3D_PlotLine_S16Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr uint16, ys: ptr uint16, zs: ptr uint16, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(uint16).int32): void {.importc: "ImPlot3D_PlotLine_U16Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr int32, ys: ptr int32, zs: ptr int32, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(int32).int32): void {.importc: "ImPlot3D_PlotLine_S32Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr uint32, ys: ptr uint32, zs: ptr uint32, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(uint32).int32): void {.importc: "ImPlot3D_PlotLine_U32Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr int64, ys: ptr int64, zs: ptr int64, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(int64).int32): void {.importc: "ImPlot3D_PlotLine_S64Ptr".}
proc imPlot3D_PlotLine*(label_id: cstring, xs: ptr uint64, ys: ptr uint64, zs: ptr uint64, count: int, flags: ImPlot3DLineFlags = 0.ImPlot3DLineFlags, offset: int = 0, stride: int = sizeof(uint64).int32): void {.importc: "ImPlot3D_PlotLine_U64Ptr".}
proc imPlot3D_PlotMesh*(label_id: cstring, vtx: ptr ImPlot3DPoint, idx: ptr uint, vtx_count: int, idx_count: int, flags: ImPlot3DMeshFlags = 0.ImPlot3DMeshFlags): void {.importc: "ImPlot3D_PlotMesh".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr float32, ys: ptr float32, zs: ptr float32, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(float32).int32): void {.importc: "ImPlot3D_PlotQuad_FloatPtr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr cdouble, ys: ptr cdouble, zs: ptr cdouble, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(cdouble).int32): void {.importc: "ImPlot3D_PlotQuad_doublePtr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr int8, ys: ptr int8, zs: ptr int8, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(int8).int32): void {.importc: "ImPlot3D_PlotQuad_S8Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr uint8, ys: ptr uint8, zs: ptr uint8, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(uint8).int32): void {.importc: "ImPlot3D_PlotQuad_U8Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr int16, ys: ptr int16, zs: ptr int16, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(int16).int32): void {.importc: "ImPlot3D_PlotQuad_S16Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr uint16, ys: ptr uint16, zs: ptr uint16, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(uint16).int32): void {.importc: "ImPlot3D_PlotQuad_U16Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr int32, ys: ptr int32, zs: ptr int32, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(int32).int32): void {.importc: "ImPlot3D_PlotQuad_S32Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr uint32, ys: ptr uint32, zs: ptr uint32, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(uint32).int32): void {.importc: "ImPlot3D_PlotQuad_U32Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr int64, ys: ptr int64, zs: ptr int64, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(int64).int32): void {.importc: "ImPlot3D_PlotQuad_S64Ptr".}
proc imPlot3D_PlotQuad*(label_id: cstring, xs: ptr uint64, ys: ptr uint64, zs: ptr uint64, count: int, flags: ImPlot3DQuadFlags = 0.ImPlot3DQuadFlags, offset: int = 0, stride: int = sizeof(uint64).int32): void {.importc: "ImPlot3D_PlotQuad_U64Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr float32, ys: ptr float32, zs: ptr float32, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(float32).int32): void {.importc: "ImPlot3D_PlotScatter_FloatPtr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr cdouble, ys: ptr cdouble, zs: ptr cdouble, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(cdouble).int32): void {.importc: "ImPlot3D_PlotScatter_doublePtr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr int8, ys: ptr int8, zs: ptr int8, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(int8).int32): void {.importc: "ImPlot3D_PlotScatter_S8Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr uint8, ys: ptr uint8, zs: ptr uint8, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(uint8).int32): void {.importc: "ImPlot3D_PlotScatter_U8Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr int16, ys: ptr int16, zs: ptr int16, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(int16).int32): void {.importc: "ImPlot3D_PlotScatter_S16Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr uint16, ys: ptr uint16, zs: ptr uint16, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(uint16).int32): void {.importc: "ImPlot3D_PlotScatter_U16Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr int32, ys: ptr int32, zs: ptr int32, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(int32).int32): void {.importc: "ImPlot3D_PlotScatter_S32Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr uint32, ys: ptr uint32, zs: ptr uint32, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(uint32).int32): void {.importc: "ImPlot3D_PlotScatter_U32Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr int64, ys: ptr int64, zs: ptr int64, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(int64).int32): void {.importc: "ImPlot3D_PlotScatter_S64Ptr".}
proc imPlot3D_PlotScatter*(label_id: cstring, xs: ptr uint64, ys: ptr uint64, zs: ptr uint64, count: int, flags: ImPlot3DScatterFlags = 0.ImPlot3DScatterFlags, offset: int = 0, stride: int = sizeof(uint64).int32): void {.importc: "ImPlot3D_PlotScatter_U64Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr float32, ys: ptr float32, zs: ptr float32, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(float32).int32): void {.importc: "ImPlot3D_PlotSurface_FloatPtr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr cdouble, ys: ptr cdouble, zs: ptr cdouble, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(cdouble).int32): void {.importc: "ImPlot3D_PlotSurface_doublePtr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr int8, ys: ptr int8, zs: ptr int8, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(int8).int32): void {.importc: "ImPlot3D_PlotSurface_S8Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr uint8, ys: ptr uint8, zs: ptr uint8, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(uint8).int32): void {.importc: "ImPlot3D_PlotSurface_U8Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr int16, ys: ptr int16, zs: ptr int16, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(int16).int32): void {.importc: "ImPlot3D_PlotSurface_S16Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr uint16, ys: ptr uint16, zs: ptr uint16, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(uint16).int32): void {.importc: "ImPlot3D_PlotSurface_U16Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr int32, ys: ptr int32, zs: ptr int32, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(int32).int32): void {.importc: "ImPlot3D_PlotSurface_S32Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr uint32, ys: ptr uint32, zs: ptr uint32, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(uint32).int32): void {.importc: "ImPlot3D_PlotSurface_U32Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr int64, ys: ptr int64, zs: ptr int64, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(int64).int32): void {.importc: "ImPlot3D_PlotSurface_S64Ptr".}
proc imPlot3D_PlotSurface*(label_id: cstring, xs: ptr uint64, ys: ptr uint64, zs: ptr uint64, x_count: int, y_count: int, scale_min: cdouble = 0.0, scale_max: cdouble = 0.0, flags: ImPlot3DSurfaceFlags = 0.ImPlot3DSurfaceFlags, offset: int = 0, stride: int = sizeof(uint64).int32): void {.importc: "ImPlot3D_PlotSurface_U64Ptr".}
proc imPlot3D_PlotText*(text: cstring, x: float32, y: float32, z: float32, angle: float32 = 0.0f, pix_offset: ImVec2 = ImVec2(x: 0, y: 0)): void {.importc: "ImPlot3D_PlotText".}
proc imPlot3D_PlotToPixelsNonUDT*(pOut: ptr ImVec2, point: ImPlot3DPoint): void {.importc: "ImPlot3D_PlotToPixels_Plot3DPoInt".}
proc imPlot3D_PlotToPixelsNonUDT2*(pOut: ptr ImVec2, x: cdouble, y: cdouble, z: cdouble): void {.importc: "ImPlot3D_PlotToPixels_double".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr float32, ys: ptr float32, zs: ptr float32, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(float32).int32): void {.importc: "ImPlot3D_PlotTriangle_FloatPtr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr cdouble, ys: ptr cdouble, zs: ptr cdouble, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(cdouble).int32): void {.importc: "ImPlot3D_PlotTriangle_doublePtr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr int8, ys: ptr int8, zs: ptr int8, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(int8).int32): void {.importc: "ImPlot3D_PlotTriangle_S8Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr uint8, ys: ptr uint8, zs: ptr uint8, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(uint8).int32): void {.importc: "ImPlot3D_PlotTriangle_U8Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr int16, ys: ptr int16, zs: ptr int16, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(int16).int32): void {.importc: "ImPlot3D_PlotTriangle_S16Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr uint16, ys: ptr uint16, zs: ptr uint16, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(uint16).int32): void {.importc: "ImPlot3D_PlotTriangle_U16Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr int32, ys: ptr int32, zs: ptr int32, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(int32).int32): void {.importc: "ImPlot3D_PlotTriangle_S32Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr uint32, ys: ptr uint32, zs: ptr uint32, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(uint32).int32): void {.importc: "ImPlot3D_PlotTriangle_U32Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr int64, ys: ptr int64, zs: ptr int64, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(int64).int32): void {.importc: "ImPlot3D_PlotTriangle_S64Ptr".}
proc imPlot3D_PlotTriangle*(label_id: cstring, xs: ptr uint64, ys: ptr uint64, zs: ptr uint64, count: int, flags: ImPlot3DTriangleFlags = 0.ImPlot3DTriangleFlags, offset: int = 0, stride: int = sizeof(uint64).int32): void {.importc: "ImPlot3D_PlotTriangle_U64Ptr".}
proc imPlot3D_PopColormap*(count: int = 1): void {.importc: "ImPlot3D_PopColormap".}
proc imPlot3D_PopStyleColor*(count: int = 1): void {.importc: "ImPlot3D_PopStyleColor".}
proc imPlot3D_PopStyleVar*(count: int = 1): void {.importc: "ImPlot3D_PopStyleVar".}
proc imPlot3D_PushColormap*(cmap: ImPlot3DColormap): void {.importc: "ImPlot3D_PushColormap_Plot3DColormap".}
proc imPlot3D_PushColormap*(name: cstring): void {.importc: "ImPlot3D_PushColormap_Str".}
proc imPlot3D_PushStyleColor*(idx: ImPlot3DCol, col: uint32): void {.importc: "ImPlot3D_PushStyleColor_U32".}
proc imPlot3D_PushStyleColor*(idx: ImPlot3DCol, col: ImVec4): void {.importc: "ImPlot3D_PushStyleColor_Vec4".}
proc imPlot3D_PushStyleVar*(idx: ImPlot3DStyleVar, val: float32): void {.importc: "ImPlot3D_PushStyleVar_Float".}
proc imPlot3D_PushStyleVar*(idx: ImPlot3DStyleVar, val: int): void {.importc: "ImPlot3D_PushStyleVar_Int".}
proc imPlot3D_PushStyleVar*(idx: ImPlot3DStyleVar, val: ImVec2): void {.importc: "ImPlot3D_PushStyleVar_Vec2".}
proc imPlot3D_SampleColormapNonUDT*(pOut: ptr ImVec4, t: float32, cmap: ImPlot3DColormap = cast[ImPlot3DColormap](-1)): void {.importc: "ImPlot3D_SampleColormap".}
proc imPlot3D_SetCurrentContext*(ctx: ptr ImPlot3DContext): void {.importc: "ImPlot3D_SetCurrentContext".}
proc imPlot3D_SetNextFillStyle*(col: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: -1), alpha_mod: float32 = -1): void {.importc: "ImPlot3D_SetNextFillStyle".}
proc imPlot3D_SetNextLineStyle*(col: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: -1), weight: float32 = -1): void {.importc: "ImPlot3D_SetNextLineStyle".}
proc imPlot3D_SetNextMarkerStyle*(marker: ImPlot3DMarker = -1.ImPlot3DMarker, size: float32 = -1, fill: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: -1), weight: float32 = -1, outline: ImVec4 = ImVec4(x: 0, y: 0, z: 0, w: -1)): void {.importc: "ImPlot3D_SetNextMarkerStyle".}
proc imPlot3D_SetupAxes*(x_label: cstring, y_label: cstring, z_label: cstring, x_flags: ImPlot3DAxisFlags = 0.ImPlot3DAxisFlags, y_flags: ImPlot3DAxisFlags = 0.ImPlot3DAxisFlags, z_flags: ImPlot3DAxisFlags = 0.ImPlot3DAxisFlags): void {.importc: "ImPlot3D_SetupAxes".}
proc imPlot3D_SetupAxesLimits*(x_min: cdouble, x_max: cdouble, y_min: cdouble, y_max: cdouble, z_min: cdouble, z_max: cdouble, cond: ImPlot3DCond = ImPlot3DCond_Once.ImPlot3DCond): void {.importc: "ImPlot3D_SetupAxesLimits".}
proc imPlot3D_SetupAxis*(axis: ImAxis3D, label: cstring = nullptr, flags: ImPlot3DAxisFlags = 0.ImPlot3DAxisFlags): void {.importc: "ImPlot3D_SetupAxis".}
proc imPlot3D_SetupAxisFormat*(idx: ImAxis3D, formatter: ImPlot3DFormatter, data: pointer = nullptr): void {.importc: "ImPlot3D_SetupAxisFormat".}
proc imPlot3D_SetupAxisLimits*(axis: ImAxis3D, v_min: cdouble, v_max: cdouble, cond: ImPlot3DCond = ImPlot3DCond_Once.ImPlot3DCond): void {.importc: "ImPlot3D_SetupAxisLimits".}
proc imPlot3D_SetupBoxScale*(x: float32, y: float32, z: float32): void {.importc: "ImPlot3D_SetupBoxScale".}
proc imPlot3D_SetupLegend*(location: ImPlot3DLocation, flags: ImPlot3DLegendFlags = 0.ImPlot3DLegendFlags): void {.importc: "ImPlot3D_SetupLegend".}
proc imPlot3D_ShowDemoWindow*(p_open: ptr bool = nullptr): void {.importc: "ImPlot3D_ShowDemoWindow".}
proc imPlot3D_ShowStyleEditor*(`ref`: ptr ImPlot3DStyle = nullptr): void {.importc: "ImPlot3D_ShowStyleEditor".}
proc imPlot3D_StyleColorsAuto*(dst: ptr ImPlot3DStyle = nullptr): void {.importc: "ImPlot3D_StyleColorsAuto".}
proc imPlot3D_StyleColorsClassic*(dst: ptr ImPlot3DStyle = nullptr): void {.importc: "ImPlot3D_StyleColorsClassic".}
proc imPlot3D_StyleColorsDark*(dst: ptr ImPlot3DStyle = nullptr): void {.importc: "ImPlot3D_StyleColorsDark".}
proc imPlot3D_StyleColorsLight*(dst: ptr ImPlot3DStyle = nullptr): void {.importc: "ImPlot3D_StyleColorsLight".}
