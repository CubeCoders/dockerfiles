# Wine image for AMP containers based on Wine staging
# ghcr.io/cubecoders/amp:wine-staging

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND=noninteractive
ARG         TARGETARCH

ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine-staging/"
ARG         WINE_BRANCH=staging
ARG         WINE_DIST=bookworm

# Install required packages and Wine staging
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
                    # Pick first available and non-conflicting alternative
                    resolve_alt() { \
                        line="$1"; mode="$2"; \
                        printf '%s' "$line" \
                        | awk 'BEGIN{RS="\\|"}{gsub(/^[[:space:]]+|[[:space:]]+$/,""); if(length) print}' \
                        | while IFS= read -r cand; do \
                            # For i386-mode, prefer armhf if candidate exists AND MA:same; else try native. For amd64-mode, native only. \
                            if [ "$mode" = "i386" ]; then \
                                arm_cand="$(apt-cache policy "${cand}:armhf" 2>/dev/null | awk "/Candidate:/ {print \$2}")"; \
                                if [ -n "$arm_cand" ] && [ "$arm_cand" != "(none)" ] && [ "$arm_cand" != "none" ]; then \
                                    ma="$(apt-cache show "${cand}:armhf" 2>/dev/null | awk -F': ' "/^Multi-Arch:/{print \$2; exit}")"; \
                                    if [ "$ma" = "same" ]; then printf '%s:armhf\n' "$cand"; exit 0; fi; \
                                fi; \
                                nat_cand="$(apt-cache policy "$cand" 2>/dev/null | awk "/Candidate:/ {print \$2}")"; \
                                if [ -n "$nat_cand" ] && [ "$nat_cand" != "(none)" ] && [ "$nat_cand" != "none" ]; then printf '%s\n' "$cand"; exit 0; fi; \
                            else \
                                nat_cand="$(apt-cache policy "$cand" 2>/dev/null | awk "/Candidate:/ {print \$2}")"; \
                                if [ -n "$nat_cand" ] && [ "$nat_cand" != "(none)" ] && [ "$nat_cand" != "none" ]; then printf '%s\n' "$cand"; exit 0; fi; \
                            fi; \
                        done; \
                        return 1; \
                    }; \
                    # Resolve separate lists
                    : >/tmp/wine-deps.amd64; \
                    while IFS= read -r line; do \
                        sel="$(resolve_alt "$line" amd64)" || true; \
                        [ -n "$sel" ] && printf '%s\n' "$sel" >> /tmp/wine-deps.amd64; \
                    done < /tmp/wine-reqs.amd64; \
                    : >/tmp/wine-deps.armhf; \
                    while IFS= read -r line; do \
                        sel="$(resolve_alt "$line" i386)" || true; \
                        [ -n "$sel" ] && printf '%s\n' "$sel" >> /tmp/wine-deps.armhf; \
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