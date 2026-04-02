import imguin/[cimgui, simple]
import ../utils/vecs

#---------------------------------------
# Enable ImSipnner widgets respectively
#---------------------------------------
# See: https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.h
#      https://github.com/dinau/imguin/blob/main/src/imguin/private/cimspinner/cimspinner.cpp
{.passC: "-D SPINNER_RAINBOWMIX".}
{.passC: "-D SPINNER_DNADOTS".}
{.passC: "-D SPINNER_ANG8".}
{.passC: "-D SPINNER_CLOCK".}
{.passC: "-D SPINNER_PULSAR".}
{.passC: "-D SPINNER_DOTSTOBAR".}
{.passC: "-D SPINNER_ATOM".}
{.passC: "-D SPINNER_BARCHARTRAINBOW".}
{.passC: "-D SPINNER_SWINGDOTS".}
{.passC: "-D SPINNER_CAMERA".}

{.passC: "-D IMSPINNER_DEMO".}

#--------------
# spinner demo
#--------------
proc demoCImSpinners*() =
  igBegin("Nim: CImSpinner / ImSpinner demo 2026/03", nil, 0)
  defer: igEnd()
  const red = ImColor(Value: vec4(1.0, 0.0, 0.0, 1.0))
  const gold = ImColor(Value: vec4(1.0, 215/255.0, 0.0, 1.0))
  const blue1 = ImColor(Value: vec4(51/255.0, 153/255.0, 1.0, 1.0))

  SpinnerDnaDotsEx("DnaDots", 16, 2, blue1, 1.2, 8, 0.25, true); igSameLine() # Defined by "SPINNER_DNADOTS"
  SpinnerRainbowMix("Rmix", 16, 2, gold, 4); igSameLine() # Defined by "SPINNER_RAINBOWMIX"
  SpinnerAng8("Ang", 16, 2); igSameLine() # ...
  SpinnerPulsar("Pulsar", 16, 2); igSameLine()
  SpinnerClock("Clock", 16, 2); igSameLine()
  SpinnerAtom("atom", 16, 2); igSameLine()
  SpinnerSwingDots("wheel", 16, 6); igSameLine()
  SpinnerDotsToBar("tobar", 16, 2, 0.5); igSameLine()
  SpinnerBarChartRainbow("rainbow", 16, 4, red, 4); igSameLine()

  proc genColor(i: cint): ImColor_c {.cdecl.} =
    return ImColor_HSV(i.float32 * 0.25, 0.8, 0.8, 1.0)
  SpinnerCamera("Camera", 16, 8, genColor) # Defined by "SPINNER_CAMERA"
