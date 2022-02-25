ARG ALP_VER=1.21.6-alpine
FROM nginx:$ALP_VER

COPY /src/index.html /usr/share/nginx/html/index.html