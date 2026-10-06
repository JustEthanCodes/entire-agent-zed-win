# Build runner for entire-agent-zed — https://github.com/casey/just
#
# `just` is used in preference to `make` for portability (it ships as a single
# static binary and its recipes behave identically on Linux, macOS, and
# Windows). The legacy `Makefile` is still present for environments that don't
# have `just`.
#
# Windows note: these recipes assume a POSIX `sh` on PATH. Git Bash / MSYS2
# (which ship `sh`) is the expected shell on Windows — this matches the existing
# `Makefile`, which also requires `sh`. `just` itself is one `winget install
# casey.just` / `scoop install just` / single-binary download away.
#
#   just           list recipes
#   just build     compile the binary
#   just install   compile + copy to $(go env GOPATH)/bin
#   just test      run the test suite

# Canonical binary name. This intentionally does NOT match the module import
# path (whose last element is `entire-agent-zed-parser`); the project's CLI,
# git hooks, and docs all call the binary `entire-agent-zed`. `go build` with
# `-o` (as these recipes do) controls the name; a bare `go install .` would
# instead emit `entire-agent-zed-parser`. See README "Naming note".
bin := "entire-agent-zed"

# `.exe` suffix on Windows, empty everywhere else.
exe := if os() == "windows" { ".exe" } else { "" }

set shell := ["sh", "-c"]

default:
	@just --list

build:
	go build -o {{bin}}{{exe}} .

test:
	go test -v -count=1 ./...

install: build
	@mkdir -p $(go env GOPATH)/bin
	@cp {{bin}}{{exe}} $(go env GOPATH)/bin/{{bin}}{{exe}}
	@# chmod is a harmless no-op under Git Bash's sh on Windows.
	@chmod 755 $(go env GOPATH)/bin/{{bin}}{{exe}}
	@echo "Installed to $(go env GOPATH)/bin/{{bin}}{{exe}}"

uninstall:
	@rm -f $(go env GOPATH)/bin/{{bin}} $(go env GOPATH)/bin/{{bin}}.exe
	@echo "Removed entire-agent-zed from $(go env GOPATH)/bin"

clean:
	@rm -f {{bin}}{{exe}} {{bin}} {{bin}}.exe
