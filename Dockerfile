FROM python:3.12-slim

ARG MMARK_VERSION=2.2.31
ARG PANDOC_VERSION=3.8.3
ARG XML2RFC_SPEC=xml2rfc

ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates make \
    && rm -rf /var/lib/apt/lists/*

# mmark (static Go binary) — same version the markdown2rfc image ships
RUN curl -fsSL -o /tmp/mmark.tgz \
      "https://github.com/mmarkdown/mmark/releases/download/v${MMARK_VERSION}/mmark_${MMARK_VERSION}_linux_${TARGETARCH}.tgz" \
    && tar -xzf /tmp/mmark.tgz -C /usr/local/bin mmark \
    && rm /tmp/mmark.tgz

# pandoc — same pinned .deb release the GitHub Action installs
RUN curl -fsSL -o /tmp/pandoc.deb \
      "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-${TARGETARCH}.deb" \
    && dpkg -i /tmp/pandoc.deb \
    && rm /tmp/pandoc.deb

# xml2rfc (renders mmark's XML output to HTML)
RUN pip install --no-cache-dir ${XML2RFC_SPEC}

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# xml2rfc caches fetched references here; mount a volume to persist it
VOLUME /var/cache/xml2rfc

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["all"]
