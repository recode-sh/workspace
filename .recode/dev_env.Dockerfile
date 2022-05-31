# Project's dev env image must derive from "user_dev_env"
# (ie: github_user_name/.recode/dev_env.Dockerfile)
FROM user_dev_env

# VSCode extensions that need to be installed (optional)
LABEL sh.recode.vscode.extensions="golang.go, zxh404.vscode-proto3, ms-azuretools.vscode-docker"

# GitHub repositories that need to be cloned (optional) (default to the current one)
LABEL sh.recode.repositories="cli, agent, recode, aws-cloud-provider, base-dev-env, api, .recode, workspace"

# Reserved args (RECODE_*). Provided by Recode.
# eg: linux
ARG RECODE_INSTANCE_OS
# eg: amd64 or arm64
ARG RECODE_INSTANCE_ARCH

ARG GO_VERSION=1.18.2

# Install Go and dev dependencies
RUN set -euo pipefail \
  && cd /tmp \
  && LATEST_GO_VERSION=$(curl --fail --silent --show-error --location "https://golang.org/VERSION?m=text") \
  && if [[ "${GO_VERSION}" = "latest" ]] ; then \
        GO_VERSION_TO_USE="${LATEST_GO_VERSION}" ; \
     else \
        GO_VERSION_TO_USE="go${GO_VERSION}" ; \
     fi \
  && curl --fail --silent --show-error --location "https://go.dev/dl/${GO_VERSION_TO_USE}.${RECODE_INSTANCE_OS}-${RECODE_INSTANCE_ARCH}.tar.gz" --output go.tar.gz \
  && sudo tar --directory /usr/local --extract --file go.tar.gz \
  && rm go.tar.gz \
  && /usr/local/go/bin/go install golang.org/x/tools/cmd/goimports@latest \
  && /usr/local/go/bin/go install github.com/google/wire/cmd/wire@latest \
  && /usr/local/go/bin/go install github.com/golang/mock/mockgen@latest

# Add Go to path
ENV PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Install Protobuf
RUN set -euo pipefail \
  && cd /tmp \
  && LATEST_PB_VERSION=$(curl --fail --silent --show-error --location "https://api.github.com/repos/protocolbuffers/protobuf/releases/latest" | grep --only-matching --perl-regexp '(?<="tag_name": ").+(?=")') \
  && if [[ "$(uname --machine)" = "aarch64" ]] ; then \
        ARCH_TO_USE="aarch_64" ; \
     else \
        ARCH_TO_USE="x86_64" ; \
     fi \
  && curl --fail --silent --show-error --location "https://github.com/protocolbuffers/protobuf/releases/download/${LATEST_PB_VERSION}/protoc-${LATEST_PB_VERSION:1}-$(uname --kernel-name)-${ARCH_TO_USE}.zip" --output pb.zip \
  && sudo unzip -qq pb.zip -d /usr/local/pb \
  && rm pb.zip \
  && /usr/local/go/bin/go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
  && /usr/local/go/bin/go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Add Protobuf to path
ENV PATH=$PATH:/usr/local/pb/bin

# Install VSCode Go extension's dependencies
RUN set -euo pipefail \
  && /usr/local/go/bin/go install github.com/ramya-rao-a/go-outline@latest \
  && /usr/local/go/bin/go install github.com/cweill/gotests/gotests@latest \
  && /usr/local/go/bin/go install github.com/fatih/gomodifytags@latest \
  && /usr/local/go/bin/go install github.com/josharian/impl@latest \
  && /usr/local/go/bin/go install github.com/haya14busa/goplay/cmd/goplay@latest \
  && /usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest \
  && /usr/local/go/bin/go install honnef.co/go/tools/cmd/staticcheck@latest \
  && /usr/local/go/bin/go install golang.org/x/tools/gopls@latest
