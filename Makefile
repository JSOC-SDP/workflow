# Default installation prefix (current directory if not specified)
MAKE_INSTALL_PREFIX ?= .

# Targets
.PHONY: all install uninstall clean

all: bin/GetNextID

bin:
	mkdir -p bin

bin/GetNextID: bin apps/GetNextID.c
	gcc -o bin/GetNextID apps/GetNextID.c

install: all
	@if [ "$(MAKE_INSTALL_PREFIX)" = "." ]; then \
		printf "INFO: No need to run install with MAKE_INSTALL_PREFIX set to '$(MAKE_INSTALL_PREFIX)'. Exiting."; \
		exit 1; \
	fi
	mkdir -p $(MAKE_INSTALL_PREFIX)/bin
	cp bin/GetNextID $(MAKE_INSTALL_PREFIX)/bin/
	mkdir -p $(MAKE_INSTALL_PREFIX)/scripts
	cp scripts/* $(MAKE_INSTALL_PREFIX)/scripts/

uninstall:
	@if [ "$(MAKE_INSTALL_PREFIX)" = "." ] || [ "$(MAKE_INSTALL_PREFIX)" = "/" ]; then \
		printf "ERROR: Cannot run uninstall with MAKE_INSTALL_PREFIX set to '$(MAKE_INSTALL_PREFIX)'. Refusing to delete local or system files."; \
		exit 1; \
	fi
	rm -f $(MAKE_INSTALL_PREFIX)/bin/GetNextID
	rm -rf $(MAKE_INSTALL_PREFIX)/scripts

clean:
	rm -rf bin

