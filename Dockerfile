FROM docker.elastic.co/logstash/logstash-oss:6.2.4

RUN logstash-plugin install logstash-input-google_pubsub
USER root
RUN mkdir -p /usr/share/scaife-viewer && chown logstash:logstash /usr/share/scaife-viewer
USER logstash

ADD logstash.conf /usr/share/logstash/pipeline/logstash.conf
ADD share/ /usr/share/scaife-viewer/
