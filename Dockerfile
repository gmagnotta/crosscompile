# Step 1: build a temporary image that will download official Arm GNU Toolchain from https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads
FROM registry.access.redhat.com/ubi8/ubi as temporary

WORKDIR /tmp

RUN yum install -y xz.x86_64 && \
    curl https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/11.2-2022.02/binrel/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz -o /tmp/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz  && \
    xzcat /tmp/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz | tar xvf -

# Step 2: create the final cross-compile image
FROM registry.access.redhat.com/ubi8/ubi

COPY --from=temporary /tmp/gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf/ /opt/

ENV PATH="${PATH}:/opt/bin"
