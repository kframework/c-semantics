#!/bin/bash

eval $(opam config env)
eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
exec "$@"
