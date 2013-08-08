// vim: set ts=2 sw=2:
module CIL-SYNTAX
  /* a file is a list of global declarations and definitions */
  syntax File ::= Globals

  syntax Global ::= Decl
                  | FunDef
                  | TuPragma
  syntax Globals ::= List{Global, ""}

  syntax Decl ::= VarDecl | InitVarDecl | AggDecl | EnumDecl

  syntax AggDecl ::= "struct" CId "{" VarDecls "}" ";"
                   | "union" CId "{" VarDecls "}" ";"

  syntax EnumDecl ::= "enum" CId "{" EnumInits "}" ";"
  syntax EnumInit ::= CId "=" Constant
  syntax EnumInits ::= List{EnumInit, ","} [right]

  // It appears that CIL substitutes constants for the enum tags, but leaves
  // the declaration, so I think it can be safely elided.
  rule enum _:CId { _:EnumInits } ; => . [macro]

  syntax Type ::= ParamDecl // TODO(chathhorn)
  // syntax Type ::= Void
  //               | NvType
  //               | CId
  syntax Void ::= "void"
  syntax NvType ::= BasicType
  syntax BasicType ::= "char"
                     | IntType 
                     | FloatingType
                     | "_Complex" // TODO
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

  syntax Types ::= List{Type,","}


  /* TODO: simplify */
  syntax FunDef ::= DeclSpecs Declarator FunBody 

  syntax FunBody ::= "{" VarDecls Block "}"   [avoid]
                   | Block

  rule S:DeclSpecs F:Declarator B:Block => S F { .VarDecls B } [macro]

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
               | "sizeof" "(" Exp ")"     [strict, prefer]
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
  syntax Constants ::= List{Constant, ","}

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
                | "return" ";"
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
                 | LVal "=" FunCall ";"   [strict(2), prefer]
                 | FunCall ";"            [strict]

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
  // TODO(chathhorn): isCId(int) ==K true??
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

  syntax TuPragma ::= "#" "pragma" "KCIL_TU" String

  /*
   * syntactical macros 
   */
  rule if (E:Exp) S:Stmt => if (E) S else ;   [macro]

  // *** Variable, function, and typedef declarations.

  // declaration
  //     declaration-specifiers init-declarator-list? ;
  //     static_assert-declaration
  syntax VarDecl ::=
      DeclSpecs Declarator ";"
  syntax VarDecls ::= List{VarDecl, ""}    [right]
  
  syntax InitVarDecl ::= 
      DeclSpecs Declarator "=" Initializer ";"

  // declaration-specifiers
  //     storage-class-specifier declaration-specifiers?
  //     type-specifier          declaration-specifiers?
  //     type-qualifier          declaration-specifiers?
  //     function-specifier      declaration-specifiers?
  //     alignment-specifier     declaration-specifiers?
  syntax DeclSpecs ::=
      StorageClassSpec TypeSpec
    | StorageClassSpec TypeSpec TypeQual [prefer]
    | StorageClassSpec TypeQual TypeSpec
    | StorageClassSpec TypeQual TypeSpec TypeQual [prefer]
    | TypeSpec
    | TypeSpec TypeQual [prefer]
    | TypeQual TypeSpec
    | TypeQual TypeSpec TypeQual [prefer]
  rule SC:StorageClassSpec _:TypeQual TS:TypeSpec => SC TS [macro]
  rule SC:StorageClassSpec TS:TypeSpec _:TypeQual => SC TS [macro]
  rule SC:StorageClassSpec _:TypeQual TS:TypeSpec _:TypeQual => SC TS [macro]
  rule _:TypeQual TS:TypeSpec => TS [macro]
  rule TS:TypeSpec _:TypeQual => TS [macro]
  rule _:TypeQual TS:TypeSpec _:TypeQual => TS [macro]

  rule register T:TypeSpec => T [macro]

  // storage-class-specifier
  //     [ ... ]
  syntax StorageClassSpec ::=
      "typedef"
    | "extern"
    | "static"
    | "_Thread_local"
    | "auto"
    | "register"

  // type-specifier
  //     [ ... ]
  //     atomic-type-sepcifier
  //     struct-or-union-specifier
  //     enum-specifier
  //     typedef-name
  syntax TypeSpec ::=
      Void
    | BasicType
    | AggTypeSpec
    | CId

  // struct-or-union-specifier
  //     struct-or-union identifier? { struct-declaration-list }
  //     struct-or-union identifier
  syntax AggTypeSpec ::=
      "struct" CId 
    | "union" CId 
  
  // atomic-type-specifier
  //     _Atomic ( type-name )
  // syntax AtomicTypeSpec ::=
  //     "_Atomic" "(" TypeName ")"

  // type-qualifier
  //     const
  //     restrict
  //     volatile
  //     _Atomic
  syntax TypeQual ::=
      "const"
    | "restrict"
    | "volatile"
    | "_Atomic"

  // function-specifier
  //     inline
  //     _Noreturn
  // syntax FunctionSpec ::=
  //     "inline"
  //   | "_Noreturn"

  // alignment-specifier
  //     _Alignas ( type-name )
  //     _Alignas ( constant-expression )
  // syntax AlignmentSpec ::=
  //     "_Alignas" "(" TypeName ")"
  //   | "_Alignas" "(" Constant ")"

  // declarator
  //     pointer? direct-declarator
  syntax Declarator ::=
      DirectDecl 
    | Pointer DirectDecl

  // direct-declarator
  //     identifier
  //     ( declarator )
  //     direct-declarator [ type-qualifier-list? assignment-expression?]
  //     direct-declarator [ static type-qualifier-list? assignment-expression ]
  //     direct-declarator [ type-qualifier-list static assignment-expression ]
  //     direct-declarator [ type-qualifier-list? * ]
  //     direct-declarator ( parameter-type-list )
  //     direct-declarator ( identifier-list? )
  syntax DirectDecl ::=
      CId
    | "(" Declarator ")"
    | DirectDecl "(" ")" [prefer]
    | DirectDecl "[" "]" [prefer]
    | DirectDecl "(" Params ")"
    | DirectDecl "[" Constant "]"
  
  // TODO(chathhorn): type qualifiers.
  // pointer
  //      * type-qualifier-list?
  //      * type-qualifier-list? pointer
  syntax Pointer ::=
      "*"
    | "*" TypeQual
    | "*" Pointer
    | "*" TypeQual Pointer
  rule * _:TypeQual => * [macro]
  rule * _:TypeQual P:Pointer => * P [macro]

  // parameter-type-list
  //     parameter-list
  //     parameter-list , ...
  // syntax ParameterTypeList ::=
  //     Params
  //   | Params "," "..."

  // parameter-list
  //     parameter-declaration
  //     parameter-list , parameter-declaration
  syntax Params ::=
      List{ParamDecl, ","} [right]
  
  // parameter-declaration
  //     declaration-specifiers declarator
  //     declaration-specifiers abstract-declarator?
  syntax ParamDecl ::=
      DeclSpecs
    | DeclSpecs Declarator
    | DeclSpecs AbsDecl

  // type-name
  //     specifier-qualifier-list abstract-declarator?
  // syntax TypeName ::=
  //     SpecQualifierList
  //   | SpecQualifierList AbsDecl
  
  // Abstract declarators are declarators without identifiers optionally used
  // in function parameter lists declarations.

  // abstract-declarator
  //     pointer
  //     pointer? direct-abstract-declarator
  syntax AbsDecl ::=
      Pointer
    | DirectAbsDecl
    | Pointer DirectAbsDecl
  
  // direct-abstract-declarator
  //     ( abstract-declarator )
  //     direct-abstract-declarator? [ type-qualifier-list? assignment-expression? ]
  //     direct-abstract-declarator? [ static type-qualifier-list? assignment-expression ]
  //     direct-abstract-declarator? [ type-qualifier-list static assignment-expression ]
  //     direct-abstract-declarator? [ * ]
  //     direct-abstract-declarator? ( parameter-type-list? )
  syntax DirectAbsDecl ::=
      "(" ")" [prefer]
    | "[" "]" [prefer]
    | "(" AbsDecl ")"
    | "(" Params ")"
    | "[" Constant "]"
    | DirectAbsDecl "(" ")" [prefer]
    | DirectAbsDecl "[" "]" [prefer]
    | DirectAbsDecl "(" Params ")"
    | DirectAbsDecl "[" Constant "]"
  
  // initializer
  //     assignment-expression
  //     { initializer-list }
  //     { initializer-list , }
  // In CIL these should just be constants or constants with a cast.
  syntax Initializer ::= Exp | "{" Initializers "}"
  syntax Initializers ::= List{Initializer, ","}

endmodule

