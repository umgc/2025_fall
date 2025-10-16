FROM debian:stable-slim
RUN apt-get update && apt-get install -y build-essential unzip \
 && apt-get install -y curl dos2unix jq python3 openjdk-21-jdk

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm awscliv2.zip && \
    rm -rf aws

WORKDIR /code_eval

COPY ./runcode.sh ./runcode.sh
COPY ./evaluate.py ./evaluate.py

RUN dos2unix ./runcode.sh

CMD [ "/bin/bash", "runcode.sh" ]