# syntax=docker/dockerfile:1

# See https://github.com/jenkinsci/docker/blob/master/README.md#installing-more-tools
FROM docker.io/jenkins/jenkins:latest

USER root

# Docker CLI will intract with the external rootless $DOCKER_HOST
RUN --mount=type=cache,id=apt,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends docker-cli

USER jenkins

ENV JAVA_OPTS \
    -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true \
    -Dnew-build-page.flag.defaultValue=true \
    -Dnew-dashboard-page.flag.defaultValue=true \
    -Dnew-job-page.flag.defaultValue=true \
    -Dnew-manage-jenkins.flag.defaultValue=true \
    ${JAVA_OPTS}
