FROM node:13 AS build

RUN mkdir /app
WORKDIR /app

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV
COPY package*.json ./
COPY elm.json ./
RUN npm ci --loglevel warn && npm cache clean --force
COPY . .
