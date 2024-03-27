FROM hugomods/hugo:exts as hugo
# Base URL
ARG HUGO_BASEURL=https://otavio.cat
# Build site
COPY . /src
RUN hugo --minify --gc --enableGitInfo

#FROM hugomods/hugo:nginx
#COPY --from=builder /src/public /site
#COPY ./nginx.conf /etc/nginx/nginx.conf

FROM caddy:2.1.1
COPY --from=hugo /src/public /site
COPY ./Caddyfile /etc/caddy/Caddyfile
