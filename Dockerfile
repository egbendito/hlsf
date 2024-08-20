FROM rocker/geospatial:4.3.2

RUN apt-get update && \
    apt-get install -y wget curl python3-pip
#     git clone https://github.com/egbendito/hlsf

WORKDIR /home/hlsf/

COPY . ./

COPY ./app/setup-hlsf /usr/local/bin/

COPY ./app/update-hlsf /usr/local/bin/

RUN pip3 install -r ./reqs.txt
