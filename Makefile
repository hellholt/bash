BIN ?= hellholt
PREFIX ?= /usr/local
AUTOCOMPLETE_DIR ?= $(HOME)/.local/share/bash-completion/completions

install:
	mkdir -p $(AUTOCOMPLETE_DIR)
	cp hellholt.sh $(PREFIX)/bin/$(BIN)
	cp autocomplete.sh $(AUTOCOMPLETE_DIR)/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)
	rm -rf $(AUTOCOMPLETE_DIR)/$(BIN)
