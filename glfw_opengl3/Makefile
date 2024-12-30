TARGET = $(notdir $(CURDIR))
NIMCACHE = .nimcache

ifeq ($(OS),Windows_NT)
	EXE = .exe
else
	OPT += --passL:-lstdc++
endif

all:
	nim c -d:strip --nimcache:$(NIMCACHE) $(TARGET).nim

.PHONY: clean run

run: all
	./$(TARGET)$(EXE)

clean:
	@-rm $(TARGET)$(EXE)
	@-rm -fr $(NIMCACHE)
