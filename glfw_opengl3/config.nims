switch "app","gui"
switch "define", "release"

when defined(windows):
  {.passL:"-limm32".}
