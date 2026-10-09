FROM node:22-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm install --omit=dev
COPY --chown=node:node index.js logger.js ./
USER node
EXPOSE 10000
CMD ["node", "index.js"]
