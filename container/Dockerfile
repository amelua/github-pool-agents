FROM mcr.microsoft.com/dotnet/runtime-deps:6.0 as build

ARG RUNNER_ARCH="x64"
ARG RUNNER_CONTAINER_HOOKS_VERSION="0.3.1"
ARG RUNNER_VERSION="2.304.0"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update -y && apt-get install -y curl unzip --no-install-recommends

WORKDIR /actions-runner
RUN curl -C - --retry 5 -f -L -o runner.tar.gz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
&& tar xzf ./runner.tar.gz \
&& rm runner.tar.gz

RUN curl -f -L -o runner-container-hooks.zip "https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip" \
&& unzip ./runner-container-hooks.zip -d ./k8s \
&& rm runner-container-hooks.zip

FROM mcr.microsoft.com/dotnet/runtime-deps:6.0

ARG GIT_LFS_VERSION="3.2.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update -y \
&& apt-get upgrade -y \
&& apt-get install -y --no-install-recommends \
curl \
lsb-release \
git \
gpg \
jq \
unzip \
&& DPKG_ARCH="$(dpkg --print-architecture)" \
&& LSB_RELEASE_CODENAME="$(lsb_release -cs)" \
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
&& echo "deb [arch=${DPKG_ARCH} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian ${LSB_RELEASE_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
&& ( curl -L "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && unzip -q awscliv2.zip -d /tmp/ && /tmp/aws/install && rm -v awscliv2.zip && rm -rf /tmp/aws ) \
&& ( curl --retry 5 -f -L "https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-${DPKG_ARCH}-v${GIT_LFS_VERSION}.tar.gz" -o /tmp/lfs.tar.gz && tar -xzf /tmp/lfs.tar.gz -C /tmp && /tmp/git-lfs-"${GIT_LFS_VERSION}"/install.sh && rm -rf /tmp/lfs.tar.gz /tmp/git-lfs-"${GIT_LFS_VERSION}" ) \
&& GH_CLI_VERSION=$(curl -sL -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest | jq -r '.tag_name' | sed -e 's|^v||g' ) \
&& GH_CLI_DOWNLOAD_URL=$(curl -sL -H "Accept: application/vnd.github+json" https://api.github.com/repos/cli/cli/releases/latest | jq ".assets[] | select(.name == \"gh_${GH_CLI_VERSION}_linux_${DPKG_ARCH}.deb\")" | jq -r '.browser_download_url' ) \
&& curl -sSLo /tmp/ghcli.deb "${GH_CLI_DOWNLOAD_URL}" && apt-get -y install /tmp/ghcli.deb --no-install-recommends && rm /tmp/ghcli.deb

# hadolint ignore=DL3008
RUN apt-get update -y \
&& apt-get install -y --no-install-recommends \
dumb-init \
docker-ce \
docker-ce-cli \
docker-buildx-plugin \
containerd.io \
procps \
sudo \
&& apt-get clean -y \
&& apt-get autoclean -y \
&& apt-get autoremove -y \
&& rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
&& usermod -aG sudo runner \
&& usermod -aG docker runner \
&& echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
&& echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers \
&& install -d -m755 /_work \
&& install -d -m755 /opt/hostedtoolcache \
&& chown runner /_work /opt/hostedtoolcache

COPY token.sh entrypoint.sh app_token.sh start.sh /
RUN chmod +x /token.sh /entrypoint.sh /app_token.sh

WORKDIR /home/runner

COPY --chown=runner:docker --from=build /actions-runner .

USER runner

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/bin/bash", "/start.sh" ]
