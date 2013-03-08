# gcc dies on this 20080529-1.c

# use standard functions instead of builtins
mkdir -p notportable
mkdir -p hosted
mkdir -p easilyFixed
mkdir -p brokenDynamically

mkdir -p badPointers
mkdir -p badMemory
mkdir -p badArithmetic

echo "Patching declared types and return values..."
patch -p1 < returnValues.patch
patch -p1 < argTypes.patch


# fixing 921110-1.c
sed -i 's/typedef int (\*frob)()/typedef void (\*frob)(void)/g' 921110-1.c
# fixing pr34176.c
sed -i 's/static count = 0/static int count = 0/g' pr34176.c


echo "Fixing restrict..."
sed -i 's/__restrict__/restrict/g' *.c

echo "Fixing size_t..."
# replace __SIZE_TYPE__ with size_t
sed -i 's/__SIZE_TYPE__/size_t/g' *.c
for f in `grep -L 'wchar\.h\|uchar\.h\|time\.h\|string\.h\|stdio\.h\|stddef\.h\|stdlib\.h' \`grep -l 'size_t' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stddef.h>'
done
# remove typedefs of size_t that referred to __SIZE_TYPE__
sed -i 's/typedef[ ]\+size_t[ ]\+size_t/\/\//g' *.c

echo "Fixing wchar_t..."
sed -i 's/__WCHAR_TYPE__/wchar_t/g' *.c
for f in `grep -L 'wchar\.h\|stddef\.h\|stdlib\.h' \`grep -l 'wchar_t' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stddef.h>'
done
# remove typedefs of wchar_t that referred to __WCHAR_TYPE__
sed -i 's/typedef[ ]\+wchar_t[ ]\+wchar_t/\/\//g' *.c

echo "Moving nonstandard builtins..."
# remove nonstandard builtins
mv `grep -l '__builtin_[^a][^b][^o]' *.c` notportable/

echo "Moving programs that use assembly..."
# remove assembly code
mv `grep -l 'asm' *.c` notportable/

echo "Moving programs that use complex numbers..."
# remove complex numbers
mv `grep -l '_Complex' *.c` notportable/
mv `grep -l '__complex' *.c` notportable/

echo "Moving programs that use alloca..."
# remove calls to alloca
mv `grep -l 'alloca[ (]' *.c` notportable/

echo "Moving other builtin commands..."
# remove other builtin commands
mv `grep -l '__fprintf' *.c` notportable/
mv `grep -l '__printf' *.c` notportable/
mv `grep -l '__vprintf' *.c` notportable/
mv `grep -l '__vfprintf' *.c` notportable/

echo "Moving __label__ variables..."
mv `grep -l '__label__' *.c` notportable/

echo "Moving typeof operators..."
mv `grep -l 'typeof' *.c` notportable/

echo "Moving use of non portable headers..."
mv `grep -l 'sys/' *.c` notportable/

echo "Moving use of mode attribute..."
mv `grep -l 'mode[ ]*(' *.c` notportable/

echo "Moving necessary use of aligned attribute..."
mv 20010904-1.c 20010904-2.c notportable/

echo "Moving programs that use vectors..."
mv `grep -l 'vector_size' *.c` notportable/



echo "Fixing main types..."
# fix main types
# sed -i 's/main[ ]*()/main(void)/' *.c # adds void to prototype
sed -i 's/void[ ]*main/int main/' *.c # replaces void with int on same line
for f in *.c; do
	# replaces void or int on different lines with int on same line
	sed -n '1h;1!H;${;g;s/\(int\|void\)[ ]*\nmain/int main/g;p;}' $f > $f.tmp
	mv -f $f.tmp $f
done
sed -i 's/^main/int main/' *.c # returns int when line starts with main
sed -i 's/int[ ]\+main[ ]\+(int[ ]\+argc)/int main(void)/' *.c
sed -i 's/}main(/}int main(/' *.c


echo "Fixing standard library..."
## stdlib.h
# abort
sed -i 's/__builtin_abort/abort/g' *.c
sed -i 's/int[ ]\+abort[ ]*()/void abort(void)/g' *.c
sed -i 's/int[ ]\+abort[ ]*(/void abort(/g' *.c

for f in `grep -L 'void[ ]\+abort\|stdlib\.h' *.c`; do
	../../scripts/insert.sh 1 $f '#include <stdlib.h>'
done
# exit
sed -i 's/__builtin_exit/exit/g' *.c
sed -i 's/void[ ]\+exit[ ]*()/void exit(int)/g' *.c
for f in `grep -L 'void[ ]\+exit\|stdlib\.h' *.c`; do
	../../scripts/insert.sh 1 $f '#include <stdlib.h>'
done
# malloc
sed -i 's/__builtin_malloc/malloc/g' *.c
for f in `grep -L 'void[ ]*\*[ ]*malloc\|stdlib\.h' \`grep -l 'malloc' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stdlib.h>'
done

## stdio.h
# printf
for f in `grep -L 'int[ ]*printf\|stdio\.h' \`grep -l 'printf' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stdio.h>'
done

## ctype.h
# isprint
for f in `grep -L 'int[ ]*isprint\|ctype\.h' \`grep -l 'isprint' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <ctype.h>'
done

## string.h
# memcpy
sed -i 's/__builtin_memcpy/memcpy/g' *.c
for f in `grep -L 'void[ ]*\*[ ]*memcpy\|string\.h' \`grep -l 'memcpy' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <string.h>'
done
for f in `grep -L 'void[ ]*\*[ ]*memset\|string\.h' \`grep -l 'memset' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <string.h>'
done
# memcmp
sed -i 's/__builtin_memcmp/memcmp/g' *.c
for f in `grep -L 'int[ ]*memcmp\|string\.h' \`grep -l 'memcmp' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <string.h>'
done
sed -i 's/__builtin_strlen/strlen/g' *.c
for f in `grep -L 'size_t[ ]*strlen\|string\.h' \`grep -l 'strlen' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <string.h>'
done
sed -i 's/__builtin_strcpy/strcpy/g' *.c
for f in `grep -L 'char[ ]*\*[ ]*strcpy\|string\.h' \`grep -l 'strcpy' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <string.h>'
done
sed -i 's/__builtin_strcmp/strcmp/g' *.c
for f in `grep -L 'int[ ]*strcmp\|string\.h' \`grep -l 'strcmp' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <string.h>'
done

## stdarg.h
sed -i 's/__builtin_va_arg/va_arg/g' *.c
for f in `grep -L 'stdarg\.h' \`grep -l 'va_arg' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stdarg.h>'
done
sed -i 's/__builtin_va_start/va_start/g' *.c
for f in `grep -L 'stdarg\.h' \`grep -l 'va_start' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stdarg.h>'
done
sed -i 's/__builtin_va_list/va_list/g' *.c
for f in `grep -L 'stdarg\.h' \`grep -l 'va_list' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stdarg.h>'
done

## math.h
sed -i 's/__builtin_abs/abs/g' *.c
for f in `grep -L 'int[ ]*abs\|math\.h' \`grep -l 'abs[ ]*(' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <math.h>'
done

## stddef.h
sed -i 's/__builtin_offsetof/offsetof/g' *.c
for f in `grep -L 'stddef\.h' \`grep -l 'offsetof' *.c\``; do
	../../scripts/insert.sh 1 $f '#include <stddef.h>'
