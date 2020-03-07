FROM centos:7 as base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /out

# helmfile
ARG HELMFILE_VERSION
ENV HELMFILE_VERSION=${HELMFILE_VERSION:-0.98.2}
RUN curl -Lo /out/helmfile https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 && \
    chmod 755 /out/helmfile

# kubectl
ARG KUBECTL_VERSION
ENV KUBECTL_VERSION=${KUBECTL_VERSION:-1.16.0}
RUN curl -Lo /out/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod 755 /out/kubectl

# helm 3
ARG HELM3_VERSION
ENV HELM3_VERSION=${HELM3_VERSION:-3.0.3}
RUN curl -f -L https://get.helm.sh/helm-v${HELM3_VERSION}-linux-386.tar.gz | tar xzv --strip-components 1 -C /out

# git
ARG GIT_VERSION
ENV GIT_VERSION=${GIT_VERSION:-2.21.1}
RUN yum install -y \
        curl-devel \
        expat-devel \
        gcc \
        gettext-devel \
        make \
        openssl-devel \
        perl-ExtUtils-MakeMaker \
        zlib-devel

WORKDIR /usr/src/git-${GIT_VERSION}
RUN curl -L https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz | tar xvz --strip-components 1 && \
    make prefix=/usr/local/git all && \
    make prefix=/usr/local/git install

# Downloading and installing the gcloud package
WORKDIR /usr/local/gcloud
RUN curl -L https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz |tar xvz -C /usr/local/gcloud && \
    /usr/local/gcloud/google-cloud-sdk/install.sh && \
    /usr/local/gcloud/google-cloud-sdk/bin/gcloud components install beta && \
    /usr/local/gcloud/google-cloud-sdk/bin/gcloud components update

FROM golang:1.12.17 as jxl

WORKDIR /go/src/github.com/jenkins-x-labs

# hadolint ignore=DL3003
RUN git clone https://github.com/jenkins-x/bdd-jx.git && \
  cd bdd-jx && \
  make testbin

# hadolint ignore=DL3003
RUN git clone https://github.com/jenkins-x/jx.git && \
  cd jx && \
  git checkout multicluster && \
  make linux

# use a multi stage image so we don't include all the build tools above
FROM centos:7
# need to copy the whole git source else it doesn't clone the helm plugin repos below
COPY --from=base /usr/local/git /usr/local/git
COPY --from=base /usr/bin/make /usr/bin/make
COPY --from=base /out /usr/local/bin
COPY --from=base /usr/local/gcloud /usr/local/gcloud
COPY --from=jxl /go/src/github.com/jenkins-x-labs/bdd-jx/build/bddjx /go/src/github.com/jenkins-x-labs/jx/build/linux/jx /usr/local/bin/

ENV PATH=/usr/local/bin:/usr/local/git/bin:$PATH:/usr/local/gcloud/google-cloud-sdk/bin

ENV HELM_PLUGINS=/root/.cache/helm/plugins/
ENV JX_HELM3="true"

RUN helm plugin install https://github.com/databus23/helm-diff && \
    helm plugin install https://github.com/aslafy-z/helm-git.git

# hack copying in a custom built bdd-jx and a custom jx from this PR as needed but not merged yet https://github.com/jenkins-x/jx/pull/6664
# COPY build/jx /usr/local/bin/jx
# COPY build/bddjx-linux /usr/local/bin/bddjx
