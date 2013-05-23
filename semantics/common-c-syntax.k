module COMMON-C-SYNTAX
	// imports K // TODO TOOL BUG fixme if I include K, it doesn't actually include K
	
	//tags ndlocal ndheat computational structural interpRule anywhere observable
	
	// these are semantic
      // TODO(chathhorn) removing semantic tags, not sure what they means
	syntax K ::= "reval" "(" K ")" [strict]
	syntax K ::= "peval" "(" K ")" [strict]
	
	// the rest are syntactic
	syntax C ::= "AttributeWrapper" "(" K "," K ")"
	
	// sort C
	syntax C ::= Id
	syntax C ::= "List" "(" List{K} ")"
	// hybrid doesn't work with list operator, and strict doesn't do what's expected
	
	syntax K ::= "StmtCons" "(" K "," K ")"
	
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
	syntax CabsLoc ::= "CabsLoc" "(" String "," Int "," Int "," Int ")"
	
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
	// macro inf = Infinity
	syntax TypeSpecifier ::= "Named" "(" Id ")"
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
	syntax TypeSpecifier ::= "StructRef" "(" Id ")" // new
	syntax TypeSpecifier ::= "StructDef" "(" Id "," K ")" // new // Id, List
	context StructDef(_:Id, List((_:List{K},, HOLE,, _:List{K})))
	syntax TypeSpecifier ::= "UnionRef" "(" Id ")" // new
	syntax TypeSpecifier ::= "UnionDef" "(" Id "," K ")" // new // Id, List
	context UnionDef(_:Id, List((_:List{K},, HOLE,, _:List{K})))
	syntax TypeSpecifier ::= "EnumRef" "(" Id ")" // new
	syntax TypeSpecifier ::= "EnumDef" "(" Id "," K ")" // new // Id, List
	syntax TypeSpecifier ::= "TypeofExpression" "(" K ")"
	syntax TypeSpecifier ::= "TypeofType" "(" K "," K ")"
	
	syntax TypeSpecifier ::= "Complex"
	syntax TypeSpecifier ::= "Imaginary"
	syntax TypeSpecifier ::= "TAtomic" "(" K "," K ")"
	syntax TypeSpecifier ::= "Atomic" // this will be used as the actual modifier
	syntax TypeSpecifier ::= "AlignasExpression" "(" K ")"
	syntax TypeSpecifier ::= "AlignasType" "(" K "," K ")"

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
	syntax SpecifierElem ::= "SpecPattern" "(" Id ")"
	
/*
	and specifier = spec_elem list
*/
	syntax Specifier ::= "Specifier" "(" K ")"
	context Specifier(List((_:List{K},, HOLE,, _:List{K})))
	
/*
and decl_type =
	| JUSTBASE		(* Prints the declared name *)
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
	syntax DeclType ::= "FunctionType" "(" K ")" [strict]
	syntax DeclType ::= "ArrayType" "(" K "," K "," K ")" [strict(1)] // third argument should also be strict, but not doing anything with [strict 5] yet
	context ArrayType(_, (HOLE => reval(HOLE)), _) [ndheat]
	syntax DeclType ::= "PointerType" "(" K ")" [strict]
	syntax DeclType ::= "Prototype" "(" K "," K "," Bool ")" [strict(1)] // K, List, Bool
	context Prototype(_, List((_:List{K},, HOLE,, _:List{K})), _:Bool)
	
	syntax K ::= "NotVariadic"
	syntax K ::= "Variadic"
	
	
/*
and name_group = specifier * name list
*/
	syntax NameGroup ::= "NameGroup" "(" K "," K ")" [strict(1)] // K, List
	context NameGroup(_, List((_:List{K},, HOLE,, _:List{K})))
	
/*
	(* The optional expression is the bitfield *)
and field_group = specifier * (name * expression option) list
*/
	syntax FieldGroup ::= "FieldGroup" "(" K "," K ")" [strict(1)] // K, List
	syntax FieldName ::= "FieldName" "(" K ")" // new
	syntax FieldName ::= "BitFieldName" "(" K "," K ")" // new
	
