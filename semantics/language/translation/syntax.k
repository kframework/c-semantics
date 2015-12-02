module C-ABSTRACT-SYNTAX
     imports C-SYNTAX

     syntax RValue ::= RHold
     syntax KResult ::= NCLHold

     syntax SymBase ::= "nonStatic"

     // the rest are syntactic
     syntax C ::= AttributeWrapper(K, K) [function]

     syntax Statement // defined in C-ABSTRACT-SYNTAX

     syntax C ::= TypeSpecifier
     syntax C ::= Specifier
     syntax C ::= DeclType
     syntax C ::= NameGroup
     syntax C ::= FieldGroup
     syntax C ::= InitNameGroup
     syntax C ::= Name
     syntax C ::= InitName
     syntax C ::= SingleName
     syntax C ::= PureEnumItem
     syntax C ::= Constant
     syntax C ::= InitExpression
     syntax C ::= TranslationUnit
     syntax C ::= IntConstant
     syntax C ::= FloatConstant
     syntax C ::= InitFragment
     syntax C ::= FieldName
     syntax C ::= PureDefinition

     syntax Constant ::= IntConstant
     syntax Constant ::= FloatConstant

     // -------------------------------------------------
     // Below, I give the declaration as found in cabs.ml first, followed by
     // the K version

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
     syntax TypeSpecifier ::= Named(CId)
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
          [strict(2)]
     syntax TypeSpecifier ::= UnionRef(CId) // new
     // new // CId, List
     syntax C ::= UnionDef(CId, K)
          [strict(2)]
     syntax TypeSpecifier ::= EnumRef(CId) // new
     // new // CId, List
     syntax C ::= EnumDef(CId, K)

     syntax TypeSpecifier ::= TypeofExpression(K)

     syntax TypeSpecifier ::= TypeofType(K, K)

     syntax TypeSpecifier ::= "Complex"
     syntax TypeSpecifier ::= "Imaginary"
     syntax TypeSpecifier ::= TAtomic(K, K)
     syntax TypeSpecifier ::= AlignasExpression(K)
     syntax TypeSpecifier ::= AlignasType(K, K)

     /*
     and spec_elem =
     SpecTypedef
     | SpecType of typeSpecifier
     | SpecPattern of String       (* specifier pattern variable *)
     */
     syntax SpecifierElem ::= TypeSpecifier
     syntax SpecifierElem ::= SpecPattern(CId)

     /*
     and specifier = spec_elem list
     */
     syntax Specifier ::= Specifier(K) [avoid]

     // Represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax KItem ::= DeclType(K, K) [avoid, strict(1)]

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
     syntax DeclType ::= FunctionType(K) [strict]
     // third argument should also be strict, but not doing anything with
     // [strict 5] yet
     syntax DeclType ::= ArrayType(K, K, K) [strict(1)]
     syntax DeclType ::= PointerType(Specifier, K) [strict(2)]
     // K, List, Bool
     syntax DeclType ::= Prototype(K, K, Bool) [strict(1)]
     syntax DeclType ::= NoPrototype(K, K, Bool) [strict(1, 2)]

     syntax KItem ::= "NotVariadic"
     syntax KItem ::= "Variadic"

     /*
     and name_group = specifier * name list
     */ // K, List
     syntax NameGroup ::= NameGroup(K, K) [strict]

     /*
     (* The optional expression is the bitfield *)
     and field_group = specifier * (name * expression option) list
     */ // K, List
     syntax FieldGroup ::= FieldGroup(K, K) [strict(1)]
     syntax FieldName ::= FieldName(K)
     syntax FieldName ::= BitFieldName(K, K)

     /*
     (* like name_group, except the declared variables are allowed to have
     initializers *)
     (* e.g.: Int x=1, y=2; *)
     and init_name_group = specifier * init_name list
     */
     // K, List
     syntax InitNameGroup ::= InitNameGroup(K, K) [strict(1)]

     /*
     The decl_type is in the order in which they are printed. Only the name of
     the declared identifier is pulled out. The attributes are those that are
     printed after the declarator
     (* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
     (* the string, and decl_type will be PTR([], JUSTBASE) *)
     and name = String * decl_type * attribute list * cabsloc
     */
     // first argument is id, second is basetype
     syntax Name ::= Name(K, K) [avoid]
     //might not need this
     syntax CId ::= ToIdentifier(String) [function]
     /*
     (* A variable declarator ("name") with an initializer *)
     and init_name = name * init_expression
     */
     syntax InitName ::= InitName(K, K)
     context InitName(_, (HOLE:KItem => reval(HOLE))) [ndheat, result(RValue)]

     /*
     (* Single names are for declarations that cannot come in groups, like
      * function parameters and functions *)
     and single_name = specifier * name
     */
     syntax SingleName ::= SingleName(K, K)
          [strict(1)]

     /*
     and enum_item = String * expression * cabsloc
     */
     // this one has no init
     syntax PureEnumItem ::= EnumItem(CId)
     // this one has an init
     syntax PureEnumItem ::= EnumItemInit(CId, K)

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
     syntax PureDefinition ::= FunctionDefinition(K, K) [strict(1)]
     syntax PureDefinition ::= DeclarationDefinition(K)
     syntax PureDefinition ::= Typedef(K)
     syntax PureDefinition ::= OnlyTypedef(K)
     syntax PureDefinition ::= GlobAsm(String)
     syntax PureDefinition ::= Pragma(K)
     syntax PureDefinition ::= PragmaKccInv(String) | PragmaKccRule(String)
     syntax PureDefinition ::= Linkage(String, K)
     syntax PureDefinition ::= Transformer(K, K )
     syntax PureDefinition ::= ExpressionTransformer(K, K)

     // name
     syntax PureDefinition ::= LTLAnnotation(CId, K)

     /*
     (* the String is a file name, and then the list of toplevel forms *)
     and file = String * definition list
     */
     // name, code, source
     // new: Filename, strings, ast, code
     syntax TranslationUnit ::= TranslationUnit(String, K, K)

     /*
     and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
     */
     syntax Statement ::= BlockStatement(K)
     syntax Statement ::= Block(Int, K, K)
     syntax Statement ::= Sequence(K, K)

     /*
     | FOR of for_clause * expression * expression * statement * cabsloc
     */
     syntax Statement ::= For(Int, K, K, K, K)

     // gcc extension
     syntax Statement ::= CaseRange(K, K, K)

     /*
     | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
     */
     syntax Statement ::= CompGoto(K)

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
     syntax Expression ::= OffsetOf(K, K, K) [strict(1)]
     syntax Expression ::= ExpressionLoc(K, K) [function]

     //must be declared as function,
     //otherwise, if then else rule failed in for(;;) cases
     syntax Expression ::= "NothingExpression" [function]

     // For VLAs with unspecified size ([*]).
     syntax RValue ::= "UnspecifiedSizeExpression"

     /*
     (* A CAST can actually be a constructor expression *)
     | CAST of (specifier * decl_type) * init_expression
     */
     syntax Expression ::= Cast(K, K, K)
     context Cast(HOLE:KItem, _, _)
     context Cast(_, _, (HOLE:KItem => reval(HOLE))) [result(RValue)]

     // new // comp-lit id, spec, decl, init
     syntax Expression ::= CompoundLiteral(K, K, K, K) [strict(2)]
     /*
     | COMMA of expression list
     */
     // List
     syntax Expression ::= Comma(K)
     /*
     | CONSTANT of constant
     | PAREN of expression
     | VARIABLE of string
     */
     syntax Expression ::= Constant(K)
     /*
     | EXPR_SIZEOF of expression
     | TYPE_SIZEOF of specifier * decl_type
     | EXPR_ALIGNOF of expression
     | TYPE_ALIGNOF of specifier * decl_type
     */
     syntax Expression ::= SizeofExpression(K)
     syntax Expression ::= SizeofType(K, K) [strict(1)]
     syntax Expression ::= AlignofExpression(K)
     syntax Expression ::= AlignofType(K, K) [strict(1)]
     /*
     | INDEX of expression * expression
     */
     syntax Expression ::= K "[" K "]"
     /*
     | MEMBEROFPTR of expression * string
     */
     syntax Expression ::= K "->" CId [left]
     /*
     | GNU_BODY of block
     | EXPR_PATTERN of String     (* pattern variable, and name *)
     */
     syntax Expression ::= GnuBody(K)
     syntax Expression ::= ExpressionPattern(String)

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
     syntax FloatConstant ::= DecimalFloatConstant(String, Int, Float)
          [function]
     // significand, exponent, approx
     syntax FloatConstant ::= HexFloatConstant(String, Int, Float)
          [function]

     syntax Constant ::= LitU(Constant)
     syntax Constant ::= LitL(Constant)
     syntax Constant ::= LitLL(Constant)
     syntax Constant ::= LitUL(Constant)
     syntax Constant ::= LitULL(Constant)
     syntax Constant ::= LitF(Constant)

     syntax Constant ::= NoSuffix(K)

     syntax Constant ::= CharLiteral(Int)
     syntax Constant ::= WCharLiteral(Int)
     syntax Constant ::= StringLiteral(String)
     syntax Constant ::= WStringLiteral(K)

     /*
     and init_expression =
     | SINGLE_INIT of expression
     | COMPOUND_INIT of (initwhat * init_expression) list
     */

     syntax InitExpression ::= SingleInit(K) [strict]
     // List
     syntax InitExpression ::= CompoundInit(K) [strict]
     // new; (initwhat * init_expression)
     syntax InitFragment ::= InitFragment(K, K)

     /*
     and initwhat =
     NEXT_INIT
     | INFIELD_INIT of String * initwhat
     | ATINDEX_INIT of expression * initwhat
     | ATINDEXRANGE_INIT of expression * expression
     */
     syntax KResult ::= "NextInit"
                      | InFieldInit(CId, K)
                      | AtIndexInit(K, K)
                      | AtIndexRangeInit(K, K)

     /*
     and attribute = String * expression list
     */
     // String, List
     syntax C ::= Attribute(String, K)

     syntax KItem ::= "AnonymousName" // new, argument is type
     rule AnonymousName => #NoName [anywhere]

     syntax C ::= Definition
     syntax C ::= ForClause
     syntax Definition ::= DefinitionLoc(K, CabsLoc)
     syntax Definition ::= DefinitionLocRange(K, CabsLoc, CabsLoc)
     // this wraps all statements with their location in the original file
     syntax Statement ::= StatementLoc(K, K) // new

     rule DefinitionLoc(K::K, L::CabsLoc) => CodeLoc(K, L) [anywhere]
     rule StatementLoc(K::K, L::CabsLoc) => CodeLoc(K, L) [anywhere]

     syntax PureDefinition ::= StaticAssert(K, K)

     /*
     and for_clause =
     FC_EXP of expression
     | FC_DECL of definition
     */
     syntax ForClause ::= ForClauseExpression(K)

     syntax Expression ::= Conditional(K, K, K)
     rule Conditional(K1::K, K2::K, K3::K) => K1 ? K2 : K3 [anywhere]

     syntax Expression ::= ArrayIndex(K, K)
     rule ArrayIndex(K1::K, K2::K) => K1[K2]::Expression [anywhere]

     syntax Expression ::= Negative(K)
     rule Negative(K::K) => - K [anywhere]
     syntax Expression ::= Positive(K)
     rule Positive(K::K) => + K [anywhere]
     syntax Expression ::= LogicalNot(K)
     rule LogicalNot(K::K) => ! K [anywhere]
     syntax Expression ::= BitwiseNot(K)
     rule BitwiseNot(K::K) => ~ K [anywhere]
     syntax Expression ::= Dereference(K)
     rule Dereference(K::K) => * K [anywhere]
     syntax Expression ::= Reference(K)
     rule Reference(K::K) => & K [anywhere]
     syntax Expression ::= PreIncrement(K)
     rule PreIncrement(K::K) => ++ K [anywhere]
     syntax Expression ::= PreDecrement(K)
     rule PreDecrement(K::K) => -- K [anywhere]
     syntax Expression ::= PostIncrement(K)
     rule PostIncrement(K::K) => K ++ [anywhere]
     syntax Expression ::= PostDecrement(K)
     rule PostDecrement(K::K) => K -- [anywhere]

     syntax Expression ::= Multiply(K, K)
     rule Multiply(K1::K, K2::K) => K1 * K2 [anywhere]
     syntax Expression ::= Divide(K, K)
     rule Divide(K1::K, K2::K) => K1 / K2 [anywhere]
     syntax Expression ::= Modulo(K, K)
     rule Modulo(K1::K, K2::K) => K1 % K2 [anywhere]
     syntax Expression ::= Plus(K, K)
     rule Plus(K1::K, K2::K) => K1 + K2 [anywhere]
     syntax Expression ::= Minus(K, K)
     rule Minus(K1::K, K2::K) => K1 - K2 [anywhere]
     syntax Expression ::= LeftShift(K, K)
     rule LeftShift(K1::K, K2::K) => K1 << K2 [anywhere]
     syntax Expression ::= RightShift(K, K)
     rule RightShift(K1::K, K2::K) => K1 >> K2 [anywhere]
     syntax Expression ::= LessThan(K, K)
     rule LessThan(K1::K, K2::K) => K1 < K2 [anywhere]
     syntax Expression ::= LessThanOrEqual(K, K)
     rule LessThanOrEqual(K1::K, K2::K) => K1 <= K2 [anywhere]
     syntax Expression ::= GreaterThan(K, K)
     rule GreaterThan(K1::K, K2::K) => K1 > K2 [anywhere]
     syntax Expression ::= GreaterThanOrEqual(K, K)
     rule GreaterThanOrEqual(K1::K, K2::K) => K1 >= K2 [anywhere]
     syntax Expression ::= Equality(K, K)
     rule Equality(K1::K, K2::K) => K1 == K2 [anywhere]
     syntax Expression ::= NotEquality(K, K)
     rule NotEquality(K1::K, K2::K) => K1 != K2 [anywhere]
     syntax Expression ::= BitwiseAnd(K, K)
     rule BitwiseAnd(K1::K, K2::K) => K1 & K2 [anywhere]
     syntax Expression ::= BitwiseXor(K, K)
     rule BitwiseXor(K1::K, K2::K) => K1 ^ K2 [anywhere]
     syntax Expression ::= BitwiseOr(K, K)
     rule BitwiseOr(K1::K, K2::K) => K1 | K2 [anywhere]
     syntax Expression ::= LogicalAnd(K, K)
     rule LogicalAnd(K1::K, K2::K) => K1 && K2 [anywhere]
     syntax Expression ::= LogicalOr(K, K)
     rule LogicalOr(K1::K, K2::K) => K1 || K2 [anywhere]

     syntax Expression ::= Assign(K, K)
     rule Assign(K1::K, K2::K) => K1 := K2 [anywhere]
     syntax Expression ::= AssignMultiply(K, K)
     rule AssignMultiply(K1::K, K2::K) => K1 *= K2 [anywhere]
     syntax Expression ::= AssignDivide(K, K)
     rule AssignDivide(K1::K, K2::K) => K1 /= K2 [anywhere]
     syntax Expression ::= AssignModulo(K, K)
     rule AssignModulo(K1::K, K2::K) => K1 %= K2 [anywhere]
     syntax Expression ::= AssignPlus(K, K)
     rule AssignPlus(K1::K, K2::K) => K1 += K2 [anywhere]
     syntax Expression ::= AssignMinus(K, K)
     rule AssignMinus(K1::K, K2::K) => K1 -= K2 [anywhere]
     syntax Expression ::= AssignBitwiseAnd(K, K)
     rule AssignBitwiseAnd(K1::K, K2::K) => K1 &= K2 [anywhere]
     syntax Expression ::= AssignBitwiseXor(K, K)
     rule AssignBitwiseXor(K1::K, K2::K) => K1 ^= K2 [anywhere]
     syntax Expression ::= AssignBitwiseOr(K, K)
     rule AssignBitwiseOr(K1::K, K2::K) => K1 |= K2 [anywhere]
     syntax Expression ::= AssignLeftShift(K, K)
     rule AssignLeftShift(K1::K, K2::K) => K1 <<= K2 [anywhere]
     syntax Expression ::= AssignRightShift(K, K)
     rule AssignRightShift(K1::K, K2::K) => K1 >>= K2 [anywhere]

     syntax Expression ::= Dot(K, CId)
     rule Dot(K::K, X::CId) => K . X [anywhere]
     syntax Expression ::= Arrow(K, CId)
     rule Arrow(K::K, X::CId) => K -> X [anywhere]

     syntax KItem ::= CodeLoc(K, CabsLoc)

     /*@ This macro defines an important identity from
     \source[n1570]{\para{6.5.3.2}{3}}. As a syntactic macro, it should run
     on programs before they even start to reduce. */
     rule &(*(K::K)) => K [anywhere]

endmodule
