FROM hugomods/hugo:exts as builder
# Base URL
ARG HUGO_BASEURL=https://otavio.cat
# Build site
COPY . /src
RUN hugo --minify --gc --enableGitInfo

###############
# Final Stage #
###############
FROM hugomods/hugo:nginx
COPY --from=builder /src/public /site
COPY ./nginx.conf /etc/nginx/nginx.conf
