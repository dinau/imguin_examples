# Compiling:
# nim c glfw_opengl3_jp

# Modified: 2023/10
# Written by audin 2023/02

import std/[paths,math]
import ../utils/[appImGui, infoWindow]

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource
  import tinydialogs

# メインウインドウのサイズ
const MainWinWidth = 1080
const MainWinHeight = 800

proc firstWindow(win:Window)

var showAnotherWindow = true

#------
# main
#------
proc main() =
  var win = createImGui(MainWinWidth, MainWinHeight, title="JP window")
  defer: destroyImGui(win)


  #--------------
  # メインループ
  #--------------
  while not win.handle.windowShouldClose:
    pollEvents()

    if isIconifySleep(win):
      continue
    newFrame()

    if showAnotherWindow:
      infoWindow(win)
    firstWindow(win)
    #
    render(win)

   # if not showFirstWindow:
   #   win.handle.setWindowShouldClose(true) # exit program

#-------------
# firstWindow    画面左のWindowを描画
#-------------
proc firstWindow(win:Window) =
  var
    somefloat {.global.} = 0.0'f32
    counter {.global.} = 0'i32
    sFnameSelected {.global.}: string
    sBuf{.global.}: string
  once:
    sBuf = newString(200)

  let pio = igGetIO()
  block:
    igBegin("Window".cstring, nil, 0)
    defer: igEnd()

    igText("これは日本語表示テスト")
    igInputTextWithHint("テキスト入力", "ここに日本語を入力", sBuf)
    igText(("入力結果:" & sBuf).cstring)
    igCheckbox("他Window表示", showAnotherWindow.addr)
    igSliderFloat("浮動小数", somefloat.addr, 0.0f, 1.0f, "%3f", 0)
    igColorEdit3("背景色変更", win.ini.clearColor.array3, ImGuiColorEditFlags_None.ImGuiColorEditFlags)
    when defined(windows):
      if igButton("ファイルを開く", vec2(0, 0)):
        sFnameSelected = openFileDialog("Fileを開く", (getCurrentDir() / "\0".Path).string, ["*.nim", "*.nims"], "Text file")
      igSameLine(0.0f, -1.0f)
      # ヒント表示
      if igIsItemHovered(Imgui_HoveredFlagsDelayShort.cint) and igBeginTooltip():
        igText("ファイルを開きます")
        const ary = [0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f]
        igPlotLines("Curve", ary, overlayText = "オーバーレイ文字列")
        igText("Sin(time) = %.2f", sin(igGetTime()));
        igEndTooltip();
    igText("選択ファイル名 = %s", sFnameSelected.cstring)
    igText("描画フレームレート  %.3f ms/frame (%.1f FPS)" , 1000.0f / pio.Framerate.float, pio.Framerate)
    igText("経過時間 = %.1f [s]", counter.float32 / pio.Framerate)
    counter.inc
    const delay = 600 * 3
    somefloat = (counter mod delay).float32 / delay.float32
    #
    igSeparatorText(ICON_FA_WRENCH & " Icon font test ")
    igText(ICON_FA_TRASH_CAN & " Trash")
    igText(ICON_FA_MAGNIFYING_GLASS_PLUS &
      " " & ICON_FA_POWER_OFF &
      " " & ICON_FA_MICROPHONE &
      " " & ICON_FA_MICROCHIP &
      " " & ICON_FA_VOLUME_HIGH &
      " " & ICON_FA_SCISSORS &
      " " & ICON_FA_SCREWDRIVER_WRENCH &
      " " & ICON_FA_BLOG)

#------
# main
#------
main()
