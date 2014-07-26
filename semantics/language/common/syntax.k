module C-SYNTAX
     // these are semantic
     syntax KItem ::= reval(K) [semantic,context(result(KResult))]
     syntax KItem ::= peval(K) [semantic]

     //TODO: might not need this list in the future. 
     syntax HeatItem ::= hItem(K) [strict(1(context('reval)))]
     syntax HeatList ::= List{HeatItem,"hs::"} [strict]
     syntax KItem ::= hlist(HeatList) [strict]
     syntax HeatList ::= toHeatList(List) [function]
     syntax List ::= hListToList(HeatList) [function]

     syntax HeatResult ::= hrItem(K)
     syntax HeatItem ::= HeatResult
     syntax KResult ::= HeatResult

     rule hItem(V:KResult) => hrItem(V)

     rule toHeatList(.List) => .HeatList
     rule toHeatList(ListItem(K:K) L:List) => hItem(K) hs:: toHeatList(L)

     rule hListToList(.HeatList) => .List
     rule hListToList(hrItem(K:K) hs:: HL:HeatList) => ListItem(K) hListToList(HL)

     // the rest are syntactic
     syntax C ::= AttributeWrapper(K, K) [function]

     syntax C ::= CId

     syntax KResult ::= SpecifierElem

     syntax C ::= CabsLoc
     syntax C ::= TypeSpecifier
     syntax C ::= Storage
     syntax C ::= CVSpecifier
     syntax C ::= SpecifierElem
     syntax C ::= Specifier
     syntax C ::= DeclType
     syntax C ::= NameGroup
     syntax C ::= FieldGroup
     syntax C ::= InitNameGroup
     syntax C ::= Name
     syntax C ::= InitName
     syntax C ::= SingleName
     syntax C ::= Block
     syntax C ::= Statement
     syntax C ::= PureStatement
     syntax C ::= PureEnumItem
     syntax C ::= ForClause
     syntax C ::= Expression
     syntax C ::= Constant
     syntax C ::= InitExpression
     syntax C ::= TranslationUnit
     syntax C ::= IntConstant
     syntax C ::= InitFragment
     syntax C ::= FieldName
     syntax C ::= PureDefinition

     // -------------------------------------------------
     // Below, I give the declaration as found in cabs.ml first, followed by
     // the K version

     /*
     type cabsloc = {
          lineno : int;
          filename: string;
          lineOffsetStart: int;
          lineOffsetEnd : int;
     }
     */
     syntax CabsLoc ::= CabsLoc(String, Int, Int, Int)
          [klabel('CabsLoc)]
	  
     syntax CabsLoc ::= filterCabsLoc(CabsLoc)

     /*
     type typeSpecifier = (* Merge all specifiers into one type *)
     Tvoid                             (* Type specifier ISO 6.7.2 *)
     | Tchar
     | Tbool
     | Tshort
     | Tint
     | Tlong
     | Tint64
     | Tfloat
     | Tdouble
     | Tsigned
     | Tunsigned
     | Tnamed of string
     */
     syntax TypeSpecifier ::= "Void"
     syntax TypeSpecifier ::= "Char"
     syntax TypeSpecifier ::= "Bool"
     syntax TypeSpecifier ::= "Short"
     syntax TypeSpecifier ::= "Int"
     syntax TypeSpecifier ::= "Long"
     syntax TypeSpecifier ::= "Float"
     syntax TypeSpecifier ::= "Double"
     syntax TypeSpecifier ::= "Signed"
     syntax TypeSpecifier ::= "Unsigned"
     syntax Float ::= "inf"
     syntax TypeSpecifier ::= Named(CId) [klabel('Named)]
     /*
     (* each of the following three kinds of specifiers contains a field
     * or item list iff it corresponds to a definition (as opposed to
     * a forward declaration or simple reference to the type); they
     * also have a list of __attribute__s that appeared between the
     * keyword and the type name (definitions only) *)
     | Tstruct of String * field_group list option * attribute list
     | Tunion of String * field_group list option * attribute list
     | Tenum of String * enum_item list option * attribute list
     | TtypeofE of expression                      (* GCC __typeof__ *)
     | TtypeofT of specifier * decl_type       (* GCC __typeof__ *)
     */
     syntax TypeSpecifier ::= StructRef(CId)
          [klabel('StructRef)] // new
     // new // CId, List
     syntax C ::= StructDef(CId, K)
          [strict(2), klabel('StructDef)]
     syntax TypeSpecifier ::= UnionRef(CId)
          [klabel('UnionRef)] // new
     // new // CId, List
     syntax C ::= UnionDef(CId, K)
          [strict(2), klabel('UnionDef)]
     syntax TypeSpecifier ::= EnumRef(CId)
          [klabel('EnumRef)] // new
     // new // CId, List
     syntax C ::= EnumDef(CId, K)
          [klabel('EnumDef)]
     syntax TypeSpecifier ::= TypeofExpression(K)
          [klabel('TypeofExpression)]
     syntax TypeSpecifier ::= TypeofType(K, K)
          [klabel('TypeofType)]

     syntax TypeSpecifier ::= "Complex"
     syntax TypeSpecifier ::= "Imaginary"
     syntax TypeSpecifier ::= TAtomic(K, K)
          [klabel('TAtomic)]
     syntax TypeSpecifier ::= AlignasExpression(K)
          [klabel('AlignasExpression)]
     syntax TypeSpecifier ::= AlignasType(K, K)
          [klabel('AlignasType)]

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
     | SpecType of typeSpecifier
     | SpecPattern of String       (* specifier pattern variable *)
     */
     syntax SpecifierElem ::= "SpecTypedef"
     // the following are because I flattened SpecifierElem
     syntax SpecifierElem ::= CVSpecifier
     syntax SpecifierElem ::= Storage
     syntax SpecifierElem ::= "Inline"
     syntax SpecifierElem ::= "Noreturn"
     syntax SpecifierElem ::= TypeSpecifier
     syntax SpecifierElem ::= SpecPattern(CId)
          [klabel('SpecPattern)]

     /*
     and specifier = spec_elem list
     */
     syntax Specifier ::= Specifier(K) [avoid, klabel('Specifier)]

     /*
     and decl_type =
     | JUSTBASE          (* Prints the declared name *)
     | PARENTYPE of attribute list * decl_type * attribute list
               (* Prints "(attrs1 decl attrs2)".
                * attrs2 are attributes of the
                * declared identifier and it is as
                * if they appeared at the very end
                * of the declarator. attrs1 can
                * contain attributes for the
                * identifier or attributes for the
                * enclosing type.  *)
     | ARRAY of decl_type * attribute list * expression
               (* Prints "decl [ attrs exp ]".
                * decl is never a PTR. *)
     | PTR of attribute list * decl_type      (* Prints "* attrs decl" *)
     | PROTO of decl_type * single_name list * bool
               (* Prints "decl (args[, ...])".
                * decl is never a PTR.*)
     */
     syntax KItem ::= "JustBase"
     syntax DeclType ::= FunctionType(K)
          [klabel('FunctionType), strict]
     // third argument should also be strict, but not doing anything with
     // [strict 5] yet
     syntax DeclType ::= ArrayType(K, K, K)
          [klabel('ArrayType), strict(1)]
     context ArrayType(_, (HOLE => reval(HOLE)), _) [ndheat]
     syntax DeclType ::= PointerType(Specifier, K)
          [klabel('PointerType), strict(2)]
     // K, List, Bool
     syntax DeclType ::= Prototype(K, K, Bool)
          [strict(1, 2)]
     syntax DeclType ::= NoPrototype(K, K, Bool)
          [strict(1, 2)]

     syntax KItem ::= "NotVariadic"
     syntax KItem ::= "Variadic"

     /*
     and name_group = specifier * name list
     */ // K, List
     syntax NameGroup ::= NameGroup(K, K) [klabel('NameGroup), strict]

     /*
     (* The optional expression is the bitfield *)
     and field_group = specifier * (name * expression option) list
     */ // K, List
     syntax FieldGroup ::= FieldGroup(K, K) [klabel('FieldGroup), strict(1)]
     syntax FieldName ::= FieldName(K) [klabel('FieldName)]
     syntax FieldName ::= BitFieldName(K, K) [klabel('BitFieldName)]

     /*
     (* like name_group, except the declared variables are allowed to have
     initializers *)
     (* e.g.: Int x=1, y=2; *)
     and init_name_group = specifier * init_name list
     */
     // K, List
     syntax InitNameGroup ::= "InitNameGroup" "(" K "," K ")"
          [klabel('InitNameGroup), strict(1)]

     /*
     The decl_type is in the order in which they are printed. Only the name of
     the declared identifier is pulled out. The attributes are those that are
     printed after the declarator
     (* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
     (* the string, and decl_type will be PTR([], JUSTBASE) *)
     and name = String * decl_type * attribute list * cabsloc
     */
     // TODO(chathhorn): better solution?
     // first argument is id, second is basetype
     syntax Name ::= Name(K, K) [avoid, klabel('Name)]
     syntax CId ::= "#NoName" // new
     syntax CId ::= "#NoName" "(" Int ")" [klabel('#NoName)] // new
     syntax CId ::= Identifier(String) // new
     //might not need this
     syntax CId ::= ToIdentifier(String) [function]
     /*
     (* A variable declarator ("name") with an initializer *)
     and init_name = name * init_expression
     */
     syntax InitName ::= "InitName" "(" K "," K ")" [klabel('InitName)]
     context InitName(_, (HOLE => reval(HOLE))) [ndheat]

     /*
     (* Single names are for declarations that cannot come in groups, like
      * function parameters and functions *)
     and single_name = specifier * name
     */
     syntax SingleName ::= "SingleName" "(" K "," K ")"
          [klabel('SingleName), strict(1)]

     /*
     and enum_item = String * expression * cabsloc
     */
     // this one has no init
     syntax PureEnumItem ::= "EnumItem" "(" CId ")"
          [klabel('EnumItem)]
     // this one has an init
     syntax PureEnumItem ::= "EnumItemInit" "(" CId "," K ")"
          [klabel('EnumItemInit)]

     /*
     (*
     ** Declaration definition (at toplevel)
     *)
     and definition =
        FUNDEF of single_name * block * cabsloc * cabsloc
      | DECDEF of init_name_group * cabsloc (* variable(s), or function prototype *)
      | TYPEDEF of name_group * cabsloc
      | ONLYTYPEDEF of specifier * cabsloc
      | GLOBASM of String * cabsloc
      | PRAGMA of expression * cabsloc
      | LINKAGE of String * cabsloc * definition list (* extern "C" { ... } *)
      (* toplevel form transformer, from the first definition to the *)
      (* second group of definitions *)
      | TRANSFORMER of definition * definition list * cabsloc
      (* expression transformer: source and destination *)
      | EXPRTRANSFORMER of expression * expression * cabsloc
     */
     syntax PureDefinition ::= "FunctionDefinition" "(" K "," K ")"
          [klabel('FunctionDefinition), strict(1)]
     syntax PureDefinition ::= "DeclarationDefinition" "(" K ")"
          [klabel('DeclarationDefinition)]
     syntax PureDefinition ::= "Typedef" "(" K ")" [klabel('Typedef)]
     syntax PureDefinition ::= "OnlyTypedef" "(" K ")" [klabel('OnlyTypedef)]
     syntax PureDefinition ::= "GlobAsm" "(" String ")" [klabel('GlobAsm)]
     syntax PureDefinition ::= "Pragma" "(" K ")" [klabel('Pragma)]
     syntax PureDefinition ::= "Linkage" "(" String "," K ")"
          [klabel('Linkage)]
     syntax PureDefinition ::= "Transformer" "(" K "," K ")"
          [klabel('Transformer)]
     syntax PureDefinition ::= "ExpressionTransformer" "(" K "," K ")"
          [klabel('ExpressionTransformer)]

     syntax PureDefinition ::= StaticAssert(Expression, Constant)
          [klabel('StaticAssert)]

     // name
     syntax PureDefinition ::= "LTLAnnotation" "(" CId "," K ")"
          [klabel('LTLAnnotation)]

     /*
     (* the String is a file name, and then the list of toplevel forms *)
     and file = String * definition list
     */
     // name, code, source
     // new: Filename, strings, ast, code
     syntax TranslationUnit ::= TranslationUnit(String, K, K)
          [klabel('TranslationUnit)]

     /*
     (* A block contains a list of local label declarations ( GCC's ({ __label__
      * l1, l2; ... }) ) , a list of definitions and a list of statements  *)
     and block =
     { blabels: String list;
       battrs: attribute list;
       bstmts: statement list
     }
     */
     // Int, list, list
     syntax Block ::= "Block" "(" Int "," K "," K ")" [avoid, klabel('Block)]

     /*
     and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
     */
     syntax PureStatement ::= "Nop"
     syntax PureStatement ::= "Computation" "(" K ")"
          [klabel('Computation), latex({{#1}};)]
     context Computation((HOLE => reval(HOLE)))
     syntax PureStatement ::= "BlockStatement" "(" K ")"
          [klabel('BlockStatement)]
     syntax PureStatement ::= "Sequence" "(" K "," K ")"
          [klabel('Sequence)]

     /*
     | IF of expression * statement * statement * cabsloc
     | WHILE of expression * statement * cabsloc
     | DOWHILE of expression * statement * cabsloc
     | FOR of for_clause * expression * expression * statement * cabsloc
     */
     syntax PureStatement ::= "IfThenElse" "(" K "," K "," K ")"
          [klabel('IfThenElse)]
     context IfThenElse((HOLE => reval(HOLE)), _, _)
     syntax PureStatement ::= "While" "(" K "," K ")"
          [klabel('While)]
     syntax PureStatement ::= "DoWhile" "(" K "," K ")"
          [klabel('DoWhile)]
     // id, ...
     syntax PureStatement ::= "For" "(" Int "," K "," K "," K "," K ")"
          [klabel('For)]

     /*
     | BREAK of cabsloc
     | CONTINUE of cabsloc
     | RETURN of expression * cabsloc
     */
     syntax PureStatement ::= "Break" [klabel('Break)]
     syntax PureStatement ::= "Continue" [klabel('Continue)]
     syntax PureStatement ::= "Return" "(" K ")" [klabel('Return)]
     context Return((HOLE => reval(HOLE)))

     /*
     | SWITCH of expression * statement * cabsloc
     | CASE of expression * statement * cabsloc
     | CASERANGE of expression * expression * statement * cabsloc
     | DEFAULT of statement * cabsloc
     */
     // unique switch id
     syntax PureStatement ::= "Switch" "(" K "," K "," K ")" [klabel('Switch)]
     context Switch(_, (HOLE => reval(HOLE)), _)
     // unique switch id, unique case id, exp, statement
     syntax PureStatement ::= "Case" "(" Int "," Int "," K "," K ")"
          [klabel('Case)]
     // gcc extension
     syntax PureStatement ::= "CaseRange" "(" K "," K "," K ")"
          [klabel('CaseRange)]
     // unique switch id, statement
     syntax PureStatement ::= "Default" "(" Int "," K ")" [klabel('Default)]

     /*
     | LABEL of String * statement * cabsloc
     | GOTO of String * cabsloc
     | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
     | DEFINITION of definition (*definition or declaration of a variable or type*)
     */
     syntax PureStatement ::= "Label" "(" CId "," K ")" [avoid, klabel('Label)]
     syntax PureStatement ::= "Goto" "(" K ")" [klabel('Goto)] // CId
     syntax PureStatement ::= "CompGoto" "(" K ")" [klabel('CompGoto)]

     /*
     and for_clause =
     FC_EXP of expression
     | FC_DECL of definition
     */
     syntax ForClause ::= "ForClauseExpression" "(" K ")"
          [klabel('ForClauseExpression)]

     /*
     and binary_operator =
     ADD | SUB | MUL | DIV | MOD
     | AND | OR
     | BAND | BOR | XOR | SHL | SHR
     | EQ | NE | LT | GT | LE | GE
     | ASSIGN
     | ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN
     | BAND_ASSIGN | BOR_ASSIGN | XOR_ASSIGN | SHL_ASSIGN | SHR_ASSIGN

     and expression =
     NOTHING
     */
     syntax Expression ::= "OffsetOf" "(" K "," K "," K ")"
          [klabel('OffsetOf), strict(1)]
     syntax Expression ::= ExpressionLoc(K,K) [function]

     syntax Expression ::= "NothingExpression" [function]

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
                         | "&" K [strict, prec(22)]
                         | "++" K [prefer, prec(22)]
                         | "--" K [prefer, latex(\terminal{-{}-}{#1}), prec(22)]
                         | K "++" [prefer]
                         | K "--" [prefer, latex({#1}\terminal{-{}-})]
     /* | BINARY of binary_operator * expression * expression */
                         > K "*" K [prec(31), left]
                         | K "/" K [prec(31), left]
                         | K "%" K [prec(31), left]
                         > K "+" K [prec(33), left]
                         | K "-" K [prec(33), left]
                         > K "<<" K [latex({{#1}}\ll{{#2}}), prec(35), left]
                         | K ">>" K [latex({{#1}}\gg{{#2}}), prec(35), left]
                         > K "<" K [prec(37), left]
                         | K "<=" K [prec(37), left]
                         | K ">" K [prec(37), left]
                         | K ">=" K [prec(37), left]
                         > K "==" K [prec(39), left]
                         | K "!=" K [prec(39), left]
                         > K "&" K [prec(41), left]
                         > K "^" K [prec(43), left]
                         > K "|" K [prec(45), left]
                         > K "&&" K [prefer, prec(47), left]
                         > K "||" K [prec(49), left]
     /* | QUESTION of expression * expression * expression */
                         // Ternary operator is right-associative.
                         > K "?" K ":" K [right]
                         > K "*=" K [prec(53)]
                         | K "/=" K [prec(53)]
                         | K "%=" K [prec(53)]
                         | K "+=" K [prec(53)]
                         | K "-=" K [prec(53)]
                         | K "<<=" K
                              [latex({{#1}}\terminal{$\gg$=}{{#2}}), prec(53)]
                         | K "&=" K [prec(53)]
                         | K "^=" K [prec(53)]
                         | K "|=" K [prec(53)]
                         | K ">>=" K
                              [latex({{#1}}\terminal{$\ll$=}{{#2}}), prec(53)]
                         | K ":=" K [prec(53)]

     context - (HOLE => reval(HOLE))
     context + (HOLE => reval(HOLE))
     context ! (HOLE => reval(HOLE))
     context ~ (HOLE => reval(HOLE))
     context * (HOLE => reval(HOLE))
     context (HOLE => peval(HOLE)) ++
     context (HOLE => peval(HOLE)) --
     context (HOLE => reval(HOLE)) * _ [ndheat]
     context _ * (HOLE => reval(HOLE)) [ndheat]
     context (HOLE => reval(HOLE)) / _ [ndheat]
     context _ / (HOLE => reval(HOLE)) [ndheat]
     context (HOLE => reval(HOLE)) % _ [ndheat]
     context _ % (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) + _ [ndheat]
     context _ + (HOLE => reval(HOLE)) [ndheat]
     context (HOLE => reval(HOLE)) - _ [ndheat]
     context _ - (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) << _ [ndheat]
     context _ << (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) >> _ [ndheat]
     context _ >> (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) < _ [ndheat]
     context _ < (HOLE => reval(HOLE)) [ndheat]
     context (HOLE => reval(HOLE)) <= _ [ndheat]
     context _ <= (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) > _ [ndheat]
     context _ > (HOLE => reval(HOLE)) [ndheat]
     context (HOLE => reval(HOLE)) >= _ [ndheat]
     context _ >= (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) == _ [ndheat]
     context _ == (HOLE => reval(HOLE)) [ndheat]
     context (HOLE => reval(HOLE)) != _ [ndheat]
     context _ != (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) & _ [ndheat]
     context _ & (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) ^ _ [ndheat]
     context _ ^ (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) | _ [ndheat]
     context _ | (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) && _ [ndheat]

     context (HOLE => reval(HOLE)) || _ [ndheat]

     context (HOLE => peval(HOLE)) := _ [ndheat]
     context _ := (HOLE => reval(HOLE)) [ndheat]

     context (HOLE => reval(HOLE)) ? _ : _

     /*
     (* A CAST can actually be a constructor expression *)
     | CAST of (specifier * decl_type) * init_expression
     */
     syntax Expression ::= "Cast" "(" K "," K "," K ")"
          [klabel('Cast), strict(1)]
     context Cast(_, _, (HOLE => reval(HOLE)))

     syntax Expression ::= "Cast" "(" K "," K ")"
          [klabel('Cast), strict(1)]
     context Cast(_, (HOLE => reval(HOLE)))

     // new // comp-lit id, spec, decl, init
     syntax Expression ::= "CompoundLiteral" "(" K "," K "," K "," K ")"
          [klabel('CompoundLiteral), strict(2)]
     /*
     (* There is a special form of CALL in which the function called
        __builtin_va_arg and the second argument is sizeof(T). This
        should be printed as just T *)
     | CALL of expression * expression list
     */

     syntax Expression ::= "Call" "(" K "," K ")"
          [klabel('Call)] // K, List
     context Call((HOLE => reval(HOLE)), _) [ndheat]
     /*
     | COMMA of expression list
     */
     // List
     syntax Expression ::= "Comma" "(" K ")" [klabel('Comma)]
     /*
     | CONSTANT of constant
     | PAREN of expression
     | VARIABLE of string
     */
     syntax Expression ::= Constant(K) [function]
     // String constants aren't revals
     // for paren, just putting parentheses
     syntax Expression ::= CId
     /*
     | EXPR_SIZEOF of expression
     | TYPE_SIZEOF of specifier * decl_type
     | EXPR_ALIGNOF of expression
     | TYPE_ALIGNOF of specifier * decl_type
     */
     syntax Expression ::= "SizeofExpression" "(" K ")"
          [klabel('SizeofExpression)]
     syntax Expression ::= "SizeofType" "(" K "," K ")"
          [klabel('SizeofType), strict(1)]
     syntax Expression ::= "AlignofExpression" "(" K ")"
          [klabel('AlignofExpression)]
     syntax Expression ::= "AlignofType" "(" K "," K ")"
          [klabel('AlignofType)]
     /*
     | INDEX of expression * expression
     */
     syntax Expression ::= K "[" K "]"
     /*
     | MEMBEROF of expression * string
     | MEMBEROFPTR of expression * string
     */
     syntax Expression ::= K "." CId
     context (HOLE => peval(HOLE)) . _:CId
     syntax Expression ::= K "->" CId
     context (HOLE => reval(HOLE)) -> _:CId
     /*
     | GNU_BODY of block
     | EXPR_PATTERN of String     (* pattern variable, and name *)
     */
     syntax Expression ::= GnuBody(K) [klabel('GnuBody)]
     syntax Expression ::= ExpressionPattern(String)
          [klabel('ExpressionPattern)]

     /*
     and constant =
     | CONST_INT of String   (* the textual representation *)
     | CONST_FLOAT of String (* the textual representaton *)
     | CONST_CHAR of int64 list
     | CONST_WCHAR of int64 list
     | CONST_STRING of string
     | CONST_WSTRING of int64 list
     */
     syntax IntConstant ::= DecimalConstant(K) [function]
     syntax IntConstant ::= OctalConstant(K) [function]
     syntax IntConstant ::= HexConstant(K) [function]

     // significand, exponent, approx
     syntax IntConstant ::= DecimalFloatConstant(String, Int, Float)
          [function]
     // significand, exponent, approx
     syntax IntConstant ::= HexFloatConstant(String, Int, Float)
          [function]

     syntax Constant ::= LitU(K) [function]
     syntax Constant ::= LitL(K) [function]
     syntax Constant ::= LitF(K) [function]
     syntax Constant ::= LitLL(K) [function]
     syntax Constant ::= LitUL(K) [function]
     syntax Constant ::= LitULL(K) [function]

     syntax Constant ::= NoSuffix(K) [function]

     syntax Constant ::= CharLiteral(Int) [function]
     syntax Constant ::= WCharLiteral(Int) [function]
     syntax Constant ::= StringLiteral(String) [function]
     syntax Constant ::= WStringLiteral(K) [function]

     /*
     and init_expression =
     | NO_INIT
     | SINGLE_INIT of expression
     | COMPOUND_INIT of (initwhat * init_expression) list
     */
     
     syntax KResult ::= "NoInit"
     syntax InitExpression ::= SingleInit(K)
          [klabel('SingleInit), hybrid, strict]
     // List
     syntax InitExpression ::= CompoundInit(K)
          [klabel('CompoundInit), hybrid, strict]
     // new; (initwhat * init_expression)
     syntax InitFragment ::= InitFragment(K, K)
          [klabel('InitFragment)]

     /*
     and initwhat =
     NEXT_INIT
     | INFIELD_INIT of String * initwhat
     | ATINDEX_INIT of expression * initwhat
     | ATINDEXRANGE_INIT of expression * expression
     */
     syntax KResult ::= "NextInit" | InFieldInit(CId, K)
				 | AtIndexInit(K, K) | AtIndexRangeInit(K, K)

     /*
     and attribute = String * expression list
     */
     // String, List
     syntax C ::= Attribute(String, K) [klabel('Attribute)]

     syntax KItem ::= CodeLoc(K, K) [klabel('CodeLoc)]

endmodule
