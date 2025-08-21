# Wine image for AMP containers based on Wine stable
# ghcr.io/cubecoders/amp:wine-stable

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND=noninteractive
ARG         TARGETARCH

ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"
ARG         WINE_BRANCH=stable
ARG         WINE_DIST=bookworm

# Install required packages and Wine stable
RUN         set -eux; \
            apt-get update; \
            apt-get install -y --no-install-recommends cabextract winbind wine-binfmt python3; \
            case "$TARGETARCH" in \
                amd64) \
                    install -d -m 0755 /etc/apt/keyrings; \
                    wget -qO- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -; \
                    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/${WINE_DIST}/winehq-${WINE_DIST}.sources; \
                    apt-get update; \
                    apt-get install -y --install-recommends winehq-${WINE_BRANCH}; \
                    ;; \
                arm64) \
                    WINE_VERSION=$(curl -s "${WINE_LINK}" \
                        | grep -oE "wine-${WINE_BRANCH}-amd64_[0-9][0-9.]*~${WINE_DIST}-[0-9]+_amd64\.deb" \
                        | sort -V | tail -1 \
                        | sed -E "s/^wine-${WINE_BRANCH}-amd64_([0-9.]+)~${WINE_DIST}-[0-9]+_amd64\.deb$/\1/"); \
                    DEB_A1="wine-${WINE_BRANCH}-amd64_${WINE_VERSION}~${WINE_DIST}-1_amd64.deb"; \
                    DEB_A2="wine-${WINE_BRANCH}_${WINE_VERSION}~${WINE_DIST}-1_amd64.deb"; \
                    DEB_A3="winehq-${WINE_BRANCH}_${WINE_VERSION}~${WINE_DIST}-1_amd64.deb"; \
                    DEB_B1="wine-${WINE_BRANCH}-i386_${WINE_VERSION}~${WINE_DIST}-1_i386.deb"; \
                    wget -q ${WINE_LINK}${DEB_A1}; \
                    wget -q ${WINE_LINK}${DEB_A2}; \
                    wget -q ${WINE_LINK}${DEB_A3}; \
                    wget -q ${WINE_LINK}${DEB_B1}; \
                    for deb in *.deb; do dpkg-deb -x "$deb" /wine-installer; done; \
                    : >/tmp/wine-reqs.amd64; : >/tmp/wine-reqs.i386; \
                    # Collect dependencies
                    for deb in ${DEB_A1} ${DEB_A2} ${DEB_A3}; do \
                        { dpkg-deb -I "$deb" \
                            | awk -F': ' '/^( Depends| Recommends):/{print $2}' \
                            | tr ',' '\n' \
                            | sed -E 's/\(.*\)//; s/^[[:space:]]+|[[:space:]]+$//g' \
                            | grep -E '.' \
                            | grep -Ev '^(wine|winehq)[[:alnum:]-]*$'; } >> /tmp/wine-reqs.amd64 || :; \
                    done; \
                    { dpkg-deb -I "${DEB_B1}" \
                        | awk -F': ' '/^( Depends| Recommends):/{print $2}' \
                        | tr ',' '\n' \
                        | sed -E 's/\(.*\)//; s/^[[:space:]]+|[[:space:]]+$//g' \
                        | grep -E '.' \
                        | grep -Ev '^(wine|winehq)[[:alnum:]-]*$'; } >> /tmp/wine-reqs.i386 || :; \
                    # Pick first available alternative
                    pick_first_available() { \
                        line="$1"; \
                        printf '%s' "$line" \
                        | awk 'BEGIN{RS="\\|"}{gsub(/^[[:space:]]+|[[:space:]]+$/,""); if(length) print}' \
                        | while IFS= read -r cand; do \
                            candver="$(apt-cache policy "$cand" 2>/dev/null | awk "/Candidate:/ {print \$2}")"; \
                            if [ -n "$candver" ] && [ "$candver" != "(none)" ] && [ "$candver" != "none" ]; then \
                                printf '%s\n' "$cand"; exit 0; \
                            fi; \
                            done; \
                        return 1; \
                    }; \
                    # Resolve separate lists
                    : >/tmp/wine-deps.amd64; \
                    while IFS= read -r line; do \
                        sel="$(pick_first_available "$line")" || true; \
                        [ -n "$sel" ] && printf '%s\n' "$sel" >> /tmp/wine-deps.amd64; \
                    done < /tmp/wine-reqs.amd64; \
                    : >/tmp/wine-deps.armhf; \
                    while IFS= read -r line; do \
                        sel="$(pick_first_available "$line")" || true; \
                        [ -n "$sel" ] && printf '%s:armhf\n' "$sel" >> /tmp/wine-deps.armhf; \
                    done < /tmp/wine-reqs.i386; \
                    # Generate final dependency list
                    sort -u /tmp/wine-deps.amd64 /tmp/wine-deps.armhf > /tmp/wine-deps.txt; \
                    echo "Wine dependencies:"; cat /tmp/wine-deps.txt || :; \
                    mv wine-installer/opt/wine* /opt/wine-${WINE_DIST}; \
                    rm -rf wine-installer *.deb; \
                    xargs -ra "/tmp/wine-deps.txt" apt-get install -y --no-install-recommends; \
                    if [ -f /opt/wine-stable/bin/wine64 ]; then \
                        ln -sf /opt/wine-${WINE_DIST}/bin/wine64 /usr/bin/wine; \
                        ln -sf /opt/wine-${WINE_DIST}/bin/wine /usr/bin/wine32; \
                    else \
                        ln -sf /opt/wine-${WINE_DIST}/bin/wine /usr/bin/wine; \
                    fi; \
                    ln -sf /opt/wine-${WINE_DIST}/bin/wineboot /usr/bin/wineboot; \
                    ln -sf /opt/wine-${WINE_DIST}/bin/winecfg /usr/bin/winecfg; \
                    ln -sf /opt/wine-${WINE_DIST}/bin/wineserver /usr/bin/wineserver; \
                    chmod +x /usr/bin/wine /usr/bin/wineboot /usr/bin/winecfg /usr/bin/wineserver; \
                    if [ -f /usr/bin/wine32 ]; then chmod +x /usr/bin/wine32; fi; \
                    ;; \
            esac; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*