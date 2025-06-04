FROM jenkins/jenkins:lts

USER root

RUN apt-get update && apt-get install -y \
    git \
    curl \
    docker.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

# Instalar plugins básicos do Jenkins
RUN jenkins-plugin-cli --plugins workflow-aggregator git docker-workflow

VOLUME /var/jenkins_home

EXPOSE 8080

CMD ["java", "-jar", "/usr/share/jenkins/jenkins.war"]