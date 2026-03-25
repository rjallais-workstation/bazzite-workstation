# hadolint global ignore=DL3059
# Allow build scripts to be referenced without being copied into the final image
ARG BASE_IMAGE_NAME=ghcr.io/ublue-os/bazzite-gnome
ARG DEFAULT_TAG=stable

FROM scratch AS ctx
COPY build_files /
COPY bin /bin
COPY mise.ci.toml /mise.toml

# Import shared Bluefin configurations from OCI container
COPY --from=ghcr.io/projectbluefin/common:latest /system_files /oci/common

# Base Image
FROM ${BASE_IMAGE_NAME}:${DEFAULT_TAG}

### Bootstrap mise and install tools
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    mkdir -p /.mise/tasks/ && \
    cp -r /ctx/finalize /ctx/install /ctx/prepare /.mise/tasks/ && \
    cp /ctx/mise.toml /mise.toml && \
    cp /ctx/bin/mise /bin/mise && \
    chmod +x /bin/mise && \
    find /.mise/tasks -type f -name '*.nu' -exec chmod +x {} \; && \
    ./bin/mise install

### LAYER 1: Remove unwanted packages
#RUN --mount=type=cache,dst=/var/cache ./bin/mise run install:remove-packages

#### LAYER 2: Enable COPR repositories
RUN ./bin/mise run prepare:repos

#### LAYER 3: Install system packages
RUN --mount=type=cache,dst=/var/cache ./bin/mise run install:packages

#### LAYER 4: Install Docker CE
RUN --mount=type=cache,dst=/var/cache ./bin/mise run install:docker

#### LAYER 5: Install NetBird
RUN --mount=type=cache,dst=/var/cache ./bin/mise run install:netbird

#### LAYER 6: Enable services
RUN ./bin/mise run prepare:services

#### LAYER 7: Install Bluefin modular components
RUN --mount=type=bind,from=ctx,source=/,target=/ctx ./bin/mise run install:bluefin

### LINTING
## Clean runtime artifacts and verify final image
RUN --network=none ./bin/mise run finalize:lint
