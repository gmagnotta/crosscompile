#!/usr/bin/env bash
#
# This script emulates an s2i build process performed exclusively with buildah.
# Currently only builder images are supported.
#
# Version 0.0.4
#
set -e

BUILDER_IMAGE="quay.io/gmagnotta/crosscompiler"
ASSEMBLE_USER="nobody"
SCRIPTS_URL="/usr/local/s2i/"
OUTPUT_IMAGE="testnative"
INCREMENTAL=false
CONTEXT_DIR="."
RUNTIME_ARTIFACT="/deployments"
RUNTIME_IMAGE="debian:stable-slim"

echo "Start"
builder=$(buildah from $BUILDER_IMAGE)

buildah add --chown $ASSEMBLE_USER:0 $builder ./$CONTEXT_DIR /tmp/src

if [ "$INCREMENTAL" = "true" ]; then

    if [ -f "./artifacts.tar" ]; then
        echo "Restoring artifacts"
        buildah add --chown $ASSEMBLE_USER:0 $builder ./artifacts.tar /tmp/artifacts
    fi

fi

ENV=""
if [ -f "$CONTEXT_DIR/.s2i/environment" ]; then

    while IFS="" read -r line
    do
      [[ "$line" =~ ^#.*$ ]] && continue
      ENV+="-e $line "
    done < $CONTEXT_DIR/.s2i/environment

    echo "ENV is $ENV"

fi

if [ -x "$CONTEXT_DIR/.s2i/bin/assemble" ]; then
    echo "Using assemble from .s2i"
    eval buildah run $ENV $builder -- /tmp/src/.s2i/bin/assemble
else
    echo "Using assemble from image"
    eval buildah run $ENV $builder -- $SCRIPTS_URL/assemble
fi

if [ "$INCREMENTAL" = "true" ]; then

    echo "Saving artifacts"
    if [ -f "./artifacts.tar" ]; then
        rm ./artifacts.tar
    fi

    buildah run $builder -- /bin/bash -c "if [ -x \"$SCRIPTS_URL/save-artifacts\" ]; then $SCRIPTS_URL/save-artifacts ; fi" > ./artifacts.tar

fi

if [ ! -z "$RUNTIME_IMAGE" ]; then
    echo "Creating Runtime Image"
    runner=$(buildah from --arch arm --variant v5 $RUNTIME_IMAGE)
    buildah copy --chown $ASSEMBLE_USER:0 --from $builder $runner $RUNTIME_ARTIFACT $RUNTIME_ARTIFACT
    buildah config --workingdir /deployments $runner
    buildah config --entrypoint '["./hello"]' $runner
    buildah config --cmd '[]' $runner
    buildah commit $runner $OUTPUT_IMAGE
    buildah rm $runner
else
    echo "Not creating runtime image"
    buildah config --cmd $SCRIPTS_URL/run $builder
    buildah commit $builder $OUTPUT_IMAGE
fi

buildah rm $builder
