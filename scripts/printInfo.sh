let TOTAL_RULES=0
let TOTAL_EQUATIONS=0
let TOTAL_LINES=0
let NUM_RULES=0
let NUM_EQUATIONS=0
let NUM_LINES=0

function stats {
	FILENAME1=$1
	FILENAME2=$2
	
	printf "%35s %35s\n" "$FILENAME1" "$FILENAME2"
	
	let NUM_RULES1=`cat $FILENAME1 | perl maudeloc.pl | grep ": rule\|^mb rule" | wc -l`
	let NUM_EQUATIONS1=`cat $FILENAME1 | perl maudeloc.pl | grep "^eq \|^ceq " | wc -l`
	let NUM_LINES1=`cat $FILENAME1 | perl maudeloc.pl | grep -v "^mb rule$\|^endm$" | wc -l`
	let TOTAL_RULES=$TOTAL_RULES+$NUM_RULES1
	let TOTAL_EQUATIONS=$TOTAL_EQUATIONS+$NUM_EQUATIONS1
	let TOTAL_LINES=$TOTAL_LINES+$NUM_LINES1
	
	let NUM_RULES2=0
	let NUM_EQUATIONS2=0
	let NUM_LINES2=0
	if [ ! -z "$FILENAME2" ]; then
		let NUM_RULES2=`cat $FILENAME2 | perl maudeloc.pl | grep ": rule\|^mb rule" | wc -l`
		let NUM_EQUATIONS2=`cat $FILENAME2 | perl maudeloc.pl | grep "^eq \|^ceq " | wc -l`
		let NUM_LINES2=`cat $FILENAME2 | perl maudeloc.pl | grep -v "^mb rule$\|^endm$" | wc -l`
		let TOTAL_RULES=$TOTAL_RULES+$NUM_RULES2
		let TOTAL_EQUATIONS=$TOTAL_EQUATIONS+$NUM_EQUATIONS2
		let TOTAL_LINES=$TOTAL_LINES+$NUM_LINES2
	fi
	printf "%35s %35s\n" "`printf "rules: %3d\n" $NUM_RULES1`" "`printf "rules: %3d\n" $NUM_RULES2`"
	printf "%35s %35s\n" "`printf "eqns:  %3d\n" $NUM_EQUATIONS1`" "`printf "eqns:  %3d\n" $NUM_EQUATIONS2`"
	printf "%35s %35s\n" "`printf "lines: %3d\n" $NUM_LINES1`" "`printf "lines: %3d\n" $NUM_LINES2`"
}

stats "../semantics/.k/common-c-configuration.maude" "../semantics/.k/dynamic-c-configuration.maude"
stats "../semantics/.k/common-c-declarations.maude" "../semantics/.k/dynamic-c-declarations.maude"
stats "../semantics/.k/common-c-expressions.maude" "../semantics/.k/dynamic-c-expressions.maude"
stats "../semantics/.k/common-c-semantics.maude" "../semantics/.k/dynamic-c-semantics.maude"
stats "../semantics/.k/common-c-statements.maude" "../semantics/.k/dynamic-c-statements.maude"
stats "../semantics/.k/common-c-typing.maude" "../semantics/.k/dynamic-c-typing.maude"
stats "../semantics/.k/common-c-syntax.maude" 
stats "../semantics/.k/common-c-helpers.maude" 
stats "../semantics/.k/dynamic-c-standard-lib.maude"
stats "../semantics/.k/dynamic-c-memory.maude" 
stats "../semantics/.k/dynamic-c-conversions.maude" 
stats "../semantics/.k/dynamic-c-errors.maude" 
echo "---------------------------------------------------------------------------"
printf "Syntactic Ops:     %4d\n" `cat ../semantics/.k/common-c-syntax.maude | perl maudeloc.pl | grep "^op " | wc -l`
printf "Total Rules:       %4d\n" $TOTAL_RULES
printf "Total Eqns:        %4d\n" $TOTAL_EQUATIONS
printf "Total Rules+Eqns:  %4d\n" $(($TOTAL_EQUATIONS+$TOTAL_RULES))
printf "Total Lines:       %4d\n" $TOTAL_LINES
printf "Compiled eq:       %4d\n" `cat ../semantics/c-compiled.maude | perl maudeloc.pl | grep "^eq " | wc -l`
printf "Compiled ceq:       %4d\n" `cat ../semantics/c-compiled.maude | perl maudeloc.pl | grep "^ceq " | wc -l`
printf "Compiled rl:       %4d\n" `cat ../semantics/c-compiled.maude | perl maudeloc.pl | grep "^rl " | wc -l`
printf "Compiled crl:       %4d\n" `cat ../semantics/c-compiled.maude | perl maudeloc.pl | grep "^crl " | wc -l`
printf "Compiled ops:       %4d\n" `cat ../semantics/c-compiled.maude | perl maudeloc.pl | grep "^op " | wc -l`
echo "---------------------------------------------------------------------------"
stats "../semantics/c-total.maude" 