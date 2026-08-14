ARG DEBIAN_IMAGE=debian:bookworm-slim@sha256:abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241

FROM ${DEBIAN_IMAGE} AS texlive-builder

ARG TEXLIVE_INSTALLER_URL=https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
ARG TEXLIVE_INSTALLER_SHA256=a9526e69df95356c45de64b6b16670437b1de2ad2ab15d3bcfc2a16a65fc11fb
ARG TEXLIVE_REPOSITORY=https://mirror.ctan.org/systems/texlive/tlnet

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/usr/local/texlive/2026/bin/x86_64-linux:${PATH}

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    fontconfig \
    gpg \
    perl \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

COPY docker/texlive.profile /tmp/texlive.profile
COPY docker/texlive-packages.txt /tmp/texlive-packages.txt
COPY docker/texlive-packages.lock /tmp/texlive-packages.lock

RUN set -eu; \
    curl --fail --location --retry 5 --retry-all-errors \
    --output /tmp/install-tl-unx.tar.gz "${TEXLIVE_INSTALLER_URL}"; \
    echo "${TEXLIVE_INSTALLER_SHA256}  /tmp/install-tl-unx.tar.gz" | sha256sum --check --strict; \
    mkdir /tmp/install-tl; \
    tar --extract --gzip --file /tmp/install-tl-unx.tar.gz \
    --strip-components=1 --directory /tmp/install-tl; \
    /tmp/install-tl/install-tl \
    --profile /tmp/texlive.profile \
    --repository "${TEXLIVE_REPOSITORY}"; \
    packages="$(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' /tmp/texlive-packages.txt)"; \
    attempt=1; \
    until tlmgr install --repository "${TEXLIVE_REPOSITORY}" ${packages}; do \
    if [ "${attempt}" -ge 3 ]; then exit 1; fi; \
    attempt=$((attempt + 1)); \
    sleep 5; \
    done; \
    mktexlsr; \
    fmtutil-sys --all; \
    rm -rf /tmp/install-tl /tmp/install-tl-unx.tar.gz

RUN set -eu; \
    awk 'BEGIN { RS=""; FS="\n" } \
    /^name 00texlive\./ { next } \
    { name=""; revision=""; \
      for (i=1; i<=NF; i++) { \
        if ($i ~ /^name /) { name=substr($i, 6) } \
        if ($i ~ /^revision /) { revision=substr($i, 10) } \
      } \
      if (name != "" && revision != "") print name, revision \
    }' /usr/local/texlive/2026/tlpkg/texlive.tlpdb \
    | sort > /tmp/texlive-packages.actual; \
    diff --unified /tmp/texlive-packages.lock /tmp/texlive-packages.actual; \
    test "$(kpsewhich acmart.cls)" != ""; \
    grep --fixed-strings --quiet \
    '[2026/06/27 v2.19 Typesetting articles for the Association for Computing Machinery]' \
    "$(kpsewhich acmart.cls)"; \
    test "$(kpsewhich ACM-Reference-Format.bst)" != ""

FROM texlive-builder AS validation

COPY sample /tmp/sample
COPY docker/tests /tmp/acm-smoke
COPY fonts/times.ttf fonts/timesbd.ttf fonts/timesbi.ttf fonts/timesi.ttf \
    /usr/local/share/fonts/truetype/times-new-roman/

RUN set -eu; \
    fc-cache --force; \
    mkdir -p /tmp/report-build; \
    latexmk -cd -xelatex -interaction=nonstopmode -halt-on-error -file-line-error \
    -outdir=/tmp/acm-review-build /tmp/acm-smoke/review.tex; \
    latexmk -cd -xelatex -interaction=nonstopmode -halt-on-error -file-line-error \
    -outdir=/tmp/acm-sigconf-build /tmp/acm-smoke/sigconf.tex; \
    latexmk -cd -xelatex -interaction=nonstopmode -halt-on-error -file-line-error \
    -outdir=/tmp/report-build /tmp/sample/main.tex; \
    test -s /tmp/acm-review-build/review.pdf; \
    test -s /tmp/acm-sigconf-build/sigconf.pdf; \
    test -s /tmp/report-build/main.pdf; \
    ! grep --quiet 'You do not have the' /tmp/acm-review-build/review.log; \
    ! grep --quiet 'You do not have the' /tmp/acm-sigconf-build/sigconf.log

FROM ${DEBIAN_IMAGE} AS runtime

ARG USER_ID=1000
ARG GROUP_ID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/tmp \
    PATH=/usr/local/texlive/2026/bin/x86_64-linux:${PATH} \
    TEXMFVAR=/tmp/texmf-var \
    TEXMFCONFIG=/tmp/texmf-config

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
    fontconfig \
    perl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=validation /usr/local/texlive /usr/local/texlive
COPY docker/texlive-packages.lock /usr/local/share/texlive-packages.lock
COPY fonts/times.ttf fonts/timesbd.ttf fonts/timesbi.ttf fonts/timesi.ttf \
    /usr/local/share/fonts/truetype/times-new-roman/

RUN set -eu; \
    for font in /usr/local/share/fonts/truetype/times-new-roman/*.ttf; do \
    fc-scan --format '%{family[0]}\n' "$font" | grep --fixed-strings --line-regexp --quiet 'Times New Roman' \
    || { echo "Invalid Times New Roman font: $font" >&2; exit 1; }; \
    done; \
    fc-cache --force; \
    test "$(fc-match 'Times New Roman' --format '%{family[0]}')" = 'Times New Roman'; \
    mkdir -p /workspace; \
    chown "${USER_ID}:${GROUP_ID}" /workspace

WORKDIR /workspace

USER ${USER_ID}:${GROUP_ID}

CMD ["bash"]
