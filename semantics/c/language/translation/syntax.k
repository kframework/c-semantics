module C-ABSTRACT-SORTS
     imports C-DYNAMIC-SORTS
     syntax RValue ::= RHold
     syntax Nclv ::= NCLHold
     syntax KResult ::= HoldResult
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
     syntax TypeSpecifier ::= OversizedFloat()
     syntax TypeSpecifier ::= Signed()
     syntax TypeSpecifier ::= Unsigned()
     syntax TypeSpecifier ::= Named(CId)

     syntax Float ::= "inf" [function]

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
     syntax TypeSpecifier ::= StructDef(CId, K, KItem)
     syntax TypeSpecifier ::= UnionRef(CId, K) // new
     // new // CId, List
     syntax TypeSpecifier ::= UnionDef(CId, K, KItem)
     syntax TypeSpecifier ::= EnumRef(CId, K) // new
     // new // CId, List
     syntax TypeSpecifier ::= EnumDef(CId, K, KItem)

     syntax TypeSpecifier ::= Complex()
     syntax TypeSpecifier ::= Imaginary()

     syntax TypeSpecifier ::= AutoType()
     syntax SimpleAutoType ::= "auto-type"
     syntax SimpleType ::= SimpleAutoType
     syntax SimpleUType ::= SimpleAutoType

     syntax SpecifierElem ::= TypeofExpression(KItem)
     syntax SpecifierElem ::= TypeofType(KItem, KItem)
     syntax SpecifierElem ::= TAtomic(KItem, KItem)
     syntax SpecifierElem ::= AlignasExpression(KItem)
     syntax SpecifierElem ::= AlignasType(KItem, KItem)

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
     syntax Specifier ::= Specifier(KItem) [avoid]

     // Represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax KItem ::= DeclType(KItem, KItem) [avoid, strict(1)]

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
     syntax KItem ::= FunctionType(KItem) [strict]
     // third argument should also be strict, but not doing anything with
     // [strict 5] yet
     syntax KItem ::= ArrayType(KItem, K, KItem) [strict(1)]
     syntax KItem ::= PointerType(Specifier, KItem) [strict(2)]
     // K, List, Bool
     syntax KItem ::= Prototype(KItem, KItem, Bool) [strict(1)]
     syntax KItem ::= NoPrototype(KItem, KItem, Bool) [strict(1, 2)]

     syntax KItem ::= "NotVariadic"
     syntax KItem ::= "Variadic"

     /*
     and name_group = specifier * name list
     */ // K, List
     syntax KItem ::= NameGroup(K, KItem) [strict]

     /*
     (* The optional expression is the bitfield *)
     and field_group = specifier * (name * expression option) list
     */ // K, List
     syntax KItem ::= FieldGroup(KItem, KItem) [strict(1)]
     syntax KItem ::= FieldName(KItem)
     syntax KItem ::= BitFieldName(KItem, KItem)

     /*
     (* like name_group, except the declared variables are allowed to have
     initializers *)
     (* e.g.: Int x=1, y=2; *)
     and init_name_group = specifier * init_name list
     */
     // K, List
     syntax KItem ::= InitNameGroup(KItem, KItem) [strict(1)]

     /*
     The decl_type is in the order in which they are printed. Only the name of
     the declared identifier is pulled out. The attributes are those that are
     printed after the declarator
     (* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
     (* the string, and decl_type will be PTR([], JUSTBASE) *)
     and name = String * decl_type * attribute list * cabsloc
     */
     // first argument is id, second is basetype
     syntax KItem ::= Name(CId, KItem, KItem) [avoid]
     /*
     (* A variable declarator ("name") with an initializer *)
     and init_name = name * init_expression
     */
     syntax KItem ::= InitName(KItem, K)
     context InitName(_, (HOLE:KItem => reval(HOLE))) [ndheat, result(RValue)]

     /*
     (* Single names are for declarations that cannot come in groups, like
      * function parameters and functions *)
     and single_name = specifier * name
     */
     syntax KItem ::= SingleName(KItem, KItem) [strict(1)]

     /*
     and enum_item = String * expression * cabsloc
     */
     // this one has no init
     syntax KItem ::= EnumItem(CId)
     // this one has an init
     syntax KItem ::= EnumItemInit(CId, K)

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
     syntax KItem ::= FunctionDefinition(KItem, KItem) [strict(1)]
     syntax KItem ::= DeclarationDefinition(KItem)
     syntax KItem ::= Typedef(KItem)
     syntax KItem ::= OnlyTypedef(KItem)
     syntax KItem ::= GlobAsm(String)
     syntax KItem ::= Pragma(KItem)
     syntax KItem ::= PragmaKccRule(String)
     syntax KItem ::= Linkage(String, KItem)
     syntax KItem ::= StaticAssert(K, KItem)

     /*
     (* the String is a file name, and then the list of toplevel forms *)
     and file = String * definition list
     */
     // name, code, source
     // new: Filename, strings, ast, code
     syntax KItem ::= TranslationUnit(String, KItem, KItem)

     /*
     and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
     */
     syntax KItem ::= BlockStatement(KItem)
     syntax KItem ::= Block(Int, KItem, KItem)  [klabel(Block3)]
     syntax KItem ::= Sequence(KItem, KItem)

     /*
     | DOWHILE of expression * statement * cabsloc * cabsloc
     | FOR of for_clause * expression * expression * statement * cabsloc
     */
     syntax KItem ::= DoWhile(K, KItem, CabsLoc)  [klabel(DoWhile3)]
     syntax KItem ::= For(Int, KItem, K, K, K)  [klabel(For5)]

     // gcc extension
     syntax KItem ::= CaseRange(KItem, KItem, KItem)

     /*
     | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
     */
     syntax KItem ::= CompGoto(KItem)

     syntax KItem ::= OtherStatement()

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
     syntax KItem ::= OffsetOf(KItem, KItem, KItem) [strict(1)]
     syntax KItem ::= TypesCompat(KItem, KItem, KItem, KItem) [strict(1, 3)]
     syntax KItem ::= ExpressionLoc(KItem, KItem) [function]

     //must be declared as function,
     //otherwise, if then else rule failed in for(;;) cases
     syntax KItem ::= NothingExpression() [function]

     // For VLAs with unspecified size ([*]).
     syntax RValue ::= UnspecifiedSizeExpression()

     /*
     (* A CAST can actually be a constructor expression *)
     | CAST of (specifier * decl_type) * init_expression
     */
     syntax KItem ::= Cast(K, KItem, K)
     context Cast(HOLE:KItem, _, _)
     context Cast(_, _, (HOLE:KItem => reval(HOLE))) [result(RValue)]

     // new // comp-lit id, spec, decl, init
     syntax KItem ::= CompoundLiteral(Int, K, KItem, KItem) [strict(2)]
     /*
     | COMMA of expression list
     */
     // List
     syntax KItem ::= Comma(KItem)
     /*
     | CONSTANT of constant
     | PAREN of expression
     | VARIABLE of string
     */
     syntax KItem ::= Constant(KItem) [function]
     /*
     | EXPR_SIZEOF of expression
     | TYPE_SIZEOF of specifier * decl_type
     | EXPR_ALIGNOF of expression
     | TYPE_ALIGNOF of specifier * decl_type
     */
     syntax KItem ::= SizeofExpression(K)
     syntax KItem ::= SizeofType(KItem, K) [strict(1)]
     syntax KItem ::= AlignofExpression(KItem)
     syntax KItem ::= AlignofType(KItem, KItem) [strict(1)]
     syntax KItem ::= Generic(K, KItem)
     syntax KItem ::= GenericPair(KItem, KItem, KItem)
     syntax KItem ::= GenericDefault(KItem)
     /*
     | GNU_BODY of block
     | EXPR_PATTERN of String     (* pattern variable, and name *)
     */
     syntax KItem ::= ExpressionPattern(String)

     /*
     and constant =
     | CONST_INT of String   (* the textual representation *)
     | CONST_FLOAT of String (* the textual representaton *)
     | CONST_CHAR of int64 list
     | CONST_WCHAR of int64 list
     | CONST_STRING of string
     | CONST_WSTRING of int64 list
     */
     syntax IntConstant ::= DecimalConstant(KItem)
     syntax IntConstant ::= OctalConstant(KItem) [function]
     syntax IntConstant ::= HexConstant(KItem) [function]

     // significand, exponent, approx
     syntax FloatConstant ::= DecimalFloatConstant(String, Int, Float) [function]
     // significand, exponent, approx
     syntax FloatConstant ::= HexFloatConstant(String, Int, Float) [function]

     syntax Constant ::= LitU(Constant) [function]
     syntax Constant ::= LitL(Constant) [function]
     syntax Constant ::= LitLL(Constant) [function]
     syntax Constant ::= LitUL(Constant) [function]
     syntax Constant ::= LitULL(Constant) [function]
     syntax Constant ::= LitF(Constant) [function]

     syntax Constant ::= NoSuffix(Constant) [function]

     syntax Constant ::= CharLiteral(Int) [function]
     syntax Constant ::= WCharLiteral(Int) [function]
     syntax Constant ::= StringLiteral
     syntax StringLiteral ::= StringLiteral(String)
     syntax StringLiteral ::= WStringLiteral(KItem)

     /*
     and init_expression =
     | SINGLE_INIT of expression
     | COMPOUND_INIT of (initwhat * init_expression) list
     */

     syntax KItem ::= SingleInit(KItem) [strict]
     // List
     syntax KItem ::= CompoundInit(KItem) [strict]
     // new; (initwhat * init_expression)
     syntax KItem ::= InitFragment(KItem, KItem)

     /*
     and initwhat =
     NEXT_INIT
     | INFIELD_INIT of String * initwhat
     | ATINDEX_INIT of expression * initwhat
     | ATINDEXRANGE_INIT of expression * expression
     */
     syntax KResult ::= NextInit()
                      | InFieldInit(CId, KItem)
                      | AtIndexInit(K, KItem)
                      | AtIndexRangeInit(KItem, KItem)

     /*
     and attribute = String * expression list
     */
     // String, List

     syntax CId ::= AnonymousName() [function]

     syntax KItem ::= DefinitionLoc(KItem, CabsLoc)
     syntax KItem ::= DefinitionLocRange(KItem, CabsLoc, CabsLoc)
     // this wraps all statements with their location in the original file
     syntax KItem ::= StatementLoc(KItem, CabsLoc) // new

     /*
     and for_clause =
     FC_EXP of expression
     | FC_DECL of definition
     */
     syntax KItem ::= ForClauseExpression(KItem)

     syntax KItem ::= Conditional(KItem, KItem, KItem)

     syntax KItem ::= ArrayIndex(KItem, KItem)

     syntax KItem ::= Negative(KItem)
     syntax KItem ::= Positive(KItem)
     syntax KItem ::= LogicalNot(KItem)
     syntax KItem ::= BitwiseNot(KItem)
     syntax KItem ::= Dereference(KItem)
     syntax KItem ::= Reference(KItem)
     syntax KItem ::= PreIncrement(KItem)
     syntax KItem ::= PreDecrement(KItem)
     syntax KItem ::= PostIncrement(KItem)
     syntax KItem ::= PostDecrement(KItem)

     syntax KItem ::= Multiply(KItem, KItem)
     syntax KItem ::= Divide(KItem, KItem)
     syntax KItem ::= Modulo(KItem, KItem)
     syntax KItem ::= Plus(KItem, KItem)
     syntax KItem ::= Minus(KItem, KItem)
     syntax KItem ::= LeftShift(KItem, KItem)
     syntax KItem ::= RightShift(KItem, KItem)
     syntax KItem ::= LessThan(KItem, KItem)
     syntax KItem ::= LessThanOrEqual(KItem, KItem)
     syntax KItem ::= GreaterThan(KItem, KItem)
     syntax KItem ::= GreaterThanOrEqual(KItem, KItem)
     syntax KItem ::= Equality(KItem, KItem)
     syntax KItem ::= NotEquality(KItem, KItem)
     syntax KItem ::= BitwiseAnd(KItem, KItem)
     syntax KItem ::= BitwiseXor(KItem, KItem)
     syntax KItem ::= BitwiseOr(KItem, KItem)
     syntax KItem ::= LogicalAnd(KItem, KItem)
     syntax KItem ::= LogicalOr(KItem, KItem)

     syntax KItem ::= Assign(KItem, KItem)
     syntax KItem ::= AssignMultiply(KItem, KItem)
     syntax KItem ::= AssignDivide(KItem, KItem)
     syntax KItem ::= AssignModulo(KItem, KItem)
     syntax KItem ::= AssignPlus(KItem, KItem)
     syntax KItem ::= AssignMinus(KItem, KItem)
     syntax KItem ::= AssignBitwiseAnd(KItem, KItem)
     syntax KItem ::= AssignBitwiseXor(KItem, KItem)
     syntax KItem ::= AssignBitwiseOr(KItem, KItem)
     syntax KItem ::= AssignLeftShift(KItem, KItem)
     syntax KItem ::= AssignRightShift(KItem, KItem)

     syntax KItem ::= Dot(KItem, CId)
     syntax KItem ::= Arrow(KItem, CId)

