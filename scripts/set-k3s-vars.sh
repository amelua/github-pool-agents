#!/bin/bash

_dir="${2-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
_target="${_dir%/*}" # deleted slash
_dest="${_target%scripts}/prod"

## clean
rm -rf "${_dest}"

# ==============================================================================
# FUNCTIONS - START
# ==============================================================================
run_prepare() {
    install -d -m755 "${_dest}/k3s"
}

function run_keda() {
    keda_yml="000_keda.yaml"
    echo -e "\e[1;32m==>\e[0m\033[1m Copyimg Keda YAML file... \e[m"
    install -m644 "${_target%scripts}/templates/${keda_yml}" "${_dest}/${keda_yml}"
}

function run_copy()
{
    # shellcheck source=/dev/null
    source "${_target%scripts}/.env" > /dev/null 2>&1 || echo -e "\e[1;32m==>\e[0m\033[1m Using default enviroments variables Operative System... \e[m"

    set +o allexport

    scale_yml="001_scalejob.yaml"

    echo -e "\e[1;32m==>\e[0m\033[1m Preparing YAML file... \e[m"
    install -m644 "${_target%scripts}/templates/k3s/${scale_yml}" "${_target%scripts}/templates/k3s/${scale_yml}.bak"

    ACCESS_TOKEN_64=$(echo -n "$ACCESS_TOKEN" | base64)
    DISABLE_AUTO_UPDATE="${DISABLE_AUTO_UPDATE:-true}"
    DOCKER_TAG="${DOCKER_TAG:-latest}"
    DOCKER_IMAGE_PULL_POLICY="${DOCKER_IMAGE_PULL_POLICY:-IfNotPresent}"
    EPHEMERAL="${EPHEMERAL:-true}"
    RUN_AS_ROOT="${RUN_AS_ROOT:-false}"
    RUNNER_GROUP="${RUNNER_GROUP:-Default}"

    sed -i \
        -e "s|__ENV_ACCESS_TOKEN__|${ACCESS_TOKEN_64}|g" \
        -e "s|__ENV_DISABLE_AUTO_UPDATE__|${DISABLE_AUTO_UPDATE}|g" \
        -e "s|__ENV_DOCKER_IMAGE_PULL_POLICY__|${DOCKER_IMAGE_PULL_POLICY}|g" \
        -e "s|__ENV_DOCKER_IMG_URL__|${DOCKER_IMG_URL}|g" \
        -e "s|__ENV_DOCKER_TAG__|${DOCKER_TAG}|g" \
        -e "s|__ENV_EPHEMERAL__|${EPHEMERAL}|g" \
        -e "s|__ENV_LABELS__|${LABELS}|g" \
        -e "s|__ENV_ORG_NAME__|${ORG_NAME}|g" \
        -e "s|__ENV_POOL_ID__|${POOL_ID}|g" \
        -e "s|__ENV_REPO_URL__|${REPO_URL}|g" \
        -e "s|__ENV_RUN_AS_ROOT__|${RUN_AS_ROOT}|g" \
        -e "s|__ENV_RUNNER_GROUP__|${RUNNER_GROUP}|g" \
        -e "s|__ENV_RUNNER_SCOPE__|${RUNNER_SCOPE}|g" \
        "${_target%scripts}/templates/k3s/${scale_yml}.bak"

    echo -e "\e[1;32m==>\e[0m\033[1m Writing YAML file... \e[m"
    install -m644 "${_target%scripts}/templates/k3s/${scale_yml}.bak" "${_dest}/k3s/${scale_yml}"

    echo -e "\e[1;32m==>\e[0m\033[1m Clean YAML file... \e[m"
    rm "${_target%scripts}/templates/k3s/${scale_yml}.bak" > /dev/null 2>&1 || true
}

# ==============================================================================
# EXECUTION - START
# ==============================================================================
run_prepare "$@"
run_keda "$@"
run_copy "$@"
