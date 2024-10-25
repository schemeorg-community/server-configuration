FROM jenkins/ssh-agent:latest
COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/
ARG DOCKER_GROUP
RUN groupadd docker -g $DOCKER_GROUP
RUN usermod -aG docker jenkins
