## 1. Dockerizing the MongoDB Service
```sh
docker run -d --rm -p 27017:27017 --name my-mongodb mongo
```

## 2. Dockerizing the Node App
In `app.js` replace

```js
'mongodb://localhost:27017/course-goals'
```

with

```js
'mongodb://host.docker.internal:27017/course-goals'
```
Create `Dockerfile`:
```docker
FROM node:14
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 80
CMD ["node", "app.js"]
```
Build an image:
```sh
docker build -t my-backend-img ./backend
```
Run a container:
```sh
docker run -d --rm -p 8080:80 --name my-backend-app my-backend-img
```
Because port 80 is occupied in Windows, we use port 8080 instead. That does mean that in the frontend app, we have to change the url from `http://localhost/` to `http://localhost:8080/` in all three places. We do this in `frontend/src/App.js`.

## 3. Dockerizing the React App
Create a `Dockerfile`:
```docker
FROM node:14
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```
Build the Docker image:
```sh
docker build -t my-frontend-img ./frontend
```
Run the container:
```sh
docker run -d --rm -p 3000:3000 --name my-frontend-app my-frontend-img
```

## 4. Adding Networks

```sh
docker network create my-network
```
Now we start each container inside of this network.

### MongoDB
```sh
docker run -d --rm -p 27017:27017 --name my-mongodb mongo
```
becomes
```sh
docker run -d --rm --network my-network --name my-mongodb mongo
```
### Backend
We need to change the code.
```js
'mongodb://host.docker.internal:27017/coarse-goals`
```
becomes
```js
'mongodb://my-mongodb:27017/coarse-goals'
```
Build the image:
```sh
docker build -t my-backend-img ./backend
```
To run the container:
```sh
docker run -d --rm -p 8080:80 --name my-backend-app my-backend-img
```
becomes
```sh
docker run -d --rm -p 8080:80 --network my-network --name my-backend-app my-backend-img
```

### Frontend
In App.js change the url host from `localhost` to `my-backend-img`. And change the port to `8080`.

Build the image:
```sh
docker build -t my-frontend-img ./frontend
```

To run the container:
```sh
docker run -d --rm -p 3000:3000 --name my-frontend-app my-frontend-img
```
stays
```sh
docker run -d --rm -p 3000:3000 --name my-frontend-app my-frontend-img
```
because it won't run in a container anyway. It runs in a browser.

## 5. MongoDB Persistence
We use a named volume to make data persistent.
```sh
docker run -d --rm --network my-network --name my-mongodb mongo
```
becomes
```sh
docker run -d --rm --network my-network --name my-mongodb -v data:/data/db mongo
```

## 6. MongoBD limited access
Access should be limited to a single user account.

If we use the environment variables `MONGO_INITDB_ROOT_USERNAME` and `MONGI_INITDB_ROOT_PASSWORD`, then those credentials must be used to access the database.
```sh
docker run -d --rm --network my-network --name my-mongodb -v data:/data/db mongo
```
becomes
```sh
docker run -d --rm --network my-network --name my-mongodb -v data:/data/db -e MONGO_INITDB_ROOT_USERNAME=user1 -e MONGO_INITDB_ROOT_PASSWORD=Password1! mongo
```
Edit the `app.js` file in the backend app. We need to provide the username and password to the MongoDB connection.
```js
'mongodb://my-mongodb:27017/course-goals'
```
becomes
```js
'mongodb://user1:Password1!@my-mongodb:27017/course-goals?authSource=admin'
```
That means we have to rebuild the backend image, and run the container again.
```sh
docker stop my-backend-app
docker build -t my-backend-img ./backend
docker run -d --rm -p 8080:80 --network my-network --name my-backend-app my-backend-img
```
## 7. Backend volumes
We want to make the log files persistent. For this we'll use a named volume.
A bind mount would be nice if we want to read the log files from the file explorer, but for now we won't do that.
`-v logs:/app/logs`

We also want to have live-edit of our development code. For that we will use a bind mount. `-v "$PWD/backend:/app"`

We don't want to overwrite any node-modules folder. For that we'll create an anonymous volume. `-v /app/node_modules`

```sh
docker run -d --rm -p 8080:80 --network my-network --name my-backend-app my-backend-img
```
becomes
```sh
docker run -d --rm -p 8080:80 --network my-network --name my-backend-app -v logs:/app/logs -v "$PWD/backend:/app" -v /app/node_modules my-backend-img
```
We also need to change the `Dockerfile`.
```docker
CMD ["node", "app.js"]
```
becomes
```docker
CMD ["npm", "start"]
```
We also need to add the "start" script into `package.json`.
```json
{
  "scripts": {
    "start": "nodemon --legacy-watch app.js"
  },
  "devDependencies": {
    "nodemon": "^2.0.4"
  }
}
```
Now rebuild the image and run the container:
```sh
docker build -t my-backend-img ./backend
docker run -d --rm -p 8080:80 --network my-network --name my-backend-app -v logs:/app/logs -v "$PWD/backend:/app" -v /app/node_modules my-backend-img
```

## 8. Using Env Variables for MongoDB Username and Password
In `backend/app.js` we hardcoded the username and password for the MongoDB database.
Let's use environment variables for that.

`Dockerfile`:
```docker
ENV MONGODB_USERNAME=root
ENV MONGODB_PASSWORD=secret
```
`app.js`:
```js
`mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@my-mongodb:27017/course-goals?authSource=admin`
```
Now we need to add these env vars to the docker run command.
```sh
docker build -t my-backend-img ./backend
docker run -d --rm -p 8080:80 --network my-network --name my-backend-app -v logs:/app/logs -v "$PWD/backend:/app" -v /app/node_modules -e MONGODB_USERNAME=user1 -e MONGODB_PASSWORD=Password1! my-backend-img
```

## 9. Limit What's Being Copied in Backend
In the `COPY . .` of the Dockerfile, we're copying some files that shouldn't be copied.

Create a new file called `.dockerignore`.
```
node_modules
Dockerfile
.dockerignore
.git
.gitignore
```

## 10. Frontend Live Source Code Update
To update our code, we need a bind mount.
```sh
docker run -v "$PWD/frontend/src:/app/src" -d --rm -p 3000:3000 --name my-frontend-app my-frontend-img
```
Now we can change something in the code, and it will be reflected in the browser.

Unfortunately, this doesn't work if you're on Windows and using WSL2. See https://devblogs.microsoft.com/commandline/access-linux-filesystems-in-windows-and-wsl-2/ for a fix.

## 11. Limit What's Being Copied in Frontend
In the `COPY . .` of the Dockerfile, we're copying some files that shouldn't be copied.

Create a new file called `.dockerignore`.
```
node_modules
Dockerfile
.dockerignore
.git
.gitig