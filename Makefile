GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GORUN=$(GOCMD) run
PROJECT=circa10a/k8s-label-rules-webhook
BINARY=webhook
VERSION := $(shell grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" main.go)
GOBUILDFLAGS=-ldflags="-s -w"

test: export GIN_MODE=release
test: export METRICS=true
test:
	go test -v | sed '/ERRO/d; /level=error/d; /printer.go/d'

docs:
# Swagger
# https://github.com/swaggo/gin-swagger
	swag init -o api


build: docs
	$(GOBUILD) $(GOBUILDFLAGS) -o $(BINARY)

run: docs
	$(GORUN) . --metrics

compile: docs
	GOOS=linux GOARCH=amd64 go build $(GOBUILDFLAGS) -o bin/$(BINARY)-linux-amd64
	GOOS=linux GOARCH=arm go build $(GOBUILDFLAGS) -o bin/$(BINARY)-linux-arm
	GOOS=linux GOARCH=arm64 go build $(GOBUILDFLAGS) -o bin/$(BINARY)-linux-arm64
	GOOS=darwin GOARCH=amd64 go build $(GOBUILDFLAGS) -o bin/$(BINARY)-darwin-amd64

clean:
	$(GOCLEAN)
	rm -f $(BINARY)
	rm -rf ./api/

coverage: export GIN_MODE=release
coverage: export METRICS=true
coverage:
	go test -coverprofile=c.out | sed '/ERRO/d; /level=error/d' && go tool cover -html=c.out && rm c.out


docker-build: docs
	docker build -t $(PROJECT):$(VERSION) .

docker-run: docs
	docker run --rm -v $(shell pwd)/rules.yaml:/rules.yaml \
    -p 8080:8080 \
    $(PROJECT):$(VERSION) --file rules.yaml --metrics

docker-dev: docker-build docker-run

release: ARCH="linux-amd64"
release: docs
	GOOS=linux GOARCH=amd64 go build $(GOBUILDFLAGS) -o $(BINARY)
	tar -czf $(BINARY)-$(VERSION)-linux-amd64.tar.gz $(BINARY)

docker-release: docker-build
docker-release: docs
	echo "${DOCKER_PASSWORD}" | docker login -u ${USERNAME} --password-stdin
	docker push $(PROJECT):$(VERSION)

lint:
	golangci-lint run -v
