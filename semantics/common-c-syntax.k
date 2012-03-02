kmod COMMON-C-SYNTAX is
	including #BOOL
	including #EXT-BOOL
	including #NAT
	including #INT
	including #RAT
	including #FLOAT
	including #STRING
	including #CONVERSION
	including #RANDOM
	including #ID
	including K
	//including K-PROPER
	
	tags ndlocal ndheat computational structural interpRule anywhere
	
	// these are semantic
	// op reval : K -> K // [strict]
	// op peval : K -> K // [strict]
	op reval : K -> K [metadata "strict=()"]
	op peval : K -> K [metadata "strict=()"]
	
	// the rest are syntactic
	sort C
	op AttributeWrapper : K K -> C // new // K, List
	
	// The resulting sorts can really be replaced with K, but i've left them in for now since they don't hurt anything and are somewhat documenting
	
	// Sorts directly from CABS
	sort CabsLoc
	sort TypeSpecifier
	sort Storage
	// sort FunSpecifier // not used, even by cabs
	sort CVSpecifier
	sort SpecifierElem
	sort Specifier
	sort DeclType
	sort NameGroup
	sort FieldGroup
	sort InitNameGroup
	sort Name
	sort InitName
	sort SingleName
	sort EnumItem
	sort Definition
	sort Block
	sort AsmDetails
	sort Statement
	sort PureStatement
	sort PureEnumItem
	sort ForClause
	// sort BinaryOperator // not used by us
	// sort UnaryOperator // not used by us
	// sort Expression
	sort Constant
	sort InitExpression
	sort InitWhat
	// sort Attribute
	
	// Additional sorts
	sort Program
	sort TranslationUnit
	sort IntConstant
	sort InitFragment
	sort FieldName
	sort PureDefinition
	
	// sort C
	subsort #Id < C
	// moved heating/cooling to common-c-semantics.k
	
	// op List : List{K} -> C [metadata "strict=() hybrid=()"]
	// op List : List{K} -> C [metadata "hybrid=()"]
	op List : List{K} -> C
	// hybrid doesn't work with list operator, and strict doesn't do what's expected
	
	op StmtCons : K K -> K
	
	subsort SpecifierElem < KResult
	
	subsort CabsLoc < C
	subsort TypeSpecifier < C
	subsort Storage < C
	subsort CVSpecifier < C
	subsort SpecifierElem < C
	subsort Specifier < C
	subsort DeclType < C
	subsort NameGroup < C
	subsort FieldGroup < C
	subsort InitNameGroup < C
	subsort Name < C
	subsort InitName < C
	subsort SingleName < C
	subsort EnumItem < C
	subsort Definition < C
	subsort Block < C
	subsort AsmDetails < C
	subsort Statement < C
	subsort PureStatement < C
	subsort PureEnumItem < C
	subsort ForClause < C
	subsort Expression < C
	subsort Constant < C
	subsort InitExpression < C
	subsort InitWhat < C
	subsort Program < C
	subsort TranslationUnit < C
	subsort IntConstant < C
	subsort InitFragment < C
	subsort FieldName < C
	subsort PureDefinition < C

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
	// sort CabsLoc
	op CabsLoc : #String #Int #Int #Int -> CabsLoc
	// syntax CabsLoc ::= `CabsLoc ( #String , #Int , #Int , #Int )
	
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
	op Void : -> TypeSpecifier // [ctor]
	op Char : -> TypeSpecifier // [ctor]
	op Bool : -> TypeSpecifier // [ctor]
	op Short : -> TypeSpecifier // [ctor]
	op Int : -> TypeSpecifier // [ctor]
	op Long : -> TypeSpecifier // [ctor]
	op Float : -> TypeSpecifier // [ctor]
	op Double : -> TypeSpecifier // [ctor]
	op Signed : -> TypeSpecifier // [ctor]
	op Unsigned : -> TypeSpecifier // [ctor]
	op inf : -> #Float
	// macro inf = Infinity
	op Named : #Id -> TypeSpecifier // [ctor]
