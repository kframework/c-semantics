#!/bin/bash
#
# Tired of typing? Try:
# $ ./modgen.sh MY-FANCY-MODULE >> my-fancy-module.k


MODNAME="$1"

if [[ "$MODNAME" == "" ]]; then
	echo "Usage: $0 module-name"
	exit 1
fi

cat - <<EOF
// ------------------------------
//      $MODNAME
// ------------------------------

module $MODNAME-SORTS

     // ...

endmodule // $MODNAME-SORTS

module $MODNAME-SYNTAX
     imports $MODNAME-SORTS // self

     // ...

endmodule // $MODNAME-SYNTAX

module $MODNAME
     imports $MODNAME-SYNTAX // self

     // ...

endmodule // $MODNAME
EOF
