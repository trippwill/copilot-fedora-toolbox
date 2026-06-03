set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
	@just --list

install:
	./create-copilot-toolbox.sh

recreate:
	./create-copilot-toolbox.sh --recreate

refresh:
	./create-copilot-toolbox.sh --refresh-tools --recreate

fmt:
	shfmt -w create-copilot-toolbox.sh copilot

lint:
	shellcheck create-copilot-toolbox.sh copilot

check: lint
	shfmt -d create-copilot-toolbox.sh copilot

build:
	podman build -t "${COPILOT_TOOLBOX_IMAGE:-localhost/copilot-cli-toolbox:latest}" .

build-refresh:
	podman build --build-arg "TOOLS_REFRESH=$(date +%s)" -t "${COPILOT_TOOLBOX_IMAGE:-localhost/copilot-cli-toolbox:latest}" .
