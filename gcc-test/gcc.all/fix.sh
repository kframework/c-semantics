# use standard functions instead of builtins
mkdir -p notportable
mkdir -p hosted
mkdir -p easilyFixed
# mkdir -p defaultType
mkdir -p oldstyle
mkdir -p unclear
# mkdir -p stillBroken
# mkdir -p assumes
mkdir -p brokenDynamically

echo "Patching declared types and return values..."
patch -p1 < returnValues.patch

# i am not sure whether these are alright or not
mv 920603-1.c 920501-1.c 920731-1.c 920612-1.c 920909-1.c 920721-3.c 921208-2.c 930513-2.c 930526-1.c 930529-1.c 930622-1.c 931228-1.c 960218-1.c 961112-1.c inst-check.c int-compare.c loop-2.c loop-3.c loop-3b.c loop-3c.c mod-1.c 921124-1.c unclear/

# uses oldstyle function declarations
mv 930429-2.c 930719-1.c 950512-1.c 951003-1.c 980605-1.c oldstyle/

# assumes things about arguments, even though sig is not right
mv 20051012-1.c notportable/

# extension: gnu statement expressions
mv 20000917-1.c 20001203-2.c 20020206-1.c 20020320-1.c 930406-1.c compndlit-1.c 950906-1.c notportable/
# extension: flexible array initialization
mv 20010924-1.c pr33382.c 20030109-1.c notportable/
# extension: case range
mv pr34154.c notportable/
# extension: zero size arrays
mv pr42570.c va-arg-22.c zero-struct-1.c zero-struct-2.c zerolen-1.c zerolen-2.c 920728-1.c 20050613-1.c 20051113-1.c notportable/
# extension: size zero struct
mv 20000801-3.c pr23324.c 20071120-1.c notportable/
# extension: named variadic macros
mv printf-1.c printf-chk-1.c fprintf-1.c notportable/
# extension: nested functions
mv 20000822-1.c 20010209-1.c 20010605-1.c 20030501-1.c 20040520-1.c 20090219-1.c 920612-2.c 921017-1.c 921215-1.c 931002-1.c nest-align-1.c nestfunc-1.c nestfunc-2.c nestfunc-7.c pr22061-3.c pr22061-4.c nestfunc-3.c nest-stdar-1.c notportable/
# extension: dynamic gotos; address of label
mv 920428-2.c 920501-3.c 920501-5.c 990208-1.c comp-goto-1.c 20040302-1.c 20071210-1.c 920302-1.c 920501-4.c notportable/
# extension: forward reference to enum
mv 930408-1.c notportable/
# extension: anonymous structs
mv anon-1.c 20030714-1.c notportable/
# extension: adding void*s
mv pr17133.c pr21173.c notportable/
# extension: variable length field
mv pr41935.c 20040308-1.c 20040423-1.c 20041218-2.c 20070919-1.c notportable/
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

# duplicate definition of library function
mv 20021127-1.c notportable

# c1x specific
mv 20000223-1.c align-3.c notportable/

# cast pointers to ints and then do weird stuff
mv 930930-1.c 941014-1.c loop-2c.c loop-2d.c pr15296.c pr22098-1.c pr22098-2.c pr22098-3.c pr36339.c notportable/

# use of less common hosted functions
mv vfprintf-1.c vprintf-1.c 20030626-1.c 20030626-2.c 20070201-1.c pr34456.c string-opt-18.c 920501-8.c 920501-9.c 920726-1.c 930513-1.c 960327-1.c struct-ret-1.c strncmp-1.c hosted/

# nonportable syntax (extra semicolon outside function)
mv 20050106-1.c notportable/


# fixing 921110-1.c
sed -i 's/typedef int (\*frob)()/typedef void (\*frob)(void)/g' 921110-1.c
# fixing pr34176.c
sed -i 's/static count = 0/static int count = 0/g' pr34176.c

# move tests that are undefined for non-statically found things, like overflow
mv 20000622-1.c 20000910-1.c 20001101.c 20010329-1.c 20020508-2.c 20020508-3.c 20010904-1.c 20010904-2.c 20050215-1.c 20071030-1.c 20081117-1.c 920428-1.c 921202-1.c 930126-1.c 930930-2.c 940115-1.c 950704-1.c 950710-1.c 960608-1.c 980526-2.c 980701-1.c 980716-1.c 991118-1.c arith-rand.c arith-rand-ll.c bf64-1.c bf-pack-1.c bf-sign-2.c bitfld-3.c loop-15.c pr17252.c pr22493-1.c pr23047.c pr28289.c pr31448-2.c pr32244-1.c pr34099-2.c pr34099.c pr34971.c pr37882.c pr40386.c pr40493.c pr42691.c pr43629.c pr44555.c stdarg-3.c va-arg-14.c brokenDynamically/

# bad locations
mv 20021010-2.c 20041112-1.c 20050125-1.c 960116-1.c loop-2e.c pr34176.c pr39233.c ptr-arith-1.c 941014-2.c brokenDynamically/

# overflow
mv 20030316-1.c 20040409-1.c 20040409-2.c 20040409-3.c 20060110-1.c 20060110-2.c 920711-1.c 920730-1.c 960317-1.c brokenDynamically/

# uninitialized
mv 20030404-1.c 20100430-1.c brokenDynamically/

# arithmetic on pointers
mv pr23467.c brokenDynamically/



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

echo "Moving alignof operators..."
mv `grep -l 'alignof' *.c` notportable/

echo "Moving va_arg_pack operators..."
mv `grep -l 'va_arg_pack' *.c` notportable/

echo "Moving use of non portable headers..."
mv `grep -l 'sys/' *.c` notportable/

echo "Moving use of mode attribute..."
mv `grep -l 'mode[ ]*(' *.c` notportable/

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
sed -i 's/int[ ]\+abort()/void abort(void)/g' *.c
sed -i 's/int[ ]\+abort(/void abort(/g' *.c

for f in `grep -L 'void[ ]\+abort\|stdlib\.h' *.c`; do
	../../scripts/insert.sh 1 $f '#include <stdlib.h>'
done
# exit
sed -i 's/__builtin_exit/exit/g' *.c
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

# these aren't bad, just moving them out of the way for my testing
mkdir -p superSlow
mv 20011008-3.c memcpy-1.c memcpy-2.c pr43220.c strcmp-1.c strcpy-1.c superSlow/
# these aren't bad, i just know I fail them
mkdir -p shouldPass
mv 20010325-1.c 921110-1.c 970214-2.c struct-cpy-1.c widechar-1.c 970214-1.c 970217-1.c pr42614.c wchar_t-1.c widechar-2.c shouldPass/


rm *.bak