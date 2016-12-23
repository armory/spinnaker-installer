FROM python:3

RUN apt-get -y update && \
    apt-get -y install apt-transport-https ca-certificates && \
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
    echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list && \
    apt-get -y update && \
    apt-cache policy docker-engine && \
    apt-get -y update && \
    apt-get -y install \
      docker-engine \
      curl \
      net-tools \
      vim \
      docker-engine \
      unzip

#This is for the main application
RUN /usr/local/bin/pip install \
    boto==2.44.0 \
    requests==2.12.3 \
    nose==1.3.7

RUN curl -O https://releases.hashicorp.com/terraform/0.8.2/terraform_0.8.2_linux_amd64.zip && \
    unzip terraform_0.8.2_linux_amd64.zip -d /usr/bin/

ADD ./src/armory /home/armory
ADD ./src/managing-acct /home/terraform/managing-acct

WORKDIR /home/armory

RUN which nosetests
CMD ["/usr/local/bin/nosetests", "-v", "--nocapture", "./"]
