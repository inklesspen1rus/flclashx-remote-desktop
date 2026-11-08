FROM debian:trixie-slim

# Опция для apt, чтобы не очищать кэш автоматически
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Install all packages + websockify + noVNC in a single layer, then clean up
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=bind,source=pkgs,target=/pkgs \
    DEBIAN_FRONTEND=noninteractive apt update && apt install -y --no-install-recommends \
        openssl xvfb x11vnc fluxbox supervisor xterm wget gpg \
        ttf-wqy-zenhei \
        python3-pip \
    # Install websockify without optional deps (numpy/jwcrypto/redis not needed for VNC proxy)
    && pip install --no-cache-dir --break-system-packages --no-deps websockify \
    # Remove pip after install (not needed at runtime)
    && apt purge python3-pip -y \
    && rm -rf /usr/lib/python3.*/ensurepip \
    # Clean Python bytecode cache
    && find /usr/lib/python3.* -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true \
    && find /usr/lib/python3.* -name '*.pyc' -delete 2>/dev/null; true \
    # Remove Python modules not needed at runtime
    && rm -rf /usr/lib/python3.*/site-packages/setuptools* \
              /usr/lib/python3.*/site-packages/packaging* \
              /usr/lib/python3.*/site-packages/pyparsing* \
              /usr/lib/python3.*/test \
              /usr/lib/python3.*/idlelib \
              /usr/lib/python3.*/turtle* \
              /usr/lib/python3.*/venv \
              /usr/lib/python3.*/ensurepip \
              /usr/lib/python3.*/tkinter \
              /usr/lib/python3.*/unittest \
              /usr/lib/python3.*/pydoc* \
              /usr/lib/python3.*/doctest* \
    # Download noVNC and keep only runtime assets
    && wget -qO /tmp/novnc.tar.gz https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz \
    && mkdir -p /usr/share/novnc \
    && tar xzf /tmp/novnc.tar.gz -C /usr/share/novnc --strip-components=1 \
    && rm /tmp/novnc.tar.gz \
    && ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html \
    # Remove noVNC non-runtime files
    && rm -rf /usr/share/novnc/docs \
             /usr/share/novnc/tests \
             /usr/share/novnc/screenshots \
             /usr/share/novnc/snap \
             /usr/share/novnc/.github \
             /usr/share/novnc/package.json \
             /usr/share/novnc/karma.conf.js \
             /usr/share/novnc/po \
             /usr/share/novnc/utils \
    # Install firefox
    && install -d -m 0755 /etc/apt/keyrings \
    && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- > /etc/apt/keyrings/packages.mozilla.org.asc \
    && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends xdg-desktop-portal-gtk libsecret-1-0 ayatana-indicator-common ayatana-indicator-application libegl1 libgles2 \
    && dpkg -i /pkgs/FlClashX-linux-amd64.deb \
    # Clean docs, and temp files
    && rm -rf /var/cache/apk/* /tmp/* \
              /usr/share/gtk-doc \
              /usr/share/man \
              /usr/share/doc \
    && rm -rf /var/lib/apt/lists/*

ADD supervisord.conf /etc/supervisord.conf
ADD xrdp.ini /etc/xrdp/xrdp.ini
ADD menu /root/.fluxbox/menu
ADD entry.sh /entry.sh

RUN chmod +x /entry.sh

ENV DISPLAY=:0
ENV RESOLUTION=1024x768

EXPOSE 6901 7890

ENTRYPOINT ["/entry.sh"]
