module C-ABSTRACT-SORTS
     imports C-DYNAMIC-SORTS
     syntax RValue ::= RHold
     syntax Nclv ::= NCLHold
endmodule

module C-ABSTRACT-SYNTAX
     imports C-ABSTRACT-SORTS
     imports SET
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports C-REVAL-SYNTAX
     imports C-TYPING-SORTS

     syntax SymBase ::= "nonStatic"

     // the rest are syntactic
     syntax C ::= AttributeWrapper(K, K) [function]

     syntax Statement // defined in C-ABSTRACT-SYNTAX

     syntax C ::= TypeSpecifier
     syntax C ::= Specifier
     syntax C ::= DeclTypeSyntax
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
     syntax TypeSpecifier ::= Void()
     syntax TypeSpecifier ::= Char()
     syntax TypeSpecifier ::= Bool()
     syntax TypeSpecifier ::= Short()
     syntax TypeSpecifier ::= Int()
     syntax TypeSpecifier ::= Long()
     syntax TypeSpecifier ::= OversizedInt()
     syntax TypeSpecifier ::= Float()
     syntax TypeSpecifier ::= Double()
     syntax TypeSpecifier ::= Signed()
     syntax TypeSpecifier ::= Unsigned()
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
     syntax TypeSpecifier ::= StructRef(CId, K)
     // new // CId, List
     syntax TypeSpecifier ::= StructDef(CId, K, K)
     syntax TypeSpecifier ::= UnionRef(CId, K) // new
     // new // CId, List
     syntax TypeSpecifier ::= UnionDef(CId, K, K)
     syntax TypeSpecifier ::= EnumRef(CId, K) // new
     // new // CId, List
     syntax TypeSpecifier ::= EnumDef(CId, K, K)

     syntax TypeSpecifier ::= Complex()
     syntax TypeSpecifier ::= Imaginary()

     syntax TypeSpecifier ::= AutoType()
     syntax SimpleAutoType ::= "auto-type"
     syntax SimpleType ::= SimpleAutoType
     syntax SimpleUType ::= SimpleAutoType

     syntax SpecifierElem ::= TypeofExpression(K)
     syntax SpecifierElem ::= TypeofType(K, K)
     syntax SpecifierElem ::= TAtomic(K, K)
     syntax SpecifierElem ::= AlignasExpression(K)
     syntax SpecifierElem ::= AlignasType(K, K)

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
     syntax KItem ::= JustBase()
     syntax DeclTypeSyntax ::= FunctionType(K) [strict]
     // third argument should also be strict, but not doing anything with
     // [strict 5] yet
     syntax DeclTypeSyntax ::= ArrayType(K, K, K) [strict(1)]
     syntax DeclTypeSyntax ::= PointerType(Specifier, K) [strict(2)]
     // K, List, Bool
     syntax DeclTypeSyntax ::= Prototype(K, K, Bool) [strict(1)]
     syntax DeclTypeSyntax ::= NoPrototype(K, K, Bool) [strict(1, 2)]

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
     syntax Name ::= Name(K, K, K) [avoid]
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
     syntax Statement ::= Block(Int, K, K)  [klabel(Block3)]
     syntax Statement ::= Sequence(K, K)

     /*
     | DOWHILE of expression * statement * cabsloc * cabsloc
     | FOR of for_clause * expression * expression * statement * cabsloc
     */
     syntax Statement ::= DoWhile(K, K, CabsLoc)  [klabel(DoWhile3)]
     syntax Statement ::= For(Int, K, K, K, K)  [klabel(For5)]

     // gcc extension
     syntax Statement ::= CaseRange(K, K, K)

     /*
     | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
     */
     syntax Statement ::= CompGoto(K)

     syntax Statement ::= OtherStatement()

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
     syntax Expression ::= TypesCompat(K, K, K, K) [strict(1, 3)]
     syntax Expression ::= ExpressionLoc(K, K) [function]

     //must be declared as function,
     //otherwise, if then else rule failed in for(;;) cases
     syntax Expression ::= NothingExpression() [function]

     // For VLAs with unspecified size ([*]).
     syntax RValue ::= UnspecifiedSizeExpression()

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
     syntax Expression ::= Constant(K) [function]
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
     syntax Expression ::= Generic(K, K)
     syntax Expression ::= GenericPair(K, K, K)
     syntax Expression ::= GenericDefault(K)
     /*
     | GNU_BODY of block
     | EXPR_PATTERN of String     (* pattern variable, and name *)
     */
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
     syntax IntConstant ::= DecimalConstant(K)
     syntax IntConstant ::= OctalConstant(K) [function]
     syntax IntConstant ::= HexConstant(K) [function]

     // significand, exponent, approx
     syntax FloatConstant ::= DecimalFloatConstant(String, Int, Float)
          [function]
     // significand, exponent, approx
     syntax FloatConstant ::= HexFloatConstant(String, Int, Float)
          [function]

     syntax Constant ::= LitU(Constant) [function]
     syntax Constant ::= LitL(Constant) [function]
     syntax Constant ::= LitLL(Constant) [function]
     syntax Constant ::= LitUL(Constant) [function]
     syntax Constant ::= LitULL(Constant) [function]
     syntax Constant ::= LitF(Constant) [function]

     syntax Constant ::= NoSuffix(K) [function]

     syntax Constant ::= CharLiteral(Int) [function]
     syntax Constant ::= WCharLiteral(Int) [function]
     syntax Constant ::= StringLiteral
     syntax StringLiteral ::= StringLiteral(String)
     syntax StringLiteral ::= WStringLiteral(K)

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
     syntax KResult ::= NextInit()
                      | InFieldInit(CId, K)
                      | AtIndexInit(K, K)
                      | AtIndexRangeInit(K, K)

     /*
     and attribute = String * expression list
     */
     // String, List

     syntax KItem ::= AnonymousName() // new, argument is type

     syntax C ::= Definition
     syntax C ::= ForClause
     syntax Definition ::= DefinitionLoc(K, CabsLoc)
     syntax Definition ::= DefinitionLocRange(K, CabsLoc, CabsLoc)
     // this wraps all statements with their location in the original file
     syntax Statement ::= StatementLoc(K, K) // new

     syntax PureDefinition ::= StaticAssert(K, K)

     /*
     and for_clause =
     FC_EXP of expression
     | FC_DECL of definition
     */
     syntax ForClause ::= ForClauseExpression(K)

     syntax Expression ::= Conditional(K, K, K)

     syntax Expression ::= ArrayIndex(K, K)

     syntax Expression ::= Negative(K)
     syntax Expression ::= Positive(K)
     syntax Expression ::= LogicalNot(K)
     syntax Expression ::= BitwiseNot(K)
     syntax Expression ::= Dereference(K)
     syntax Expression ::= Reference(K)
     syntax Expression ::= PreIncrement(K)
     syntax Expression ::= PreDecrement(K)
     syntax Expression ::= PostIncrement(K)
     syntax Expression ::= PostDecrement(K)

     syntax Expression ::= Multiply(K, K)
     syntax Expression ::= Divide(K, K)
     syntax Expression ::= Modulo(K, K)
     syntax Expression ::= Plus(K, K)
     syntax Expression ::= Minus(K, K)
     syntax Expression ::= LeftShift(K, K)
     syntax Expression ::= RightShift(K, K)
     syntax Expression ::= LessThan(K, K)
     syntax Expression ::= LessThanOrEqual(K, K)
     syntax Expression ::= GreaterThan(K, K)
     syntax Expression ::= GreaterThanOrEqual(K, K)
     syntax Expression ::= Equality(K, K)
     syntax Expression ::= NotEquality(K, K)
     syntax Expression ::= BitwiseAnd(K, K)
     syntax Expression ::= BitwiseXor(K, K)
     syntax Expression ::= BitwiseOr(K, K)
     syntax Expression ::= LogicalAnd(K, K)
     syntax Expression ::= LogicalOr(K, K)

     syntax Expression ::= Assign(K, K)
     syntax Expression ::= AssignMultiply(K, K)
     syntax Expression ::= AssignDivide(K, K)
     syntax Expression ::= AssignModulo(K, K)
     syntax Expression ::= AssignPlus(K, K)
     syntax Expression ::= AssignMinus(K, K)
     syntax Expression ::= AssignBitwiseAnd(K, K)
     syntax Expression ::= AssignBitwiseXor(K, K)
     syntax Expression ::= AssignBitwiseOr(K, K)
     syntax Expression ::= AssignLeftShift(K, K)
     syntax Expression ::= AssignRightShift(K, K)

     syntax Expression ::= Dot(K, CId)
     syntax Expression ::= Arrow(K, CId)