/*
	(* each of the following three kinds of specifiers contains a field 
	* or item list iff it corresponds to a definition (as opposed to
	* a forward declaration or simple reference to the type); they
	* also have a list of __attribute__s that appeared between the
	* keyword and the type name (definitions only) *)
	| Tstruct of #String * field_group list option * attribute list
	| Tunion of #String * field_group list option * attribute list
	| Tenum of #String * enum_item list option * attribute list
	| TtypeofE of expression                      (* GCC __typeof__ *)
	| TtypeofT of specifier * decl_type       (* GCC __typeof__ *)
*/	
	op StructRef : #Id -> TypeSpecifier // [ctor] // new
	// op StructDef : #Id K -> TypeSpecifier [metadata "strict=(2)" ctor] // new // Id, List
	op StructDef : #Id K -> TypeSpecifier // [ctor] // new // Id, List
	context StructDef(_:#Id, List((_:List{K},, HOLE,, _:List{K})))
	op UnionRef : #Id -> TypeSpecifier // [ctor] // new
	// op UnionDef : #Id K -> TypeSpecifier [metadata "strict=(2)" ctor] // new // Id, List
	op UnionDef : #Id K -> TypeSpecifier // [ctor] // new // Id, List
	context UnionDef(_:#Id, List((_:List{K},, HOLE,, _:List{K})))
	op EnumRef : #Id -> TypeSpecifier // [ctor] // new
	op EnumDef : #Id K -> TypeSpecifier // [ctor] // new // Id, List
	op TypeofExpression : K -> TypeSpecifier // [ctor]
	op TypeofType : K K -> TypeSpecifier // [ctor]
	
	op Complex : -> TypeSpecifier // [ctor]
	op Imaginary : -> TypeSpecifier // [ctor]
	op TAtomic : K K -> TypeSpecifier // [ctor]
	op Atomic : -> TypeSpecifier // [ctor] // this will be used as the actual modifier
	op AlignasExpression : K -> TypeSpecifier // [ctor]
	op AlignasType : K K -> TypeSpecifier // [ctor]

/*
and storage =
	NO_STORAGE | AUTO | STATIC | EXTERN | REGISTER
*/
	op NoStorage : -> Storage // [ctor]
	op Auto : -> Storage // [ctor]
	op Static : -> Storage // [ctor]
	op Extern : -> Storage // [ctor]
	op Register : -> Storage // [ctor]
	op ThreadLocal : -> Storage // [ctor]
	
/*
and funspec = 
	INLINE | VIRTUAL | EXPLICIT
*/
	// Not sure what this is from, maybe C++_  It's not used elsewhere in cabs.
	
/*
and cvspec =
	CV_CONST | CV_VOLATILE | CV_RESTRICT
*/
	op Const : -> CVSpecifier
	op Volatile : -> CVSpecifier
	op Restrict : -> CVSpecifier
	
/*
and spec_elem =
	SpecTypedef          
	| SpecCV of cvspec            (* const/volatile *)
	| SpecAttr of attribute       (* __attribute__ *)
	| SpecStorage of storage
	| SpecInline
	| SpecType of typeSpecifier
	| SpecPattern of #String       (* specifier pattern variable *)
*/
	op SpecTypedef : -> SpecifierElem
	// the following are because I flattened SpecifierElem
	subsort CVSpecifier < SpecifierElem
	// subsort Attribute < SpecifierElem
	subsort Storage < SpecifierElem
	op Inline : -> SpecifierElem
	op Noreturn : -> SpecifierElem
	subsort TypeSpecifier < SpecifierElem
	op SpecPattern : #Id -> SpecifierElem
	
/*
	and specifier = spec_elem list
*/
	op Specifier : K -> Specifier
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
	op JustBase : -> K
	op FunctionType : K -> DeclType [metadata "strict=()"]
	op ArrayType : K K K -> DeclType [metadata "strict=(1)"] // third argument should also be strict, but not doing anything with [strict 5] yet
	context ArrayType(_, (HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	op PointerType : K -> DeclType [metadata "strict=()"]
	op Prototype : K K #Bool -> DeclType [metadata "strict=(1)"] // K, List, Bool
	context Prototype(_, List((_:List{K},, HOLE,, _:List{K})), _:#Bool)
	
	op NotVariadic : -> K
	op Variadic : -> K
	
	
/*
and name_group = specifier * name list
*/
	op NameGroup : K K -> NameGroup [metadata "strict=(1)"] // K, List
	context NameGroup(_, List((_:List{K},, HOLE,, _:List{K})))
	
/*
	(* The optional expression is the bitfield *)
and field_group = specifier * (name * expression option) list
*/
	op FieldGroup : K K -> FieldGroup [metadata "strict=(1)"] // K, List
	op FieldName : K -> FieldName // new
	op BitFieldName : K K -> FieldName // new
	
/*
	(* like name_group, except the declared variables are allowed to have initializers *)
	(* e.g.: #Int x=1, y=2; *)
and init_name_group = specifier * init_name list
*/
	op InitNameGroup : K K -> InitNameGroup [metadata "strict=(1)"] // K, List
	
/*
	(* The decl_type is in the order in which they are printed. Only the name of
	 * the declared identifier is pulled out. The attributes are those that are
	 * printed after the declarator *)
	(* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
	(* the string, and decl_type will be PTR([], JUSTBASE) *)
and name = #String * decl_type * attribute list * cabsloc
*/
	op Name : K K -> Name // first argument is id, second is basetype
	//op AnonymousName : K -> Name // new, argument is type
	op AnonymousName : -> K // new, argument is type
	op #NoName : -> #Id [metadata "latex=(renameTo \\#NoName)"] // new
	// latex "\llbracket\,{#1}\,\rrbracket"
	op #NoName : #Nat -> #Id [metadata "latex=(renameTo \\#NoName\\mybracket{_})"] // new
	op Identifier : #String -> #Id // new	
	// op NameLoc : K K -> Name // new
	
	macro AnonymousName = #NoName
	//macro AnonymousName(K:K) = Name(#NoName, K:K)
	
/*
	(* A variable declarator ("name") with an initializer *)
and init_name = name * init_expression
*/
	op InitName : K K -> InitName
	context InitName(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
/*
	(* Single names are for declarations that cannot come in groups, like
	 * function parameters and functions *)
and single_name = specifier * name
*/
	op SingleName : K K -> SingleName [metadata "strict=(1)"]
	
/*
and enum_item = #String * expression * cabsloc
*/
	op EnumItem : #Id -> PureEnumItem // this one has no init
	op EnumItemInit : #Id K -> PureEnumItem // this one has an init
	//op EnumItemLoc : K K -> EnumItem // new
		
/*
	(*
	** Declaration definition (at toplevel)
	*)
	and definition =
	   FUNDEF of single_name * block * cabsloc * cabsloc
	 | DECDEF of init_name_group * cabsloc        (* variable(s), or function prototype *)
	 | TYPEDEF of name_group * cabsloc
	 | ONLYTYPEDEF of specifier * cabsloc
	 | GLOBASM of #String * cabsloc
	 | PRAGMA of expression * cabsloc
	 | LINKAGE of #String * cabsloc * definition list (* extern "C" { ... } *)
	 (* toplevel form transformer, from the first definition to the *)
	 (* second group of definitions *)
	 | TRANSFORMER of definition * definition list * cabsloc
	 (* expression transformer: source and destination *)
	 | EXPRTRANSFORMER of expression * expression * cabsloc
*/
	op FunctionDefinition : K K -> PureDefinition [metadata "strict=(1)"]
	op DeclarationDefinition : K -> PureDefinition
	op Typedef : K -> PureDefinition
	op OnlyTypedef : K -> PureDefinition
	op GlobAsm : #String -> PureDefinition
	op Pragma : K -> PureDefinition
	op Linkage : #String K -> PureDefinition // seems to be unused
	op Transformer : K K -> PureDefinition // seems to be unused
	op ExpressionTransformer : K K -> PureDefinition
	op LTLAnnotation : K -> PureDefinition // name
	
	// new

	op LTL-Atom : K -> Expression 
	op LTL-Builtin : K -> Expression
	
	op LTL-True : -> Expression
	op LTL-False : -> Expression
	op LTL-And : K K -> Expression
	op LTL-Or : K K -> Expression
	op LTL-Not : K -> Expression
	op LTL-Next : K -> Expression
	op LTL-Always : K -> Expression
	op LTL-Eventually : K -> Expression
	op LTL-Until : K K -> Expression
	op LTL-Release : K K -> Expression
	op LTL-Implies : K K -> Expression
	op LTL-Equiv : K K -> Expression
	op LTL-WeakUntil : K K -> Expression
	
	op DefinitionLoc : K K -> Definition // new
	op DefinitionLocRange : K K K -> Definition // new
	
/*
(* the #String is a file name, and then the list of toplevel forms *)
and file = #String * definition list
*/
	// name, code, source
	op TranslationUnit : #String K K #String -> TranslationUnit // new: Filename, strings, ast, code
	op Program : K -> Program // new // List

/*
	(* A block contains a list of local label declarations ( GCC's ({ __label__ 
	 * l1, l2; ... }) ) , a list of definitions and a list of statements  *)
and block = 
	{ blabels: #String list;
	  battrs: attribute list;
	  bstmts: statement list
	} 
*/
	op Block : #Nat K K -> Block // #Nat, list, list
	
/*
	(* GCC asm directives have lots of extra information to guide the optimizer *)
and asm_details =
	{ aoutputs: (string option * #String * expression) list; 
	(* optional name, constraints and expressions for outputs *)
	ainputs: (string option * #String * expression) list; 
	(* optional name, constraints and expressions for inputs *)
	aclobbers: #String list 
	(* clobbered registers *)
	}
*/
	// TODO

/*
and statement =
	NOP of cabsloc
	| COMPUTATION of expression * cabsloc
	| BLOCK of block * cabsloc
	| SEQUENCE of statement * statement * cabsloc
*/
	op Nop : -> PureStatement
	op Computation : K -> PureStatement
	context Computation((HOLE => reval(HOLE))) // not sure why i had this commented out before...
	op BlockStatement : K -> PureStatement
	op Sequence : K K -> PureStatement
/*
	| IF of expression * statement * statement * cabsloc
	| WHILE of expression * statement * cabsloc
	| DOWHILE of expression * statement * cabsloc
	| FOR of for_clause * expression * expression * statement * cabsloc
*/
	op IfThenElse : K K K -> PureStatement
	context IfThenElse((HOLE => reval(HOLE)), _, _)
	op While : K K -> PureStatement
	op DoWhile : K K -> PureStatement
	op For : #Nat K K K K -> PureStatement // id, ...
/*
	| BREAK of cabsloc
	| CONTINUE of cabsloc
	| RETURN of expression * cabsloc
*/
	op Break : -> PureStatement
	op Continue : -> PureStatement
	op Return : K -> PureStatement
	context Return((HOLE => reval(HOLE)))
/*
	| SWITCH of expression * statement * cabsloc
	| CASE of expression * statement * cabsloc
	| CASERANGE of expression * expression * statement * cabsloc
	| DEFAULT of statement * cabsloc
*/
	op Switch : K K K -> PureStatement // unique switch id
	context Switch(_, (HOLE => reval(HOLE)), _)
	op Case : #Nat #Nat K K -> PureStatement // unique switch id, unique case id, exp, statement
	op CaseRange : K K K -> PureStatement // gcc extension
	op Default : #Nat K -> PureStatement // unique switch id, statement
/*
	| LABEL of #String * statement * cabsloc
	| GOTO of #String * cabsloc
	| COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
	| DEFINITION of definition (*definition or declaration of a variable or type*)
*/
	op Label : #Id K -> PureStatement
	op Goto : K -> PureStatement // #Id
	op CompGoto : K -> PureStatement
	// op LocalDefinition : K -> PureStatement  // renamed from "DEFINITION"
/*
	| ASM of attribute list * (* typically only volatile and const *)
		  #String list * (* template *)
		  asm_details option * (* extra details to guide GCC's optimizer *)
		  cabsloc
	| TRY_EXCEPT of block * expression * block * cabsloc
	| TRY_FINALLY of block * block * cabsloc
*/
	// TODO not handling Asm
	op TryExcept : K K K -> PureStatement
	op TryFinally : K K -> PureStatement
	
	// this wraps all statements with their location in the original file
	op StatementLoc : K K -> Statement // new
	
/*
and for_clause = 
	FC_EXP of expression
	| FC_DECL of definition
*/
	op ForClauseExpression : K -> ForClause
	//op ForClauseDeclaration : K -> ForClause
	
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
	op OffsetOf : K K K -> Expression [metadata "strict=(1)"]
	op ExpressionLoc : K K -> Expression // new

	op NothingExpression : -> Expression
/*
	| UNARY of unary_operator * expression

and unary_operator =
	MINUS | PLUS | NOT | BNOT | MEMOF | ADDROF
	| PREINCR | PREDECR | POSINCR | POSDECR
*/
	syntax Expression ::= "-" K [prec(22)]
	// op -_ : K -> Expression [prec 22]
	context -_((HOLE => reval(HOLE)))
	syntax Expression ::= "+" K [prec(22)]
	// op +_ : K -> Expression [prec 22]
	context +_((HOLE => reval(HOLE)))
	syntax Expression ::= "!" K [prec(22)]
	// op !_ : K -> Expression [prec 22]
	context !_((HOLE => reval(HOLE)))
	syntax Expression ::= "~" K [prec(22)]
	// op ~_ : K -> Expression [prec 22]
	context ~_((HOLE => reval(HOLE)))
	syntax Expression ::= "*" K [prec(22)]
	// op *_ : K -> Expression [prec 22]
	context *_((HOLE => reval(HOLE)))
	syntax Expression ::= "&" K [strict prec(22)]
	// op &_ : K -> Expression [prec 22 metadata "strict=()"]
	syntax Expression ::= "++" K [prec(22)]
	syntax Expression ::= "--" K [prec(22)]
	// op ++_ : K -> Expression [prec 22]
	// op --_ : K -> Expression [prec 22]
	syntax Expression ::= K "++"
	// op _++ : K -> Expression
	context _++((HOLE => peval(HOLE)))
	syntax Expression ::= K "--"
	// op _-- : K -> Expression
	context _--((HOLE => peval(HOLE)))
	
/*
	| LABELADDR of #String  (* GCC's && Label *)
*/
	// TODO not handling && Label
/*
	| BINARY of binary_operator * expression * expression
*/
	syntax Expression ::= K "*" K [prec(31) gather(E e)]
	syntax Expression ::= K "/" K [prec(31) gather(E e)]
	syntax Expression ::= K "%" K [prec(31) gather(E e)]
	// op _*_ : K K -> Expression [prec 31 gather(E e)]
	// op _/_ : K K -> Expression [prec 31 gather(E e)]
	// op _%_ : K K -> Expression [prec 31 gather(E e)]
	context _*_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _*_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	context _/_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _/_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	context _%_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _%_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "+" K [prec(33) gather(E e)]
	syntax Expression ::= K "-" K [prec(33) gather(E e)]
	// op _+_ : K K -> Expression [prec 33 gather(E e)]
	// op _-_ : K K -> Expression [prec 33 gather(E e)]
	context _+_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _+_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	context _-_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _-_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "<<" K [prec(35) gather(E e)]
	// op _<<_ : K K -> Expression [prec 35 gather(E e)]
	context _<<_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _<<_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K ">>" K [prec(35) gather(E e)]
	// op _>>_ : K K -> Expression [prec 35 gather(E e)]
	context _>>_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _>>_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "<" K [prec(37) gather(E e)]
	syntax Expression ::= K "<=" K [prec(37) gather(E e)]
	// op _<_ : K K -> Expression [prec 37 gather(E e)]
	// op _<=_ : K K -> Expression [prec 37 gather(E e)]
	context _<_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _<_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	context _<=_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _<=_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K ">" K [prec(37) gather(E e)]
	syntax Expression ::= K ">=" K [prec(37) gather(E e)]
	// op _>_ : K K -> Expression [prec 37 gather(E e)]
	// op _>=_ : K K -> Expression [prec 37 gather(E e)]
	context _>_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _>_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	context _>=_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _>=_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "==" K [prec(39) gather(E e)]
	syntax Expression ::= K "!=" K [prec(39) gather(E e)]
	// op _==_ : K K -> Expression [prec 39 gather(E e)]
	// op _!=_ : K K -> Expression [prec 39 gather(E e)]
	context _==_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _==_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	context _!=_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _!=_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "&" K [prec(41) gather(E e)]
	// op _&_ : K K -> Expression [prec 41 gather(E e)]
	context _&_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _&_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "^" K [prec(43) gather(E e)]
	// op _^_ : K K -> Expression [prec 43 gather(E e)]
	context _^_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _^_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "|" K [prec(45) gather(E e)]
	// op _|_ : K K -> Expression [prec 45 gather(E e)]
	context _|_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	context _|_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
	syntax Expression ::= K "&&" K [prec(47) gather(E e)]
	// op _&&_ : K K -> Expression [prec 47 gather(E e)]
	context _&&_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	
	syntax Expression ::= K "||" K [prec(49) gather(E e)]
	// op _||_ : K K -> Expression [prec 49 gather(E e)]
	context _||_((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	
	syntax Expression ::= K "*=" K [prec(53)]
	syntax Expression ::= K "/=" K [prec(53)]
	syntax Expression ::= K "%=" K [prec(53)]
	syntax Expression ::= K "+=" K [prec(53)]
	syntax Expression ::= K "-=" K [prec(53)]
	// op _*=_ : K K -> Expression [prec 53]
	// op _/=_  : K K -> Expression [prec 53]
	// op _%=_  : K K -> Expression [prec 53]
	// op _+=_ : K K -> Expression [prec 53]
	// op _-=_ : K K -> Expression [prec 53]
	syntax Expression ::= K "<<=" K [prec(53)]
	syntax Expression ::= K "&=" K [prec(53)]
	syntax Expression ::= K "^=" K [prec(53)]
	syntax Expression ::= K "|=" K [prec(53)]
	syntax Expression ::= K ">>=" K [prec(53)]
	// op _<<=_ : K K -> Expression [prec 53]
	// op _&=_ : K K -> Expression [prec 53]
	// op _^=_ : K K -> Expression [prec 53]
	// op _|=_ : K K -> Expression [prec 53]
	// op _>>=_ : K K -> Expression [prec 53]
	syntax Expression ::= K ":=" K [prec(53)]
	// op _:=_ : K K -> Expression [prec 53]
	context _:=_((HOLE => peval(HOLE)), _) [metadata "ndheat=()"]
	context _:=_(_, (HOLE => reval(HOLE))) [metadata "ndheat=()"]
	
/*
	| QUESTION of expression * expression * expression
*/
	syntax Expression ::= K "?" K ":" K [prec(51) gather(e & E)]
	// op _?_:_ : K K K -> Expression [prec 51 gather(e & E)]
	// syntax Expression ::= K ? K : K [prec 51 gather(e & E)]
	context _?_:_((HOLE => reval(HOLE)), _, _)

/*
	(* A CAST can actually be a constructor expression *)
	| CAST of (specifier * decl_type) * init_expression
*/
	op Cast : K K K -> Expression [metadata "strict=(1)"]
	context Cast(_, _, (HOLE => reval(HOLE)))
	
	op CompoundLiteral : K K K K -> Expression [metadata "strict=(2)"] // new // comp-lit id, spec, decl, init
/*
	(* There is a special form of CALL in which the function called is
	   __builtin_va_arg and the second argument is sizeof(T). This 
	   should be printed as just T *)
	| CALL of expression * expression list
*/

	op Call : K K -> Expression // K, List
	context Call((HOLE => reval(HOLE)), _) [metadata "ndheat=()"]
	// context Call(_, (_ :: (HOLE:C => reval(HOLE)) :: _)) [metadata "ndheat=()"]
	context Call(_, List((_:List{K},, (HOLE => reval(HOLE)),, _:List{K}))) [metadata "ndheat=()"]
/*
	| COMMA of expression list
*/
	op Comma : K -> Expression // List
	// context Comma((HOLE:C => reval(HOLE)) :: _) [metadata "ndheat=()"]
	// context 'Comma('_::_((HOLE:C => reval(HOLE)),, _)) [metadata "ndheat=()"]
	context Comma(List(((HOLE => reval(HOLE)),, _:List{K}))) [metadata "ndheat=()"]
/*
	| CONSTANT of constant
	| PAREN of expression
	| VARIABLE of string
*/
	op Constant : K -> Expression
	// context Constant((HOLE => reval(HOLE)))
	// #String constants aren't revals
	// for paren, just putting parentheses
	subsort #Id < Expression
/*
	| EXPR_SIZEOF of expression
	| TYPE_SIZEOF of specifier * decl_type
	| EXPR_ALIGNOF of expression
	| TYPE_ALIGNOF of specifier * decl_type
*/
	op SizeofExpression : K -> Expression
	op SizeofType : K K -> Expression [metadata "strict=(1)"]
	op AlignofExpression : K -> Expression
	op AlignofType : K K -> Expression
/*
	| INDEX of expression * expression
*/
	op _`[_`] : K K -> Expression
	// op ArrayIndex : K K -> Expression
/*
	| MEMBEROF of expression * string
	| MEMBEROFPTR of expression * string
*/
	op _._ : K #Id -> Expression
	context _._((HOLE => peval(HOLE)), _:#Id)
	op _->_ : K #Id -> Expression
	context _->_((HOLE => reval(HOLE)), _:#Id)
/*
	| GNU_BODY of block
	| EXPR_PATTERN of #String     (* pattern variable, and name *)
*/
	op GnuBody : K -> Expression
	op ExpressionPattern : #String -> Expression
	
/*
and constant =
	| CONST_INT of #String   (* the textual representation *)
	| CONST_FLOAT of #String (* the textual representaton *)
	| CONST_CHAR of int64 list
	| CONST_WCHAR of int64 list
	| CONST_STRING of string
	| CONST_WSTRING of int64 list 
*/
	op DecimalConstant : K -> IntConstant // new
	op OctalConstant : K -> IntConstant // new
	op HexConstant : K -> IntConstant // new // expected to be string
	
	op DecimalFloatConstant : #String #Int #Float -> IntConstant // new; significand, exponent, approx
	op HexFloatConstant : #String #Int #Float -> IntConstant // new; significand, exponent, approx
	
	op U : K -> Constant // new
	op L : K -> Constant // new
	op F : K -> Constant // new
	op LL : K -> Constant // new
	op UL : K -> Constant // new
	op ULL : K -> Constant // new
	op NoSuffix : K -> Constant // new
	
	//op IntLiteral : K -> Constant
	//op FloatLiteral : K -> Constant
	op CharLiteral : #Int -> Constant
	op WCharLiteral : #Int -> Constant
	op StringLiteral : #String -> Constant
	op WStringLiteral : List{K} -> Constant
	

/*
and init_expression =
  | NO_INIT
  | SINGLE_INIT of expression
  | COMPOUND_INIT of (initwhat * init_expression) list
*/
	op NoInit : -> KResult // InitExpression
	op SingleInit : K -> InitExpression [metadata "hybrid=() strict=()"]
	op CompoundInit : K -> InitExpression [metadata "hybrid=() strict=()"] // List
	op InitFragment : K K -> InitFragment // new; (initwhat * init_expression)
	
/*
and initwhat =
	NEXT_INIT
	| INFIELD_INIT of #String * initwhat
	| ATINDEX_INIT of expression * initwhat
	| ATINDEXRANGE_INIT of expression * expression
*/
	op NextInit : -> KResult
	op InFieldInit : #Id K -> KResult
	op AtIndexInit : K K -> KResult
	op AtIndexRangeInit : K K -> KResult // nonstandard

	
/*
and attribute = #String * expression list
*/
	op Attribute : #String K -> C // #String, List
	
	
	
	op CodeLoc : K K -> K
	macro DefinitionLoc(K:K, L:K) = CodeLoc(K:K, L:K)
	macro StatementLoc(K:K, L:K) = CodeLoc(K:K, L:K)
	// macro ExpressionLoc(K:K, L:K) = CodeLoc(K:K, L:K)	
	macro DefinitionLocRange(K:K, _, L:K) = CodeLoc(K:K, L:K)
	// macro EnumItemLoc(K:K, L:K) = CodeLoc(K:K, L:K)
	
	
	/*@ This macro defines an important identity from (n1570) 6.5.3.2.  As a syntactic macro, it should run on programs before they even start to reduce. */
	macro &(*(K:K)) = K:K
	
	

	/*@ The below macros simply transform the prefix AST names to the infix/mixfix names we use from now on */
	
	// all these macros are temporary while I adjust the semantics to the new grammar
	op Conditional : K K K -> Expression
	macro Conditional(K1:K, K2:K, K3:K) = K1:K ? K2:K : K3:K
	
	op ArrayIndex : K K -> Expression
	macro ArrayIndex(K1:K, K2:K) = K1:K[K2:K]
	
	op Negative : K -> Expression
	macro Negative(K:K) = - K:K
	op Positive : K -> Expression
	macro Positive(K:K) = + K:K
	op LogicalNot : K -> Expression
	macro LogicalNot(K:K) = ! K:K
	op BitwiseNot : K -> Expression
	macro BitwiseNot(K:K) = ~ K:K
	op Dereference : K -> Expression
	macro Dereference(K:K) = * K:K
	op Reference : K -> Expression
	macro Reference(K:K) = & K:K
	op PreIncrement : K -> Expression
	macro PreIncrement(K:K) = ++ K:K
	op PreDecrement : K -> Expression
	macro PreDecrement(K:K) = -- K:K
	op PostIncrement : K -> Expression
	macro PostIncrement(K:K) = K:K ++
	op PostDecrement : K -> Expression
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
	
	ops Dot : K #Id -> Expression
	macro Dot(K:K, X:#Id) = K:K . X:#Id
	op Arrow : K #Id -> Expression
	macro Arrow(K:K, X:#Id) = K:K -> X:#Id
	
	
	
	
	
	
	
endkm