/*
	(* like name_group, except the declared variables are allowed to have initializers *)
	(* e.g.: Int x=1, y=2; *)
and init_name_group = specifier * init_name list
*/
	syntax InitNameGroup ::= "InitNameGroup" "(" K "," K ")" [strict(1)] // K, List
	
/*
	(* The decl_type is in the order in which they are printed. Only the name of
	 * the declared identifier is pulled out. The attributes are those that are
	 * printed after the declarator *)
	(* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
	(* the string, and decl_type will be PTR([], JUSTBASE) *)
and name = String * decl_type * attribute list * cabsloc
*/
	syntax Name ::= "Name" "(" K "," K ")" // first argument is id, second is basetype
	syntax K ::= "AnonymousName" // new, argument is type
	syntax Id ::= "#NoName" // new
	// [metadata "latex=(renameTo \\#NoName)"] 
	syntax Id ::= "#NoName" "(" Int ")" // new
	// metadata "latex=(renameTo \\#NoName\\mybracket{_})"
	syntax Id ::= "Identifier" "(" String ")" // new	
	
	macro AnonymousName = #NoName
	
/*
	(* A variable declarator ("name") with an initializer *)
and init_name = name * init_expression
*/
	syntax InitName ::= "InitName" "(" K "," K ")"
	context InitName(_, (HOLE => reval(HOLE))) [ndheat]
	
/*
	(* Single names are for declarations that cannot come in groups, like
	 * function parameters and functions *)
and single_name = specifier * name
*/
	syntax SingleName ::= "SingleName" "(" K "," K ")" [strict(1)]
	
/*
and enum_item = String * expression * cabsloc
*/
	syntax PureEnumItem ::= "EnumItem" "(" Id ")" // this one has no init
	syntax PureEnumItem ::= "EnumItemInit" "(" Id "," K ")" // this one has an init
		
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
	syntax PureDefinition ::= "FunctionDefinition" "(" K "," K ")" [strict(1)]
	syntax PureDefinition ::= "DeclarationDefinition" "(" K ")"
	syntax PureDefinition ::= "Typedef" "(" K ")"
	syntax PureDefinition ::= "OnlyTypedef" "(" K ")"
	syntax PureDefinition ::= "GlobAsm" "(" String ")"
	syntax PureDefinition ::= "Pragma" "(" K ")"
	syntax PureDefinition ::= "Linkage" "(" String "," K ")" // seems to be unused
	syntax PureDefinition ::= "Transformer" "(" K "," K ")" // seems to be unused
	syntax PureDefinition ::= "ExpressionTransformer" "(" K "," K ")"
	syntax PureDefinition ::= "LTLAnnotation" "(" K ")" // name
	
	// new
	syntax Expression ::= "LTL-Atom" "(" K ")"
	syntax Expression ::= "LTL-Builtin" "(" K ")"
	
	syntax Expression ::= "LTL-True"
	syntax Expression ::= "LTL-False"
	syntax Expression ::= "LTL-And" "(" K "," K ")"
	syntax Expression ::= "LTL-Or" "(" K "," K ")"
	syntax Expression ::= "LTL-Not" "(" K ")"
	syntax Expression ::= "LTL-Next" "(" K ")"
	syntax Expression ::= "LTL-Always" "(" K ")"
	syntax Expression ::= "LTL-Eventually" "(" K ")"
	syntax Expression ::= "LTL-Until" "(" K "," K ")"
	syntax Expression ::= "LTL-Release" "(" K "," K ")"
	syntax Expression ::= "LTL-Implies" "(" K "," K ")"
	syntax Expression ::= "LTL-Equiv" "(" K "," K ")"
	syntax Expression ::= "LTL-WeakUntil" "(" K "," K ")"
	
	syntax Definition ::= "DefinitionLoc" "(" K "," K ")" // new
	syntax Definition ::= "DefinitionLocRange" "(" K "," K "," K ")" // new
	
/*
(* the String is a file name, and then the list of toplevel forms *)
and file = String * definition list
*/
	// name, code, source
	syntax TranslationUnit ::= "TranslationUnit" "(" String "," K "," K "," String ")" // new: Filename, strings, ast, code
	syntax Program ::= "Program" "(" K ")" // new // List