done


# assumes things about arguments, even though sig is not right
mv 921208-2.c 20051012-1.c notportable/

# extension: gnu statement expressions
mv 20000917-1.c 20001203-2.c 20020206-1.c 20020320-1.c compndlit-1.c 950906-1.c notportable/
# extension: flexible array initialization
mv 20010924-1.c pr33382.c 20030109-1.c notportable/
# extension: case range
mv pr34154.c notportable/
# extension: zero size arrays
mv pr42570.c zero-struct-1.c zero-struct-2.c zerolen-1.c 920728-1.c 20050613-1.c 20051113-1.c notportable/
# extension: size zero struct
mv 20000801-3.c pr23324.c notportable/
# extension: named variadic macros
mv printf-1.c fprintf-1.c notportable/
# extension: nested functions
mv 20000822-1.c 20010209-1.c 20010605-1.c 20030501-1.c 20040520-1.c 20090219-1.c 920612-2.c 921017-1.c 921215-1.c 931002-1.c nest-align-1.c nestfunc-1.c nestfunc-2.c nestfunc-7.c pr22061-3.c pr22061-4.c nestfunc-3.c nest-stdar-1.c notportable/
# extension: dynamic gotos; address of label
mv 920501-3.c 920501-5.c 990208-1.c comp-goto-1.c 20040302-1.c 20071210-1.c 920302-1.c 920501-4.c notportable/
# extension: forward reference to enum
mv 930408-1.c notportable/
# extension: anonymous structs
mv anon-1.c 20030714-1.c notportable/
# extension: adding void*s
mv pr17133.c pr21173.c badPointers/
# extension: variable length field
mv 20040308-1.c 20040423-1.c 20041218-2.c 20070919-1.c notportable/
# extension: void function can't return void expression
mv 20000314-3.c notportable/
# extension: use of implicit pointer casting
mv 20041212-1.c notportable/
# extension: can't cast to union type
mv 960416-1.c notportable/
# extension: empty initializer
mv pr19687.c pr28982b.c notportable/
# extension: integer to pointer conversion
mv 20001111-1.c notportable/
# gnustyle field designators
mv 991228-1.c struct-ini-4.c notportable/
# implementation defined wide chars
mv wchar_t-1.c notportable/
# seems to be doing some kind of instrumentation
mv eeprof-1.c notportable/

