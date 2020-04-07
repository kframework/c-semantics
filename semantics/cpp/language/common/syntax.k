module CPP-SORTS
     syntax CId ::= OpId

     syntax Init ::= Stmt | Expr

     syntax NoArg

     syntax Expr ::= Name

     syntax Name

     syntax Stmt ::= Block

     syntax Block

     syntax OpId

     syntax RefQualifier

     syntax Tag

     syntax AccessSpecifier
endmodule

module CPP-SYNTAX
     imports CPP-SORTS
     imports INT-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-REVAL-SYNTAX
     imports CPP-TYPING-SORTS
     imports COMPAT-SORTS

     syntax OpId ::= "operatornew" [symbol]
                   | "operatordelete" [symbol]
                   | "operatornew[]" [symbol]
                   | "operatordelete[]" [symbol]
                   | "operator+" [symbol]
                   | "operator-" [symbol]
                   | "operator*" [symbol]
                   | "operator/" [symbol]
                   | "operator%" [symbol]
                   | "operator^" [symbol]
                   | "operator&" [symbol]
                   | "operator|" [symbol]
                   | "operator~" [symbol]
                   | "operator!" [symbol]
                   | "operator=" [symbol]
                   | "operator<" [symbol]
                   | "operator>" [symbol]
                   | "operator+=" [symbol]
                   | "operator-=" [symbol]
                   | "operator*=" [symbol]
                   | "operator/=" [symbol]
                   | "operator%=" [symbol]
                   | "operator^=" [symbol]
                   | "operator&=" [symbol]
                   | "operator|=" [symbol]
                   | "operator<<" [symbol]
                   | "operator>>" [symbol]
                   | "operator<<=" [symbol]
                   | "operator>>=" [symbol]
                   | "operator==" [symbol]
                   | "operator!=" [symbol]
                   | "operator<=" [symbol]
                   | "operator>=" [symbol]
                   | "operator&&" [symbol]
                   | "operator||" [symbol]
                   | "operator++" [symbol]
                   | "operator--" [symbol]
                   | "operator," [symbol]
                   | "operator->*" [symbol]
                   | "operator->" [symbol]
                   | "operator()" [symbol]
                   | "operator[]" [symbol]

     // not technically operator ids, but used internally in order to process
     // syntax from the parser
     syntax OpId ::= "operator." [symbol]
                   | "operator.*" [symbol]
                   | "operator?" [symbol]
                   | "operator_++" [symbol]
                   | "operator++_" [symbol]
                   | "operator_--" [symbol]
                   | "operator--_" [symbol]

     syntax Specifier ::= Alignas(Int) [symbol]

     syntax Expr ::= temp(Int, CPPType)
                   | newSize(Int)

     syntax DestructorId ::= DestructorId(CId)

     syntax TypeId ::= DestructorId
                  | ConstructorId(CId)
     syntax CId ::= TypeId
                  | ConversionId(CPPType)

     syntax ClassKey ::= Struct() [symbol] | Union() [symbol] | Class() [symbol]

     syntax Tag ::= ClassKey | Enum() [symbol] | Typename() [symbol] | NoTag() [symbol]

     syntax AccessSpecifier ::= Public() [symbol] | Private() [symbol] | Protected() [symbol] | NoAccessSpec()

     syntax RefQualifier ::= RefLValue() [symbol] | RefRValue() [symbol] | RefNone() [symbol]

     syntax TemplateKeyword ::= "template" | "no-template"

     // for trace
     syntax Expr ::= CallExpr(Expr, StrictList) [klabel(CallExpr2)]

     syntax Expr ::= ResolvedExpr

     syntax ResolvedExpr ::= left:
                     Expr "[" Expr "]" [strict(c)]
                   | Expr "++" [strict(c)]
                   | Expr "--" [strict(c)]
                   | BuiltinCallOp(Expr, Bool, List)
                   | ReinterpretCast(AType, Expr) [strict(c)]
                   | ConstCast(AType, Expr) [strict(c)]
                   > right:
                     "++" Expr [strict(c)]
                   | "--" Expr [strict(c)]
                   | NewOp(CPPType, Expr, K, K, Int)
                   | DeleteOp(Expr, Expr, K, Int)
                   | "*" Expr
                   | "&" Expr

                   // like & but applies to all objects including xvalues and class prvalues
                   | getAddress(Expr) [strict(c)]
                   | "!" Expr
                   | "-" Expr
                   | "+" Expr
                   | "~" Expr
                   | Expr "." TemplateKeyword Name
                   | Expr "->" TemplateKeyword Name
                   > left:
                     Expr ".*" Expr
                   | Expr "->*" Expr
                   > left:
                     Expr "*" Expr
                   | Expr "/" Expr
                   | Expr "%" Expr
                   > left:
                     Expr "+" Expr
                   | Expr "-" Expr
                   > left:
                     Expr "<<" Expr
                   | Expr ">>" Expr
                   > left:
                     Expr "<" Expr
                   | Expr "<=" Expr
                   | Expr ">" Expr
                   | Expr ">=" Expr
                   > left:
                     Expr "==" Expr
                   | Expr "!=" Expr
                   > left:
                     Expr "&" Expr
                   > left:
                     Expr "^" Expr
                   > left:
                     Expr "|" Expr
                   > left:
                     Expr "&&" Expr
                   > left:
                     Expr "||" Expr
                   > right:
                     Expr ":=" Init [strict(c; 1)]
                   | Expr ":=init" Init [strict(c; 1)]
                   | Expr "+=" Init [strict(c; 1)]
                   | Expr "-=" Init [strict(c; 1)]
                   | Expr "*=" Init [strict(c; 1)]
                   | Expr "/=" Init [strict(c; 1)]
                   | Expr "%=" Init [strict(c; 1)]
                   | Expr "^=" Init [strict(c; 1)]
                   | Expr "&=" Init [strict(c; 1)]
                   | Expr "|=" Init [strict(c; 1)]
                   | Expr "<<=" Init [strict(c; 1)]
                   | Expr ">>=" Init [strict(c; 1)]
                   | ConditionalOp(Expr, Expr, Expr, ValueCategory, CPPType)
                   | ThrowOp(Expr) [strict(c)]
                   > left:
                     Comma(Expr, Expr) [strict(c; 1)]
     syntax Name ::= Name(NNS, CId)
                   | Name(NNS, CId, List)

     syntax ExecName ::= ExecName(NNS, CId)

     syntax Expr ::= ExecName

     syntax Expr ::= ConvertType(CPPType, Expr)
                   | ExprLoc

     syntax ExprLoc ::= ExprLoc(CabsLoc, KItem)

     syntax Init ::= ExprLoc

     syntax Block ::= BlockStmt(List)
                    | BlockStmt(Int, List)

     syntax Decl

     syntax Stmt ::= LabelStmt(CId, List)
                   | GotoStmt(CId) [symbol]
                   | ExpressionStmt(Expr) [strict(c)]
                   | PRValExpressionStmt(Expr) [strict(c)]
                   | BreakStmt()
                   | ReturnOp(init: Expr, obj: K)
                   | IfStmt(Decl, Stmt, Stmt)
                   | IfStmt(Expr, K, K)
                   | WhileStmt(Decl, Stmt)
                   | WhileStmt(Expr, K)
                   | ForStmt(Expr, K, K) [klabel(ForStmt3)]
                   | TryStmt(K, List)
                   | CatchOp(CPPType, K)
                   | CatchAnyOp(K)

     // returns the current exception object. Used to initialize
     // catch declarations.
     syntax Expr ::= exceptionObject(CPPType)