/*
	(* A block contains a list of local label declarations ( GCC's ({ __label__ 
	 * l1, l2; ... }) ) , a list of definitions and a list of statements  *)
and block = 
	{ blabels: String list;
	  battrs: attribute list;
	  bstmts: statement list
	} 
*/
	syntax Block ::= "Block" "(" Int "," K "," K ")" // Int, list, list

/*
and statement =
	NOP of cabsloc
	| COMPUTATION of expression * cabsloc
	| BLOCK of block * cabsloc
	| SEQUENCE of statement * statement * cabsloc
*/
	syntax PureStatement ::= "Nop"
	syntax PureStatement ::= "Computation" "(" K ")" [latex "{{#1}};"]
	context Computation((HOLE => reval(HOLE))) // not sure why i had this commented out before...
	syntax PureStatement ::= "BlockStatement" "(" K ")"
	syntax PureStatement ::= "Sequence" "(" K "," K ")"
/*
	| IF of expression * statement * statement * cabsloc
	| WHILE of expression * statement * cabsloc
	| DOWHILE of expression * statement * cabsloc
	| FOR of for_clause * expression * expression * statement * cabsloc
*/
	syntax PureStatement ::= "IfThenElse" "(" K "," K "," K ")"
	context IfThenElse((HOLE => reval(HOLE)), _, _)
	syntax PureStatement ::= "While" "(" K "," K ")"
	syntax PureStatement ::= "DoWhile" "(" K "," K ")"
	syntax PureStatement ::= "For" "(" Int "," K "," K "," K "," K ")" // id, ...
/*
	| BREAK of cabsloc
	| CONTINUE of cabsloc
	| RETURN of expression * cabsloc
*/
	syntax PureStatement ::= "Break"
	syntax PureStatement ::= "Continue"
	syntax PureStatement ::= "Return" "(" K ")"
	context Return((HOLE => reval(HOLE)))
/*
	| SWITCH of expression * statement * cabsloc
	| CASE of expression * statement * cabsloc
	| CASERANGE of expression * expression * statement * cabsloc
	| DEFAULT of statement * cabsloc
*/
	syntax PureStatement ::= "Switch" "(" K "," K "," K ")" // unique switch id
	context Switch(_, (HOLE => reval(HOLE)), _)
	syntax PureStatement ::= "Case" "(" Int "," Int "," K "," K ")" // unique switch id, unique case id, exp, statement
	syntax PureStatement ::= "CaseRange" "(" K "," K "," K ")" // gcc extension
	syntax PureStatement ::= "Default" "(" Int "," K ")" // unique switch id, statement
/*
	| LABEL of String * statement * cabsloc
	| GOTO of String * cabsloc
	| COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
	| DEFINITION of definition (*definition or declaration of a variable or type*)
*/
	syntax PureStatement ::= "Label" "(" Id "," K ")"
	syntax PureStatement ::= "Goto" "(" K ")" // Id
	syntax PureStatement ::= "CompGoto" "(" K ")"
	
	// this wraps all statements with their location in the original file
	syntax Statement ::= "StatementLoc" "(" K "," K ")" // new
	
/*
and for_clause = 
	FC_EXP of expression
	| FC_DECL of definition
*/
	syntax ForClause ::= "ForClauseExpression" "(" K ")"
	
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
	syntax Expression ::= "OffsetOf" "(" K "," K "," K ")" [strict(1)]
	syntax Expression ::= "ExpressionLoc" "(" K "," K ")" // new

	syntax Expression ::= "NothingExpression"
/*
	| UNARY of unary_operator * expression

and unary_operator =
	MINUS | PLUS | NOT | BNOT | MEMOF | ADDROF
	| PREINCR | PREDECR | POSINCR | POSDECR
*/
	syntax Expression ::= "-" K [metadata "type-strict=()" prec(22)]
	context -_((HOLE => reval(HOLE)))
	syntax Expression ::= "+" K [metadata "type-strict=()" prec(22)]
	context +_((HOLE => reval(HOLE)))
	syntax Expression ::= "!" K [metadata "type-strict=()" prec(22)]
	context !_((HOLE => reval(HOLE)))
	syntax Expression ::= "~" K [metadata "type-strict=()" prec(22)]
	context ~_((HOLE => reval(HOLE)))
	syntax Expression ::= "*" K [metadata "type-strict=()" prec(22)]
	context *_((HOLE => reval(HOLE)))
	syntax Expression ::= "&" K [metadata "type-strict=()" strict prec(22)]
	syntax Expression ::= "++" K [metadata "type-strict=()" prec(22)]
	syntax Expression ::= "--" K [metadata "type-strict=()" latex "\terminal{-{}-}{#1}" prec(22)]
	syntax Expression ::= K "++" [metadata "type-strict=()"]
	context _++((HOLE => peval(HOLE)))
	syntax Expression ::= K "--" [metadata "type-strict=()" latex "{#1}\terminal{-{}-}" ]
	context _--((HOLE => peval(HOLE)))
	
