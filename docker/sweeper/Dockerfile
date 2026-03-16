FROM python:3.10-slim

ARG CODEARTIFACT_URL
RUN pip install --no-cache-dir \
    --extra-index-url "${CODEARTIFACT_URL}" \
    detent-lib

CMD ["python", "-m", "detent.sweeper"]
