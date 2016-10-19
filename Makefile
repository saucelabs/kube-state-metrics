all: build

FLAGS =
ENVVAR = GOOS=linux GOARCH=amd64 CGO_ENABLED=0
REGISTRY = gcr.io/google_containers
TAG = v0.3.0
TMPDIR=/tmp/kube-state-metrics

deps:
	go get github.com/tools/godep

build: clean deps
	$(ENVVAR) godep go build -o kube-state-metrics 

test-unit: clean deps build
	$(ENVVAR) godep go test . $(FLAGS)

container: build
	docker build -t ${REGISTRY}/kube-state-metrics:$(TAG) .

push: container
	gcloud docker push ${REGISTRY}/kube-state-metrics:$(TAG)

clean:
	rm -f kube-state-metrics

deploy_local: build
	version=dev-$(shell uuidgen | cut -c 1-8); \
	docker build -t kube-state-metrics:$$version .; \
	mkdir -p $(TMPDIR) && rm -f $(TMPDIR)/*.yml; \
	sed \
		-e "s/v0.3.0/$$version/g" \
		-e "s/gcr.io\/google_containers\///g" \
		kubernetes/deployment.yml \
		> $(TMPDIR)/deployment.yml; \
	kubectl delete --ignore-not-found -f $(TMPDIR)/deployment.yml; \
	kubectl create -f $(TMPDIR)/deployment.yml; \
	kubectl delete -f kubernetes/service.yml; \
	kubectl create -f kubernetes/service.yml

.PHONY: all deps build test-unit container push clean
