FROM hugomods/hugo:exts as hugo
# Base URL
ARG HUGO_BASEURL=https://otavio.cat
# Build site
COPY . /src
RUN hugo --minify --gc --enableGitInfo

FROM caddy:2.8
COPY --from=hugo /src/public /site
COPY ./Caddyfile /etc/caddy/Caddyfile
