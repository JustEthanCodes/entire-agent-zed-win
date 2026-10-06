BINARY := entire-agent-zed

# On Windows a main package must carry a ".exe" suffix to be launched directly.
ifeq ($(shell go env GOOS),windows)
  BINARY := $(BINARY).exe
endif

# Where `go install` (and this Makefile) place binaries. This resolves to
# <GOPATH>/bin on every platform (Linux, macOS, Windows). Override with
# `make install INSTALL_DIR=...` to pick a different destination.
INSTALL_DIR ?= $(shell go env GOPATH)/bin

.PHONY: build test install uninstall clean

build:
	go build -o $(BINARY) .

test:
	go test -v -count=1 ./...

install: build
	@mkdir -p $(INSTALL_DIR)
	@cp $(BINARY) $(INSTALL_DIR)/$(BINARY)
	@chmod 755 $(INSTALL_DIR)/$(BINARY)
	@echo "Installed to $(INSTALL_DIR)/$(BINARY)"

uninstall:
	@rm -f $(INSTALL_DIR)/entire-agent-zed $(INSTALL_DIR)/entire-agent-zed.exe
	@echo "Removed entire-agent-zed from $(INSTALL_DIR)"

clean:
	@rm -f $(BINARY)
