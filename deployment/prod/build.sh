#!/bin/bash
#
# Copyright 2023 Ant Group Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

show_help() {
    echo "Usage: bash build.sh [OPTION]... -v {the_version}"
    echo "  -v  --version"
    echo "          the version to build with."
    echo "  -l --latest"
    echo "          tag this version as latest."
    echo "  -u --upload"
    echo "          upload to docker registry."
}

if [[ "$#" -lt 2 ]]; then
    show_help
    exit
fi

while [[ "$#" -ge 1 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift

            if [[ "$#" -eq 0 ]]; then
                echo "Version shall not be empty."
                echo ""
                show_help
                exit 1
            fi
            shift
        ;;
        -l|--latest)
            LATEST=1
            shift
        ;;
        -u|--upload)
            UPLOAD=1
            shift
        ;;
        *)
            echo "Unknown argument passed: $1"
            exit 1
        ;;
    esac
done


if [[ -z ${VERSION} ]]; then
    echo "Please specify the version."
    exit 1
fi


GREEN="\033[32m"
NO_COLOR="\033[0m"

DOCKER_REG="secretflow"


IMAGE_TAG=${DOCKER_REG}/teeapps-sgx-ubuntu20.04:${VERSION}
LATEST_TAG=${DOCKER_REG}/teeapps-sgx-ubuntu20.04:latest
echo -e "Building ${GREEN}${IMAGE_TAG}${NO_COLOR}"
cd ../.. && docker build . -f deployment/prod/Dockerfile -t ${IMAGE_TAG} \
  --build-arg config_templates="$(cat deployment/prod/config_templates.yml)" \
  --build-arg deploy_templates="$(cat deployment/prod/deploy_templates.yml)" \
  --build-arg comp_list="$(cat teeapps/component/comp_list.json)" \
  --build-arg translation="$(cat teeapps/component/translation.json)" \
  --network=host
echo -e "Finish building ${GREEN}${IMAGE_TAG}${NO_COLOR}"
if [[ UPLOAD -eq 1 ]]; then
    docker push ${IMAGE_TAG}
fi


if [[ LATEST -eq 1 ]]; then
    echo -e "Tag and push ${GREEN}${LATEST_TAG}${NO_COLOR} ..."
    docker tag ${IMAGE_TAG} ${LATEST_TAG}
    if [[ UPLOAD -eq 1 ]]; then
        docker push ${LATEST_TAG}
    fi
fi