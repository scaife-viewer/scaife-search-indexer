FROM jruby:9.1 AS gem-build

RUN apt-get update \
    && apt-get install -y git \
    && mkdir -p /usr/local/src && cd /usr/local/src/ \
    && git clone https://github.com/SvenW/logstash-input-google_pubsub \
    && cd logstash-input-google_pubsub \
    && git checkout f4b06da95069cd6caf8ae9ee0b6e23300649e9f6 \
    && ./ci/build.sh \
    && gem build logstash-input-google_pubsub.gemspec


FROM docker.elastic.co/logstash/logstash-oss:6.2.2

COPY --from=gem-build /usr/local/src/logstash-input-google_pubsub/logstash-input-google_pubsub-1.0.4.gem /tmp
RUN logstash-plugin install /tmp/logstash-input-google_pubsub-1.0.4.gem
USER root
RUN mkdir -p /usr/share/scaife-viewer && chown logstash:logstash /usr/share/scaife-viewer
USER logstash

ADD logstash.conf /usr/share/logstash/pipeline/logstash.conf
ADD share/ /usr/share/scaife-viewer/
