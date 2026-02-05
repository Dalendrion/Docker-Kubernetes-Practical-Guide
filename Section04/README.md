# 1. Communicating with the web

No action required.

# 2. Communicating with the host machine

Build an image with the tag `favorites-node`:

```sh
docker build -t favorites-node .
```

Run a container based on the image:

```sh
docker run --name favorites -d -p 3000:3000 --rm favorites-node
```

This will fail, because the app can't connect to MongoDB. See `app.js` lines 70 to 80. The container can't communicate with MongoDB on the host machine.

Change `localhost` to `host.docker.internal`.

# 3. Communicating with another container
## 3.1. The basic way

Run a standard MongoDB container. No image is needed, because it already exists on Dockerhub.

```sh
docker run --name mongodb -d mongo
```

Inspect the mongodb container.
```sh
docker inspect mongodb
```
Take note of the "IPAddress".
```json
[
    {
        ...,
        "NetworkSettings": {
            ...,
            "Networks": {
                "bridge": {
                    ...,
                    "IPAddress": "172.17.0.3",
                    ...
                }
            }
        }
    }
]
```


In `app.js` change the mongodb url from
```js
'mongodb://host.docker.internal:27017/swfavorites'
```
to
```js
'mongodb://172.17.0.3:27017/swfavorites'
```
Build an image with the tag `favorites-node`:

```sh
docker build -t favorites-node .
```

Run a container based on the image:

```sh
docker run --name favorites -d -p 3000:3000 --rm favorites-node
```

But this is not at all convenient. We have to do manual lookup of the IP address, and place it in the code. Which means we need to build a new image each time the IP address changes.

## 3.2. The better way: Container Networks

Stop and remove all containers, and run

```sh
docker network create favorites-net
docker run -d --name mongodb --network favorites-net mongo
```

Now we can use the name of the container instead of a host.

The name of the container is `mongodb`, so
```js
mongoose.connect(
  'mongodb://172.17.0.3:27017/swfavorites',
```
becomes
```js
mongoose.connect(
  'mongodb://mongodb:27017/swfavorites',
```
Build the image:
```js
docker build -t favorites-node .
```
Run the application container in the same network:
```sh
docker run --name favorites -d -p 3000:3000 --rm --network favorites-net favorites-node
```