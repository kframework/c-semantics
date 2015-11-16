module C-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports INT-SYNTAX
     imports BOOL-SYNTAX
     imports LIST

     imports C-DYNAMIC-SYNTAX

     syntax KBott ::= "(" K ")" [bracket]

     syntax KResult ::= SpecifierElem

     syntax C ::= CabsLoc
     syntax C ::= CId
     syntax C ::= CVSpecifier
     syntax C ::= Expression
     syntax C ::= SpecifierElem
     syntax C ::= Statement
     syntax C ::= Storage

     syntax CId ::= Identifier(String) // new
     syntax CId ::= "#NoName" // new
     syntax CId ::= #NoName(Int) // new

     syntax Statement ::= Block(Int, K) [avoid]

     /*
     type cabsloc = {
          lineno : int;
          filename: string;
          lineOffsetStart: int;
          lineOffsetEnd : int;
     }
     */
     syntax CabsLoc ::= CabsLoc(String, Int, Int, Int)

     /*
     and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
     */
     syntax Statement ::= "Nop"
     syntax Statement ::= Computation(K) [latex({{#1}};)]
     context Computation(HOLE:KItem => reval(HOLE)) [result(RValue)]

     /*
     and storage =
     NO_STORAGE | AUTO | STATIC | EXTERN | REGISTER
     */
     // this will be used as the actual atomic modifier
     syntax Storage ::= "Atomic"
     syntax Storage ::= "NoStorage"
     syntax Storage ::= "Auto"
     syntax Storage ::= "Static"
     syntax Storage ::= "Extern"
     syntax Storage ::= "Register"
     syntax Storage ::= "ThreadLocal"

     /*
     and cvspec =
     CV_CONST | CV_VOLATILE | CV_RESTRICT
     */
     syntax CVSpecifier ::= "Const"
     syntax CVSpecifier ::= "Volatile"
     syntax CVSpecifier ::= "Restrict"

     /*
     and spec_elem =
     SpecTypedef
     | SpecCV of cvspec            (* const/volatile *)
     | SpecAttr of attribute       (* __attribute__ *)
     | SpecStorage of storage
     | SpecInline
     */
     syntax SpecifierElem ::= "SpecTypedef"
     // the following are because I flattened SpecifierElem
     syntax SpecifierElem ::= CVSpecifier
     syntax SpecifierElem ::= Storage
     syntax SpecifierElem ::= "Inline"
     syntax SpecifierElem ::= "Noreturn"

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
     syntax Statement ::= "Break"
     syntax Statement ::= "Continue"

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
     syntax Expression ::= "-" K [prec(22)]
                         | "+" K [prec(22)]
                         | "!" K [prec(22)]
                         | "~" K [prec(22)]
                         | "*" K [prec(22)]
                         | "&" K [prec(22), strict]
                         | "++" K [prec(22), prefer, strict]
                         | "--" K [prec(22), prefer, strict, latex(\terminal{-{}-}{#1})]
                         | K "++" [prefer, strict]
                         | K "--" [prefer, strict, latex({#1}\terminal{-{}-})]
     /* | BINARY of binary_operator * expression * expression */
                         > K "*" K [prec(31), left]
                         | K "/" K [prec(31), left]
                         | K "%" K [prec(31), left]
                         > K "+" K [prec(33), left]
                         | K "-" K [prec(33), left]
                         > K "<<" K [prec(35), left, latex({{#1}}\ll{{#2}})]
                         | K ">>" K [prec(35), left, latex({{#1}}\gg{{#2}})]
                         > K "<" K [prec(37), left]
                         | K "<=" K [prec(37), left]
                         | K ">" K [prec(37), left]
                         | K ">=" K [prec(37), left]
                         > K "==" K [prec(39), left]
                         | K "!=" K [prec(39), left]
                         > K "&" K [prec(41), left]
                         > K "^" K [prec(43), left]
                         > K "|" K [prec(45), left]
                         > K "&&" K [prec(47), prefer, left]
                         > K "||" K [prec(49), left]
     /* | QUESTION of expression * expression * expression */
                         // Ternary operator is right-associative.
                         > K "?" K ":" K
                              [prec(51), right, gather(e & E)]
                         > K "*=" K
                              [prec(53)]
                         | K "/=" K
                              [prec(53)]
                         | K "%=" K
                              [prec(53)]
                         | K "+=" K
                              [prec(53)]
                         | K "-=" K
                              [prec(53)]
                         | K "<<=" K
                              [prec(53)]
                         | K "&=" K
                              [prec(53)]
                         | K "^=" K
                              [prec(53)]
                         | K "|=" K
                              [prec(53)]
                         | K ">>=" K
                              [prec(53), latex({{#1}}\terminal{$\ll$=}{{#2}})]
                         | K ":=" K [prec(53)]

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

     syntax Expression ::= Cast(K, K)
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

     /*
     and init_expression =
     | NO_INIT
     */
     syntax KItem ::= "NoInit"

     /*
     and attribute = String * expression list
     */
     // String, List
     syntax C ::= Attribute(String, K)

endmodule
