FROM ubuntu:bionic

# Environment.
ENV TZ="America/Chicago" \
    LOCALE="en_US.UTF-8" \
    DEPS_DIR="/home/user/c-semantics-deps"

# Timezone.
RUN ln --symbolic --no-dereference --force /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone


###########
# Locale. #
###########

RUN apt-get update -qq \
    && apt-get install --yes locales \
    && locale-gen --no-purge "${LOCALE}"

ENV LANG="${LOCALE}" \
    LC_ALL="${LOCALE}" \
    LANGUAGE="en_US:en"

RUN update-locale


#####################
# Install packages. #
#####################

RUN apt-get update -qq \
    \
    && apt install --yes                                                             \
        bison build-essential clang++-6.0 clang-6.0 cmake coreutils curl diffutils   \
        flex git libboost-test-dev libffi-dev libgmp-dev libjemalloc-dev libmpfr-dev \
        libstdc++6 libxml2 libyaml-cpp-dev llvm-6.0 m4 maven opam openjdk-8-jdk      \
        pkg-config python3 python-jinja2 python-pygments unifdef zlib1g-dev          \
        cpanminus

RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

##########################
# Set up a default user. #
##########################

RUN apt-get install --yes sudo

ARG UID=1000
ARG GID=1000

RUN addgroup --gid ${GID} user \
  && adduser --uid ${UID} \
             --gid ${GID} \
             --shell /bin/sh \
             --disabled-password \
             --gecos "" \
             user \
  && usermod -aG sudo user \
  && echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

USER ${UID}:${GID}


##################
# Perl packages. #
##################

RUN cpanm --local-lib=~/perl5 local::lib \
  && eval $(perl -I "~/perl5/lib/perl5/" -Mlocal::lib) \
  && cpanm -L ~/perl5 \
        App::FatPacker \
        Getopt::Declare \
        String::Escape \
        String::ShellQuote \
        UUID::Tiny


###################
# Configure opam. #
###################

# Copy the necessary things.
COPY --chown=user:user \
  .build/k/k-distribution/src/main/scripts/bin/k-configure-opam-dev \
  ${DEPS_DIR}/opam-config/bin/k-configure-opam-dev
COPY --chown=user:user \
  .build/k/k-distribution/src/main/scripts/bin/k-configure-opam-common \
  ${DEPS_DIR}/opam-config/bin/k-configure-opam-common
COPY --chown=user:user \
  .build/k/k-distribution/src/main/scripts/lib/opam \
  ${DEPS_DIR}/opam-config/lib/opam

# Run the scripts.
RUN ${DEPS_DIR}/opam-config/bin/k-configure-opam-dev


############
# Build K. #
############

COPY --chown=user:user ./.build/k/ ${DEPS_DIR}/k

RUN cd ${DEPS_DIR}/k \
  && mvn package -q -U \
      -DskipTests -DskipKTest \
      -Dhaskell.backend.skip -Dllvm.backend.skip \
      -Dcheckstyle.skip

ENV K_BIN="${DEPS_DIR}/k/k-distribution/target/release/k/bin"
