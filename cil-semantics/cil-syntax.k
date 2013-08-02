module CIL-SYNTAX
  /* a file is a list of global declarations and definitions */
  syntax File ::= Globals

  syntax Global ::= Decl
                  | FunDef
  syntax Globals ::= List{Global, ""}

  syntax Decl ::= VarDecl | AggDecl | TypeDef | FunDecl
  syntax TypeDef ::= "typedef" Type CId ";" 

  syntax AggDecl ::= "struct" CId "{" VarDecls "}" ";"
                   | "union" CId "{" VarDecls "}" ";"

  syntax Type ::= Void
                | NvType
                | CId
  syntax Void ::= "void"
  syntax NvType ::= BasicType
                  | PtrType 
                  | ArrayType
                  | AggType
                  | ConstType
  syntax BasicType ::= "char"
                     | IntType 
                     | FloatingType
  syntax IntType ::= SignedIntType
                   | UnsignedIntType
  syntax SignedIntType ::= "signed" "char"
                         | "short"
                         | "int"
                         | "long"
                         | "long" "long" 
  syntax UnsignedIntType ::= "_Bool"
                           | "unsigned" "char"
                           | "unsigned" "short"
                           | "unsigned" "int"
                           | "unsigned" "long"
                           | "unsigned" "long" "long"
  syntax FloatingType ::= "float"
                        | "double"
                        | "long" "double"
  syntax PtrType ::= Type "*"
  syntax ConstType ::= Type "const"
  syntax ArrayType ::= Type "[" Nat "]" 
  syntax AggType ::= "struct" CId | "union" CId
  syntax Types ::= List{Type,","}


  /* TODO: simplify */
  syntax FunDef ::= Type CId "(" FunParams ")" FunBody 
                  | FunSpecs Type CId "(" FunParams ")" FunBody 

  syntax FunDecl ::= Type CId "(" FunParams ")" ";" 
                  | FunSpecs Type CId "(" FunParams ")" ";" 
                  | Type CId "(" FunParams ")" FunAttrs ";" 
                  | FunSpecs Type CId "(" FunParams ")" FunAttrs ";" 

  // Elide function attributes.
  rule S:FunSpecs T:Type F:CId ( P:FunParams ) _:FunAttrs ; 
    => S T F ( P ) ;  [macro]
  rule T:Type F:CId ( P:FunParams ) _:FunAttrs ; 
    => T F ( P ) ;  [macro]
  rule _:FunAttrs T:Type F:CId ( P:FunParams ) ; 
    => T F ( P ) ;  [macro]
  rule L:Linkage _:FunAttrs T:Type F:CId ( P:FunParams ) ; 
    => L T F ( P ) ;  [macro]

  syntax FunSpecs ::= Linkage | FunAttrs | Linkage FunAttrs

  syntax Param ::= Type CId
  syntax Params ::= List{Param,","}
  syntax FunParams ::= Params | Void

  syntax Attr ::= "__nothrow__"
                | "__noreturn__" 
                | "__nonnull__" "(" Int ")" 
                | "__leaf__"
                | "__pure__"
  syntax Attrs ::= List{Attr, ","}
  syntax FunAttrs ::= "__attribute__" "(" "(" Attrs ")" ")"

  // Elide const.
  rule T:Type const => T [macro]

  syntax FunBody ::= "{" VarDecls Block "}"   [avoid]
                   | Block
  rule T:Type F:CId(void) FB:FunBody => T F(.Params) FB [macro]
  rule T:Type F:CId(Ps:Params) B:Block => T F(Ps) { .VarDecls B } [macro]

  syntax Storage ::= "static"
                   | "extern"
                   | "register"
                   | "_Thread_local"

  syntax Linkage ::= "static" | "extern"

  syntax VarDecl ::= Type Var ";"
  syntax VarDecls ::= List{VarDecl, ""}    [right]

  /*
   * expressions
   */
  syntax Exp ::= Constant
               | "(" Exp ")"              [bracket]
               | LVal 
               | "&" LVal
               | "+" Exp                  [strict]
               | "-" Exp                  [strict]
               | "~" Exp                  [strict]
               | "!" Exp
               | "sizeof" "(" Type ")"    [prefer]
               /* 
                * NOTE: this grammar allows "sizeof (int) 1", which is not
                * allowed by the official C grammar (not sure why, it only
                * allows "sizeof ((int) 1)")
                */
               // | "sizeof" Exp // not in CIL
               > "(" Type ")" Exp         [strict, prefer]
               > left:
                 Exp "*" Exp              [strict, left]
               | Exp "/" Exp              [strict, left]
               | Exp "%" Exp              [strict, left]
               > left:
                 Exp "+" Exp              [strict, left]
               | Exp "-" Exp              [strict, left]
               > left:
                 Exp "<<" Exp             [strict, left]
               | Exp ">>" Exp             [strict, left]
               > left:
                 Exp "<" Exp              [strict, left]
               | Exp ">" Exp              [strict, left]
               | Exp "<=" Exp             [strict, left]
               | Exp ">=" Exp             [strict, left]
               > left:
                 Exp "==" Exp             [strict, left]
               | Exp "!=" Exp             [strict, left]
               > left:
                 Exp "&" Exp              [strict, left]
               > left:
                 Exp "^" Exp              [strict, left]
               > left:
                 Exp "|" Exp              [strict, left]
               > left:
                 Exp "&&" Exp             [strict(1), left]
               > left:
                 Exp "||" Exp             [strict(1), left]
               > left:
                 Exp "?" Exp ":" Exp      [strict(1), left]
               /*
                * TODO: this is a GCC feature which is not yet supported 
                | AlignOf of typ  (* This corresponds to the GCC __alignof_. *)
                | AlignOfE of exp
                */
  syntax Exps ::= List{Exp,","}   [strict]
  syntax Constant ::= Int
                 /*
                  * FIXME: parse 0U, 0L, ... as lexical tokens instead of
                  * grammar productions.
                  */
                 | Int"U"
                 | Int"UL"
                 | Int"ULL"
                 | String
                 | Float
                 | "'"CharConstant"'"

  syntax Char ::= Token{[a-zA-Z0-9\~\!\@\#\$\%\^\&\*\(\)\-\_\+\=\:\;\?]} 
    [onlyLabel]
  syntax CharConstant ::= Char | EscapeString
  syntax EscapeString ::= "\\'" | "\\\\" | "\\a" | "\\b" | "\\f" 
                        | "\\n" | "\\r" | "\\t" | "\\v" 
                        // Also \" but I can't get it to work.

  /* TODO: check the form of CIL lvalues; might lead to simpler semantics */
  syntax LVal ::= CId
                | "*" Exp           [strict]
                | Exp "." CId
                | Exp "[" Exp "]"   [strict(1)]

  syntax Var ::= CId
  syntax Field ::= CId
  syntax CIds ::= List{CId, ","}

  /*
   * statements
   */
  syntax Stmt ::= Instr 
                | "return" "(" Exp ")" ";"                    [strict]
                // | "return" ";" // chathhorn: not CIL, return always has parens
                | "goto" Label ";"
                | "break" ";"
                // | "continue" ";" // chathhorn: doesn't seem to be part of CIL.
                | "if" "(" Exp ")" Stmt "else" Stmt   [avoid]
                | "if" "(" Exp ")" Stmt
                | "switch" "(" Exp ")" Block          [strict]
                | "while" "(" Exp ")" Stmt
                | Block
                | Label ":" Stmt
                | ";"
                /*
                 * TODO: support try blocks
                 | TryFinally of block * block * location
                 | TryExcept of block * (instr list * exp) * block * location
                 */
  syntax Stmts ::= List{Stmt, ""}   [right]
  syntax Instr ::= LVal "=" Exp ";"       [strict(2)]
                 | LVal "=" FunCall ";"   [strict(2)]
                 | FunCall ";"            [strict]
  /*
   * TODO: FunCall is strict only in the second argument because we do not
   * support function pointers yet.
   */
  syntax FunCall ::= Exp "(" Exps ")"   [strict(2)]
  syntax Block ::= "{" Stmts "}"
  syntax Label ::= CId
                 | "case" Exp   [strict]
                 | "default"

  /*
   * lexical tokens
   */
  /* C identifiers */
  syntax CId ::= CIdToken
               | "main"
               | "malloc"
               | "free"
  /* regular expression for tokens representing C identifiers */
  syntax CIdToken ::= Token{[\$A-Za-z\_][\$A-Za-z\_0-9]*}    [onlyLabel]
  /* exclude predefined functions */
  syntax CIdToken ::= "main"      [reject]
                    | "malloc"    [reject]
                    | "free"      [reject]
  /* exclude keywords */
  syntax CIdToken ::= "sizeof"      [reject]
                    | "return"      [reject]
                    | "goto"        [reject]
                    | "break"       [reject]
                    | "continue"    [reject]
                    | "if"          [reject]
                    | "else"        [reject]
                    | "switch"      [reject]
                    | "while"       [reject]
                    | "void"        [reject]
                    | "char"        [reject]
                    | "int"         [reject]
                    | "short"       [reject]
                    | "long"        [reject]
                    | "unsigned"    [reject]
                    | "struct"      [reject]
                    | "union"       [reject]
     
  /*
   * syntactical macros 
   */
  rule if (E:Exp) S:Stmt => if (E) S else ;   [macro]
  // rule T:Type X:CId = E; => T X; X = E;   [macro]
  //rule !E:Exp => E == 0                       [macro]
  // rule E1:Exp != E2:Exp => !(E1 == E2)        [macro]

  /*
   * priorities
   */
  //syntax priority 'return_; > '_;
endmodule

