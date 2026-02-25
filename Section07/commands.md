## Using Docker

We can make a utility container with the following Dockerfile:
```docker
FROM node:18-alpine
WORKDIR /app
```

```sh
docker build -t node-util .
docker run -it node-util npm init
```
Now we run the docker comtainer with the command `npm init`.

So this container is now free to run **any** command.

But we want to reflect the file structure of the container to a file structure on the local machine. That way, we can use the generated files to manage our own project.

So in this case, the package.json that's generated can be used to create our own project.

```sh
docker run -it -v $PWD/:/app node-util npm init
```

To limit ourselves, and thus protect our file system, we can restrict ourselves to just use `npm` commands.

```docker
FROM node:14-alpine
WORKDIR /app
ENTRYPOINT ["npm"]
```
Now we can use
```sh
docker build -t my-npm .
docker run -it -v $PWD/:/app my-npm init
```
The "npm" from the ENTRYPOINT and the "init" from the docker run command will combine to form "npm init".

You could even add an npm dependency. Let's add the "express" dependency.
```sh
docker run -it -v $PWD/:/app my-npm install express --save
```

## Using Docker Compose

Add `docker-compose.yml`
```yml
services:            # docker run my-npm
  npm:
    build: ./
    stdin_open: true # -i
    tty: true        # -t
    volumes:
      - ./:/app      # -v $PWD/:/app
    
```

Now we can use a docker-compose command to run commands:
```sh
docker-compose run ${SERVICE} ${COMMAND} 
```
So we run:
```sh
docker-compose run --rm npm init
docker-compose run --rm npm install express --save
```
We add `--rm`, because `docker-compose run` commands don't automatically remove containers.