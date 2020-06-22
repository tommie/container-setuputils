DOCKER ?= docker

BASE_IMAGES ?= alpine debian ubuntu

.PHONY: check-docker
check-docker:
	@for image in $(BASE_IMAGES); do \
		echo "Checking $$image..." && \
		$(DOCKER) build --tag container-setuputils:test --build-arg "BASE_IMAGE=$$image" -f Dockerfile.test . && \
		$(DOCKER) run --rm container-setuputils:test || exit 1 ; \
	done

.PHONY: check
check:
	@for tst in *_test; do \
		echo "Checking $tst..." && \
		./$tst || exit $? ; \
	done
