FROM ubuntu:bionic

ENV TZ=America/Chicago
RUN    ln --symbolic --no-dereference --force /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN apt update && apt upgrade --yes

RUN apt install --yes                                                                \
        bison build-essential clang++-6.0 clang-6.0 cmake coreutils curl diffutils   \
        flex git libboost-test-dev libffi-dev libgmp-dev libjemalloc-dev libmpfr-dev \
        libstdc++6 libxml2 libyaml-cpp-dev llvm-6.0 m4 maven opam openjdk-8-jdk      \
        pkg-config python3 python-jinja2 python-pygments unifdef zlib1g-dev

RUN apt install --yes locales

RUN locale-gen --no-purge en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

RUN cpan install App::FatPacker Getopt::Declare String::Escape String::ShellQuote UUID::Tiny

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN    groupadd -g $GROUP_ID user                     \
    && useradd -m -u $USER_ID -s /bin/sh -g user user

USER $USER_ID:$GROUP_ID


###################
# Configure opam. #
###################

ARG K_OPAM_DIR=/home/user/opam-config

# Copy the necessary things.
COPY --chown=user:user \
  .build/k/k-distribution/src/main/scripts/bin/k-configure-opam-dev \
  ${K_OPAM_DIR}/bin/k-configure-opam-dev
COPY --chown=user:user \
  .build/k/k-distribution/src/main/scripts/bin/k-configure-opam-common \
  ${K_OPAM_DIR}/bin/k-configure-opam-common
COPY --chown=user:user \
  .build/k/k-distribution/src/main/scripts/lib/opam \
  ${K_OPAM_DIR}/lib/opam

# Run the scripts.
RUN ${K_OPAM_DIR}/bin/k-configure-opam-dev


############
# Build K. #
############

ARG K_BUILD_DIR=/home/user/k-build

COPY --chown=user:user ./.build/k/ ${K_BUILD_DIR}/

RUN cd ${K_BUILD_DIR} \
  && mvn package -q -U \
      -DskipTests -DskipKTest \
      -Dhaskell.backend.skip -Dllvm.backend.skip \
      -Dcheckstyle.skip

ENV K_BIN="${K_BUILD_DIR}/k-distribution/target/release/k/bin"
