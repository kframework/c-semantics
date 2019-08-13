FROM runtimeverificationinc/ubuntu:bionic

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


# This user is set up in the runtimeverificationinc/ubuntu:* images.
USER user:user


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


# This is where the rest of the dependencies go.
ENV DEPS_DIR="/home/user/c-semantics-deps"


###################
# Configure opam. #
###################

COPY --from=runtimeverificationinc/ocaml:ubuntu-bionic \
     --chown=user:user \
     /home/user/.opam \
     /home/user/.opam

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