# duplicate definition of library function
mv 20021127-1.c notportable/

# identifier appears with both internal and external linkage
mv pr42614.c notportable/

# c1x specific
mv 20000223-1.c align-3.c notportable/

# cast pointers to ints and then do weird stuff
mv 930930-1.c 941014-1.c loop-2c.c loop-2d.c pr22098-1.c pr22098-2.c pr22098-3.c pr36339.c notportable/

# use of less common hosted functions
mv vfprintf-1.c vprintf-1.c 20030626-1.c 20030626-2.c 20070201-1.c pr34456.c string-opt-18.c 920501-8.c 920501-9.c 920726-1.c 930513-1.c 960327-1.c struct-ret-1.c strncmp-1.c 980605-1.c hosted/

# nonportable syntax (extra semicolon outside function)
mv 20050106-1.c notportable/

# extension: push/pop macro pragma
mv pushpop_macro.c notportable/

# these assume floats that are more accurate than the standard requires
# i'm not sure about this
# mv 20031003-1.c notportable/

# implementation-defined bitfield types
mv 20081117-1.c 930126-1.c 960608-1.c 991118-1.c bf64-1.c bf-pack-1.c bf-sign-2.c bitfld-3.c pr31448-2.c pr32244-1.c pr34099.c pr34971.c pr37882.c brokenDynamically/

# assuming things about representation of floats, or uses floats as other types
mv 20071030-1.c 930930-2.c stdarg-3.c pr42691.c brokenDynamically/

# assuming things about representation of pointers
mv 980716-1.c 920428-1.c pr17252.c brokenDynamically/

# comparing/subtracting incomparable pointers
mv 950710-1.c 980701-1.c brokenDynamically/

# bad locations
mv 20021010-2.c 20041112-1.c 20050125-1.c 960116-1.c loop-2e.c pr34176.c pr39233.c ptr-arith-1.c 941014-2.c 20000622-1.c 20000910-1.c 20001101.c 20010329-1.c 940115-1.c loop-15.c pr44555.c badPointers/

# caught by ubc
mv 980526-2.c badPointers/

# uninitialized
mv 20030404-1.c pr34099-2.c 921202-1.c 20100430-1.c va-arg-14.c pr43629.c pr40493.c 930719-1.c badMemory/

# arithmetic/bit on pointers
mv pr23467.c 20050215-1.c brokenDynamically/

