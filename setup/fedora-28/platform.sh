#!/bin/bash

function install() {
	sudo dnf install -y "$@" < /dev/null
}



function platform_system_update() {
	sudo dnf update -y < /dev/null
}



function platform_install_k_dependencies() {
	install libxml2-devel mpfr-devel gmp-devel java-1.8.0-openjdk z3 z3-devel flex maven opam python3 libffi-devel

}

function platform_install_ocaml() {
	# We use Fedora ocaml repo because
	# otherwise we would need to build
	# ocaml twice: first the regular version
	# and then the patched one.
	
	install ocaml
}



function platform_install_c_semantics_dependencies() {
	install bison

	install perl-libxml-perl perl-String-Escape perl-String-ShellQuote perl-App-FatPacker perl-UUID-Tiny perl-XML-LibXML perl-Log-Log4perl

	# Getopt::Declare is not present in Fedora
	sudo cpan -i Getopt::Declare < /dev/null
}

