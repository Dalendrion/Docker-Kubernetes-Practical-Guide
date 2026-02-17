
## Create Network
```sh
docker network create my-app-net
```

## Run MongoDB Container
```sh
docker run --name my-mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  -v data:/data/db \
  --rm \
  -d \
  --network my-app-net \
  mongo
```

## Build Node API Image
```sh
docker build -t my-backend-img .
```

## Run Node API Container
```sh
docker run --name my-backend-app \
  -e MONGODB_USERNAME=root \
  -e MONGODB_PASSWORD=secret \
  -v logs:/app/logs \
  -v $PWD/backend:/app \
  -v /app/node_modules \
  --rm \
  -d \
  --network my-app-net \
  -p 8080:80 \
  my-backend-img
```

## Build React SPA Image
```sh
docker build -t my-frontend-img .
```

## Run React SPA Container
```sh
docker run --name my-frontend-app \
  -v $PWD/frontend/src:/app/src \
  --rm \
  -d \
  -p 3000:3000 \
  -it \
  my-frontend-img
```

## Stop all Containers
```sh
docker stop my-mongodb my-backend-app my-frontend-app
```
