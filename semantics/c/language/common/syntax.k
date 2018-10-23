module C-SORTS
     syntax StorageClassSpecifier
     syntax Qualifier
     syntax Modifier ::= Qualifier
     syntax Modifier ::= StorageClassSpecifier
endmodule

module C-SYNTAX
     imports C-SORTS
     imports C-REVAL-SYNTAX
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports COMMON-SYNTAX

     syntax KResult ::= SpecifierElem

     syntax C ::= CabsLoc
     syntax C ::= CId
     syntax C ::= Qualifier
     syntax C ::= Expression
     syntax C ::= SpecifierElem
     syntax C ::= Statement
     syntax C ::= StorageClassSpecifier

     syntax Statement ::= Block(Int, K) [avoid]

     /*
     type cabsloc = {
          lineno : int;
          filename: string;
          lineOffsetStart: int;
          lineOffsetEnd : int;
          systemHeader : bool;
     }
     */

     /*
     and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
     */
     syntax Statement ::= Nop()
     syntax Statement ::= Computation(K) [latex({{#1}};)]
     context Computation(HOLE:KItem => reval(HOLE)) [result(RValue)]

     syntax Statement ::= "Initializer" "(" K ":=" K ")" [strict(1)]
     context Initializer(_ := (HOLE:KItem => reval(HOLE))) [result(RValue)]

     syntax Statement ::= Zero(K) [strict]
     syntax Statement ::= InitPadding(K, CId) [strict(1)]


     /*
     and cvspec =
     CV_CONST | CV_VOLATILE | CV_RESTRICT
     */

     /*
     and spec_elem =
     SpecTypedef
     | SpecCV of cvspec            (* const/volatile *)
     | SpecAttr of attribute       (* __attribute__ *)
     | SpecStorage of storage
     | SpecInline
     */
     syntax SpecifierElem ::= SpecTypedef()
     syntax SpecifierElem ::= MissingType()
     // the following are because I flattened SpecifierElem
     syntax SpecifierElem ::= Modifier

     syntax StorageClassSpecifier ::= AutoSpecifier
     syntax Modifier ::= FunctionSpecifier
     syntax FunctionSpecifier ::= Noreturn()
                                | SpecExtendsTuOf(CId)

     /*
     | IF of expression * statement * statement * cabsloc
     | WHILE of expression * statement * cabsloc
     | DOWHILE of expression * statement * cabsloc
     | FOR of for_clause * expression * expression * statement * cabsloc
     */
     syntax Statement ::= IfThenElse(K, K, K)
     context IfThenElse((HOLE:KItem => reval(HOLE)), _, _) [result(RValue)]

     syntax Statement ::= While(K, K)
     syntax Statement ::= DoWhile(K, K)
     // Condition, post expression, body
     syntax Statement ::= For(K, K, K)
     /*
     | BREAK of cabsloc
     | CONTINUE of cabsloc
     | RETURN of expression * cabsloc
     */
     syntax Statement ::= Break()
     syntax Statement ::= Continue()

     syntax Statement ::= Return(K)
     context Return(HOLE:KItem => reval(HOLE)) [result(RValue)]

     /*
     | SWITCH of expression * statement * cabsloc
     | CASERANGE of expression * expression * statement * cabsloc
     */
     // unique switch id
     syntax Statement ::= Switch(K, K, K)
     context Switch(_, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]

     /*
     | CASE of expression * statement * cabsloc
     | DEFAULT of statement * cabsloc
     */
     // unique switch id, unique case id, exp, statement
     syntax Statement ::= Case(Int, Int, K, K)
     // unique switch id, statement
     syntax Statement ::= Default(Int, K)

     /*
     | LABEL of String * statement * cabsloc
     */
     syntax Statement ::= Label(CId, K) [avoid]


     /*
     | GOTO of String * cabsloc
     */
     syntax Statement ::= Goto(CId) // CId

     /*
     | UNARY of unary_operator * expression

     and unary_operator =
     MINUS | PLUS | NOT | BNOT | MEMOF | ADDROF
     | PREINCR | PREDECR | POSINCR | POSDECR
     */
     syntax Expression ::= "-" K
                         | "+" K
                         | "!" K
                         | "~" K
                         | "*" K
                         | "&" K [strict]
                         | "++" K [prefer, strict]
                         | "--" K [prefer, strict, latex(\terminal{-{}-}{#1})]
                         | K "++" [prefer, strict]
                         | K "--" [prefer, strict, latex({#1}\terminal{-{}-})]
     /* | BINARY of binary_operator * expression * expression */
                         > K "*" K [left]
                         | K "/" K [left]
                         | K "%" K [left]
                         > K "+" K [left]
                         | K "-" K [left]
                         > K "<<" K [left, latex({{#1}}\ll{{#2}})]
                         | K ">>" K [left, latex({{#1}}\gg{{#2}})]
                         > K "<" K [left]
                         | K "<=" K [left]
                         | K ">" K [left]
                         | K ">=" K [left]
                         > K "==" K [left]
                         | K "!=" K [left]
                         > K "&" K [left]
                         > K "^" K [left]
                         > K "|" K [left]
                         > K "&&" K [prefer, left]
                         > K "||" K [left]
     /* | QUESTION of expression * expression * expression */
                         // Ternary operator is right-associative.
                         > K "?" K ":" K
                              [right, gather(e & E)]
                         > K "*=" K
                         | K "/=" K
                         | K "%=" K
                         | K "+=" K
                         | K "-=" K
                         | K "<<=" K
                         | K "&=" K
                         | K "^=" K
                         | K "|=" K
                         | K ">>=" K
                              [latex({{#1}}\terminal{$\ll$=}{{#2}})]
                         | K ":=" K

     context - (HOLE:KItem => reval(HOLE)) [result(RValue)]
     context + (HOLE:KItem => reval(HOLE)) [result(RValue)]
     context ! (HOLE:KItem => reval(HOLE)) [result(RValue)]
     context ~ (HOLE:KItem => reval(HOLE)) [result(RValue)]
     context * (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context (HOLE:KItem => reval(HOLE)) * _ [ndheat, result(RValue)]
     context _ * (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
     context (HOLE:KItem => reval(HOLE)) / _ [ndheat, result(RValue)]
     context _ / (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
     context (HOLE:KItem => reval(HOLE)) % _ [ndheat, result(RValue)]
     context _ % (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) + _ [ndheat, result(RValue)]
     context _ + (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
     context (HOLE:KItem => reval(HOLE)) - _ [ndheat, result(RValue)]
     context _ - (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) << _ [ndheat, result(RValue)]
     context _ << (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) >> _ [ndheat, result(RValue)]
     context _ >> (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) < _ [ndheat, result(RValue)]
     context _ < (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
     context (HOLE:KItem => reval(HOLE)) <= _ [ndheat, result(RValue)]
     context _ <= (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) > _ [ndheat, result(RValue)]
     context _ > (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
     context (HOLE:KItem => reval(HOLE)) >= _ [ndheat, result(RValue)]
     context _ >= (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) == _ [ndheat, result(RValue)]
     context _ == (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
     context (HOLE:KItem => reval(HOLE)) != _ [ndheat, result(RValue)]
     context _ != (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) & _ [ndheat, result(RValue)]
     context _ & (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) ^ _ [ndheat, result(RValue)]
     context _ ^ (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context (HOLE:KItem => reval(HOLE)) | _ [ndheat, result(RValue)]
     context _ | (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     context HOLE:KItem *= _
     context _ *= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem /= _
     context _ /= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem %= _
     context _ %= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem += _
     context _ += (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem -= _
     context _ -= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem <<= _
     context _ <<= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem &= _
     context _ &= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem ^= _
     context _ ^= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem |= _
     context _ |= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem >>= _
     context _ >>= (HOLE:KItem => reval(HOLE)) [result(RValue)]

     context HOLE:KItem := _ [ndheat]
     context _ := (HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]

     syntax Expression ::= Cast(K, K) [klabel(Cast2)]
     context Cast(HOLE:KItem, _)
     context Cast(_, (HOLE:KItem => reval(HOLE))) [result(RValue)]

     /*
     (* There is a special form of CALL in which the function called
        __builtin_va_arg and the second argument is sizeof(T). This
        should be printed as just T *)
     | CALL of expression * expression list
     */
     syntax Expression ::= Call(K, K)
     context Call((HOLE:KItem => reval(HOLE)), _) [ndheat, result(RValue)]
     /*
     | MEMBEROF of expression * string
     */
     syntax Expression ::= K "." CId [left, strict(1)]

     syntax Expression ::= GnuBody(K)

     /*
     and attribute = String * expression list
     */
     // String, List
     syntax C ::= Attribute(String, K)

endmodule
