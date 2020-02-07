FROM clearlinux:latest AS tools

# Grab os-release info from the minimal base image so
# that the new content matches the exact OS version
COPY --from=clearlinux/os-core:latest /usr/lib/os-release /

# Update to clearlinux/os-core version to ensure
# that the swupd command line arguments are identical
RUN source /os-release && \
    swupd update -V ${VERSION_ID} --no-boot-update $swupd_args

# Install additional content in a target directory
# using the os version from the minimal base
RUN source /os-release && \
    mkdir /install_root \
    && swupd os-install -V ${VERSION_ID} \
    --path /install_root --statedir /swupd-state \
    --bundles=dev-utils \
    && rm -rf /install_root/var/lib/swupd/*

FROM clearlinux:latest AS meson-build

COPY --from=tools /install_root /

COPY main.c meson.build /home/src/

RUN \
  cd /home/src && \
  meson builddir --prefix=/home/build --buildtype plain && \
	DESTDIR=/home/build ninja -v -C builddir install

FROM clearlinux/os-core:latest

COPY --from=meson-build /home/build /
