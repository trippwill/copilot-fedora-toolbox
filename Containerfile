FROM registry.fedoraproject.org/fedora-toolbox:44

LABEL org.opencontainers.image.title="copilot-fedora-toolbox" \
      org.opencontainers.image.description="Fedora Toolbox image for GitHub Copilot CLI" \
      org.opencontainers.image.source="https://github.com/trippwill/copilot-fedora-toolbox"

RUN dnf install -y --setopt=install_weak_deps=False \
    bat \
    ca-certificates \
    curl \
    diffutils \
    fd-find \
    findutils \
    gh \
    git \
    git-delta \
    gzip \
    jq \
    just \
    less \
    libsecret \
    make \
    ncurses \
    ncurses-term \
    npm \
    patch \
    ripgrep \
    shellcheck \
    shfmt \
    tar \
    unzip \
    vim-enhanced \
    xz \
    yq \
    zsh \
    zstd \
 && dnf clean all \
 && rm -rf /var/cache/dnf

ARG TOOLS_REFRESH
RUN printf 'TOOLS_REFRESH=%s\n' "$TOOLS_REFRESH" >/dev/null \
 && npm install --global --prefix /usr/local @github/copilot

RUN curl --fail --silent --show-error --location https://mise.run --output /tmp/mise-install.sh \
 && MISE_INSTALL_HELP=0 MISE_INSTALL_PATH=/usr/local/bin/mise sh /tmp/mise-install.sh \
 && rm /tmp/mise-install.sh

COPY xterm-ghostty.terminfo /tmp/xterm-ghostty.terminfo

RUN tic -x -o /usr/share/terminfo /tmp/xterm-ghostty.terminfo \
 && rm /tmp/xterm-ghostty.terminfo
