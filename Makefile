.PHONY: all clean

all:
	cd c_src/termbox2 && $(MAKE)

clean:
	cd c_src/termbox2 && $(MAKE) clean
