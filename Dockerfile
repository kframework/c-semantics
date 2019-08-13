FROM runtimeverificationinc/kframework:ubuntu-bionic

#####################
# Install packages. #
#####################

RUN     apt-get update -q \
    &&  apt install --yes \
          openjdk-8-jdk   \
          libstdc++6      \
          llvm-6.0

# TODO (Minas)
# We should not need jdk-8. The base image has jdk-11 installed.
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java


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


# This is where the rest of the dependencies go.
ENV DEPS_DIR="/home/user/c-semantics-deps"

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
