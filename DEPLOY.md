The docs in the main README are good for setting up and running the Docker
image. These docs instead cover how to update the image and redeploy, tailored
to our exact setup.

1. Pull changes and rebuild the Docker image

   ```console
   $ cd once-campfire
   $ git pull  # I've left it on brent/main instead of origin/main now
   $ docker build -t campfire
   ```

2. Shut down the running container with the old image

   ```console
   $ docker ps
   $ docker stop $CONTAINER_ID
   ```

3. Restart with the new image

   ```console
   $ cd
   $ ./run.sh
   ```
