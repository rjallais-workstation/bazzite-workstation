# Allow build scripts and custom files to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build /build
COPY custom /custom
COPY system_files /system_files

# Base Image
FROM ghcr.io/projectbluefin/bluefin:stable

### MODIFICATIONS
# Run the main build script which handles all customizations
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install nu && nu /ctx/build/10-build.nu

### LINTING
# Clean runtime artifacts and verify final image
RUN bootc container lint
