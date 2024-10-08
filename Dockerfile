
# Base
FROM node:22-alpine as base
ENV NODE_ENV=production YARN_VERSION=3.2.1
#ENV YARN_VERSION=4.5.0

# https://calvinf.com/blog/2023/11/10/node-js-20-yarn-4-and-next-js-on-docker
# update dependencies, add libc6-compat and dumb-init to the base image
RUN apk update && apk upgrade && apk add --no-cache libc6-compat && apk add dumb-init
# install and use yarn 4.x
RUN corepack enable && corepack prepare yarn@${YARN_VERSION} && corepack install -g yarn@${YARN_VERSION}
RUN npm install -g esbuild

# add the user and group we'll need in our final image
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 apprunner



# Install dependencies
FROM base AS deps
WORKDIR /usr/src/app
COPY package.json yarn.lock* .yarnrc.yml .yarn ./

RUN yarn install --immutable

COPY . .
RUN yarn build


# # Build code
# FROM base AS builder
# WORKDIR /usr/src/app
# COPY --from=deps /usr/src/app/node_modules /usr/src/app/public /usr/src/app/.yarn ./
# COPY . .

#RUN yarn plugin import @yarnpkg/plugin-workspace-tools
# command above adds .yarnrc.yml 
#plugins:
#    - path: .yarn/plugins/@yarnpkg/plugin-workspace-tools.cjs
#      spec: "@yarnpkg/plugin-workspace-tools"
#RUN yarn workspaces focus --production
# RUN yarn workspaces foreach --from . -R run build
# RUN yarn build => this is not for production build



# Production Build
FROM base AS prod
WORKDIR /usr/src/app
RUN mkdir build

COPY --from=deps --chown=apprunner:nodejs /usr/src/app/node_modules/ ./node_modules
COPY --from=deps --chown=apprunner:nodejs /usr/src/app/build/ ./build
COPY --from=deps --chown=apprunner:nodejs /usr/src/app/public/ ./public
COPY --from=deps --chown=apprunner:nodejs /usr/src/app/package.json /usr/src/app/yarn.lock* /usr/src/app/.yarnrc.yml ./

USER apprunner

EXPOSE 8000
EXPOSE 8001
EXPOSE 8002

# CMD [ "top" ]
CMD [ "npm", "start" ]



# NOTES

# in case you use yarn start command 
# COPY --from=deps --chown=apprunner:nodejs /usr/src/app/.yarn/ ./.yarn
# CMD [ "yarn", "start" ]

# dumb-init is not working right now, but
# if you interested: https://github.com/Yelp/dumb-init
# CMD ["dumb-init","npm","start"]