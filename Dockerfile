ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-bionic-${K_COMMIT}

#####################
# Install packages. #
#####################

RUN     apt-get update -q \
    &&  apt install --yes \
          libstdc++6      \
          llvm-6.0        \
          clang++-6.0     \
          clang-6.0

# This user is set up in the runtimeverificationinc/kframework:* images.
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g $GROUP_ID user && useradd -m -u $USER_ID -s /bin/sh -g user user

USER user:user
WORKDIR /home/user

COPY --chown=user:user .build/k/k-distribution/main/scripts/lib/opam ~/lib/opam
COPY --chown=user:user .build/k/k-distribution/main/scripts/bin      ~/bin

ENV OPAMROOT=/home/user/.opam
RUN ./bin/k-configure-opam-dev
