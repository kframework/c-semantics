FROM runtimeverificationinc/kframework:ubuntu-bionic

#####################
# Install packages. #
#####################

RUN   apt-get update -q     \
  &&  apt-get install --yes \
        libstdc++6          \
        llvm-6.0            \
        clang++-6.0         \
        clang-6.0           \
        clang-8             \
        libclang-8-dev      \
        llvm-8-tools        \
        lld-8               \
        zlib1g-dev          \
        bison               \
        flex                \
        libboost-test-dev   \
        libgmp-dev          \
        libmpfr-dev         \
        libyaml-dev         \
        libjemalloc-dev     \
        pkg-config

RUN    git clone 'https://github.com/z3prover/z3' --branch=z3-4.8.7 \
    && cd z3                                                        \
    && python scripts/mk_make.py                                    \
    && cd build                                                     \
    && make -j8                                                     \
    && make install                                                 \
    && cd ../..                                                     \
    && rm -rf z3

# This user is set up in the runtimeverificationinc/kframework:* images.
USER user:user

##################
# Perl packages. #
##################

COPY --from=runtimeverificationinc/perl:ubuntu-bionic \
     --chown=user:user \
     /home/user/perl5 \
     /home/user/perl5

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

# This is where the rest of the dependencies go.
ENV DEPS_DIR="/home/user/c-semantics-deps"
ENV PATH="${DEPS_DIR}/k/llvm-backend/src/main/native/llvm-backend/build/bin:${PATH}"
ENV K_BIN="${DEPS_DIR}/k/k-distribution/target/release/k/bin"

COPY --chown=user:user ./.build/k/ ${DEPS_DIR}/k

RUN cd ${DEPS_DIR}/k \
  && mvn package -e -q -U \
      -DskipTests -DskipKTest \
      -Dhaskell.backend.skip \
      -Dcheckstyle.skip \
      -Dproject.build.type=FastBuild

