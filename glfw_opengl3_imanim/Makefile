# 1. https://github.com/Anuken/staticglfw
#
TARGET =  $(notdir $(CURDIR))

ifeq ($(OS),Windows_NT)
	EXE = .exe
	PYTHON = python
else
	PYTHON = python3
endif

OPT += -d:strip

# Smaller size and some more time
#OPT += -d:lto

EMSDK_ROOT := $(shell em-config EMSCRIPTEN_ROOT)
GLFW3_INCLUDE := $(EMSDK_ROOT)/cache/ports/contrib.glfw3/include

OPT_WASM += $(OPT)
OPT_WASM += --passC:"-I$(GLFW3_INCLUDE)"

all:
	nim c $(OPT) -d:emscripten $(TARGET).nim

.PHONY: app cleanall run server fmt

OPT_APP += $(OPT)

app:
	nim c $(OPT_APP) $(TARGET).nim
	./$(TARGET)$(EXE)

cleanall:
	@-rm wasm/{*.data,*.js,*.html,*.wasm} $(TARGET)$(EXE)
	@-rm -fr .nimcache_app .nimcache_wasm

clean: cleanall

run: all server

server:
	$(PYTHON) -m http.server 8000

fmt:
	nimpretty --maxLineLen:1000 $(TARGET).nim
