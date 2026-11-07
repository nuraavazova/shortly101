# ---- stage 1: build ----
FROM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && npm test

# ---- stage 2: run ----
FROM node:26-alpine
ENV NODE_ENV=production
WORKDIR /app

# nginx + tools to make the cert at boot and drop privileges
RUN apk add --no-cache nginx openssl su-exec \
 && mkdir -p /etc/nginx/certs /run/nginx

COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY public ./public
RUN rm -rf /usr/local/lib/node_modules/npm
RUN mkdir -p /app/data && chown node:node /app/data

# nginx reverse-proxy config + boot script
COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 443
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/healthz || exit 1
ARG GIT_SHA=dev
ENV GIT_SHA=$GIT_SHA
ENTRYPOINT ["/start.sh"]
