BIN ?= hellholt
PREFIX ?= /usr/local

install:
	cp hellholt.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)
