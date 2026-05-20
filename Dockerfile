# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

# Copy only package files first for better layer caching
COPY app/package*.json ./

# Install production deps only
RUN npm ci --only=production

# ---- Runtime stage ----
FROM node:20-alpine AS runtime

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy deps from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application source
COPY app/server.js .
COPY app/package.json .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
