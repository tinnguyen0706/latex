FROM debian:bookworm-slim

ARG USER_ID=1000
ARG GROUP_ID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/tmp \
    TEXMFVAR=/tmp/texmf-var \
    TEXMFCONFIG=/tmp/texmf-config

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
    fontconfig \
    latexmk \
    texlive-bibtex-extra \
    texlive-fonts-recommended \
    texlive-latex-extra \
    texlive-science \
    texlive-xetex \
    && rm -rf /var/lib/apt/lists/*

COPY fonts/times.ttf fonts/timesbd.ttf fonts/timesbi.ttf fonts/timesi.ttf \
    /usr/local/share/fonts/truetype/times-new-roman/

RUN set -eu; \
    for font in /usr/local/share/fonts/truetype/times-new-roman/*.ttf; do \
    fc-scan --format '%{family[0]}\n' "$font" | grep --fixed-strings --line-regexp --quiet 'Times New Roman' \
    || { echo "Invalid Times New Roman font: $font" >&2; exit 1; }; \
    done; \
    fc-cache --force; \
    test "$(fc-match 'Times New Roman' --format '%{family[0]}')" = 'Times New Roman'

RUN mkdir -p /workspace \
    && chown "${USER_ID}:${GROUP_ID}" /workspace

WORKDIR /workspace

USER ${USER_ID}:${GROUP_ID}

CMD ["bash"]
