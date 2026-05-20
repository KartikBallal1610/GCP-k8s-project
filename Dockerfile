# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

COPY app/package.json ./

RUN npm install --only=production

# ---- Runtime stage ----
FROM node:20-alpine AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only production deps from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy app source
COPY app/server.js .
COPY app/package.json .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]