endmodule

module C-ABSTRACT-REWRITING
     imports C-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports COMMON-SYNTAX

     rule AnonymousName() => #NoName [anywhere]

     rule DefinitionLoc(K::K, L::CabsLoc) => CodeLoc(K, L) [anywhere]
     rule StatementLoc(K::K, L::CabsLoc) => CodeLoc(K, L) [anywhere]

     rule Conditional(K1::K, K2::K, K3::K) => K1 ? K2 : K3 [anywhere]
     rule Negative(K::K) => - K [anywhere]
     rule Positive(K::K) => + K [anywhere]
     rule LogicalNot(K::K) => ! K [anywhere]
     rule BitwiseNot(K::K) => ~ K [anywhere]
     rule Dereference(K::K) => * K [anywhere]
     rule Reference(K::K) => & K [anywhere]
     rule PreIncrement(K::K) => ++ K [anywhere]
     rule PreDecrement(K::K) => -- K [anywhere]
     rule PostIncrement(K::K) => K ++ [anywhere]
     rule PostDecrement(K::K) => K -- [anywhere]

     rule Multiply(K1::K, K2::K) => K1 * K2 [anywhere]
     rule Divide(K1::K, K2::K) => K1 / K2 [anywhere]
     rule Modulo(K1::K, K2::K) => K1 % K2 [anywhere]
     rule Plus(K1::K, K2::K) => K1 + K2 [anywhere]
     rule Minus(K1::K, K2::K) => K1 - K2 [anywhere]
     rule LeftShift(K1::K, K2::K) => K1 << K2 [anywhere]
     rule RightShift(K1::K, K2::K) => K1 >> K2 [anywhere]
     rule LessThan(K1::K, K2::K) => K1 < K2 [anywhere]
     rule LessThanOrEqual(K1::K, K2::K) => K1 <= K2 [anywhere]
     rule GreaterThan(K1::K, K2::K) => K1 > K2 [anywhere]
     rule GreaterThanOrEqual(K1::K, K2::K) => K1 >= K2 [anywhere]
     rule Equality(K1::K, K2::K) => K1 == K2 [anywhere]
     rule NotEquality(K1::K, K2::K) => K1 != K2 [anywhere]
     rule BitwiseAnd(K1::K, K2::K) => K1 & K2 [anywhere]
     rule BitwiseXor(K1::K, K2::K) => K1 ^ K2 [anywhere]
     rule BitwiseOr(K1::K, K2::K) => K1 | K2 [anywhere]
     rule LogicalAnd(K1::K, K2::K) => K1 && K2 [anywhere]
     rule LogicalOr(K1::K, K2::K) => K1 || K2 [anywhere]

     rule Assign(K1::K, K2::K) => K1 := K2 [anywhere]
     rule AssignMultiply(K1::K, K2::K) => K1 *= K2 [anywhere]
     rule AssignDivide(K1::K, K2::K) => K1 /= K2 [anywhere]
     rule AssignModulo(K1::K, K2::K) => K1 %= K2 [anywhere]
     rule AssignPlus(K1::K, K2::K) => K1 += K2 [anywhere]
     rule AssignMinus(K1::K, K2::K) => K1 -= K2 [anywhere]
     rule AssignBitwiseAnd(K1::K, K2::K) => K1 &= K2 [anywhere]
     rule AssignBitwiseXor(K1::K, K2::K) => K1 ^= K2 [anywhere]
     rule AssignBitwiseOr(K1::K, K2::K) => K1 |= K2 [anywhere]
     rule AssignLeftShift(K1::K, K2::K) => K1 <<= K2 [anywhere]
     rule AssignRightShift(K1::K, K2::K) => K1 >>= K2 [anywhere]

     rule Dot(K::K, X::CId) => K . X [anywhere]

     /*@ This macro defines an important identity from
     \source[n1570]{\para{6.5.3.2}{3}}. As a syntactic macro, it should run
     on programs before they even start to reduce. */
     rule &(*(K::K)) => K [anywhere]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{4}}}{
     A postfix expression followed by the \cinline{->} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member of the object to which the first expression
     points, and is an lvalue. \broken{If the first expression is a pointer to
     a qualified type, the result has the so-qualified version of the type of
     the designated member.}
     }*/
     rule Arrow(K::K, F::CId) => (* K) . F [anywhere]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.1}{2--3}}}{
     A postfix expression followed by an expression in square brackets
     \cinline{[]} is a subscripted designation of an element of an array
     object. The definition of the subscript operator \cinline{[]} is that
     \cinline{E1[E2]} is identical to \cinline{(*((E1)+(E2)))}. Because of the
     conversion rules that apply to the binary \cinline{+} operator, if
     \cinline{E1} is an array object (equivalently, a pointer to the initial
     element of an array object) and \cinline{E2} is an integer,
     \cinline{E1[E2]} designates the \cinline{E2}-th element of \cinline{E1}
     (counting from zero).

     Successive subscript operators designate an element of a multidimensional
     array object. If \cinline{E} is an $n$-dimensional array ($n \ge 2$) with
     dimensions $i \times j \times\cdots\times k$, then \cinline{E} (used as
     other than an lvalue) is converted to a pointer to an ($n -
     1$)-dimensional array with dimensions $j \times\cdots\times k$. If the
     unary \cinline{*} operator is applied to this pointer explicitly, or
     implicitly as a result of subscripting, the result is the referenced ($n -
     1$)-dimensional array, which itself is converted into a pointer if used as
     other than an lvalue. It follows from this that arrays are stored in
     row-major order (last subscript varies fastest).
     }*/
     rule ArrayIndex(E1::K, E2::K) => *(E1 + E2) [anywhere]


endmodule
