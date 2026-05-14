# Default installation prefix (current directory if not specified)
PREFIX ?= .

# Targets
.PHONY: all install uninstall clean

all: bin/GetNextID

bin:
	mkdir -p bin

bin/GetNextID: bin apps/GetNextID.c
	gcc -o bin/GetNextID apps/GetNextID.c

install: all
	mkdir -p $(PREFIX)/bin
	cp bin/GetNextID $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/GetNextID

clean:
	rm -rf bin

