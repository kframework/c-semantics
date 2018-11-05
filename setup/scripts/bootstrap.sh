#!/bin/bash

set -e

source ~/settings.sh
source ~/platform.sh

function update_system() {
	echo "== Updating system"
	platform_system_update

}

function prepare_basics() {
	update_system
	mkdir -p $SW_DIR
}

function install_k_dependencies() {
	echo "== Installing K dependencies"
	platform_install_k_dependencies
}

function grab_k() {
	cd $SW_DIR
	if [[ ! -d "$K_PATH" ]]; then
		echo "Cloning K"
		git clone "$K_REPO" "$K_PATH"
	fi
	cd "$K_PATH"
	git pull
	git checkout "$K_BRANCH"

}

function install_k() {
	install_k_dependencies
	grab_k

	mvn package -Dmaven.test.skip=true
	cd
}

function install_ocaml() {
	echo "Installing OCaml"
	platform_install_ocaml
	echo "Configuring patched OCaml"
	$K_BIN/k-configure-opam-dev < /dev/null
}

function install_clang() {
	if [[ -d "$CLANG_PATH" ]]; then
		echo "Clang seem to be already installed"
		return
	fi

	echo "Installing Clang"

	# Grab some clang
	CLANG_STRING="clang+llvm-$CLANG_VERSION-x86_64-linux-gnu-ubuntu-16.04"
	wget -q "http://releases.llvm.org/$CLANG_VERSION/$CLANG_STRING.tar.xz"
	tar -xJf "$CLANG_STRING.tar.xz"
	mv "$CLANG_STRING" "$CLANG_PATH"

	# cleanup
	rm "$CLANG_STRING.tar.xz"
}

CGMEMTIME="$SW_DIR/cgmemtime/cgmemtime"
# We use cgmemtime to measure the memory consumption
# of the build process
function install_cgmemtime() {
	if [[ -d "$SW_DIR/cgmemtime" ]]; then
		echo "cgmemtime seem to be already installed"
		return
	fi
	pushd "$SW_DIR"
	git clone https://github.com/gsauthof/cgmemtime.git
	cd cgmemtime
	make
	popd
	sudo $CGMEMTIME --setup -g $(id -gn) --perm 775
}

function install_c_semantics_dependencies() {
	echo "Installing C-semantics dependencies"
	platform_install_c_semantics_dependencies
	install_clang
	install_cgmemtime
}

function grab_c_semantics() {

	if [[ ! -d "$HOME/c-semantics" ]]; then
		echo "Cloning c-semantics"
		git clone "$C_SEMANTICS_REPO" "$HOME/c-semantics"
	fi
	pushd "$HOME/c-semantics"
	git checkout "$C_SEMANTICS_BRANCH"
	popd
}

function build_c_semantics() {
	source "$HOME/env.sh"
	cd "$HOME/c-semantics"
	pushd clang-tools
		cmake -DCMAKE_CXX_FLAGS="-fno-rtti" -DLLVM_PATH="$CLANG_PATH" .
	popd
	$CGMEMTIME make
}

function main() {
	prepare_basics
	install_k
	install_ocaml
	install_c_semantics_dependencies
	grab_c_semantics
	build_c_semantics
}

LOGFILE="$HOME/log.txt"

function log() {
  "$@" 2>&1 | tee -a "$LOGFILE"
}

function provision() {
	log echo
	log echo
	log echo
	log echo "Running provisioning script"
	log date
	log echo
	log main
}

provision
