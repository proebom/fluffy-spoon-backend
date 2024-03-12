# syntax=docker/dockerfile:1
ARG NODE_VERSION=20.11.1
ARG NEST_VERSION=10.2.4
ARG PNPM_VERSION=8.15.4

FROM node:${NODE_VERSION}-slim as base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
RUN --mount=type=cache,target=/root/.npm \
    pnpm install -g @nestjs/cli@${NEST_VERSION}
COPY . /app
WORKDIR /app

FROM base as prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base as build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

FROM base
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist
EXPOSE 3330
CMD ["pnpm", "start"]
