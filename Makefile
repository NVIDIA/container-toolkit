# Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DOCKER   ?= docker
MKDIR    ?= mkdir
DIST_DIR ?= $(CURDIR)/dist

LIB_NAME := nvidia-container-toolkit
LIB_VERSION := 1.5.1
LIB_TAG ?=

GOLANG_VERSION := 1.16.3
MODULE := github.com/NVIDIA/nvidia-container-toolkit

# By default run all native docker-based targets
docker-native:
include $(CURDIR)/docker/docker.mk

GOOS ?= linux

binary:
	GOOS=$(GOOS) go build -ldflags "-s -w" -o "$(LIB_NAME)" $(MODULE)/cmd/$(LIB_NAME)

# Define the check targets for the Golang codebase
.PHONY: check fmt assert-fmt ineffassign lint misspell vet
check: assert-fmt lint misspell vet
fmt:
	go list -f '{{.Dir}}' $(MODULE)/... \
		| xargs gofmt -s -l -w

assert-fmt:
	go list -f '{{.Dir}}' $(MODULE)/... \
		| xargs gofmt -s -l > fmt.out
	@if [ -s fmt.out ]; then \
		echo "\nERROR: The following files are not formatted:\n"; \
		cat fmt.out; \
		rm fmt.out; \
		exit 1; \
	else \
		rm fmt.out; \
	fi

ineffassign:
	ineffassign $(MODULE)/...

lint:
	# We use `go list -f '{{.Dir}}' $(GOLANG_PKG_PATH)/...` to skip the `vendor` folder.
	go list -f '{{.Dir}}' $(MODULE)/... | xargs golint -set_exit_status

misspell:
	misspell $(MODULE)/...

vet:
	go vet $(MODULE)/...

COVERAGE_FILE := coverage.out
test:
	go test -coverprofile=$(COVERAGE_FILE) $(MODULE)/...

coverage: test
	go tool cover -func=$(COVERAGE_FILE)
