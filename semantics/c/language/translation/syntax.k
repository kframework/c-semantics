module C-ABSTRACT-SORTS
     imports C-DYNAMIC-SORTS
     syntax RValue ::= RHold
     syntax Nclv ::= NCLHold
     syntax KResult ::= HoldResult
endmodule

module C-ABSTRACT-SYNTAX
     imports C-ABSTRACT-SORTS
     imports COMPAT-SORTS
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
     syntax TypeSpecifier ::= Void() [symbol]
     syntax TypeSpecifier ::= Char() [symbol]
     syntax TypeSpecifier ::= Bool() [symbol]
     syntax TypeSpecifier ::= Short() [symbol]
     syntax TypeSpecifier ::= Int() [symbol]
     syntax TypeSpecifier ::= Long() [symbol]
     syntax TypeSpecifier ::= OversizedInt() [symbol]
     syntax TypeSpecifier ::= Float() [symbol]
     syntax TypeSpecifier ::= Double() [symbol]
     syntax TypeSpecifier ::= OversizedFloat() [symbol]
     syntax TypeSpecifier ::= Signed() [symbol]
     syntax TypeSpecifier ::= Unsigned() [symbol]
     syntax TypeSpecifier ::= Named(CId) [symbol]

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
     syntax TypeSpecifier ::= StructRef(CId, K) [symbol]
     // new // CId, List
     syntax TypeSpecifier ::= StructDef(CId, K, StrictList) [symbol]
     syntax TypeSpecifier ::= UnionRef(CId, K) [symbol] // new
     // new // CId, List
     syntax TypeSpecifier ::= UnionDef(CId, K, StrictList) [symbol]
     syntax TypeSpecifier ::= EnumRef(CId, K) [symbol] // new
     // new // CId, List
     syntax TypeSpecifier ::= EnumDef(CId, K, StrictList) [symbol]

     syntax TypeSpecifier ::= Complex() [symbol]
     syntax TypeSpecifier ::= Imaginary() [symbol]

     syntax TypeSpecifier ::= AutoType() [symbol]
     syntax SimpleAutoType ::= "auto-type"
     syntax SimpleType ::= SimpleAutoType
     syntax SimpleUType ::= SimpleAutoType

     syntax SpecifierElem ::= TypeofExpression(KItem) [symbol]
     syntax SpecifierElem ::= TypeofType(KItem, KItem) [symbol]
     syntax SpecifierElem ::= TAtomic(KItem, KItem) [symbol]
     syntax SpecifierElem ::= AlignasExpression(KItem) [symbol]
     syntax SpecifierElem ::= AlignasType(KItem, KItem) [symbol]

     /*
     and spec_elem =
     SpecTypedef
     | SpecType of typeSpecifier
     | SpecPattern of String       (* specifier pattern variable *)
     */
     syntax SpecifierElem ::= TypeSpecifier
     syntax SpecifierElem ::= SpecPattern(CId) [symbol]

     /*
     and specifier = spec_elem list
     */
     syntax Specifier ::= Specifier(StrictList) [avoid, symbol]

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
     syntax KItem ::= JustBase() [symbol]
     syntax KItem ::= FunctionType(KItem) [strict, symbol]
     // third argument should also be strict, but not doing anything with
     // [strict 5] yet
     syntax KItem ::= ArrayType(KItem, K, KItem) [strict(1), symbol]
     syntax KItem ::= PointerType(Specifier, KItem) [strict(2), symbol]
     // K, List, Bool
     syntax KItem ::= Prototype(KItem, StrictList, Bool) [strict(1), symbol]
     syntax KItem ::= NoPrototype(KItem, StrictList, Bool) [strict(1, 2), symbol]

     syntax KItem ::= "NotVariadic"
     syntax KItem ::= "Variadic"

     /*
     and name_group = specifier * name list
     */ // K, List
     syntax KItem ::= NameGroup(KItem, StrictList) [strict, symbol]

     /*
     (* The optional expression is the bitfield *)
     and field_group = specifier * (name * expression option) list
     */ // K, List
     syntax KItem ::= FieldGroup(KItem, StrictList) [strict(1), symbol]
     syntax KItem ::= FieldName(KItem) [symbol]
     syntax KItem ::= BitFieldName(KItem, KItem) [symbol]

     /*
     (* like name_group, except the declared variables are allowed to have
     initializers *)
     (* e.g.: Int x=1, y=2; *)
     and init_name_group = specifier * init_name list
     */
     // K, List
     syntax KItem ::= InitNameGroup(KItem, StrictList) [strict(1), symbol]

     /*
     The decl_type is in the order in which they are printed. Only the name of
     the declared identifier is pulled out. The attributes are those that are
     printed after the declarator
     (* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
     (* the string, and decl_type will be PTR([], JUSTBASE) *)
     and name = String * decl_type * attribute list * cabsloc
     */
     // first argument is id, second is basetype
     syntax KItem ::= Name(CId, KItem, KItem) [avoid, symbol]
     /*
     (* A variable declarator ("name") with an initializer *)
     and init_name = name * init_expression
     */
     syntax KItem ::= InitName(KItem, K) [symbol]

     /*
     (* Single names are for declarations that cannot come in groups, like
      * function parameters and functions *)
     and single_name = specifier * name
     */
     syntax KItem ::= SingleName(KItem, KItem) [strict(1), symbol]

     /*
     and enum_item = String * expression * cabsloc
     */
     // this one has no init
     syntax KItem ::= EnumItem(CId) [symbol]
     // this one has an init
     syntax KItem ::= EnumItemInit(CId, K) [symbol]

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
     syntax KItem ::= FunctionDefinition(KItem, KItem) [strict(1), symbol]
     syntax KItem ::= DeclarationDefinition(KItem) [symbol]
     syntax KItem ::= Typedef(KItem) [symbol]
     syntax KItem ::= OnlyTypedef(KItem) [symbol]
     syntax KItem ::= GlobAsm(String) [symbol]
     syntax KItem ::= Pragma(KItem) [symbol]
     syntax KItem ::= PragmaKccRule(String) [symbol]
     syntax KItem ::= Linkage(String, StrictList) [symbol]
     syntax KItem ::= StaticAssert(K, KItem) [symbol]

     /*
     (* the String is a file name, and then the list of toplevel forms *)
     and file = String * definition list
     */
     // name, code, source
     // new: Filename, strings, ast, code
     syntax KItem ::= TranslationUnit(String, StrictList, StrictList) [symbol]

     /*
     and statement =
     NOP of cabsloc
     | COMPUTATION of expression * cabsloc
     | BLOCK of block * cabsloc
     | SEQUENCE of statement * statement * cabsloc
     */
     syntax KItem ::= BlockStatement(KItem) [symbol]
     syntax KItem ::= Block(Int, StrictList, StrictList)  [klabel(Block3), symbol]
     syntax KItem ::= Sequence(KItem, KItem)

     /*
     | DOWHILE of expression * statement * cabsloc * cabsloc
     | FOR of for_clause * expression * expression * statement * cabsloc
     */
     syntax KItem ::= DoWhile(K, KItem, CabsLoc)  [klabel(DoWhile3), symbol]
     syntax KItem ::= For(Int, KItem, K, K, K)  [klabel(For5), symbol]

     // gcc extension
     syntax KItem ::= CaseRange(KItem, KItem, KItem) [symbol]

     /*
     | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
     */
     syntax KItem ::= CompGoto(KItem) [symbol]

     syntax KItem ::= OtherStatement() [symbol]

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
     syntax KItem ::= OffsetOf(KItem, KItem, KItem) [strict(1), symbol]
     syntax KItem ::= TypesCompat(KItem, KItem, KItem, KItem) [strict(1, 3), symbol]
     syntax KItem ::= ExpressionLoc(K, K) [function]

     //must be declared as function,
     //otherwise, if then else rule failed in for(;;) cases
     syntax KItem ::= NothingExpression() [function, symbol]

     // For VLAs with unspecified size ([*]).
     syntax RValue ::= UnspecifiedSizeExpression() [symbol]

     /*
     (* A CAST can actually be a constructor expression *)
     | CAST of (specifier * decl_type) * init_expression
     */
     syntax KItem ::= Cast(K, KItem, K) [symbol]
     syntax KItem ::= #Cast(K, KItem, K, explicit: Bool) [symbol]
     context Cast(HOLE:KItem, _, _)
     context #Cast(HOLE:KItem, _, _, _)
     context Cast(_, _, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     context #Cast(_, _, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]

     // new // comp-lit id, spec, decl, init
     syntax KItem ::= CompoundLiteral(Int, KItem, KItem, KItem) [strict(2), symbol]
     /*
     | COMMA of expression list
     */
     // List
     syntax KItem ::= Comma(StrictList) [symbol]
     /*
     | CONSTANT of constant
     | PAREN of expression
     | VARIABLE of string
     */
     syntax KItem ::= Constant(KItem) [function, symbol]
     /*
     | EXPR_SIZEOF of expression
     | TYPE_SIZEOF of specifier * decl_type
     | EXPR_ALIGNOF of expression
     | TYPE_ALIGNOF of specifier * decl_type
     */
     syntax KItem ::= SizeofExpression(K) [symbol]
     syntax KItem ::= SizeofType(KItem, K) [strict(1), symbol]
     syntax KItem ::= AlignofExpression(KItem) [symbol]
     syntax KItem ::= AlignofType(KItem, KItem) [strict(1), symbol]
     syntax KItem ::= Generic(K, StrictList) [symbol]
     syntax KItem ::= GenericPair(KItem, KItem, KItem) [symbol]
     syntax KItem ::= GenericDefault(KItem) [symbol]
     /*
     | GNU_BODY of block
     | EXPR_PATTERN of String     (* pattern variable, and name *)
     */
     syntax KItem ::= ExpressionPattern(String) [symbol]

     /*
     and constant =
     | CONST_INT of String   (* the textual representation *)
     | CONST_FLOAT of String (* the textual representaton *)
     | CONST_CHAR of int64 list
     | CONST_WCHAR of int64 list
     | CONST_STRING of string
     | CONST_WSTRING of int64 list
     */
     syntax IntConstant ::= DecimalConstant(Int) [symbol]
     syntax IntConstant ::= OctalConstant(Int) [function, symbol]
     syntax IntConstant ::= HexConstant(String) [function, symbol]

     // significand, exponent, approx
     syntax FloatConstant ::= DecimalFloatConstant(String, Int, Float) [function, symbol]
     // significand, exponent, approx
     syntax FloatConstant ::= HexFloatConstant(String, Int, Float) [function, symbol]

     syntax Constant ::= LitU(Constant) [function, symbol]
     syntax Constant ::= LitL(Constant) [function, symbol]
     syntax Constant ::= LitLL(Constant) [function, symbol]
     syntax Constant ::= LitUL(Constant) [function, symbol]
     syntax Constant ::= LitULL(Constant) [function, symbol]
     syntax Constant ::= LitF(Constant) [function, symbol]

     syntax Constant ::= NoSuffix(Constant) [function, symbol]

     syntax Constant ::= CharLiteral(Int) [function, symbol]
     syntax Constant ::= WCharLiteral(Int) [function, symbol]
     syntax Constant ::= StringLiteral
     syntax StringLiteral ::= StringLiteral(String) [symbol]
     syntax StringLiteral ::= WStringLiteral(StrictList) [symbol]

     /*
     and init_expression =
     | SINGLE_INIT of expression
     | COMPOUND_INIT of (initwhat * init_expression) list
     */

     syntax KItem ::= SingleInit(KItem) [strict, symbol] 
     // List
     syntax KItem ::= CompoundInit(StrictList) [strict, symbol]
     // new; (initwhat * init_expression)
     syntax KItem ::= InitFragment(KItem, KItem) [symbol]

     /*
     and initwhat =
     NEXT_INIT
     | INFIELD_INIT of String * initwhat
     | ATINDEX_INIT of expression * initwhat
     | ATINDEXRANGE_INIT of expression * expression
     */
     syntax KResult ::= NextInit() [symbol]
                      | InFieldInit(CId, KItem) [symbol]
                      | AtIndexInit(K, KItem) [symbol]
                      | AtIndexRangeInit(KItem, KItem) [symbol]

     /*
     and attribute = String * expression list
     */
     // String, List

     syntax CId ::= AnonymousName() [function, symbol]

     syntax KItem ::= DefinitionLoc(KItem, CabsLoc) [symbol]
     syntax KItem ::= DefinitionLocRange(KItem, CabsLoc, CabsLoc) [symbol]
     syntax KItem ::= InitLoc(KItem, CabsLoc) [symbol]
     // this wraps all statements with their location in the original file
     syntax KItem ::= StatementLoc(KItem, CabsLoc) [symbol] // new

     /*
     and for_clause =
     FC_EXP of expression
     | FC_DECL of definition
     */
     syntax KItem ::= ForClauseExpression(KItem) [symbol]

     syntax KItem ::= Conditional(KItem, KItem, KItem) [symbol]

     syntax KItem ::= ArrayIndex(KItem, KItem) [symbol]

     syntax KItem ::= Negative(KItem) [symbol]
     syntax KItem ::= Positive(KItem) [symbol]
     syntax KItem ::= LogicalNot(KItem) [symbol]
     syntax KItem ::= BitwiseNot(KItem) [symbol]
     syntax KItem ::= Dereference(KItem) [symbol]
     syntax KItem ::= Reference(KItem) [symbol]
     syntax KItem ::= PreIncrement(KItem) [symbol]
     syntax KItem ::= PreDecrement(KItem) [symbol]
     syntax KItem ::= PostIncrement(KItem) [symbol]
     syntax KItem ::= PostDecrement(KItem) [symbol]

     syntax KItem ::= Multiply(KItem, KItem) [symbol]
     syntax KItem ::= Divide(KItem, KItem) [symbol]
     syntax KItem ::= Modulo(KItem, KItem) [symbol]
     syntax KItem ::= Plus(KItem, KItem) [symbol]
     syntax KItem ::= Minus(KItem, KItem) [symbol]
     syntax KItem ::= LeftShift(KItem, KItem) [symbol]
     syntax KItem ::= RightShift(KItem, KItem) [symbol]
     syntax KItem ::= LessThan(KItem, KItem) [symbol]
     syntax KItem ::= LessThanOrEqual(KItem, KItem) [symbol]
     syntax KItem ::= GreaterThan(KItem, KItem) [symbol]
     syntax KItem ::= GreaterThanOrEqual(KItem, KItem) [symbol]
     syntax KItem ::= Equality(KItem, KItem) [symbol]
     syntax KItem ::= NotEquality(KItem, KItem) [symbol]
     syntax KItem ::= BitwiseAnd(KItem, KItem) [symbol]
     syntax KItem ::= BitwiseXor(KItem, KItem) [symbol]
     syntax KItem ::= BitwiseOr(KItem, KItem) [symbol]
     syntax KItem ::= LogicalAnd(KItem, KItem) [symbol]
     syntax KItem ::= LogicalOr(KItem, KItem) [symbol]

     syntax KItem ::= Assign(KItem, KItem) [symbol]
     syntax KItem ::= AssignMultiply(KItem, KItem) [symbol]
     syntax KItem ::= AssignDivide(KItem, KItem) [symbol]
     syntax KItem ::= AssignModulo(KItem, KItem) [symbol]
     syntax KItem ::= AssignPlus(KItem, KItem) [symbol]
     syntax KItem ::= AssignMinus(KItem, KItem) [symbol]
     syntax KItem ::= AssignBitwiseAnd(KItem, KItem) [symbol]
     syntax KItem ::= AssignBitwiseXor(KItem, KItem) [symbol]
     syntax KItem ::= AssignBitwiseOr(KItem, KItem) [symbol]
     syntax KItem ::= AssignLeftShift(KItem, KItem) [symbol]
     syntax KItem ::= AssignRightShift(KItem, KItem) [symbol]

     syntax KItem ::= Dot(KItem, CId) [symbol]
     syntax KItem ::= Arrow(KItem, CId) [symbol]

endmodule

module C-ABSTRACT-REWRITING
     imports C-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports COMMON-SYNTAX
     imports FLOAT
     imports K-EQUAL-SYNTAX
     imports STRING

     rule AnonymousName() => #NoName

     rule DefinitionLoc(K:KItem, L::CabsLoc) => CodeLoc(K, L) [anywhere]
     rule InitLoc(K:KItem, CabsLoc(Loc:String, _, Line:Int, _, _) #as L::CabsLoc) =>
          #if (Loc ==String "cabs loc unknown") andBool (Line ==Int -10)
          #then K  // TODO: something better
          #else CodeLoc(K, L)
          #fi
          [anywhere]
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
     rule &(ExpLoc(*(K:KItem), _:CabsLoc)) => K [anywhere]

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
