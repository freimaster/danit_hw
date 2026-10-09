FROM fluent/fluentd:v1.19.4-debian-2.1
USER root
# Pin the Ruby client to the Elasticsearch server's major version.
RUN gem install elasticsearch -v 8.19.0 --no-document && gem install fluent-plugin-elasticsearch -v 5.4.3 --conservative --no-document && mkdir -p /fluentd/buffer && chown -R fluent:fluent /fluentd/buffer
COPY fluent.conf /fluentd/etc/fluent.conf
USER fluent
