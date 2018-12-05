#!/bin/bash

grep -h '^module ' "$@" | cut -d' ' -f2 | sort
