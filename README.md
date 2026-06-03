# copilot-fedora-toolbox

[![CI](https://github.com/trippwill/copilot-fedora-toolbox/actions/workflows/ci.yml/badge.svg)](https://github.com/trippwill/copilot-fedora-toolbox/actions/workflows/ci.yml)

Build a Fedora Toolbox image for GitHub Copilot CLI and install a host-side
`copilot` wrapper that runs the CLI inside the Toolbox container.

## Prerequisites

- Fedora Toolbx (`toolbox`) and Podman on the host.
- `~/.local/bin` on your `PATH` for the installed wrapper.
- Optional local development tools: `just`, `shellcheck`, and `shfmt`.

The image includes GitHub CLI, Git, common shell utilities, `shellcheck`,
`shfmt`, `just`, `mise`, and GitHub Copilot CLI.

## Install

Run the setup script from the repository root:

```sh
./create-copilot-toolbox.sh
```

If you have `just` installed, the equivalent convenience command is:

```sh
just install
```

The script:

1. Builds `localhost/copilot-cli-toolbox:latest`.
2. Creates the `copilot-cli` Toolbox container if it does not already exist.
3. Installs the host wrapper to `~/.local/bin/copilot`.

If `~/.local/bin` is not on your `PATH`, add it in your shell startup file:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

Run Copilot CLI as usual from the host:

```sh
copilot --help
copilot
```

The wrapper runs `copilot` inside the `copilot-cli` Toolbox container, preserves
your current working directory, and forwards all arguments.

## Configuration

The setup script and wrapper use these environment variables:

| Variable | Default | Used by |
| --- | --- | --- |
| `COPILOT_TOOLBOX_IMAGE` | `localhost/copilot-cli-toolbox:latest` | setup script |
| `COPILOT_TOOLBOX_CONTAINER` | `copilot-cli` | setup script and wrapper |
| `COPILOT_TOOLBOX_BIN_DIR` | `${XDG_BIN_HOME:-$HOME/.local/bin}` | setup script |
| `COPILOT_TOOLBOX_EDITOR` | `${EDITOR:-vim}` | wrapper |
| `COPILOT_TOOLBOX_VISUAL` | `${VISUAL:-$COPILOT_TOOLBOX_EDITOR}` | wrapper |

If you change `COPILOT_TOOLBOX_CONTAINER`, export it persistently in your shell
startup file before running the setup script and before using `copilot`. The
script and wrapper must agree on the container name.

## Update or recreate the Toolbox

Rebuilding the image does not update an already-created Toolbox container. To
rebuild the image and recreate the container:

```sh
./create-copilot-toolbox.sh --recreate
```

Or with `just`:

```sh
just recreate
```

Normal rebuilds reuse Podman layers, including the Copilot CLI and `mise`
layers. To refresh those floating latest installs and recreate the Toolbox so
it uses the rebuilt image:

```sh
just refresh
```

To refresh the Copilot CLI and `mise` image layers without recreating the
Toolbox:

```sh
./create-copilot-toolbox.sh --refresh-tools
just build-refresh
```

To rebuild the image and skip wrapper installation:

```sh
./create-copilot-toolbox.sh --no-install-wrapper
```

Rerun `./create-copilot-toolbox.sh` to reinstall the wrapper after editing it.

## Local validation

If you have `just`, `shellcheck`, and `shfmt` installed on the host:

```sh
just check
```

Useful recipes:

```sh
just --list
just install
just recreate
just refresh
just fmt
just lint
just build
just build-refresh
```

The container image also installs these tools, so you can run validation from
inside the Toolbox after it is created.

## Troubleshooting

- `copilot: command not found`: make sure `~/.local/bin` is on `PATH`, then run
  `./create-copilot-toolbox.sh` again.
- `toolbox: command not found`: install Fedora Toolbx on the host.
- `mise: command not found` inside the Toolbox: recreate the Toolbox with
  `./create-copilot-toolbox.sh --recreate` so the latest image is used.
- Terminal display issues in Ghostty: the image installs the included
  `xterm-ghostty` terminfo entry during build.
