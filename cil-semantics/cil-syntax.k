// vim: set ts=2 sw=2:
module CIL-SYNTAX
  /* 
   * A file is a list of global declarations and definitions. 
   */
  syntax File ::= Globals

  syntax Global ::= Decl
                  | FunDef
                  | TuPragma
  syntax Globals ::= List{Global, ""}

  syntax Decl ::= VarDecl | InitVarDecl | AggDecl | TypedefDecl

  /* 
   * Global declarations.
   */
  syntax AggDecl ::= "struct" CId "{" VarDecls "}" ";"
                   | "union" CId "{" VarDecls "}" ";"
                   | "enum" CId "{" EnumInits "}" ";"
                   | "struct" CId ";" // forward decls
                   | "union" CId ";"
                   | "enum" CId ";"

  syntax EnumInit ::= CId "=" Constant
  syntax EnumInits ::= List{EnumInit, ","} [right]

  syntax TypedefDecl ::= "typedef" DeclSpecs Declarator ";"

  syntax FunDef ::= DeclSpecs Declarator FunBody 

  syntax FunBody ::= "{" VarDecls Block "}"   [avoid]
                   | Block

  rule S:DeclSpecs F:Declarator B:Block => S F { .VarDecls B } [macro]

  syntax TuPragma ::= "#" "pragma" "KCIL_TU" String

  /*
   * Basic types.
   */
  syntax Type ::= ParamDecl // TODO(chathhorn)
  syntax Void ::= "void"
  syntax NvType ::= BasicType
  syntax BasicType ::= "char"
                     | IntType 
                     | FloatingType
                     | "_Complex" // TODO
                     | "__builtin_va_list"
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

  /*
   * Expressions.
   */
  syntax Exp ::= 
      Constant
    | Var
    | "(" Exp ")" [bracket]
    | Exp "." Field
    | Exp "->" Field
    | Exp "[" Exp "]"
    > "-" Exp [strict]
    | "+" Exp [strict]
    | "!" Exp
    | "~" Exp [strict]
    | "*" Exp [strict]
    | "&" Exp [strict]
    | sizeof(TypeOrExp) [prefer]
    > "(" Type ")" Exp [strict, prefer]
    > left:
      Exp "*" Exp [strict]
    | Exp "/" Exp [strict]
    | Exp "%" Exp [strict]
    > left:
      Exp "+" Exp [strict]
    | Exp "-" Exp [strict]
    > left:
      Exp "<<" Exp [strict]
    | Exp ">>" Exp [strict]
    > left:
      Exp "<" Exp [strict]
    | Exp "<=" Exp [strict]
    | Exp ">" Exp [strict]
    | Exp ">=" Exp [strict]
    > left:
      Exp "==" Exp [strict]
    | Exp "!=" Exp [strict]
    > left: Exp "&" Exp [strict]
    > left: Exp "^" Exp [strict]
    > left: Exp "|" Exp [strict]

  rule E:Exp -> F:Field => (*E).F [macro]

  syntax Exps ::= List{Exp,","}   [strict]

  syntax TypeOrExp ::= Type | Exp
  syntax Var ::= CId
  syntax Field ::= CId

  /*
   * Literals.
   */
  syntax Constant ::= Int
                 | DecimalConstant
                 | OctalConstant
                 | HexConstant
                 | String
                 | DecimalFloatConstant
                 | NoDotDecimalFloatConstant
                 | HexFloatConstant
                 | NoDotHexFloatConstant
  // TODO(chathhorn): Something fishy re asterisks in Token.
                 | "'*'"
                 | "'"CharConstant"'"
                 | CharConstantPrefix "'"CharConstant"'"

  // TODO(chathhorn): char constant prefix. Especially L, which appears in the
  // torture tests.
  rule _:CharConstantPrefix ' C:CharConstant ' => ' C ' [macro]
  
  syntax DecimalConstant ::= 
    Token{[1-9][0-9]*[Uu]?[Ll]?[Ll]?[Uu]?} [onlyLabel]
  syntax OctalConstant ::= 
    Token{[0][0-7]*[Uu]?[Ll]?[Ll]?[Uu]?} [onlyLabel]
  syntax HexConstant ::= 
    Token{[0][xX][0-9a-fA-F]*[Uu]?[Ll]?[Ll]?[Uu]?} [onlyLabel]

  // Either the dot or the exponent part (preceded by e or p) is required for
  // float constants.
  syntax DecimalFloatConstant ::=
    Token{[0-9]*[\.][0-9]*[eE]?[\+\-]?[0-9]*[FfLl]?} [onlyLabel]
  syntax NoDotDecimalFloatConstant ::=
    Token{[0-9]+[eE][\+\-]?[0-9]+[FfLl]?} [onlyLabel]
  syntax HexFloatConstant ::=
    Token{[0][xX][0-9a-fA-F]*[\.][0-9a-fA-F]*[pP]?[\+\-]?[0-9]*[FfLl]?} 
    [onlyLabel]
  syntax NoDotHexFloatConstant ::=
    Token{[0][xX][0-9a-fA-F]+[pP][\+\-]?[0-9]+[FfLl]?} [onlyLabel]

  syntax Constants ::= List{Constant, ","}

  syntax CharConstantPrefix ::= Token{[LuU]} [onlyLabel]

  syntax Char ::= 
    Token{[a-zA-Z0-9\~\!\@\#\$\%\^\&\(\)\-\_\+\=\:\;\?\/\|\`\{\}\[\]\<\>]} 
    [onlyLabel]
  syntax CharConstant ::= Char | EscapeString
  syntax EscapeString ::= "\\'" | "\\\\" | "\\a" | "\\b" | "\\f" 
                        | "\\n" | "\\r" | "\\t" | "\\v" 
                        | OctalStringEscape | HexStringEscape
  // TODO(chathhorn): Also \" but I can't get it to work.

  syntax HexStringEscape ::=
    Token{[\\][x][0-9a-fA-F]*} [onlyLabel]
  syntax OctalStringEscape ::=
    Token{[\\][0-7][0-7]?[0-7]?} [onlyLabel]

  // TODO(chathhorn): hex and octal escape codes in strings?

  /*
   * Statements.
   */
  syntax Stmt ::= Instr 
                | "return" "(" Exp ")" ";"                    [strict]
                | "return" ";"
                | "goto" Label ";"
                | "break" ";"
                | "continue" ";"
                | "if" "(" Exp ")" Stmt "else" Stmt   [avoid]
                | "if" "(" Exp ")" Stmt
                | "switch" "(" Exp ")" Block
                | "while" "(" Exp ")" Stmt
                | Block
                | Label ":" Stmt
                | ";"

  rule if (E:Exp) S:Stmt => if (E) S else ;   [macro]

  syntax Stmts ::= List{Stmt, ""}   [right]
  syntax Instr ::= Exp "=" Exp ";"       [strict(2)]
                 | Exp "=" FunCall ";"   [strict(2), prefer]
                 | FunCall ";"            [strict]
                 | Exp "++" ";"
                 | Exp "--" ";"
                 | Exp "+=" Exp ";"
                 | Exp "-=" Exp ";"
                 | Exp "*=" Exp ";"
                 | Exp "/=" Exp ";"
                 | Exp "%=" Exp ";"
                 | Exp "&=" Exp ";"
                 | Exp "|=" Exp ";"
                 | Exp "^=" Exp ";"

  rule X:Exp += E:Exp ; => X = X + E ; [macro]
  rule X:Exp -= E:Exp ; => X = X - E ; [macro]
  rule X:Exp *= E:Exp ; => X = X * E ; [macro]
  rule X:Exp /= E:Exp ; => X = X / E ; [macro]
  rule X:Exp %= E:Exp ; => X = X % E ; [macro]
  rule X:Exp &= E:Exp ; => X = X & E ; [macro]
  rule X:Exp |= E:Exp ; => X = X | E ; [macro]
  rule X:Exp ^= E:Exp ; => X = X ^ E ; [macro]

  syntax FunCall ::= Exp "(" Exps ")"   [strict(2)]
  syntax Block ::= "{" Stmts "}"
  syntax Label ::= CId
                 | "case" Exp
                 | "default"

  /*
   * Lexical tokens.
   */
  /* C identifiers */
  syntax CId ::= CIdToken
               | "main"
  syntax CIds ::= List{CId, ","}
  /* regular expression for tokens representing C identifiers */
  syntax CIdToken ::= Token{[\$A-Za-z\_][\$A-Za-z\_0-9]*}    [onlyLabel]
  /* exclude predefined functions */
  syntax CIdToken ::= "main"      [reject]
  /* exclude keywords */
  syntax CIdToken ::=
      "auto"             [reject]
    | "break"            [reject]
    | "case"             [reject]
    | "char"             [reject]
    | "const"            [reject]
    | "continue"         [reject]
    | "default"          [reject]
    | "do"               [reject]
    | "double"           [reject]
    | "else"             [reject]
    | "enum"             [reject]
    | "extern"           [reject]
    | "float"            [reject]
    | "for"              [reject]
    | "goto"             [reject]
    | "if"               [reject]
    | "inline"           [reject]
    | "int"              [reject]
    | "long"             [reject]
    | "register"         [reject]
    | "restrict"         [reject]
    | "return"           [reject]
    | "short"            [reject]
    | "signed"           [reject]
    | "sizeof"           [reject]
    | "static"           [reject]
    | "struct"           [reject]
    | "switch"           [reject]
    | "typedef"          [reject]
    | "union"            [reject]
    | "unsigned"         [reject]
    | "void"             [reject]
    | "volatile"         [reject]
    | "while"            [reject]
    | "_Alignas"         [reject]
    | "_Alignof"         [reject]
    | "_Atomic"          [reject]
    | "_Bool"            [reject]
    | "_Complex"         [reject]
    | "_Generic"         [reject]
    | "_Imaginary"       [reject]
    | "_Noreturn"        [reject]
    | "_Static_assert"   [reject]
    | "_Thread_local"    [reject]
    // CIL versions.
    | "__restrict"       [reject]
    | "__inline"         [reject]
    // Bonus.
    | "__builtin_va_list" [reject]

  // Complete list of C11 reserved words plus some extras from CIL.
  // TODO(chathhorn): This duplicate list allows us distinguish CIds from
  // keywords. (Because, e.g., isCId(int) == true, despite the "reject.")
  syntax Keyword ::=
      "auto"             [reject]
    | "break"            [reject]
    | "case"             [reject]
    | "char"             [reject]
    | "const"            [reject]
    | "continue"         [reject]
    | "default"          [reject]
    | "do"               [reject]
    | "double"           [reject]
    | "else"             [reject]
    | "enum"             [reject]
    | "extern"           [reject]
    | "float"            [reject]
    | "for"              [reject]
    | "goto"             [reject]
    | "if"               [reject]
    | "inline"           [reject]
    | "int"              [reject]
    | "long"             [reject]
    | "register"         [reject]
    | "restrict"         [reject]
    | "return"           [reject]
    | "short"            [reject]
    | "signed"           [reject]
    | "sizeof"           [reject]
    | "static"           [reject]
    | "struct"           [reject]
    | "switch"           [reject]
    | "typedef"          [reject]
    | "union"            [reject]
    | "unsigned"         [reject]
    | "void"             [reject]
    | "volatile"         [reject]
    | "while"            [reject]
    | "_Alignas"         [reject]
    | "_Alignof"         [reject]
    | "_Atomic"          [reject]
    | "_Bool"            [reject]
    | "_Complex"         [reject]
    | "_Generic"         [reject]
    | "_Imaginary"       [reject]
    | "_Noreturn"        [reject]
    | "_Static_assert"   [reject]
    | "_Thread_local"    [reject]
    // CIL versions.
    | "__restrict"       [reject]
    | "__inline"         [reject]
    // Bonus.
    | "__builtin_va_list" [reject]

  /*
   * Declarations (variables, functions, and typedefs).
   */

  // declaration
  //     declaration-specifiers init-declarator-list? ;
  //     static_assert-declaration
  syntax VarDecl ::=
      DeclSpecs Declarator ";" 
    // Bitfields; really only allowed in structs/unions.
    | DeclSpecs Declarator ":" Constant ";"

  // Elide bitfields for now.
  rule DS:DeclSpecs D:Declarator : _:Constant ; => DS D ; [macro]

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
      "extern"
    | "static"
    | "_Thread_local"
    | "auto"
    | "register"

  // atomic-type-specifier
  //     _Atomic ( type-name )

  // type-specifier
  //     [ ... ]
  //     atomic-type-sepcifier
  //     struct-or-union-specifier
  //     enum-specifier
  //     typedef-name
  syntax TypeSpec ::=
      Void
    | "_Atomic" "(" Type ")"
    | "..."
    | BasicType
    | AggTypeSpec
    | CId

  // struct-or-union-specifier
  //     struct-or-union identifier? { struct-declaration-list }
  //     struct-or-union identifier
  syntax AggTypeSpec ::=
      "struct" CId 
    | "union" CId 
    | "enum" CId 
  
  // function-specifier
  //     inline
  //     _Noreturn

  // alignment-specifier
  //     _Alignas ( type-name )
  //     _Alignas ( constant-expression )

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
    // Function specifiers.
    |  "inline"
    | "_Noreturn"
    // Alignment specifier.
    | "_Alignas" "(" TypeOrExp ")"
    // CIL versions.
    | "__restrict"
    | "__inline"

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

  // NOTE that we've made "..." a TypeSpec instead of using this production, so
  // our parser will allow that "..." to appear anywhere a regular type could
  // appear.
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
    | DeclSpecs AbsDecl [prefer]

  // Abstract declarators are declarators without identifiers, optionally used
  // in function parameter list declarations.

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
    | "(" AbsDecl ")" [avoid]
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

