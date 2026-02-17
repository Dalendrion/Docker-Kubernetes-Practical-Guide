FROM node:14
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 80
ENV MONGODB_USERNAME=user1
ENV MONGODB_PASSWORD=Password1!
CMD ["npm", "start"]