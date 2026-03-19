.PHONY: clean

all:
	@nim make.nims

fmt:
	@nim make.nims $@

clean:
	@nim make.nims $@
	@-$(MAKE) -C sdl3_opengl3  $@
	@-$(MAKE) -C sdl3_renderer $@
	@-$(MAKE) -C sdl3_sdlgpu3  $@


sdl: sdl3
	$(MAKE) -C sdl2_opengl3
	$(MAKE) -C sdl2_renderer

sdl3:
	$(MAKE) -C sdl3_opengl3
	$(MAKE) -C sdl3_renderer
	$(MAKE) -C sdl3_sdlgpu3
	$(MAKE) -C sdl3_vulkan



gen: copylibs

# For rlimgui_basic
RLIMGUI_ORG_DIR = ../libs/rlImGui
RLIMGUI_DIR = rlimgui_basic/rlimgui

copylibs:
	-mkdir -p $(RLIMGUI_DIR)
	cp -f $(RLIMGUI_ORG_DIR)/{*.cpp,*.h,LICENSE} $(RLIMGUI_DIR)/
	(cd $(RLIMGUI_DIR); patch --unified --forward rlImGui.h rlimgui.patch)
