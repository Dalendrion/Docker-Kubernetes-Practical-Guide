Dockerize BOTH apps - the Python and the Node app.

1. **Create appropriate images for both
apps (two separate images!).**

    node-app/Dockerfile:

    ```docker
    FROM node
    WORKDIR /node-app
    COPY ./package.json /node-app
    RUN npm install
    EXPOSE 3000
    COPY . /node-app
    CMD ["node", "server.js"]
    ```

    python-app/Dockerfile:

    ```docker
    FROM python
    WORKDIR /python-app
    COPY . /python-app
    CMD ["python", "bmi.py"]
    ```

    Terminal: node-app:

    ```sh
    docker build .
    ```

    Terminal: python-app:

    ```sh
    docker build .
    ```

2. **Launch a container for each created image, making sure, 
that the app inside the container works correctly and is usable.**

    Terminal: node-app:

    ```sh
    docker run -p 3000:3000 NODE_IMAGE_ID
    ```

    Terminal: python-app:

    ```sh
    docker run -it PYTHON_IMAGE_ID
    ```

3. **Re-create both containers and assign names to both containers.
Use these names to stop and restart both containers.**

    Terminal: main

    ```sh
    docker ps
    docker stop CONTAINER_NAME
    ```

    Terminal: node-app:

    ```sh
    docker run -p 3000:3000 --name my-node-app NODE_IMAGE_ID
    ```

    Terminal: python-app:

    ```sh
    docker run -it --name my-python-app PYTHON_IMAGE_ID
    ```

    Terminal: main

    ```sh
    docker ps
    docker stop my-node-app
    docker stop my-python-app
    ```

    Terminal: node-app:

    ```sh
    docker start -a my-node-app
    ```

    Terminal: python-app:

    ```sh
    docker start -ai my-python-app
    ```

4. **Clean up (remove) all stopped (and running) containers, 
clean up all created images.**

    Terminal: main:

    ```sh
    docker stop my-python-app
    docker stop my-node-app
    docker rm my-python-app
    docker rm my-node-app
    docker image prune
    ```

5. **Re-build the images - this time with
names and tags assigned to them.**

    Terminal: node-app:

    ```sh
    docker build . -t my-node-app:1.0.0
    ```

    Terminal: python-app:

    ```sh
    docker build . -t my-python-app:1.0.0
    ```

6. **Run new containers based on the re-built images, ensuring that the containers
are removed automatically when stopped.**

    Terminal: node-app:

    ```sh
    docker run --rm -p 3000:3000 --name my-node-app my-node-app:1.0.0
    ```

    Terminal: python-app:

    ```sh
    docker run --rm -it --name my-python-app my-python-app:1.0.0
    ```