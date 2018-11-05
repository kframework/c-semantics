#!/bin/bash

function install() {
	sudo apt install -y "$@" < /dev/null
}



function platform_system_update() {
	sudo apt update -y < /dev/null
	sudo apt upgrade -y < /dev/null
}



function platform_install_k_dependencies() {
	install build-essential m4 openjdk-8-jdk libgmp-dev libmpfr-dev pkg-config flex z3 libz3-dev maven opam python3

}

function platform_install_ocaml() {
	# We use Ubuntu ocaml repo package because
	# otherwise we would need to build
	# ocaml twice: first the regular version
	# and then the patched one.
	
	install ocaml libffi-dev
}



function platform_install_c_semantics_dependencies() {
	install cmake diffutils bison zlib1g-dev

	install libuuid-tiny-perl libxml-libxml-perl libgetopt-declare-perl libstring-escape-perl libstring-shellquote-perl libapp-fatpacker-perl
}

