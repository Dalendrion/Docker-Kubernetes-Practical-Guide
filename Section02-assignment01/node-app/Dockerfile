FROM node
WORKDIR /node-app
COPY ./package.json /node-app
RUN npm install
EXPOSE 80
COPY . /node-app
CMD ["node", "server.js"]