endmodule

module CPP-SYNTAX-HEATING
     imports CPP-SYNTAX
     imports C-CONFIGURATION

     context <k> _ := (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ := (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ :=init (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ :=init (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ += (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ += (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ -= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ -= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ *= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ *= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ /= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ /= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ %= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ %= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ ^= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ ^= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ &= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ &= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ |= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ |= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ <<= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ <<= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ >>= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ >>= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> * (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> * (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) + _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) + _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ + (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ + (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) - _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) - _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ - (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ - (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) * _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) * _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ * (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ * (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) / _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) / _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ / (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ / (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) % _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) % _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ % (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ % (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) ^ _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) ^ _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ ^ (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ ^ (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) & _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) & _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ & (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ & (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) | _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) | _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ | (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ | (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) != _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) != _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ != (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ != (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) == _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) == _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ == (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ == (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) < _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) < _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ < (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ < (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) <= _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) <= _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ <= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ <= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) > _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) > _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ > (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ > (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) >= _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) >= _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ >= (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ >= (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) << _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) << _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ << (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ << (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> (HOLE:Expr => reval(HOLE)) >> _ ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> (HOLE:Expr => reval(HOLE)) >> _ ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> _ >> (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> _ >> (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     context <k> IfStmt((HOLE:Expr => reval(HOLE)), _, _) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> IfStmt((HOLE:Expr => reval(HOLE)), _, _) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

endmodule
