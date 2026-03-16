FROM jenkins/inbound-agent:latest AS jnlp

FROM python:3.10-slim

# Java for JNLP agent
RUN apt-get update && apt-get install -y --no-install-recommends \
    default-jre-headless git \
    && rm -rf /var/lib/apt/lists/*

# JNLP agent from Jenkins image
COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

# Python dependencies — install detent-lib from CodeArtifact, rest from PyPI
ARG CODEARTIFACT_URL
RUN pip install --no-cache-dir \
    --extra-index-url "${CODEARTIFACT_URL}" \
    boto3 detent-lib

ENTRYPOINT ["jenkins-agent"]
