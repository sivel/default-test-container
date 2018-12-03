FROM ubuntu:16.04

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    DEBIAN_FRONTEND=noninteractive

COPY files/deadsnakes.list /etc/apt/sources.list.d/deadsnakes.list

ADD requirements/sanity.ps1 \
    https://packages.microsoft.com/keys/microsoft.asc \
    https://packages.microsoft.com/config/ubuntu/16.04/prod.list \
    https://bootstrap.pypa.io/get-pip.py \
    /tmp/
ADD https://bootstrap.pypa.io/2.6/get-pip.py /tmp/get-pip2.6.py

RUN set -eux && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 && \
    apt-key add /tmp/microsoft.asc && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        git \
        libbz2-dev \
        libffi-dev \
        libreadline-dev \
        libsqlite3-dev \
        libxml2-dev \
        libxslt1-dev \
        locales \
        make \
        openssh-client \
        openssl \
        python2.6-dev \
        python2.7-dev \
        python3.5-dev \
        python3.6-dev \
        python3.7-dev \
        shellcheck \
        apt-transport-https \
    && \
    rm /etc/apt/apt.conf.d/docker-clean && \
    locale-gen en_US.UTF-8 && \
    ln -s python2.7 /usr/bin/python2 && \
    ln -s python3.6 /usr/bin/python3 && \
    ln -s python3   /usr/bin/python && \
    # Install dotnet core SDK, pwsh, and other PS/.NET sanity test tools.
    # For now, we need to manually purge XML docs and other items from a Nuget dir to vastly reduce the image size.
    # See https://github.com/dotnet/dotnet-docker/issues/237 for details.
    ln -s /tmp/prod.list /etc/apt/sources.list.d/microsoft.list && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        dotnet-sdk-2.1.4 \
        powershell \
    && \
    find /usr/share/dotnet/sdk/NuGetFallbackFolder/ -name '*.xml' -type f -delete && \
    dotnet --version && \
    pwsh --version && \
    /tmp/sanity.ps1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    find /usr -type f -regex ".*\.py[co]" -delete

VOLUME /sys/fs/cgroup /run/lock /run /tmp

ENV container=docker
CMD ["/sbin/init"]

# Install pip and requirements last to speed up local container rebuilds when updating requirements.

COPY files/requirements.sh \
    files/early-requirements.txt \
    /tmp/
COPY requirements/*.txt /tmp/requirements/
COPY freeze/*.txt /tmp/freeze/

RUN set -eux && \
    /tmp/requirements.sh 2.6 && \
    /tmp/requirements.sh 2.7 && \
    /tmp/requirements.sh 3.5 && \
    /tmp/requirements.sh 3.6 && \
    /tmp/requirements.sh 3.7 && \
    rm -rf /root/.cache/pip && \
    find /usr -type f -regex ".*\.py[co]" -delete
