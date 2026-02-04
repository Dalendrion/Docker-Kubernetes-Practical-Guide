FROM node

WORKDIR /app

# COPY . /app

# We change the code often. Which means that everything after the `COPY . /app` line, all commands are executed again.
# So it will run npm install.
# But that's not necessary, because the package.json often stays the same. `RUN npm install` is only needed if package.json changes.
COPY package.json /app

RUN npm install

COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