/*
	| BINARY of binary_operator * expression * expression
*/
	syntax Expression ::= K "*" K [metadata "type-strict=()" prec(31) gather(E e)]
	syntax Expression ::= K "/" K [metadata "type-strict=()" prec(31) gather(E e)]
	syntax Expression ::= K "%" K [metadata "type-strict=()" prec(31) gather(E e)]
	context _*_((HOLE => reval(HOLE)), _) [ndheat]
	context _*_(_, (HOLE => reval(HOLE))) [ndheat]
	context _/_((HOLE => reval(HOLE)), _) [ndheat]
	context _/_(_, (HOLE => reval(HOLE))) [ndheat]
	context _%_((HOLE => reval(HOLE)), _) [ndheat]
	context _%_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "+" K [metadata "type-strict=()" prec(33) gather(E e)]
	syntax Expression ::= K "-" K [metadata "type-strict=()" prec(33) gather(E e)]
	context _+_((HOLE => reval(HOLE)), _) [ndheat]
	context _+_(_, (HOLE => reval(HOLE))) [ndheat]
	context _-_((HOLE => reval(HOLE)), _) [ndheat]
	context _-_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "<<" K [metadata "type-strict=(1)" latex "{{#1}}\ll{{#2}}" prec(35) gather(E e)]
	context _<<_((HOLE => reval(HOLE)), _) [ndheat]
	context _<<_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K ">>" K [metadata "type-strict=(1)" latex "{{#1}}\gg{{#2}}" prec(35) gather(E e)]
	context _>>_((HOLE => reval(HOLE)), _) [ndheat]
	context _>>_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "<" K [metadata "type-strict=()" prec(37) gather(E e)]
	syntax Expression ::= K "<=" K [metadata "type-strict=()" prec(37) gather(E e)]
	context _<_((HOLE => reval(HOLE)), _) [ndheat]
	context _<_(_, (HOLE => reval(HOLE))) [ndheat]
	context _<=_((HOLE => reval(HOLE)), _) [ndheat]
	context _<=_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K ">" K [metadata "type-strict=()" prec(37) gather(E e)]
	syntax Expression ::= K ">=" K [metadata "type-strict=()" prec(37) gather(E e)]
	context _>_((HOLE => reval(HOLE)), _) [ndheat]
	context _>_(_, (HOLE => reval(HOLE))) [ndheat]
	context _>=_((HOLE => reval(HOLE)), _) [ndheat]
	context _>=_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "==" K [metadata "type-strict=()" prec(39) gather(E e)]
	syntax Expression ::= K "!=" K [metadata "type-strict=()" prec(39) gather(E e)]
	context _==_((HOLE => reval(HOLE)), _) [ndheat]
	context _==_(_, (HOLE => reval(HOLE))) [ndheat]
	context _!=_((HOLE => reval(HOLE)), _) [ndheat]
	context _!=_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "&" K [metadata "type-strict=()" prec(41) gather(E e)]
	context _&_((HOLE => reval(HOLE)), _) [ndheat]
	context _&_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "^" K [metadata "type-strict=()" prec(43) gather(E e)]
	context _^_((HOLE => reval(HOLE)), _) [ndheat]
	context _^_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "|" K [metadata "type-strict=()" prec(45) gather(E e)]
	context _|_((HOLE => reval(HOLE)), _) [ndheat]
	context _|_(_, (HOLE => reval(HOLE))) [ndheat]
	
	syntax Expression ::= K "&&" K [metadata "type-strict=()" prec(47) gather(E e)]
	context _&&_((HOLE => reval(HOLE)), _) [ndheat]
	
	syntax Expression ::= K "||" K [metadata "type-strict=()" prec(49) gather(E e)]
	context _||_((HOLE => reval(HOLE)), _) [ndheat]
	
	syntax Expression ::= K "*=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "/=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "%=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "+=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "-=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "<<=" K [metadata "type-strict=(1)" latex "{{#1}}\terminal{$\gg$=}{{#2}}" prec(53)]
	syntax Expression ::= K "&=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "^=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K "|=" K [metadata "type-strict=(1)" prec(53)]
	syntax Expression ::= K ">>=" K [metadata "type-strict=(1)" latex "{{#1}}\terminal{$\ll$=}{{#2}}" prec(53)]
	syntax Expression ::= K ":=" K [metadata "type-strict=(1)" prec(53)]
	context _:=_((HOLE => peval(HOLE)), _) [ndheat]
	context _:=_(_, (HOLE => reval(HOLE))) [ndheat]
	
/*
	| QUESTION of expression * expression * expression
*/
	syntax Expression ::= K "?" K ":" K [metadata "type-strict=(2 3)" prec(51) gather(e & E)]
	context _?_:_((HOLE => reval(HOLE)), _, _)

/*
	(* A CAST can actually be a constructor expression *)
	| CAST of (specifier * decl_type) * init_expression
*/
	syntax Expression ::= "Cast" "(" K "," K "," K ")" [strict(1)]
	context Cast(_, _, (HOLE => reval(HOLE)))
	
	syntax Expression ::= "CompoundLiteral" "(" K "," K "," K "," K ")" [strict(2)] // new // comp-lit id, spec, decl, init
/*
	(* There is a special form of CALL in which the function called
	   __builtin_va_arg and the second argument is sizeof(T). This 
	   should be printed as just T *)
	| CALL of expression * expression list
*/

	syntax Expression ::= "Call" "(" K "," K ")" [metadata "type-strict=(1)"] // K, List
	context Call((HOLE => reval(HOLE)), _) [ndheat]
	context Call(_, List((_:List{K},, (HOLE => reval(HOLE)),, _:List{K}))) [ndheat]
/*
	| COMMA of expression list
*/
	syntax Expression ::= "Comma" "(" K ")" // List
	context Comma(List(((HOLE => reval(HOLE)),, _:List{K}))) [ndheat]
/*
	| CONSTANT of constant
	| PAREN of expression
	| VARIABLE of string
*/
	syntax Expression ::= "Constant" "(" K ")" // [latex "{#1}"]
	// String constants aren't revals
	// for paren, just putting parentheses
	syntax Expression ::= Id
/*
	| EXPR_SIZEOF of expression
	| TYPE_SIZEOF of specifier * decl_type
	| EXPR_ALIGNOF of expression
	| TYPE_ALIGNOF of specifier * decl_type
*/
	syntax Expression ::= "SizeofExpression" "(" K ")"
	syntax Expression ::= "SizeofType" "(" K "," K ")" [strict(1)]
	syntax Expression ::= "AlignofExpression" "(" K ")"
	syntax Expression ::= "AlignofType" "(" K "," K ")"
/*
	| INDEX of expression * expression
*/
	syntax Expression ::= K "[" K "]" [metadata "type-strict=()"]
/*
	| MEMBEROF of expression * string
	| MEMBEROFPTR of expression * string
*/
	syntax Expression ::= K "." Id [metadata "type-strict=(1)"]
	context _._((HOLE => peval(HOLE)), _:Id)
	syntax Expression ::= K "->" Id
	context _->_((HOLE => reval(HOLE)), _:Id)
/*
	| GNU_BODY of block
	| EXPR_PATTERN of String     (* pattern variable, and name *)
*/
	syntax Expression ::= "GnuBody" "(" K ")"
	syntax Expression ::= "ExpressionPattern" "(" String ")"
	
/*
and constant =
	| CONST_INT of String   (* the textual representation *)
	| CONST_FLOAT of String (* the textual representaton *)
	| CONST_CHAR of int64 list
	| CONST_WCHAR of int64 list
	| CONST_STRING of string
	| CONST_WSTRING of int64 list 
*/
	syntax IntConstant ::= "DecimalConstant" "(" K ")" // new
	syntax IntConstant ::= "OctalConstant" "(" K ")"  // new
	syntax IntConstant ::= "HexConstant" "(" K ")"  // new // expected to be string
	
	syntax IntConstant ::= "DecimalFloatConstant" "(" String "," Int "," Float ")" // new; significand, exponent, approx
	syntax IntConstant ::= "HexFloatConstant" "(" String "," Int "," Float ")" // new; significand, exponent, approx
	
	syntax Constant ::= "U" "(" K ")" // new
	syntax Constant ::= "L" "(" K ")" // new
	syntax Constant ::= "F" "(" K ")" // new
	syntax Constant ::= "LL" "(" K ")" // new
	syntax Constant ::= "UL" "(" K ")" // new
	syntax Constant ::= "ULL" "(" K ")" // new
	syntax Constant ::= "NoSuffix" "(" K ")" // new
	
	syntax Constant ::= "CharLiteral" "(" Int ")"
	syntax Constant ::= "WCharLiteral" "(" Int ")"
	syntax Constant ::= "StringLiteral" "(" String ")"
	syntax Constant ::= "WStringLiteral" "(" List{K} ")"
	

/*
and init_expression =
  | NO_INIT
  | SINGLE_INIT of expression
  | COMPOUND_INIT of (initwhat * init_expression) list
*/
	syntax KResult ::= "NoInit" // InitExpression
	syntax InitExpression ::= "SingleInit" "(" K ")" [hybrid strict]
	syntax InitExpression ::= "CompoundInit" "(" K ")" [hybrid strict] // List
	syntax InitFragment ::= "InitFragment" "(" K "," K ")" // new; (initwhat * init_expression)
	
/*
and initwhat =
	NEXT_INIT
	| INFIELD_INIT of String * initwhat
	| ATINDEX_INIT of expression * initwhat
	| ATINDEXRANGE_INIT of expression * expression
*/
	syntax KResult ::= "NextInit"
	syntax KResult ::= "InFieldInit" "(" Id "," K ")"
	syntax KResult ::= "AtIndexInit" "(" K "," K ")"
	syntax KResult ::= "AtIndexRangeInit" "(" K "," K ")" // nonstandard

	
/*
and attribute = String * expression list
*/
	syntax C ::= "Attribute" "(" String "," K ")" // String, List
	
	syntax K ::= "CodeLoc" "(" K "," K ")"
	macro DefinitionLoc(K:K, L:K) = CodeLoc(K:K, L:K)
	macro StatementLoc(K:K, L:K) = CodeLoc(K:K, L:K)
	macro DefinitionLocRange(K:K, _, L:K) = CodeLoc(K:K, L:K)
	
	
	/*@ This macro defines an important identity from \source[n1570]{\para{6.5.3.2}{3}}.  As a syntactic macro, it should run on programs before they even start to reduce. */
	macro &(*(K:K)) = K:K
		

	/*@ The below macros simply transform the prefix AST names to the infix/mixfix names we use from now on */
	
	// all these macros are temporary while I adjust the semantics to the new grammar
	syntax Expression ::= "Conditional" "(" K "," K "," K ")"
	macro Conditional(K1:K, K2:K, K3:K) = K1:K ? K2:K : K3:K
	
	syntax Expression ::= "ArrayIndex" "(" K "," K ")"
	macro ArrayIndex(K1:K, K2:K) = K1:K[K2:K]
	
	syntax Expression ::= "Negative" "(" K ")"
	macro Negative(K:K) = - K:K
	syntax Expression ::= "Positive" "(" K ")"
	macro Positive(K:K) = + K:K
	syntax Expression ::= "LogicalNot" "(" K ")"
	macro LogicalNot(K:K) = ! K:K
	syntax Expression ::= "BitwiseNot" "(" K ")"
	macro BitwiseNot(K:K) = ~ K:K
	syntax Expression ::= "Dereference" "(" K ")"
	macro Dereference(K:K) = * K:K
	syntax Expression ::= "Reference" "(" K ")"
	macro Reference(K:K) = & K:K
	syntax Expression ::= "PreIncrement" "(" K ")"
	macro PreIncrement(K:K) = ++ K:K
	syntax Expression ::= "PreDecrement" "(" K ")"
	macro PreDecrement(K:K) = -- K:K
	syntax Expression ::= "PostIncrement" "(" K ")"
	macro PostIncrement(K:K) = K:K ++
	syntax Expression ::= "PostDecrement" "(" K ")"
	macro PostDecrement(K:K) = K:K --

	ops Multiply : K K -> Expression
	macro Multiply(K1:K, K2:K) = K1:K * K2:K
	ops Divide : K K -> Expression
	macro Divide(K1:K, K2:K) = K1:K / K2:K
	ops Modulo : K K -> Expression
	macro Modulo(K1:K, K2:K) = K1:K % K2:K
	ops Plus : K K -> Expression
	macro Plus(K1:K, K2:K) = K1:K + K2:K
	ops Minus : K K -> Expression
	macro Minus(K1:K, K2:K) = K1:K - K2:K
	ops LeftShift : K K -> Expression
	macro LeftShift(K1:K, K2:K) = K1:K << K2:K
	ops RightShift : K K -> Expression
	macro RightShift(K1:K, K2:K) = K1:K >> K2:K
	ops LessThan : K K -> Expression
	macro LessThan(K1:K, K2:K) = K1:K < K2:K
	ops LessThanOrEqual : K K -> Expression
	macro LessThanOrEqual(K1:K, K2:K) = K1:K <= K2:K
	ops GreaterThan : K K -> Expression
	macro GreaterThan(K1:K, K2:K) = K1:K > K2:K
	ops GreaterThanOrEqual : K K -> Expression
	macro GreaterThanOrEqual(K1:K, K2:K) = K1:K >= K2:K
	ops Equality : K K -> Expression
	macro Equality(K1:K, K2:K) = K1:K == K2:K
	ops NotEquality : K K -> Expression
	macro NotEquality(K1:K, K2:K) = K1:K != K2:K
	ops BitwiseAnd : K K -> Expression
	macro BitwiseAnd(K1:K, K2:K) = K1:K & K2:K
	ops BitwiseXor : K K -> Expression
	macro BitwiseXor(K1:K, K2:K) = K1:K ^ K2:K
	ops BitwiseOr : K K -> Expression
	macro BitwiseOr(K1:K, K2:K) = K1:K | K2:K
	ops LogicalAnd : K K -> Expression
	macro LogicalAnd(K1:K, K2:K) = K1:K && K2:K
	ops LogicalOr : K K -> Expression
	macro LogicalOr(K1:K, K2:K) = K1:K || K2:K
	

	ops Assign : K K -> Expression
	macro Assign(K1:K, K2:K) = K1:K := K2:K
	ops AssignMultiply : K K -> Expression
	macro AssignMultiply(K1:K, K2:K) = K1:K *= K2:K
	ops AssignDivide : K K -> Expression
	macro AssignDivide(K1:K, K2:K) = K1:K /= K2:K
	ops AssignModulo : K K -> Expression
	macro AssignModulo(K1:K, K2:K) = K1:K %= K2:K
	ops AssignPlus : K K -> Expression
	macro AssignPlus(K1:K, K2:K) = K1:K += K2:K
	ops AssignMinus : K K -> Expression
	macro AssignMinus(K1:K, K2:K) = K1:K -= K2:K
	ops AssignBitwiseAnd : K K -> Expression
	macro AssignBitwiseAnd(K1:K, K2:K) = K1:K &= K2:K
	ops AssignBitwiseXor : K K -> Expression
	macro AssignBitwiseXor(K1:K, K2:K) = K1:K ^= K2:K
	ops AssignBitwiseOr : K K -> Expression
	macro AssignBitwiseOr(K1:K, K2:K) = K1:K |= K2:K
	ops AssignLeftShift : K K -> Expression
	macro AssignLeftShift(K1:K, K2:K) = K1:K <<= K2:K
	ops AssignRightShift : K K -> Expression
	macro AssignRightShift(K1:K, K2:K) = K1:K >>= K2:K
	
	ops Dot : K Id -> Expression
	macro Dot(K:K, X:Id) = K:K . X:Id
	syntax Expression ::= "Arrow" "(" K "," Id ")"
	macro Arrow(K:K, X:Id) = K:K -> X:Id

endmodule
