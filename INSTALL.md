# Installation

`entire-agent-zed` is the [Entire.io](https://entire.dev) External Agent plugin for
the [Zed Editor](https://zed.dev). It reads Zed's AI threads out of the Zed
threads database and exposes them to the Entire agent ecosystem.

> **Windows?** This guide covers all platforms. The project now builds natively
> on Windows with **no C compiler** (see [Dependencies](#dependencies)).

## Prerequisites

- **Go 1.24.4 or newer** (the module's `go` directive is `1.24.4`).
- **No C compiler required.** The SQLite driver is 100% pure Go, so `gcc`,
  MinGW, and MSVC are *not* needed — on Windows a plain `go build` works out of
  the box.
- `git` (only required if you want the automatic lifecycle hooks).
- `just` *(recommended)* — a single static binary. Install once with
  `winget install casey.just` / `scoop install just`, or grab it from
  https://github.com/casey/just. If you don't install `just`, you can still use
  the `Makefile` (`make` ships with Git Bash / MSYS2 on Windows) or the manual
  `go build` commands below.

## Option A — Install with `just` (recommended)

The `justfile` handles the platform `.exe` suffix and the install location:

```bash
just build          # compiles ./entire-agent-zed (Unix) / .\entire-agent-zed.exe (Windows)
just install        # copies it to $(go env GOPATH)/bin
just test           # run the full test suite
just uninstall      # remove from $(go env GOPATH)/bin
just clean          # remove the local build artifact
```

Run `just` with no arguments to list every recipe. `just install` places the
binary on `$(go env GOPATH)/bin`, which is `~/go/bin` on Linux/macOS and
`%USERPROFILE%\go\bin` on Windows. Make sure that directory is on your `PATH`.

## Option B — Build without `just`

You can also use the legacy `Makefile` (`make build`, `make install`, `make test`,
`make uninstall`, `make clean`) — `make` ships with Git Bash / MSYS2 on Windows —
or build directly with the Go toolchain.

### Windows (PowerShell)

```powershell
go build -o entire-agent-zed.exe .

# Copy the binary to a folder on your PATH, e.g.:
copy entire-agent-zed.exe "$env:USERPROFILE/go/bin/"
```

### Linux / macOS

```bash
go build -o entire-agent-zed .
cp entire-agent-zed ~/go/bin/
```

> **Naming note:** the module's import path ends in `-parser`, so a *bare*
> `go build` / `go install .` (without `-o`) writes the output as
> `entire-agent-zed-parser(.exe)` — not the `entire-agent-zed` name the rest of
> these instructions (and the git hooks) use. Always build with
> `-o entire-agent-zed[.exe]` (or use `just build` / `make build`) to get the
> canonical name.

## Verify the install

```bash
entire-agent-zed --help
```

You should see the help text listing the available commands (`install-hooks`,
`transcript`, `parse-hook`, `info`, etc.).

## Install the git hooks (lifecycle tracking)

From a Git repository you want tracked:

```bash
entire-agent-zed install-hooks
```

This installs a `post-commit` hook in `.git/hooks/`. On **every commit** it fires
the Entire lifecycle events (`session-start` → `turn-start` on the first
commit, then `turn-end` → `turn-start` on each subsequent commit), and migrates
any legacy `pre-commit` hooks automatically.

Check/remove them later:

```bash
entire-agent-zed are-hooks-installed   # prints JSON: {"installed": true/false}
entire-agent-zed uninstall-hooks
```

The hook works on Linux, macOS, and Windows (Git for Windows runs hooks through
its bundled `sh.exe`). The hook preloads `$HOME/go/bin` (and `~/.local/bin`)
onto `PATH` so a `go install`-/built `entire` CLI is found when it runs.

## Connecting to Zed's database

The agent locates Zed's threads database (`threads.db`) automatically using Zed's
own data-directory conventions:

| OS      | Default location |
|---------|------------------|
| Linux   | `~/.local/share/zed/threads/threads.db` |
| macOS   | `~/Library/Application Support/Zed/threads/threads.db` |
| Windows | `%LOCALAPPDATA%\Zed\threads\threads.db` (i.e. `~\AppData\Local\Zed\threads\threads.db`) |

On Windows, if you installed a Zed **Preview** that wrote to the roaming config
directory instead, the roaming path (`~\AppData\Roaming\Zed\threads\threads.db`)
is checked as a fallback.

To point the agent at a non-default Zed data directory, set the
`ZED_DATA_DIR` environment variable to the directory that *contains* a
`threads/threads.db`:

```bash
# Linux / macOS / Git Bash
export ZED_DATA_DIR="$HOME/.local/share/zed"

# Windows PowerShell
$env:ZED_DATA_DIR = "$env:LOCALAPPDATA\Zed"
```

This mirrors Zed's own `--data-dir` flag and works on every platform. You can
confirm which path the agent resolved with:

```bash
entire-agent-zed resolve-session-file   # prints the threads.db path it will use
```

## Dependencies

Zed stores its AI threads in a local SQLite database. Earlier versions of this
agent used `github.com/mattn/go-sqlite3`, which is **CGO-only** and requires a C
compiler (MinGW on Windows). That made the agent fail to build — or silently
produce a non-functional stub — on a clean Windows install of Go with no C
toolchain.

The agent now uses [`modernc.org/sqlite`](https://pkg.go.dev/modernc.org/sqlite),
a **100% pure-Go** SQLite driver. Because it needs no C compiler, the binary
builds everywhere the Go toolchain does (Linux, macOS, Windows), and read-only
access to Zed's database is preserved via a `file:<path>?mode=ro` DSN.

## Troubleshooting

**`go: command not found`** — Install Go from https://go.dev/dl and reopen your
terminal. Verify with `go version`.

**Build fails with `cgo: C compiler "gcc" not found`** — You are building an old
checkout that still uses `mattn/go-sqlite3`. Update to the current `main`, which
uses the pure-Go `modernc.org/sqlite` driver; then `CGO_ENABLED=0` (the default
when no C compiler is present) is fine.

**Module download fails / `wsarecv: An existing connection ... forcibly closed`** — the default `proxy.golang.org` is unreachable from your network. Switch to a reachable mirror:

```bash
go env -w GOPROXY=https://goproxy.cn,direct
go env -w GOSUMDB=sum.golang.cn
```

**The binary isn't found after install** — Make sure `$(go env GOPATH)/bin` is on
your `PATH`, or use the full path: `~/go/bin/entire-agent-zed --help`
(Windows: `%USERPROFILE%\go\bin\entire-agent-zed.exe --help`).

**Can't find `threads.db`** — Run `entire-agent-zed resolve-session-file` to see
the exact path the agent is checking, and/or set `ZED_DATA_DIR` (see above).
