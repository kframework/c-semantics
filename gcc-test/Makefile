KCC ?= "./dist/kcc"
GCC ?= "gcc -w -m32 -O0 -U __GNUC__ -std=c99"
GCCO3 ?= "gcc -w -m32 -O3 -U __GNUC__ -std=c99"
GCC34 ?= "gcc34 -w -m32 -O0 -U __GNUC__ -std=c99"
ICC ?= "icc -w -m32 -O0 -U __GNUC__ -std=c99"
# CLANG ?= "clang -Wno-tautological-compare -Wno-unused-value -Wno-format-extra-args -Wno-pointer-sign -Wno-switch -Wno-format -Wno-empty-body -m32 -O0 -U __GNUC__ -pedantic -std=c99"
CLANG ?= "clang -fno-color-diagnostics -w -m32 -O0 -U __GNUC__ -std=c99"
CILCC ?= "./cilcc.sh"
COMPCERT ?= "ccomp -fbitfields -flonglong -fstruct-passing -fstruct-assign -U __GNUC__"


RUNTEST = runtest --tool=gcc
KCC_FLAGS = --outdir results/out.kcc --tool_exec $(KCC)
GCC_FLAGS = --outdir results/out.gcc --tool_exec $(GCC)
GCCO3_FLAGS = --outdir results/out.gcco3 --tool_exec $(GCCO3)
GCC34_FLAGS = --outdir results/out.gcc34 --tool_exec $(GCC34)
ICC_FLAGS = --outdir results/out.icc --tool_exec $(ICC)
CLANG_FLAGS = --outdir results/out.clang --tool_exec $(CLANG)
CIL_FLAGS = --outdir results/out.cilcc --tool_exec $(CILCC)
COMPCERT_FLAGS = --outdir results/out.compcert --tool_exec $(COMPCERT)

.PHONY: all prepare default gcc34 clean gcc icc kcc cilcc clang compcert

all: kcc

prepare:
	cp -R ../dist .

default: prepare
	
gcc: default
	@mkdir -p results/out.gcc
	@-$(RUNTEST) gcc.all/execute.exp $(GCC_FLAGS)
# echo "test,tool,phase,status,timeout" > gcc.full.csv
	@cat results/out.gcc/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\):/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,gcc,\3,\1,/p' > gcc.full.csv
# =COUNTIF(D2:D2;"PASS")
gcco3: default
	@mkdir -p results/out.gcc
	@-$(RUNTEST) gcc.all/execute.exp $(GCCO3_FLAGS)
#echo "test,tool,phase,status,timeout" > gcc.full.csv
	@cat results/out.gcco3/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\):/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,gcco3,\3,\1/p' > gcco3.full.csv
compcert: default
	@mkdir -p results/out.compcert
	@-$(RUNTEST) gcc.all/execute.exp $(COMPCERT_FLAGS)
	@cat results/out.compcert/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\):/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,compcert,\3,\1/p' > compcert.full.csv
gcc34: default
	@mkdir -p results/out.gcc34	
	@-$(RUNTEST) gcc.all/execute.exp $(GCC34_FLAGS)
	@cat results/out.gcc34/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\):/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,gcc34,\3,\1/p' > gcc34.full.csv
icc: default
	@mkdir -p results/out.icc
	@-$(RUNTEST) gcc.all/execute.exp $(ICC_FLAGS)
	@cat results/out.icc/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\):/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,icc,\3,\1/p' > icc.full.csv
cilcc: default
	@mkdir -p results/out.cilcc
	@-$(RUNTEST) gcc.all/execute.exp $(CIL_FLAGS)
	@cat results/out.cilcc/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\):/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,cilcc,\3,\1/p' > cilcc.full.csv
clang: default
	@mkdir -p results/out.clang
	@-$(RUNTEST) gcc.all/execute.exp $(CLANG_FLAGS)
	@cat results/out.clang/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\),:/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,clang,\3,\1/p' > clang.full.csv
kcc: default
	@mkdir -p results/out.kcc
	@-$(RUNTEST) gcc.all/execute.exp $(KCC_FLAGS)
	@cat results/out.kcc/gcc.sum | sed -n 's/^\(.*\):/\1,:/p' | sed '/timed out\./{N;s/WARNING: program timed out\.\n\(.*\),:/\1,TIMEOUT:/}' | sed -n 's/^\(.*\): gcc\..*\/\(.*\) \(.*\),/\2,kcc,\3,\1/p' > kcc.full.csv
	
spreadsheet:
# sed "1 d;$$ d" kcc.fast.csv > kcc.fast.csv.tmp
# sed "1 d;$$ d" kcc.slow.csv > kcc.slow.csv.tmp
# sed "1 d;$$ d" kcc.superSlow.csv > kcc.superSlow.csv.tmp
	cat kcc.fast.csv kcc.slow.csv kcc.superSlow.csv > kcc.full.csv.tmp
	echo "test,tool,phase,status,timeout" > kcc.full.out
	sort -t , -k 1,1 -k 3,3 kcc.full.csv.tmp >> kcc.full.out
	echo "test,tool,phase,status,timeout" > gcc.full.out
	sort -t , -k 1,1 -k 3,3 gcc.full.csv >> gcc.full.out
	echo "test,tool,phase,status,timeout" > gcc34.full.out
	sort -t , -k 1,1 -k 3,3 gcc34.full.csv >> gcc34.full.out
	echo "test,tool,phase,status,timeout" > icc.full.out
	sort -t , -k 1,1 -k 3,3 icc.full.csv >> icc.full.out
	echo "test,tool,phase,status,timeout" > cilcc.full.out
	sort -t , -k 1,1 -k 3,3 cilcc.full.csv >> cilcc.full.out
	paste -d, gcc.full.out gcc34.full.out icc.full.out cilcc.full.out kcc.full.out > output.csv
	
clean:
	rm -f kcompile_* compilation.log gcc.log gcc.sum *.pre.gen a.out *.maude.tmp *-gen.maude *.prepre.gen *.gen.maude *-compiled.maude *.warnings.log
