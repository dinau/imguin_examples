import strutils
import raylib
import ./rlimgui
import imguin/[cimgui, simple]

import ../utils/setupFonts

when defined(windows):
  when not defined(vcc):   # imguinVcc.res TODO WIP
    include ./res/resource

# ----------------------------------------------------------------------------------------
# Global Variables Definition
# ----------------------------------------------------------------------------------------
const
  screenWidth = 1080
  screenHeight = 600

# ----------------------------------------------------------------------------------------
# Module functions Definition
# ----------------------------------------------------------------------------------------
proc testShowCursor() =
  showCursor()

proc testDrawRectangle() =
  let rec = Rectangle(x: 50, y: 50, width: 400, height: 150)
  drawRectangle(rec, raylib.Color(r: 64, g: 166, b: 217, a: 55))

proc testDrawText() =
  drawText("Nim-" & NimVersion,                                    70, 70,  20, DarkBlue)
  drawText("Raylib v$#.$#" % [$RaylibVersion[0], $RaylibVersion[1]], 70, 100, 20, DarkBlue)
  drawText("2025/10",                                                70, 130, 20, DarkBlue)

  let font = getFontDefault()
  let position = Vector2(x: 150, y: 160)
  drawText(font, "Hello with custom font", position, 24, 2, Gray)

# ----------------------------------------------------------------------------------------
# Program main entry point
# ----------------------------------------------------------------------------------------
proc main =
  # Initialization
  # --------------------------------------------------------------------------------------
  setConfigFlags(flags(MSAA_4X_HINT, VSYNC_HINT, WINDOW_RESIZABLE))
  initWindow(screenWidth, screenHeight, "rlImGui Window 2025/10 in Nim" )

  # Define our custom camera to look into our 3d world
  var camera = Camera(
    position: Vector3(x: 18, y: 18, z: 18), # Camera position
    target: Vector3(x: 0, y: 0, z: 0),      # Camera looking at point
    up: Vector3(x: 0, y: 1, z: 0),          # Camera up vector (rotation towards target)
    fovy: 45,                               # Camera field-of-view Y
    projection: Perspective                 # Camera projection type
  )

  var image = loadImage("istockphoto_com-1209065219-128.png")                # https://www.istockphoto.com  search "grayscale height map"
  let texture = loadTextureFromImage(image)                                  # Convert image to texture (VRAM)
  let mesh = genMeshHeightmap(image, Vector3(x: 16, y: 8, z: 16))            # Generate heightmap mesh (RAM and VRAM)
  var model = loadModelFromMesh(mesh)                                        # Load model from generated mesh
  Model(model).materials[0].maps[MaterialMapIndex.Diffuse].texture = texture # Set map diffuse texture

  let mapPosition = Vector3(x: -8, y: 0, z: -8)                              # Define model position
  reset(image)                                                               # Unload heightmap image from RAM, already uploaded to VRAM

  setTargetFPS(60)                                                           # Set our game to run at 60 frames-per-second

  #-----------------
  rlImGuiSetup(true)
  #-----------------

  let (_, _, _, font) = setupFonts()
  let pio = igGetIO()
  pio.MouseDrawCursor = true

  var mapColor = ccolor(elm:(x:(255 - 73)/255, y:(255 - 113)/255, z:(255 - 166)/255, w:1.0))

  # --------------------------------------------------------------------------------------
  # Main game loop
  while not windowShouldClose(): # Detect window close button or ESC key
    # Update
    # ------------------------------------------------------------------------------------
    # TODO: Update your variables here
    updateCamera(camera, Orbital) # Set an orbital camera mode
    # ------------------------------------------------------------------------------------
    # Draw
    # ------------------------------------------------------------------------------------
    beginDrawing()
    rlImGuiBegin()

    #-------------
    # ImGui block
    #-------------
    pio.FontDefault = font
    block:
      igPushFont(nil, 19.0)
      defer: igPopFont()

      igShowDemoWindow(nil)

      igBegin("Test Window " & ICON_FA_DOG  , nil, 0)
      igText("%s", ICON_FA_SUN & " Sun")
      igText("%s", ICON_FA_CLOUD_RAIN & " Rain" )
      igText("Change Color")
      igColorEdit3("##Change color", mapColor.array3, 0)
      igEnd()

    #-------------------
    # Raylib draw texts
    #-------------------
    testDrawRectangle()
    testDrawText()

    #------------------------
    # Raylib draw height map
    #------------------------
    clearBackground(BLACK)

    beginMode3D(camera)
    let color = raylib.Color(r: (mapColor.elm.x * 255).uint8, g: (mapColor.elm.y * 255).uint8, b: (mapColor.elm.z * 255).uint8, a: (mapColor.elm.w * 255).uint8)
    drawModel(Model(model), mapPosition, 1, color)
    drawGrid(20, 1)
    endMode3D()

    drawTexture(texture, screenWidth - texture.width - 20, 20, White)
    drawRectangleLines(screenWidth - texture.width - 20, 20, texture.width, texture.height, DarkBlue)
    drawText("$# FPS" % [$getFPS()], 10, 10, 20, GRAY)

    drawText("Dear ImGui + Nalylib(Raylib) + rlImGui", 50, 250, 20, RayWhite)

    #----------
    # end proc
    #----------
    rlImGuiEnd()
    endDrawing()

  # end while

  # ------------------------------------------------------------------------------------
  # De-Initialization
  # --------------------------------------------------------------------------------------
  rlImGuiShutdown()
  closeWindow() # Close window and OpenGL context
  # --------------------------------------------------------------------------------------

main()
