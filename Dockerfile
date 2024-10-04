FROM node:20-alpine as prod
EXPOSE 8000
EXPOSE 8001
EXPOSE 8002

ENV NODE_ENV=production
WORKDIR /usr/src/app

COPY package.json ./
COPY yarn.lock ./
RUN yarn install --production

COPY . .
RUN yarn build

CMD [ "yarn", "start" ]
