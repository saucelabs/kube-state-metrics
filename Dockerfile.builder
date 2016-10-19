from golang:1.7-alpine

RUN apk add --update alpine-sdk

ENV GOPATH=/builder/go
ENV PROJECT_DIR $GOPATH/src/github.com/saucelabs/kube-state-metrics
ENV PATH $PATH:$GOPATH/bin

RUN mkdir -p $PROJECT_DIR
COPY / $PROJECT_DIR/

RUN \
  cd $PROJECT_DIR && \
  make build test-unit && \
  gzip ./kube-state-metrics

CMD sleep 180
