FROM node:20-alpine AS base

WORKDIR /app

COPY package*.json ./

FROM base AS deps

RUN npm install

FROM deps AS test

COPY . .

CMD ["npm", "test"]

FROM base AS production-deps

RUN npm install --omit=dev

FROM node:20-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

COPY --from=production-deps /app/node_modules ./node_modules
COPY . .

EXPOSE 80

CMD ["npm", "start"]
