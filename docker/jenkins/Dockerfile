FROM docker.io/jenkins/jenkins:lts

USER root

# Docker CLI will intract with the external rootless $DOCKER_HOST
RUN --mount=type=cache,id=apt,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends docker-cli

USER jenkins
