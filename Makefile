.PHONY: clean

all:
	@nim make.nims

clean:
	@nim make.nims $@
	@-$(MAKE) -C sdl3_opengl3  $@
	@-$(MAKE) -C sdl3_renderer $@
	@-$(MAKE) -C sdl3_sdlgup3  $@

sdl:
	$(MAKE) -C sdl3_opengl3
	$(MAKE) -C sdl3_renderer
	$(MAKE) -C sdl3_sdlgpu3