# caught by valgrind
# 20030404-1.c 
# 921202-1.c
# 941014-2.c
# pr34099-2.c

# caught by our tool and by ubc

# left shift, bad result
mv 20020508-2.c badArithmetic/
mv 20060110-1.c badArithmetic/
mv 20060110-2.c badArithmetic/
mv pr7284-1.c badArithmetic/

# left shift, negative
mv 20020508-3.c badArithmetic/
mv 960317-1.c badArithmetic/
mv pr40386.c badArithmetic/

# signed overflow
mv 20030316-1.c badArithmetic/
mv 20040409-1.c badArithmetic/
mv 20040409-2.c badArithmetic/
mv 20040409-3.c badArithmetic/
mv 920612-1.c badArithmetic/
mv 920711-1.c badArithmetic/
mv 920730-1.c badArithmetic/
mv 930529-1.c badArithmetic/
mv 950704-1.c badArithmetic/
mv loop-3b.c badArithmetic/
mv loop-3.c badArithmetic/
mv pr22493-1.c badArithmetic/
mv pr23047.c badArithmetic/

# unsure
mv arith-rand.c badArithmetic/
mv arith-rand-ll.c badArithmetic/

# these aren't bad, i just know I fail them
# mkdir -p fails
# mv 970217-1.c 20031003-1.c 20040811-1.c 20040208-1.c 20040208-2.c pr22061-2.c fails/
# mv fails/


# # 34 slow
# mkdir -p passesButSlow
# # really slow, > 5 hrs
# # 7
# mv pr43220.c memcpy-2.c 960521-1.c strcpy-1.c 20011008-3.c passesButSlow/
# mv memcpy-1.c strcmp-1.c passesButSlow/
# # really slow, 15m--5hr
# # 4
# mv 20050224-1.c 920501-6.c 961017-2.c memset-1.c passesButSlow/
# # slow, 2m--15m
# # 10
# mv 20030209-1.c 20031012-1.c 920501-2.c 930921-1.c 950221-1.c passesButSlow/
# mv memcpy-bi.c memset-2.c memset-3.c pr20621-1.c strlen-1.c passesButSlow/

# # tier 1
# # less slow, 30s--2m
# # 17
# mv 20040629-1.c 20040705-1.c 20040705-2.c 20041011-1.c 20050826-1.c passesButSlow/
# mv 931018-1.c 990513-1.c 990628-1.c ashrdi-1.c cmpdi-1.c passesButSlow/
# mv divcmp-3.c nestfunc-4.c p18298.c pr19005.c pr20601-1.c passesButSlow/
# mv pr36093.c va-arg-10.c passesButSlow/
# # kind of slow, 15s--30s
# # 13
# mv 20000605-1.c 20030916-1.c 20060905-1.c 20071219-1.c 930614-2.c passesButSlow/
# mv ashldi-1.c loop-ivopts-2.c lshrdi-1.c pr27260.c loop-11.c passesButSlow/
# mv string-opt-5.c va-arg-2.c va-arg-9.c passesButSlow/
# # kind of slow, 10s--15s
# # 3
# mv va-arg-24.c mode-dependent-address.c 20021120-1.c passesButSlow/
# # barely slow, 5s--10s  
# # 32
# mv 20000224-1.c 20000412-2.c 20000422-1.c 20020402-2.c 20020406-1.c passesButSlow/
# mv 20020506-1.c stdarg-4.c 20040313-1.c 20050502-1.c 20050826-2.c passesButSlow/
# mv 20060412-1.c 20071029-1.c 20080424-1.c 930628-1.c 950612-1.c passesButSlow/
# mv 951204-1.c 980506-3.c 980707-1.c 990128-1.c 990326-1.c passesButSlow/
# mv 990404-1.c 991201-1.c 991216-2.c conversion.c divcmp-1.c passesButSlow/
# mv pr28982a.c switch-1.c pr35472.c pr35800.c pr36034-1.c passesButSlow/
# mv pr36034-2.c pr42512.c passesButSlow/

rm *.bak