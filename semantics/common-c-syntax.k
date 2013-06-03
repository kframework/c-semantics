module COMMON-C-SYNTAX
     // imports K // TODO TOOL BUG fixme if I include K, it doesn't actually include K
     
     //tags ndlocal ndheat computational structural interpRule anywhere observable

     // these are semantic
     syntax K ::= "reval" "(" K ")" [semantic, strict]
     syntax K ::= "peval" "(" K ")" [semantic, strict]
     
     // the rest are syntactic
     syntax C ::= "AttributeWrapper" "(" K "," K ")" [klabel('AttributeWrapper)]
     
     // sort C
     syntax C ::= Id
      // chathhorn (List => klist)
     syntax C ::= "klist" "(" KList ")" [klabel('klist)]
     // hybrid doesn't work with list operator, and strict doesn't do what's expected
     
     syntax K ::= "StmtCons" "(" K "," K ")" [klabel('StmtCons)]
     
     //@ this production ensures that a TypeResult sort is created, together with an 'isTypeResult predicate
     syntax TypeResult ::= "dummyTypeProduction"
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
     syntax C ::= Definition
     syntax C ::= Block
     syntax C ::= Statement
     syntax C ::= PureStatement
     syntax C ::= PureEnumItem
     syntax C ::= ForClause
     syntax C ::= Expression
     syntax C ::= Constant
     syntax C ::= InitExpression
     syntax C ::= Program
     syntax C ::= TranslationUnit
     syntax C ::= IntConstant
     syntax C ::= InitFragment
     syntax C ::= FieldName
     syntax C ::= PureDefinition

// -------------------------------------------------
// Below, I give the declaration as found in cabs.ml first, followed by the K version
     
/*
type cabsloc = {
          lineno : int;
          filename: string;
          lineOffsetStart: int;
          lineOffsetEnd : int;
     }
*/
     syntax CabsLoc ::= "CabsLoc" "(" String "," Int "," Int "," Int ")" [klabel('CabsLoc)]
     
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
     // rule inf => Infinity [macro]
     syntax TypeSpecifier ::= "Named" "(" Id ")" [klabel('Named)]
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
     syntax TypeSpecifier ::= "StructRef" "(" Id ")" [klabel('StructRef)] // new
     syntax TypeSpecifier ::= "StructDef" "(" Id "," K ")" [klabel('StructDef)] // new // Id, List
     context StructDef(_:Id, klist((_:KList,, HOLE,, _:KList)))
     syntax TypeSpecifier ::= "UnionRef" "(" Id ")" [klabel('UnionRef)] // new
     syntax TypeSpecifier ::= "UnionDef" "(" Id "," K ")" [klabel('UnionDef)] // new // Id, List
     context UnionDef(_:Id, klist((_:KList,, HOLE,, _:KList)))
     syntax TypeSpecifier ::= "EnumRef" "(" Id ")" [klabel('EnumRef)] // new
     syntax TypeSpecifier ::= "EnumDef" "(" Id "," K ")" [klabel('EnumDef)] // new // Id, List
     syntax TypeSpecifier ::= "TypeofExpression" "(" K ")" [klabel('TypeofExpression)]
     syntax TypeSpecifier ::= "TypeofType" "(" K "," K ")" [klabel('TypeofType)]
     
     syntax TypeSpecifier ::= "Complex" 
     syntax TypeSpecifier ::= "Imaginary"
     syntax TypeSpecifier ::= "TAtomic" "(" K "," K ")" [klabel('TAtomic)]
     syntax TypeSpecifier ::= "Atomic" // this will be used as the actual modifier
     syntax TypeSpecifier ::= "AlignasExpression" "(" K ")" [klabel('AlignasExpression)]
     syntax TypeSpecifier ::= "AlignasType" "(" K "," K ")" [klabel('AlignasType)]

/*
and storage =
     NO_STORAGE | AUTO | STATIC | EXTERN | REGISTER
*/
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
     syntax SpecifierElem ::= "SpecPattern" "(" Id ")" [klabel('SpecPattern)]
     
/*
     and specifier = spec_elem list
*/
     syntax Specifier ::= "Specifier" "(" K ")" [klabel('Specifier)]
      syntax "Specifier" -/- [a-zA-Z\:]
     context Specifier(klist((_:KList,, HOLE,, _:KList)))
     
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
     syntax K ::= "JustBase"
     syntax DeclType ::= "FunctionType" "(" K ")" [klabel('FunctionType), strict]
     syntax DeclType ::= "ArrayType" "(" K "," K "," K ")" [klabel('ArrayType), strict(1)] // third argument should also be strict, but not doing anything with [strict 5] yet
     context ArrayType(_, (HOLE => reval(HOLE)), _) // TODO(chathhorn) [ndheat]
     syntax DeclType ::= "PointerType" "(" K ")" [klabel('PointerType), strict]
     syntax DeclType ::= "Prototype" "(" K "," K "," Bool ")" [klabel('Prototype), strict(1)] // K, List, Bool
     context Prototype(_, klist((_:KList,, HOLE,, _:KList)), _:Bool)
     
     syntax K ::= "NotVariadic"
     syntax K ::= "Variadic"
     
     
/*
and name_group = specifier * name list
*/
     syntax NameGroup ::= "NameGroup" "(" K "," K ")" [klabel('NameGroup), strict(1)] // K, List
     context NameGroup(_, klist((_:KList,, HOLE,, _:KList)))
     
/*
     (* The optional expression is the bitfield *)
and field_group = specifier * (name * expression option) list
*/
     syntax FieldGroup ::= "FieldGroup" "(" K "," K ")" [klabel('FieldGroup), strict(1)] // K, List
     syntax FieldName ::= "FieldName" "(" K ")" [klabel('FieldName)] // new
     syntax FieldName ::= "BitFieldName" "(" K "," K ")" [klabel('BitFieldName)] // new
     
/*
     (* like name_group, except the declared variables are allowed to have initializers *)
     (* e.g.: Int x=1, y=2; *)
and init_name_group = specifier * init_name list
*/
     syntax InitNameGroup ::= "InitNameGroup" "(" K "," K ")" [klabel('InitNameGroup), strict(1)] // K, List
     
/*
     (* The decl_type is in the order in which they are printed. Only the name of
      * the declared identifier is pulled out. The attributes are those that are
      * printed after the declarator *)
     (* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
     (* the string, and decl_type will be PTR([], JUSTBASE) *)
and name = String * decl_type * attribute list * cabsloc
*/
      // TODO(chathhorn): better solution?
     syntax Name ::= "Name" "(" K "," K ")" [klabel('Name)] // first argument is id, second is basetype
      syntax "Name" -/- [a-zA-Z\:]
     syntax K ::= "AnonymousName" // new, argument is type
     syntax Id ::= "#NoName" // new
     // [metadata "latex=(renameTo \\#NoName)"] 
     syntax Id ::= "#NoName" "(" Int ")" [klabel('#NoName)] // new
     // metadata "latex=(renameTo \\#NoName\\mybracket{_})"
     syntax Id ::= "Identifier" "(" String ")" [klabel('Identifier)] // new     
     
     rule AnonymousName => #NoName [macro]
     
/*
     (* A variable declarator ("name") with an initializer *)
and init_name = name * init_expression
*/
     syntax InitName ::= "InitName" "(" K "," K ")" [klabel('InitName)]
     context InitName(_, (HOLE => reval(HOLE))) // TODO(chathhorn): [ndheat]
     
/*
     (* Single names are for declarations that cannot come in groups, like
      * function parameters and functions *)
and single_name = specifier * name
*/
     syntax SingleName ::= "SingleName" "(" K "," K ")" [klabel('SingleName), strict(1)]
     
/*
and enum_item = String * expression * cabsloc
*/
     syntax PureEnumItem ::= "EnumItem" "(" Id ")" [klabel('EnumItem)] // this one has no init
     syntax PureEnumItem ::= "EnumItemInit" "(" Id "," K ")" [klabel('EnumItemInit)] // this one has an init
          
/*
     (*
     ** Declaration definition (at toplevel)
     *)
     and definition =
        FUNDEF of single_name * block * cabsloc * cabsloc
      | DECDEF of init_name_group * cabsloc        (* variable(s), or function prototype *)
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
     syntax PureDefinition ::= "FunctionDefinition" "(" K "," K ")" [klabel('FunctionDefinition), strict(1)]
     syntax PureDefinition ::= "DeclarationDefinition" "(" K ")" [klabel('DeclarationDefinition)]
     syntax PureDefinition ::= "Typedef" "(" K ")" [klabel('Typedef)]
     syntax PureDefinition ::= "OnlyTypedef" "(" K ")" [klabel('OnlyTypedef)]
     syntax PureDefinition ::= "GlobAsm" "(" String ")" [klabel('GlobAsm)]
     syntax PureDefinition ::= "Pragma" "(" K ")" [klabel('Pragma)]
     syntax PureDefinition ::= "Linkage" "(" String "," K ")" [klabel('Linkage)] // seems to be unused
      syntax "Linkage" -/- [a-zA-Z\:]
     syntax PureDefinition ::= "Transformer" "(" K "," K ")" [klabel('Transformer)] // seems to be unused
     syntax PureDefinition ::= "ExpressionTransformer" "(" K "," K ")" [klabel('ExpressionTransformer)]
     syntax PureDefinition ::= "LTLAnnotation" "(" K ")" [klabel('LTLAnnotation)] // name
     
     // new
     syntax Expression ::= "LTL-Atom" "(" K ")" [klabel('LTL-Atom)]
     syntax Expression ::= "LTL-Builtin" "(" K ")" [klabel('LTL-Builtin)]
     
     syntax Expression ::= "LTL-True"
     syntax Expression ::= "LTL-False"
     syntax Expression ::= "LTL-And" "(" K "," K ")" [klabel('LTL-And)]
     syntax Expression ::= "LTL-Or" "(" K "," K ")" [klabel('LTL-Or)]
     syntax Expression ::= "LTL-Not" "(" K ")" [klabel('LTL-Not)]
     syntax Expression ::= "LTL-Next" "(" K ")" [klabel('LTL-Next)]
     syntax Expression ::= "LTL-Always" "(" K ")" [klabel('LTL-Always)]
     syntax Expression ::= "LTL-Eventually" "(" K ")" [klabel('LTL-Eventually)]
     syntax Expression ::= "LTL-Until" "(" K "," K ")" [klabel('LTL-Until)]
     syntax Expression ::= "LTL-Release" "(" K "," K ")" [klabel('LTL-Release)]
     syntax Expression ::= "LTL-Implies" "(" K "," K ")" [klabel('LTL-Implies)]
     syntax Expression ::= "LTL-Equiv" "(" K "," K ")" [klabel('LTL-Equiv)]
     syntax Expression ::= "LTL-WeakUntil" "(" K "," K ")" [klabel('LTL-WeakUntil)]
     
     syntax Definition ::= "DefinitionLoc" "(" K "," K ")" [klabel('DefinitionLoc)] // new
     syntax Definition ::= "DefinitionLocRange" "(" K "," K "," K ")" [klabel('DefinitionLocRange)] // new
     
/*
(* the String is a file name, and then the list of toplevel forms *)
and file = String * definition list
*/
     // name, code, source
     syntax TranslationUnit ::= "TranslationUnit" "(" String "," K "," K "," String ")" [klabel('TranslationUnit)] // new: Filename, strings, ast, code
     syntax Program ::= "Program" "(" K ")" [klabel('Program)] // new // List

/*
     (* A block contains a list of local label declarations ( GCC's ({ __label__ 
      * l1, l2; ... }) ) , a list of definitions and a list of statements  *)
and block = 
     { blabels: String list;
       battrs: attribute list;
       bstmts: statement list
     } 
*/
     syntax Block ::= "Block" "(" Int "," K "," K ")" [klabel('Block)] // Int, list, list
      syntax "Block" -/- [a-zA-Z\:]

/*
and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
*/
     syntax PureStatement ::= "Nop"
     syntax PureStatement ::= "Computation" "(" K ")" [klabel('Computation), latex({{#1}};)]
     context Computation((HOLE => reval(HOLE))) // not sure why i had this commented out before...
     syntax PureStatement ::= "BlockStatement" "(" K ")" [klabel('BlockStatement)]
     syntax PureStatement ::= "Sequence" "(" K "," K ")" [klabel('Sequence)]
/*
     | IF of expression * statement * statement * cabsloc
     | WHILE of expression * statement * cabsloc
     | DOWHILE of expression * statement * cabsloc
     | FOR of for_clause * expression * expression * statement * cabsloc
*/
     syntax PureStatement ::= "IfThenElse" "(" K "," K "," K ")" [klabel('IfThenElse)]
     context IfThenElse((HOLE => reval(HOLE)), _, _)
     syntax PureStatement ::= "While" "(" K "," K ")" [klabel('While)]
     syntax PureStatement ::= "DoWhile" "(" K "," K ")" [klabel('DoWhile)]
     syntax PureStatement ::= "For" "(" Int "," K "," K "," K "," K ")" [klabel('For)] // id, ...
/*
     | BREAK of cabsloc
     | CONTINUE of cabsloc
     | RETURN of expression * cabsloc
*/
     syntax PureStatement ::= "Break" [klabel('Break)]
     syntax PureStatement ::= "Continue" [klabel('Continue)]
     syntax PureStatement ::= "Return" "(" K ")" [klabel('Return)]
      syntax "Return" -/- [a-zA-Z\:]
     context Return((HOLE => reval(HOLE)))
/*
     | SWITCH of expression * statement * cabsloc
     | CASE of expression * statement * cabsloc
     | CASERANGE of expression * expression * statement * cabsloc
     | DEFAULT of statement * cabsloc
*/
     syntax PureStatement ::= "Switch" "(" K "," K "," K ")" [klabel('Switch)] // unique switch id
     context Switch(_, (HOLE => reval(HOLE)), _)
     syntax PureStatement ::= "Case" "(" Int "," Int "," K "," K ")" [klabel('Case)] // unique switch id, unique case id, exp, statement
     syntax PureStatement ::= "CaseRange" "(" K "," K "," K ")" [klabel('CaseRange)] // gcc extension
     syntax PureStatement ::= "Default" "(" Int "," K ")" [klabel('Default)] // unique switch id, statement 
/*
     | LABEL of String * statement * cabsloc
     | GOTO of String * cabsloc
     | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
     | DEFINITION of definition (*definition or declaration of a variable or type*)
*/
     syntax PureStatement ::= "Label" "(" Id "," K ")" [klabel('Label)]
      syntax "Label" -/- [a-zA-Z\:]
     syntax PureStatement ::= "Goto" "(" K ")" [klabel('Goto)] // Id
     syntax PureStatement ::= "CompGoto" "(" K ")" [klabel('CompGoto)]
     
     // this wraps all statements with their location in the original file
     syntax Statement ::= "StatementLoc" "(" K "," K ")" [klabel('StatementLoc)] // new
     
/*
and for_clause = 
     FC_EXP of expression
     | FC_DECL of definition
*/
     syntax ForClause ::= "ForClauseExpression" "(" K ")" [klabel('ForClauseExpression)]
     
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
     syntax Expression ::= "OffsetOf" "(" K "," K "," K ")" [klabel('OffsetOf), strict(1)]
     syntax Expression ::= "ExpressionLoc" "(" K "," K ")" [klabel('ExpressionLoc)] // new

     syntax Expression ::= "NothingExpression"
/*
     | UNARY of unary_operator * expression

and unary_operator =
     MINUS | PLUS | NOT | BNOT | MEMOF | ADDROF
     | PREINCR | PREDECR | POSINCR | POSDECR
*/
     syntax Expression ::= "-" K [prec(22)] // type-strict=()
                         | "+" K [prec(22)] // type-strict=()
                         | "!" K [prec(22)] // type-strict=()
                         | "~" K [prec(22)] // type-strict=()
                         | "*" K [prec(22)] // type-strict=()
                         | "&" K [strict, prec(22)] // type-strict=()
                         | "++" K [prec(22)] // type-strict=()
                         | "--" K [latex(\terminal{-{}-}{#1}), prec(22)] // type-strict=()
                         | K "++" // type-strict=()
                         | K "--" [latex({#1}\terminal{-{}-})] // type-strict=()
/* | BINARY of binary_operator * expression * expression */
                         > K "*" K [prec(31), left] // type-strict=()
                         | K "/" K [prec(31), left] // type-strict=()
                         | K "%" K [prec(31), left] // type-strict=()
                         > K "+" K [prec(33), left] // type-strict=()
                         | K "-" K [prec(33), left] // type-strict=()
                          > K "<<" K [latex({{#1}}\ll{{#2}}), prec(35), left] // type-strict=(1)
                         | K ">>" K [latex({{#1}}\gg{{#2}}), prec(35), left] // type-strict=(1)
                          > K "<" K [prec(37), left] // type-strict=()
                         | K "<=" K [prec(37), left] // type-strict=()
                         | K ">" K [prec(37), left] // type-strict=()
                         | K ">=" K [prec(37), left] // type-strict=()
                          > K "==" K [prec(39), left] // type-strict=()
                         | K "!=" K [prec(39), left] // type-strict=()
                          > K "&" K [prec(41), left] // type-strict=()
                          > K "^" K [prec(43), left] // type-strict=()
                          > K "|" K [prec(45), left] // type-strict=()
                          > K "&&" K [prec(47), left] // type-strict=()
                          > K "||" K [prec(49), left] // type-strict=()
/* | QUESTION of expression * expression * expression */
                          > K "?" K ":" K [prec(51), left, gather(e & E)] // type-strict=(2 3)
                          > K "*=" K [prec(53)] // type-strict=(1)
                         | K "/=" K [prec(53)] // type-strict=(1)
                         | K "%=" K [prec(53)] // type-strict=(1)
                         | K "+=" K [prec(53)] // type-strict=(1)
                         | K "-=" K [prec(53)] // type-strict=(1)
                         | K "<<=" K [latex({{#1}}\terminal{$\gg$=}{{#2}}), prec(53)] // type-strict=(1)
                         | K "&=" K [prec(53)] // type-strict=(1)
                         | K "^=" K [prec(53)] // type-strict=(1)
                         | K "|=" K [prec(53)] // type-strict=(1)
                         | K ">>=" K [latex({{#1}}\terminal{$\ll$=}{{#2}}), prec(53)] // type-strict=(1)
                         | K ":=" K [prec(53)] // type-strict=(1)

      syntax "&" -/- [\&]
      syntax "+" -/- [\+]
      syntax "-" -/- [\-]
      
     context - (HOLE => reval(HOLE))
     context + (HOLE => reval(HOLE))
     context ! (HOLE => reval(HOLE))
     context ~ (HOLE => reval(HOLE))
     context * (HOLE => reval(HOLE))
     context (HOLE => peval(HOLE)) ++
     context (HOLE => peval(HOLE)) --
     context (HOLE => reval(HOLE)) * _ // TODO(chathhorn) [ndheat]
     context _ * (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     context (HOLE => reval(HOLE)) / _ // TODO(chathhorn) [ndheat]
     context _ / (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     context (HOLE => reval(HOLE)) % _ // TODO(chathhorn) [ndheat]
     context _ % (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) + _ // TODO(chathhorn) [ndheat]
     context _ + (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     context (HOLE => reval(HOLE)) - _ // TODO(chathhorn) [ndheat]
     context _ - (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) << _ // TODO(chathhorn) [ndheat]
     context _ << (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) >> _ // TODO(chathhorn) [ndheat]
     context _ >> (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) < _ // TODO(chathhorn) [ndheat]
     context _ < (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     context (HOLE => reval(HOLE)) <= _ // TODO(chathhorn) [ndheat]
     context _ <= (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) > _ // TODO(chathhorn) [ndheat]
     context _ > (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     context (HOLE => reval(HOLE)) >= _ // TODO(chathhorn) [ndheat]
     context _ >= (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) == _ // TODO(chathhorn) [ndheat]
     context _ == (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     context (HOLE => reval(HOLE)) != _ // TODO(chathhorn) [ndheat]
     context _ != (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) & _ // TODO(chathhorn) [ndheat]
     context _ & (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) ^ _ // TODO(chathhorn) [ndheat]
     context _ ^ (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) | _ // TODO(chathhorn) [ndheat]
     context _ | (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) && _ // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) || _ // TODO(chathhorn) [ndheat]
     
     context (HOLE => peval(HOLE)) := _ // TODO(chathhorn) [ndheat]
     context _ := (HOLE => reval(HOLE)) // TODO(chathhorn) [ndheat]
     
     context (HOLE => reval(HOLE)) ? _ : _

/*
     (* A CAST can actually be a constructor expression *)
     | CAST of (specifier * decl_type) * init_expression
*/
     syntax Expression ::= "Cast" "(" K "," K "," K ")" [klabel('Cast), strict(1)]
     context Cast(_, _, (HOLE => reval(HOLE)))
     
     syntax Expression ::= "CompoundLiteral" "(" K "," K "," K "," K ")" [klabel('CompoundLiteral), strict(2)] // new // comp-lit id, spec, decl, init
/*
     (* There is a special form of CALL in which the function called
        __builtin_va_arg and the second argument is sizeof(T). This 
        should be printed as just T *)
     | CALL of expression * expression list
*/

      // type-strict=(1)
     syntax Expression ::= "Call" "(" K "," K ")" [klabel('Call)] // K, List
     context Call((HOLE => reval(HOLE)), _) // TODO(chathhorn) [ndheat]
     context Call(_, klist((_:KList,, (HOLE => reval(HOLE)),, _:KList))) // TODO(chathhorn) [ndheat]
/*
     | COMMA of expression list
*/
     syntax Expression ::= "Comma" "(" K ")" [klabel('Comma)] // List
     context Comma(klist(((HOLE => reval(HOLE)),, _:KList))) // TODO(chathhorn) [ndheat]
/*
     | CONSTANT of constant
     | PAREN of expression
     | VARIABLE of string
*/
     syntax Expression ::= "Constant" "(" K ")" [klabel('Constant)] // [latex({#1})]
     // String constants aren't revals
     // for paren, just putting parentheses
     syntax Expression ::= Id
/*
     | EXPR_SIZEOF of expression
     | TYPE_SIZEOF of specifier * decl_type
     | EXPR_ALIGNOF of expression
     | TYPE_ALIGNOF of specifier * decl_type
*/
     syntax Expression ::= "SizeofExpression" "(" K ")" [klabel('SizeofExpression)]
     syntax Expression ::= "SizeofType" "(" K "," K ")" [klabel('SizeofType), strict(1)]
     syntax Expression ::= "AlignofExpression" "(" K ")" [klabel('AlignofExpression)]
     syntax Expression ::= "AlignofType" "(" K "," K ")" [klabel('AlignofType)]
/*
     | INDEX of expression * expression
*/
      // type-strict=()
     syntax Expression ::= K "[" K "]"
/*
     | MEMBEROF of expression * string
     | MEMBEROFPTR of expression * string
*/
      // type-strict=(1)
     syntax Expression ::= K "." Id
     context (HOLE => peval(HOLE)) . _:Id
     syntax Expression ::= K "->" Id
     context (HOLE => reval(HOLE)) -> _:Id
/*
     | GNU_BODY of block
     | EXPR_PATTERN of String     (* pattern variable, and name *)
*/
     syntax Expression ::= "GnuBody" "(" K ")" [klabel('GnuBody)]
     syntax Expression ::= "ExpressionPattern" "(" String ")" [klabel('ExpressionPattern)]
     
/*
and constant =
     | CONST_INT of String   (* the textual representation *)
     | CONST_FLOAT of String (* the textual representaton *)
     | CONST_CHAR of int64 list
     | CONST_WCHAR of int64 list
     | CONST_STRING of string
     | CONST_WSTRING of int64 list 
*/
     syntax IntConstant ::= "DecimalConstant" "(" K ")" [klabel('DecimalConstant)] // new
     syntax IntConstant ::= "OctalConstant" "(" K ")" [klabel('OctalConstant)]  // new
     syntax IntConstant ::= "HexConstant" "(" K ")" [klabel('HexConstant)]  // new // expected to be string
     
     syntax IntConstant ::= "DecimalFloatConstant" "(" String "," Int "," Float ")" [klabel('DecimalFloatConstant)] // new; significand, exponent, approx
     syntax IntConstant ::= "HexFloatConstant" "(" String "," Int "," Float ")" [klabel('HexFloatConstant)] // new; significand, exponent, approx
     
     syntax Constant ::= "ConstU" "(" K ")" [klabel('ConstU)] // new
     syntax Constant ::= "ConstL" "(" K ")" [klabel('ConstL)] // new
     syntax Constant ::= "ConstF" "(" K ")" [klabel('ConstF)] // new
     syntax Constant ::= "ConstLL" "(" K ")" [klabel('ConstLL)] // new
     syntax Constant ::= "ConstUL" "(" K ")" [klabel('ConstUL)] // new
     syntax Constant ::= "ConstULL" "(" K ")" [klabel('ConstULL)] // new

     syntax Constant ::= "NoSuffix" "(" K ")" [klabel('NoSuffix)] // new
     
     syntax Constant ::= "CharLiteral" "(" Int ")" [klabel('CharLiteral)]
     syntax Constant ::= "WCharLiteral" "(" Int ")" [klabel('WCharLiteral)]
     syntax Constant ::= "StringLiteral" "(" String ")" [klabel('StringLiteral)]
     syntax Constant ::= "WStringLiteral" "(" KList ")" [klabel('WStringLiteral)]
     

/*
and init_expression =
  | NO_INIT
  | SINGLE_INIT of expression
  | COMPOUND_INIT of (initwhat * init_expression) list
*/
     syntax KResult ::= "NoInit" // InitExpression
     syntax InitExpression ::= "SingleInit" "(" K ")" [klabel('SingleInit), hybrid, strict]
     syntax InitExpression ::= "CompoundInit" "(" K ")" [klabel('CompoundInit), hybrid, strict] // List
     syntax InitFragment ::= "InitFragment" "(" K "," K ")" [klabel('InitFragment)] // new; (initwhat * init_expression)
     
/*
and initwhat =
     NEXT_INIT
     | INFIELD_INIT of String * initwhat
     | ATINDEX_INIT of expression * initwhat
     | ATINDEXRANGE_INIT of expression * expression
*/
     syntax KResult ::= "NextInit"
     syntax KResult ::= "InFieldInit" "(" Id "," K ")" [klabel('InFieldInit)]
     syntax KResult ::= "AtIndexInit" "(" K "," K ")" [klabel('AtIndexInit)]
     syntax KResult ::= "AtIndexRangeInit" "(" K "," K ")" [klabel('AtIndexRangeInit)] // nonstandard

     
/*
and attribute = String * expression list
*/
     syntax C ::= "Attribute" "(" String "," K ")" [klabel('Attribute)] // String, List
     
     syntax K ::= "CodeLoc" "(" K "," K ")" [klabel('CodeLoc)]
     rule DefinitionLoc(K:K, L:K) => CodeLoc(K:K, L:K) [macro]
     rule StatementLoc(K:K, L:K) => CodeLoc(K:K, L:K) [macro]
     rule DefinitionLocRange(K:K, _, L:K) => CodeLoc(K:K, L:K) [macro]
     
     
     /*@ This macro defines an important identity from \source[n1570]{\para{6.5.3.2}{3}}.  As a syntactic macro, it should run on programs before they even start to reduce. */
     rule &(*(K:K)) => K:K [macro]
          

     /*@ The below rules simply transform the prefix AST names to the infix/mixfix names we use from now on */
     
     // all these rules are temporary while I adjust the semantics to the new grammar
     syntax Expression ::= "Conditional" "(" K "," K "," K ")" [klabel('Conditional)]
     rule Conditional(K1:K, K2:K, K3:K) => K1:K ? K2:K : K3:K [macro]
     
     syntax Expression ::= "ArrayIndex" "(" K "," K ")" [klabel('ArrayIndex)]
     rule ArrayIndex(K1:K, K2:K) => K1:K[K2:K] [macro]
     
     syntax Expression ::= "Negative" "(" K ")" [klabel('Negative)]
     rule Negative(K:K) => - K:K [macro]
     syntax Expression ::= "Positive" "(" K ")" [klabel('Positive)]
     rule Positive(K:K) => + K:K [macro]
     syntax Expression ::= "LogicalNot" "(" K ")" [klabel('LogicalNot)]
     rule LogicalNot(K:K) => ! K:K [macro]
     syntax Expression ::= "BitwiseNot" "(" K ")" [klabel('BitwiseNot)]
     rule BitwiseNot(K:K) => ~ K:K [macro]
     syntax Expression ::= "Dereference" "(" K ")" [klabel('Dereference)]
     rule Dereference(K:K) => * K:K [macro]
     syntax Expression ::= "Reference" "(" K ")" [klabel('Reference)]
     rule Reference(K:K) => & K:K [macro]
     syntax Expression ::= "PreIncrement" "(" K ")" [klabel('PreIncrement)]
     rule PreIncrement(K:K) => ++ K:K [macro]
     syntax Expression ::= "PreDecrement" "(" K ")" [klabel('PreDecrement)]
     rule PreDecrement(K:K) => -- K:K [macro]
     syntax Expression ::= "PostIncrement" "(" K ")" [klabel('PostIncrement)]
     rule PostIncrement(K:K) => K:K ++ [macro]
     syntax Expression ::= "PostDecrement" "(" K ")" [klabel('PostDecrement)]
     rule PostDecrement(K:K) => K:K -- [macro]

     // ops Multiply : K K -> Expression
      syntax Expression ::= "Multiply" "(" K "," K ")" [klabel('Multiply)]
     rule Multiply(K1:K, K2:K) => K1:K * K2:K [macro]
     // ops Divide : K K -> Expression
      syntax Expression ::= "Divide" "(" K "," K ")" [klabel('Divide)]
     rule Divide(K1:K, K2:K) => K1:K / K2:K [macro]
     // ops Modulo : K K -> Expression
      syntax Expression ::= "Modulo" "(" K "," K ")" [klabel('Modulo)]
     rule Modulo(K1:K, K2:K) => K1:K % K2:K [macro]
     // ops Plus : K K -> Expression
      syntax Expression ::= "Plus" "(" K "," K ")" [klabel('Plus)]
     rule Plus(K1:K, K2:K) => K1:K + K2:K [macro]
     // ops Minus : K K -> Expression
      syntax Expression ::= "Minus" "(" K "," K ")" [klabel('Minus)]
     rule Minus(K1:K, K2:K) => K1:K - K2:K [macro]
     // ops LeftShift : K K -> Expression
      syntax Expression ::= "LeftShift" "(" K "," K ")" [klabel('LeftShift)]
     rule LeftShift(K1:K, K2:K) => K1:K << K2:K [macro]
     // ops RightShift : K K -> Expression
      syntax Expression ::= "RightShift" "(" K "," K ")" [klabel('RightShift)]
     rule RightShift(K1:K, K2:K) => K1:K >> K2:K [macro]
     // ops LessThan : K K -> Expression
      syntax Expression ::= "LessThan" "(" K "," K ")" [klabel('LessThan)]
     rule LessThan(K1:K, K2:K) => K1:K < K2:K [macro]
     // ops LessThanOrEqual : K K -> Expression
      syntax Expression ::= "LessThanOrEqual" "(" K "," K ")" [klabel('LessThanOrEqual)]
     rule LessThanOrEqual(K1:K, K2:K) => K1:K <= K2:K [macro]
     // ops GreaterThan : K K -> Expression
      syntax Expression ::= "GreaterThan" "(" K "," K ")" [klabel('GreaterThan)]
     rule GreaterThan(K1:K, K2:K) => K1:K > K2:K [macro]
     // ops GreaterThanOrEqual : K K -> Expression
      syntax Expression ::= "GreaterThanOrEqual" "(" K "," K ")" [klabel('GreaterThanOrEqual)]
     rule GreaterThanOrEqual(K1:K, K2:K) => K1:K >= K2:K [macro]
     // ops Equality : K K -> Expression
      syntax Expression ::= "Equality" "(" K "," K ")" [klabel('Equality)]
     rule Equality(K1:K, K2:K) => K1:K == K2:K [macro]
     // ops NotEquality : K K -> Expression
      syntax Expression ::= "NotEquality" "(" K "," K ")" [klabel('NotEquality)]
     rule NotEquality(K1:K, K2:K) => K1:K != K2:K [macro]
     // ops BitwiseAnd : K K -> Expression
      syntax Expression ::= "BitwiseAnd" "(" K "," K ")" [klabel('BitwiseAnd)]
     rule BitwiseAnd(K1:K, K2:K) => K1:K & K2:K [macro]
     // ops BitwiseXor : K K -> Expression
      syntax Expression ::= "BitwiseXor" "(" K "," K ")" [klabel('BitwiseXor)]
     rule BitwiseXor(K1:K, K2:K) => K1:K ^ K2:K [macro]
     // ops BitwiseOr : K K -> Expression
      syntax Expression ::= "BitwiseOr" "(" K "," K ")" [klabel('BitwiseOr)]
     rule BitwiseOr(K1:K, K2:K) => K1:K | K2:K [macro]
     // ops LogicalAnd : K K -> Expression
      syntax Expression ::= "LogicalAnd" "(" K "," K ")" [klabel('LogicalAnd)]
     rule LogicalAnd(K1:K, K2:K) => K1:K && K2:K [macro]
     // ops LogicalOr : K K -> Expression
      syntax Expression ::= "LogicalOr" "(" K "," K ")" [klabel('LogicalOr)]
     rule LogicalOr(K1:K, K2:K) => K1:K || K2:K [macro]
     

     // ops Assign : K K -> Expression
      syntax Expression ::= "Assign" "(" K "," K ")" [klabel('Assign)]
     rule Assign(K1:K, K2:K) => K1:K := K2:K [macro]
     // ops AssignMultiply : K K -> Expression
      syntax Expression ::= "AssignMultiply" "(" K "," K ")" [klabel('AssignMultiply)]
     rule AssignMultiply(K1:K, K2:K) => K1:K *= K2:K [macro]
     // ops AssignDivide : K K -> Expression
      syntax Expression ::= "AssignDivide" "(" K "," K ")" [klabel('AssignDivide)]
     rule AssignDivide(K1:K, K2:K) => K1:K /= K2:K [macro]
     // ops AssignModulo : K K -> Expression
      syntax Expression ::= "AssignModulo" "(" K "," K ")" [klabel('AssignModulo)]
     rule AssignModulo(K1:K, K2:K) => K1:K %= K2:K [macro]
     // ops AssignPlus : K K -> Expression
      syntax Expression ::= "AssignPlus" "(" K "," K ")" [klabel('AssignPlus)]
     rule AssignPlus(K1:K, K2:K) => K1:K += K2:K [macro]
     // ops AssignMinus : K K -> Expression
      syntax Expression ::= "AssignMinus" "(" K "," K ")" [klabel('AssignMinus)]
     rule AssignMinus(K1:K, K2:K) => K1:K -= K2:K [macro]
     // ops AssignBitwiseAnd : K K -> Expression
      syntax Expression ::= "AssignBitwiseAnd" "(" K "," K ")" [klabel('AssignBitwiseAnd)]
     rule AssignBitwiseAnd(K1:K, K2:K) => K1:K &= K2:K [macro]
     // ops AssignBitwiseXor : K K -> Expression
      syntax Expression ::= "AssignBitwiseXor" "(" K "," K ")" [klabel('AssignBitwiseXor)]
     rule AssignBitwiseXor(K1:K, K2:K) => K1:K ^= K2:K [macro]
     // ops AssignBitwiseOr : K K -> Expression
      syntax Expression ::= "AssignBitwiseOr" "(" K "," K ")" [klabel('AssignBitwiseOr)]
     rule AssignBitwiseOr(K1:K, K2:K) => K1:K |= K2:K [macro]
     // ops AssignLeftShift : K K -> Expression
      syntax Expression ::= "AssignLeftShift" "(" K "," K ")" [klabel('AssignLeftShift)]
     rule AssignLeftShift(K1:K, K2:K) => K1:K <<= K2:K [macro]
     // ops AssignRightShift : K K -> Expression
      syntax Expression ::= "AssignRightShift" "(" K "," K ")" [klabel('AssignRightShift)]
     rule AssignRightShift(K1:K, K2:K) => K1:K >>= K2:K [macro]
     
     // ops Dot : K Id -> Expression
     syntax Expression ::= "Dot" "(" K "," Id ")" [klabel('Dot)]
     rule Dot(K:K, X:Id) => K:K . X:Id [macro]
     syntax Expression ::= "Arrow" "(" K "," Id ")" [klabel('Arrow)]
     rule Arrow(K:K, X:Id) => K:K -> X:Id [macro]

endmodule
