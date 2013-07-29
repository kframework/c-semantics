#!/bin/bash

CIL_INTERMEDIATE_SRC=cil_tmp.c

cilly.asm.exe --printCilAsIs --commPrintLn --out $CIL_INTERMEDIATE_SRC $1
krun $CIL_INTERMEDIATE_SRC

