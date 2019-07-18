#!/bin/bash

# https://devhints.io/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'

WINE_GIT_URL="git://source.winehq.org/git/wine.git"
WINE_BUILD_SCRIPT_DIR=${WINE_BUILD_SCRIPT_DIR:-~/wine-build-script}
WINE_SOURCE_DIR_NAME="wine-src"
WINE_BUILD_64_DIR_NAME="wine-build-64"
WINE_BUILD_32_DIR_NAME="wine-build-32"
WINE_BUILD_DIR_NAME="wine-build"

SCRIPT_AND_DOCKERFILE_LOCATION=$(realpath $(dirname $0))

DOCKER_IMAGE_TAG="wine-32-bit-build-environment"
SCRIPT_DOCKER_MODE_ENABLED=${SCRIPT_DOCKER_MODE_ENABLED:-0}

function print_help() {
    cat <<END
Wine build script for 64-bit Ubuntu 18.04.

Wine source code URL:           $WINE_GIT_URL
Docker image tag:               $DOCKER_IMAGE_TAG
Build script directory:         $WINE_BUILD_SCRIPT_DIR
Script and Dockerfile location: $SCRIPT_AND_DOCKERFILE_LOCATION

Read README.md for usage instructions.

Options:
  -h, --help                    Print this message.
      --download-source-code    Download Wine source code.
      --create-docker-image     Create Docker image for building 32-bit Wine.
      --configure [OPTIONS]     Create Makefiles with configure script.
      --make [OPTIONS]          Run Makefiles.

END
}

function create_docker_image() {
    if [[ ! -e "$SCRIPT_AND_DOCKERFILE_LOCATION/Dockerfile" ]]; then
        cp "$SCRIPT_AND_DOCKERFILE_LOCATION/template-Dockerfile" "$SCRIPT_AND_DOCKERFILE_LOCATION/Dockerfile"
        CURRENT_UID=$(id -u $USER)
        CURRENT_GID=$(id -g $USER)
        sed -i "s/REPLACE-THIS-UID/$CURRENT_UID/" "$SCRIPT_AND_DOCKERFILE_LOCATION/Dockerfile"
        sed -i "s/REPLACE-THIS-GID/$CURRENT_GID/" "$SCRIPT_AND_DOCKERFILE_LOCATION/Dockerfile"
    fi
    docker build "--tag=$DOCKER_IMAGE_TAG" "$SCRIPT_AND_DOCKERFILE_LOCATION"
}

function cd_to_build_script_dir() {
    mkdir -p "$WINE_BUILD_SCRIPT_DIR"
    cd "$WINE_BUILD_SCRIPT_DIR"
}

function download_source_code() {
    cd_to_build_script_dir
    if [[ ! -e "$WINE_SOURCE_DIR_NAME" ]]; then
        git clone "$WINE_GIT_URL" "$WINE_SOURCE_DIR_NAME"
    fi
}

function configure_64_bit() {
    cd_to_build_script_dir
    mkdir -p "$WINE_BUILD_64_DIR_NAME"
    cd "$WINE_BUILD_64_DIR_NAME"
    "../$WINE_SOURCE_DIR_NAME/configure" --enable-win64 $*
}

function make_64_bit() {
    cd_to_build_script_dir
    cd "$WINE_BUILD_64_DIR_NAME"
    make $*
}

function configure_32_bit() {
    cd_to_build_script_dir
    mkdir -p "$WINE_BUILD_32_DIR_NAME"
    cd "$WINE_BUILD_32_DIR_NAME"
    "../$WINE_SOURCE_DIR_NAME/configure" $*
}

function make_32_bit() {
    cd_to_build_script_dir
    cd "$WINE_BUILD_32_DIR_NAME"
    make $*
}

function configure_final_build() {
    cd_to_build_script_dir
    mkdir -p "$WINE_BUILD_DIR_NAME"
    cd "$WINE_BUILD_DIR_NAME"
    "../$WINE_SOURCE_DIR_NAME/configure" "--with-wine64=../$WINE_BUILD_64_DIR_NAME" "--with-wine-tools=../$WINE_BUILD_32_DIR_NAME" $*
}

function make_final_build() {
    cd_to_build_script_dir
    cd "$WINE_BUILD_DIR_NAME"
    make $*
}

function main() {
    if [[ $# == 0 ]]; then
        print_help
        exit 0
    fi

    if [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
        print_help
        exit 0
    fi

    set -x

    while true; do
        case "$1" in
            --configure )
                shift
                if [[ $SCRIPT_DOCKER_MODE_ENABLED == 1 ]]; then
                    configure_32_bit $*
                    configure_final_build $*
                    exit 0
                fi
                configure_64_bit $*
                docker run -e "WINE_BUILD_SCRIPT_ARGS=--configure $*" --mount src="$WINE_BUILD_SCRIPT_DIR",target=/wine-build-script,type=bind "$DOCKER_IMAGE_TAG"
                exit 0
                ;;
            --make )
                shift
                if [[ $SCRIPT_DOCKER_MODE_ENABLED == 1 ]]; then
                    make_32_bit $*
                    make_final_build $*
                    exit 0
                fi
                make_64_bit $*
                docker run -e "WINE_BUILD_SCRIPT_ARGS=--make $*" --mount src="$WINE_BUILD_SCRIPT_DIR",target=/wine-build-script,type=bind "$DOCKER_IMAGE_TAG"
                exit 0
                ;;
            --create-docker-image )
                create_docker_image
                ;;
            --download-source-code )
                download_source_code
                ;;
            *)
                echo "Unknown option $1"
                exit 0
                ;;
        esac
        shift
        if [[ $# == 0 ]]; then
            exit 0
        fi
    done

}


main $*