endmodule

module C-ABSTRACT-REWRITING
     imports C-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports COMMON-SYNTAX
     imports FLOAT

     rule AnonymousName() => #NoName

     rule DefinitionLoc(K:KItem, L::CabsLoc) => CodeLoc(K, L) [anywhere]
     rule StatementLoc(K:KItem, L::CabsLoc) => CodeLoc(K, L) [anywhere]

     rule Conditional(K1:KItem, K2:KItem, K3:KItem) => K1 ? K2 : K3 [anywhere]
     rule Negative(K:KItem) => - K [anywhere]
     rule Positive(K:KItem) => + K [anywhere]
     rule LogicalNot(K:KItem) => ! K [anywhere]
     rule BitwiseNot(K:KItem) => ~ K [anywhere]
     rule Dereference(K:KItem) => * K [anywhere]
     rule Reference(K:KItem) => & K [anywhere]
     rule PreIncrement(K:KItem) => ++ K [anywhere]
     rule PreDecrement(K:KItem) => -- K [anywhere]
     rule PostIncrement(K:KItem) => K ++ [anywhere]
     rule PostDecrement(K:KItem) => K -- [anywhere]

     rule Multiply(K1:KItem, K2:KItem) => K1 * K2 [anywhere]
     rule Divide(K1:KItem, K2:KItem) => K1 / K2 [anywhere]
     rule Modulo(K1:KItem, K2:KItem) => K1 % K2 [anywhere]
     rule Plus(K1:KItem, K2:KItem) => K1 + K2 [anywhere]
     rule Minus(K1:KItem, K2:KItem) => K1 - K2 [anywhere]
     rule LeftShift(K1:KItem, K2:KItem) => K1 << K2 [anywhere]
     rule RightShift(K1:KItem, K2:KItem) => K1 >> K2 [anywhere]
     rule LessThan(K1:KItem, K2:KItem) => K1 < K2 [anywhere]
     rule LessThanOrEqual(K1:KItem, K2:KItem) => K1 <= K2 [anywhere]
     rule GreaterThan(K1:KItem, K2:KItem) => K1 > K2 [anywhere]
     rule GreaterThanOrEqual(K1:KItem, K2:KItem) => K1 >= K2 [anywhere]
     rule Equality(K1:KItem, K2:KItem) => K1 == K2 [anywhere]
     rule NotEquality(K1:KItem, K2:KItem) => K1 != K2 [anywhere]
     rule BitwiseAnd(K1:KItem, K2:KItem) => K1 & K2 [anywhere]
     rule BitwiseXor(K1:KItem, K2:KItem) => K1 ^ K2 [anywhere]
     rule BitwiseOr(K1:KItem, K2:KItem) => K1 | K2 [anywhere]
     rule LogicalAnd(K1:KItem, K2:KItem) => K1 && K2 [anywhere]
     rule LogicalOr(K1:KItem, K2:KItem) => K1 || K2 [anywhere]

     rule Assign(K1:KItem, K2:KItem) => K1 := K2 [anywhere]
     rule AssignMultiply(K1:KItem, K2:KItem) => K1 *= K2 [anywhere]
     rule AssignDivide(K1:KItem, K2:KItem) => K1 /= K2 [anywhere]
     rule AssignModulo(K1:KItem, K2:KItem) => K1 %= K2 [anywhere]
     rule AssignPlus(K1:KItem, K2:KItem) => K1 += K2 [anywhere]
     rule AssignMinus(K1:KItem, K2:KItem) => K1 -= K2 [anywhere]
     rule AssignBitwiseAnd(K1:KItem, K2:KItem) => K1 &= K2 [anywhere]
     rule AssignBitwiseXor(K1:KItem, K2:KItem) => K1 ^= K2 [anywhere]
     rule AssignBitwiseOr(K1:KItem, K2:KItem) => K1 |= K2 [anywhere]
     rule AssignLeftShift(K1:KItem, K2:KItem) => K1 <<= K2 [anywhere]
     rule AssignRightShift(K1:KItem, K2:KItem) => K1 >>= K2 [anywhere]

     rule Dot(K:KItem, X::CId) => K . X [anywhere]

     /*@ This macro defines an important identity from
     \source[n1570]{\para{6.5.3.2}{3}}. As a syntactic macro, it should run
     on programs before they even start to reduce. */
     rule &(*(K:KItem)) => K [anywhere]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{4}}}{
     A postfix expression followed by the \cinline{->} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member of the object to which the first expression
     points, and is an lvalue. \broken{If the first expression is a pointer to
     a qualified type, the result has the so-qualified version of the type of
     the designated member.}
     }*/
     rule Arrow(K:KItem, F::CId) => (* K) . F [anywhere]

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
     rule ArrayIndex(E1:KItem, E2:KItem) => *(E1 + E2) [anywhere]

     rule inf => 1.0 /Float 0.0

endmodule
