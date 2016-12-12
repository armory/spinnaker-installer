FROM python:3

RUN apt-get update && apt-get install -y \
    curl \
    net-tools \
    vim

#This is for the main application
RUN /usr/local/bin/pip install \
    boto==2.44.0 \
    requests==2.12.3 \
    nose==1.3.7

ADD ./src/armory /home/armory

WORKDIR /home/armory

RUN which nosetests
CMD ["/usr/local/bin/nosetests", "-vv", "--nocapture", "./"]
