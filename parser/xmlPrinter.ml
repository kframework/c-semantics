open Escape
open Cabs
open Big_int

let counter = ref 0
let currentSwitchId = ref 0
let switchStack = ref [0]
let realFilename = ref ""
let defsPrinted = ref 0
let ast = ref ""

let stringLiterals = ref []

let rec trim s =
  let l = String.length s in 
  if l=0 then s
  else if s.[0]=' ' || s.[0]='\t' || s.[0]='\n' || s.[0]='\r' then
    trim (String.sub s 1 (l-1))
  else if s.[l-1]=' ' || s.[l-1]='\t' || s.[l-1]='\n' || s.[l-1]='\r' then
    trim (String.sub s 0 (l-1))
  else
    s

(* this is from cil *)
let escape_char = function
  | '\007' -> "\\a"
  | '\b' -> "\\b"
  | '\t' -> "\\t"
  | '\n' -> "\\n"
  | '\011' -> "\\v"
  | '\012' -> "\\f"
  | '\r' -> "\\r"
  | '"' -> "\\\""
  | '\'' -> "\\'"
  | '\\' -> "\\\\"
  | ' ' .. '~' as printable -> String.make 1 printable
  | unprintable -> Printf.sprintf "\\%03o" (Char.code unprintable)
  
(* this is from cil *)
let escape_string str =
  let length = String.length str in
  let buffer = Buffer.create length in
  for index = 0 to length - 1 do
    Buffer.add_string buffer (escape_char (String.get str index))
  done;
  Buffer.contents buffer

let k_char_escape (buf: Buffer.t) (c: char) : unit = match c with
| '"' -> Buffer.add_string buf "\\\""
| '\\' -> Buffer.add_string buf "\\\\"
| '\n' -> Buffer.add_string buf "\\n"
| '\t' -> Buffer.add_string buf "\\t"
| '\r' -> Buffer.add_string buf "\\r"
| _ when let code = Char.code c in code >= 32 && code < 127 -> Buffer.add_char buf c
| _ -> Buffer.add_string buf (Printf.sprintf "\\x%02x" (Char.code c))
let k_string_escape str = 
  let buf = Buffer.create (String.length str) in
  String.iter (k_char_escape buf) str; Buffer.contents buf


(* Given a character constant (like 'a' or 'abc') as a list of 64-bit
 * values, turn it into a CIL constant.  Multi-character constants are
 * treated as multi-digit numbers with radix given by the bit width of
 * the specified type (either char or wchar_t). *)
(* CME: actually, this is based on the code in CIL *)
let rec reduce_multichar : int64 list -> int64 =
  let radix = 8 in
  List.fold_left
    (fun acc -> Int64.add (Int64.shift_left acc radix))
    Int64.zero
and interpret_character_constant char_list =
  let value = reduce_multichar char_list in
  Int64.to_int value
  
let rec reduce_multiwchar : int64 list -> int64 =
  let radix = 32 in
  List.fold_left
    (fun acc -> Int64.add (Int64.shift_left acc radix))
    Int64.zero
and interpret_wcharacter_constant char_list =
  let value = reduce_multichar char_list in
  Int64.to_int value

let replace input output =
    Str.global_replace (Str.regexp_string input) output

type attribute =
	Attrib of string * string
	
let buffer = ref (Buffer.create 1)
let printString s = (fun () -> Buffer.add_string !buffer s)

let ktoken (str: string) (sort: string) =
        fun () -> Buffer.add_string !buffer "#token(\""; Buffer.add_string !buffer (k_string_escape str); Buffer.add_string !buffer "\", \""; Buffer.add_string !buffer sort; Buffer.add_string !buffer "\")"

let rec concatN n s =
	if (n = 0) then "" else s ^ (concatN (n-1) s)

let kapply (label: string) (contents: unit -> unit) : unit -> unit =
        fun () -> Buffer.add_string !buffer "`"; Buffer.add_string !buffer label; Buffer.add_string !buffer "`("; contents (); Buffer.add_string !buffer ")"

let wrap (children : (unit -> unit) list) (name) : unit -> unit =
	kapply name (fun () -> List.iteri (fun i a -> if i = (List.length children) - 1 then a () else (a (); Buffer.add_string !buffer ", ")) children)

let nil = fun () -> Buffer.add_string !buffer ".KList"

let printNewList f l =
        kapply "list" (List.fold_right (fun k l -> wrap [(wrap [k] "ListItem"); l] "_List_") (List.map f l) (kapply ".List" nil))

(* this is where the recursive printer starts *)
	
let rec cabsToXML ((filename, defs) : file) (myRealFilename : string) : string = 
(* encoding="utf-8"  *)
	realFilename := myRealFilename;
        buffer := Buffer.create 100;
	(printTranslationUnit filename defs buffer) ();
        Buffer.contents !buffer

and printTranslationUnit (filename : string) defs buffer =
	let filenameCell = (* (printRawString filename) *)
		(printRawString !realFilename)
	 in
	let ast = printDefs defs in
	let strings = printStrings buffer in (* the evaluation order is all messed up if this has no argument *)
	wrap (filenameCell :: strings :: ast :: []) "TranslationUnit"
and printStrings buffer =
	(* List.map (fun element -> print_string (element ^ "\n")) !stringLiterals;
	print_string "printed strings\n"; *)
	printNewList (fun x -> wrap (x :: []) "Constant") !stringLiterals
and printDefs defs =
        printNewList (fun def -> printDef def) defs
and printDef def =
	match def with
		| FUNDEF (a, b, c, d) -> 
			printDefinitionLocRange (wrap ((printSingleName a) :: (printBlock b) :: []) "FunctionDefinition") c d
		| DECDEF (a, b) -> 
			printDefinitionLoc (wrap ((printInitNameGroup a) :: []) "DeclarationDefinition") b
		| TYPEDEF (a, b) ->
			printDefinitionLoc (wrap ((printNameGroup a) :: []) "Typedef") b
		| ONLYTYPEDEF (a, b) -> 
			printDefinitionLoc (wrap ((printSpecifier a) :: []) "OnlyTypedef") b
		| GLOBASM (a, b) ->
			printDefinitionLoc (wrap ((printRawString a) :: []) "GlobAsm") b
		| PRAGMA (a, b) ->
			printDefinitionLoc (wrap ((printExpression a) :: []) "Pragma") b
		| LINKAGE (a, b, c) ->
			printDefinitionLoc (wrap ((printRawString a) :: (printDefs c) :: []) "Linkage") b
		| TRANSFORMER (a, b, c) ->
			printDefinitionLoc (wrap ((printDef a) :: (printDefs b) :: []) "Transformer") c
		| EXPRTRANSFORMER (a, b, c) ->
			printDefinitionLoc (wrap ((printExpression a) :: (printExpression b) :: []) "ExprTransformer") c
		| LTL_ANNOTATION (a, b, c) ->
			printDefinitionLoc (wrap ((printIdentifier a) :: (printLTLExpression b) :: []) "LTLAnnotation") c
            | STATIC_ASSERT (a, b, c) ->
			printDefinitionLoc (wrap ((printExpression a) :: (printConstant b) :: []) "StaticAssert") c

			
and printLTLExpression a =
	let retval = printExpression a in
	retval
and printDefinitionLoc a l =
	if (hasInformation l) then (wrap (a :: (printCabsLoc l) :: []) "DefinitionLoc") else (a)
and printExpressionLoc a l =
	(* if (hasInformation l) then (wrap (a :: (printCabsLoc l) :: []) "ExpressionLoc") else (a) *)
	a
and printDefinitionLocRange a b c =
	wrap (a :: (printCabsLoc b) :: (printCabsLoc c) :: []) "DefinitionLocRange"		
and printSingleName (a, b) = 
	wrap ((printSpecifier a) :: (printName b) :: []) "SingleName"
and printAttr a b = wrap (a :: (printSpecElemList b) :: []) "AttributeWrapper"
and printBlock a = 
	let blockNum = ((counter := (!counter + 1); !counter)) in
	let blockNumCell = (printRawInt blockNum) in
	let idCell = blockNumCell in
	wrap (idCell :: (printBlockLabels a.blabels) :: (printStatementList a.bstmts) :: []) "Block3"
	(* printCell "Block" attribs ((printBlockLabels a.blabels) ^ (printStatementList a.bstmts)) in *)

	(*	
and block = 
    { blabels: string list;
      battrs: attribute list;
      bstmts: statement list
    } *)
and printCabsLoc a = 
	(* let attribs = Attrib ("filename", a.filename )
		:: Attrib ("lineno", string_of_int a.lineno )
		:: Attrib ("byteno", string_of_int a.byteno )
		:: Attrib ("ident", string_of_int a.ident )
		:: Attrib ("systemHeader", string_of_bool a.systemHeader )
		:: []
	in*)
        wrap ((printRawString a.filename) :: (printRawString (if Filename.is_relative a.filename then Filename.concat (Sys.getcwd ()) a.filename else a.filename)) :: (printRawInt a.lineno) :: (printRawInt a.lineOffsetStart) :: (printRawBool a.systemHeader) :: []) "CabsLoc"

and hasInformation l =
	l.lineno <> -10
and printNameLoc s l =
	(* if (hasInformation l) then (wrap (s :: (printCabsLoc l) :: []) "NameLoc") else (s) *)
	s
and printIdentifier a =
	kapply "ToIdentifier"  (printRawString a)
and printName (a, b, c, d) = (* string * decl_type * attribute list * cabsloc *)
	if a = "" then 
		(* printAttr (printNameLoc (wrap ((printDeclType b) :: []) "AnonymousName") d) c *)
		printNameLoc (wrap ((kapply "AnonymousName"  (nil)) :: (printDeclType b) :: (printSpecElemList c) :: []) "Name") d
	else 
		printNameLoc (wrap ((printIdentifier a) :: (printDeclType b) :: (printSpecElemList c) :: []) "Name") d
	
	
and printInitNameGroup (a, b) = 
	wrap ((printSpecifier a) :: (printInitNameList b) :: []) "InitNameGroup"
and printNameGroup (a, b) = 
	wrap ((printSpecifier a) :: (printNameList b) :: []) "NameGroup"
and printNameList a =
	printNewList printName a
and printInitNameList a = 
	printNewList printInitName a
and printFieldGroupList a =
	printNewList printFieldGroup a
and printFieldGroup (spec, fields) =
	wrap ((printSpecifier spec) :: (printFieldList fields) :: []) "FieldGroup"
and printFieldList (fields) =
	printNewList printField fields
and printField (name, expOpt) =
	match expOpt with
	| None -> wrap ((printName name) :: []) "FieldName"
	| Some exp -> wrap ((printName name) :: (printExpression exp) :: []) "BitFieldName"	
and printInitName (a, b) = 
	wrap ((printName a) :: (printInitExpression b) :: []) "InitName"
and printInitExpression a =
	match a with 
	| NO_INIT -> kapply "NoInit"  nil
	| SINGLE_INIT exp -> wrap ((printExpression exp) :: []) "SingleInit"
	| COMPOUND_INIT a -> wrap ((printInitFragmentList a) :: []) "CompoundInit"
and printInitExpressionForCast a castPrinter compoundLiteralPrinter = (* this is used when we are printing an init inside a cast, i.e., possibly a compound literal *)
	match a with 
	| NO_INIT -> kapply "Error"  (printString "cast with a NO_INIT inside doesn't make sense")
	| SINGLE_INIT exp -> castPrinter (printExpression exp)
	| COMPOUND_INIT a -> compoundLiteralPrinter (wrap ((printInitFragmentList a) :: []) "CompoundInit")
and printInitFragmentList a =
	printNewList printInitFragment a
and printGenericAssocs assocs =
	printNewList printGenericAssoc assocs
and printInitFragment (a, b) =
	wrap ((printInitWhat a) :: (printInitExpression b) :: []) "InitFragment"
and printInitWhat a = 
	match a with
	| NEXT_INIT -> kapply "NextInit"  nil
	| INFIELD_INIT (id, what) -> wrap ((printIdentifier id) :: (printInitWhat what) :: []) "InFieldInit"
	| ATINDEX_INIT (exp, what) -> wrap ((printExpression exp) :: (printInitWhat what) :: []) "AtIndexInit"
	| ATINDEXRANGE_INIT (exp1, exp2) -> wrap ((printExpression exp1) :: (printExpression exp2) :: []) "AtIndexRangeInit"
and printDeclType a =
	(match a with
	| JUSTBASE -> kapply "JustBase"  nil
	| PARENTYPE (a, b, c) -> printParenType a b c
	| ARRAY (a, b, c, d) -> printArrayType a b c d
	| PTR (a, b) -> printPointerType a b
	| PROTO (a, b, c) -> printProtoType a b c
	| NOPROTO (a, b, c) -> printNoProtoType a b c)
and printParenType a b c =
	(wrap ((printDeclType b) :: []) "FunctionType")
and printArrayType a b c d =
	(wrap ((printDeclType a) :: (printExpression c) :: (printSpecifier (b@d)) :: []) "ArrayType")
and printPointerType a b =
	(wrap ((printSpecifier a) :: (printDeclType b) :: []) "PointerType")
and printProtoType a b c =
	(* printCell "Prototype" [Attrib ("variadic", string_of_bool c)] (printList (fun x -> x) ((printDeclType a) :: (printSingleNameList b) :: [])) *)
	let variadicName = if c then "true" else "false" in
	let variadicCell = ktoken variadicName "Bool" in
	wrap ((printDeclType a) :: (printSingleNameList b) :: variadicCell :: []) "Prototype"
and printNoProtoType a b c =
	(* printCell "Prototype" [Attrib ("variadic", string_of_bool c)] (printList (fun x -> x) ((printDeclType a) :: (printSingleNameList b) :: [])) *)
	let variadicName = if c then "true" else "false" in
	let variadicCell = ktoken variadicName "Bool" in
	wrap ((printDeclType a) :: (printSingleNameList b) :: variadicCell :: []) "NoPrototype"
and printNop =
	kapply "Nop"  nil
and printComputation exp =
	wrap ((printExpression exp) :: []) "Computation"
and printExpressionList defs =
	printNewList printExpression defs
and printBuiltin (sort : string) (data : string) =
	ktoken data sort
and printRawString s =
	printBuiltin "String" ("\"" ^ (k_string_escape s) ^ "\"")
(* &#38; *)

(* Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] *)
	
and printRawFloat f =
	printRawFloatString (string_of_float f)
and printRawFloatString s =
	printBuiltin "Float" s
and printRawInt i =
	printRawIntString (string_of_int i)
and printRawIntString s =
	printBuiltin "Int" s
and printRawBool b =
	printRawBoolString (string_of_bool b)
and printRawBoolString s =
	printBuiltin "Bool" s
(* and printRawInt64 i =
	printBuiltin "Int" (Int64.to_string i) *)
and string_of_list_of_int64 (xs : int64 list) =
	let length = List.length xs in
	let buffer = Buffer.create length in
	let append charcode =
		let addition = String.make 1 (Char.chr (Int64.to_int charcode)) in
		Buffer.add_string buffer addition
	in
	List.iter append xs;
	Buffer.contents buffer
and printConstant const =
	match const with
	| CONST_INT i -> printIntLiteral i
	| CONST_FLOAT r -> printFloatLiteral r
	| CONST_CHAR c -> wrap [printRawInt (interpret_character_constant c)] "CharLiteral"
	| CONST_WCHAR c -> wrap [printRawInt (interpret_wcharacter_constant c)] "WCharLiteral"
	| CONST_STRING s -> handleStringLiteral s
	| CONST_WSTRING ws -> handleWStringLiteral ws
and handleStringLiteral s =
	let result = wrap [printRawString s] "StringLiteral" in
	(* List.map (fun element -> print_string (element ^ "\n")) !stringLiterals;
	print_string "inside string handler\n"; *)
	stringLiterals := result :: !stringLiterals;
	result
and handleWStringLiteral ws =
	let result = wrap [printNewList (fun i -> printRawInt (Int64.to_int i)) ws] "WStringLiteral" in
	stringLiterals := result :: !stringLiterals;
	result
and splitFloat (xs, i) =
	let lastOne = if (String.length i > 1) then String.uppercase (Str.last_chars i 1) else ("x") in
	let newi = (Str.string_before i (String.length i - 1)) in
	match lastOne with
	| "x" -> (xs, i)
	| "L" -> splitFloat("L" :: xs, newi)
	| "F" -> splitFloat("F" :: xs, newi)
	| _ -> (xs, i)
and splitInt (xs, i) =
	let lastOne = if (String.length i > 1) then String.uppercase (Str.last_chars i 1) else ("x") in
	let newi = (Str.string_before i (String.length i - 1)) in
	match lastOne with
	| "x" -> (xs, i)
	| "U" -> splitInt("U" :: xs, newi)
	| "L" -> splitInt("L" :: xs, newi)
	| _ -> (xs, i)
and printHexFloatConstant f = 
	let significand :: exponentPart :: [] = Str.split (Str.regexp "[pP]") f in
	let wholePart :: fractionalPart = Str.split_delim (Str.regexp "\.") significand in
	let wholePart = (if wholePart = "" then "0" else wholePart) in
	let fractionalPart =
		(match fractionalPart with
		| [] -> "0"
		| "" :: [] -> "0"
		| x :: [] -> x
		) in
	let exponentPart :: [] = Str.split (Str.regexp "[+]") exponentPart in
	let exponentPart = int_of_string exponentPart in
	
	let significand = wholePart ^ "." ^ fractionalPart in
	let approx = float_of_string ("0x" ^ significand) in
	let approx = approx *. (2. ** (float_of_int exponentPart)) in
	let exponentPart = printRawInt exponentPart in
	let significandPart = printRawString significand in
	let significandPart = significandPart in
	let exponentPart = exponentPart in
	let approxPart = printRawFloat approx in
	(wrap (significandPart :: exponentPart :: approxPart :: []) "HexFloatConstant")
	(* let significand = wholePart +. fractionalPart in
	let result = significand *. (2. ** (float_of_int exponentPart)) in
	wrap ((string_of_int (int_of_float wholePart)) :: (string_of_float fractionalPart) :: (string_of_int exponentPart) :: (string_of_float result) :: []) "HexFloatConstant" *)
and printDecFloatConstant f =
	(* print_endline f; *)
	let f = Str.split (Str.regexp "[eE]") f in
	let (significand, exponentPart) = 
		(match f with
		| (x : string) :: [] -> (x, "0")
		| (x : string) :: (y : string) :: [] -> (x, y)
		) in
	let wholePart :: fractionalPart = Str.split_delim (Str.regexp "\.") significand in
	let wholePart = (if wholePart = "" then "0" else wholePart) in
	let fractionalPart =
		(match fractionalPart with
		| [] -> "0"
		| "" :: [] -> "0"
		| x :: [] -> x
		) in
	let stringRep = wholePart ^ "." ^ fractionalPart ^ "e" ^ exponentPart in
	let exponentPart :: [] = Str.split (Str.regexp "[+]") exponentPart in
	let exponentPart = int_of_string exponentPart in
	
	let significand = wholePart ^ "." ^ fractionalPart in
	(* let approx = float_of_string significand in
	let approx = approx *. (10. ** (float_of_int exponentPart)) in *)
	
	let significandPart = printRawString significand in
	let exponentPart = printRawInt exponentPart in
	let approxPart = printRawFloatString stringRep in
	let significandPart = significandPart in
	let exponentPart = exponentPart in
	(wrap (significandPart :: exponentPart :: approxPart :: []) "DecimalFloatConstant")
	
and printFloatLiteral r =
	let (tag, r) = splitFloat ([], r) in
	let num = (
		let firstTwo = if (String.length r > 2) then (Str.first_chars r 2) else ("xx") in
			if (firstTwo = "0x" or firstTwo = "0X") then 
				let nonPrefix = Str.string_after r 2 in
					printHexFloatConstant nonPrefix					
			else ( printDecFloatConstant r)
	) in
	match tag with
	| "F" :: [] -> wrap (num :: []) "LitF"
	| "L" :: [] -> wrap (num :: []) "LitL"
	| [] -> wrap (num :: []) "NoSuffix"
and printHexConstant (i : string) =
	(* let inDec = Int64.of_string ("0x" ^ i) in 
	wrap [printRawInt64 inDec] "HexConstant" *)
	wrap [printRawString i] "HexConstant"
and printOctConstant (i : string) =
	(* let inDec = Int64.of_string ("0o" ^ i) in
	wrap [printRawInt64 inDec] "OctalConstant" *)
	wrap [printRawIntString i] "OctalConstant"
and printDecConstant (i : string) =
	(* let inDec = Int64.of_string i in
	wrap [printRawInt64 inDec] "DecimalConstant" *)
	wrap [printRawIntString i] "DecimalConstant"
and printIntLiteral i =
	let (tag, i) = splitInt ([], i) in
	let num = (
		let firstTwo = if (String.length i > 2) then (Str.first_chars i 2) else ("xx") in
		let firstOne = if (String.length i > 1) then (Str.first_chars i 1) else ("x") in
			if (firstTwo = "0x" or firstTwo = "0X") then 
				printHexConstant (Str.string_after i 2)
			else (if (firstOne = "0") then printOctConstant (Str.string_after i 1) else (printDecConstant i))
	) in
	match tag with
	| "U" :: "L" :: "L" :: []
	| "L" :: "L" :: "U" :: [] -> wrap (num :: []) "LitULL"
	| "L" :: "L" :: [] -> wrap (num :: []) "LitLL"
	| "U" :: "L" :: []
	| "L" :: "U" :: [] -> wrap (num :: []) "LitUL"
	| "U" :: [] -> wrap (num :: []) "LitU"
	| "L" :: [] -> wrap (num :: []) "LitL"
	| [] -> wrap (num :: []) "NoSuffix"
	(* | _ as z -> wrap (num :: []) (List.fold_left (fun aux arg -> aux ^ arg) "" z) *)
	
and printExpression exp =
	match exp with
	| OFFSETOF ((spec, declType), exp, loc) -> printExpressionLoc (wrap ((printSpecifier spec) :: (printDeclType declType) :: (printExpression exp) :: []) "OffsetOf") loc
	| TYPES_COMPAT ((spec1, declType1), (spec2, declType2), loc) -> printExpressionLoc (wrap ((printSpecifier spec1) :: (printDeclType declType1) :: (printSpecifier spec2) :: (printDeclType declType2) :: []) "TypesCompat") loc
	| GENERIC (exp, assocs) -> wrap (printExpression exp :: printGenericAssocs assocs :: []) "Generic"
	| LOCEXP (exp, loc) -> printExpressionLoc (printExpression exp) loc
	| UNARY (op, exp1) -> printUnaryExpression op exp1
	| BINARY (op, exp1, exp2) -> printBinaryExpression op exp1 exp2
	| NOTHING -> kapply "NothingExpression"  nil
	| UNSPECIFIED -> kapply "UnspecifiedSizeExpression"  nil
	| PAREN (exp1) -> (printExpression exp1)
	| LABELADDR (s) -> wrap ((printString s) :: []) "GCCLabelOperator"
	| QUESTION (exp1, exp2, exp3) -> wrap ((printExpression exp1) :: (printExpression exp2) :: (printExpression exp3) :: []) "Conditional"
	(* special case below for the compound literals.  i don't know why this isn't in the ast... *)
	| CAST ((spec, declType), initExp) -> 
		let castPrinter x = wrap ((printSpecifier spec) :: (printDeclType declType) :: x :: []) "Cast" in
		let id = (counter := (!counter + 1)); !counter in
		let compoundLiteralIdCell = (printRawInt id) in
		let compoundLiteralPrinter x = wrap (compoundLiteralIdCell :: (printSpecifier spec) :: (printDeclType declType) :: x :: []) "CompoundLiteral"
		in printInitExpressionForCast initExp castPrinter compoundLiteralPrinter
		(* A CAST can actually be a constructor expression *)
	| CALL (exp1, expList) -> wrap ((printExpression exp1) :: (printExpressionList expList) :: []) "Call"
		(* There is a special form of CALL in which the function called is
		__builtin_va_arg and the second argument is sizeof(T). This 
		should be printed as just T *)
	| COMMA (expList) -> wrap ((printExpressionList expList) :: []) "Comma"
	| CONSTANT (const) -> wrap (printConstant const :: []) "Constant"
	| VARIABLE name -> (printIdentifier name)
	| EXPR_SIZEOF exp1 -> wrap ((printExpression exp1) :: []) "SizeofExpression"
	| TYPE_SIZEOF (spec, declType) -> wrap ((printSpecifier spec) :: (printDeclType declType) :: []) "SizeofType"
	| EXPR_ALIGNOF exp -> wrap ((printExpression exp) :: []) "AlignofExpression"
	| TYPE_ALIGNOF (spec, declType) -> wrap ((printSpecifier spec) :: (printDeclType declType) :: []) "AlignofType"
	| INDEX (exp, idx) -> wrap ((printExpression exp) :: (printExpression idx) :: []) "ArrayIndex"
	| MEMBEROF (exp, fld) -> wrap ((printExpression exp) :: (printIdentifier fld) :: []) "Dot"
	| MEMBEROFPTR (exp, fld) -> wrap ((printExpression exp) :: (printIdentifier fld) :: []) "Arrow"
	| GNU_BODY block -> wrap ((printBlock block) :: []) "GnuBody"
	| BITMEMBEROF (exp, fld) -> wrap ((printExpression exp) :: (printIdentifier fld) :: []) "DotBit"
	| EXPR_PATTERN s -> wrap ((printRawString s) :: []) "ExpressionPattern"
	| LTL_ALWAYS e -> wrap ((printLTLExpression e) :: []) "LTLAlways"
	| LTL_IMPLIES (e1, e2) -> wrap ((printLTLExpression e1) :: (printLTLExpression e2) :: []) "LTLImplies"
	| LTL_EVENTUALLY e -> wrap ((printLTLExpression e) :: []) "LTLEventually"
	| LTL_NOT e -> wrap ((printLTLExpression e) :: []) "LTLNot"
	| LTL_ATOM e -> wrap ((printLTLExpression e) :: []) "LTLAtom"
	| LTL_BUILTIN e -> wrap ((printIdentifier e) :: []) "LTLBuiltin"
	| LTL_AND (e1, e2) -> wrap ((printLTLExpression e1) :: (printLTLExpression e2) :: []) "LTLAnd"
	| LTL_OR (e1, e2) -> wrap ((printLTLExpression e1) :: (printLTLExpression e2) :: []) "LTLOr"
	| LTL_URW ("U", e1, e2) -> wrap ((printLTLExpression e1) :: (printLTLExpression e2) :: []) "LTLUntil"
	| LTL_URW ("R", e1, e2) -> wrap ((printLTLExpression e1) :: (printLTLExpression e2) :: []) "LTLRelease"
	| LTL_URW ("W", e1, e2) -> wrap ((printLTLExpression e1) :: (printLTLExpression e2) :: []) "LTLWeakUntil"
	| LTL_O ("O", e) -> wrap ((printLTLExpression e) :: []) "LTLNext"
and printGenericAssoc assoc =
	match assoc with
	| GENERIC_PAIR ((spec, declType), exp) -> wrap (printSpecifier spec :: printDeclType declType :: printExpression exp :: []) "GenericPair"
	| GENERIC_DEFAULT (exp) -> wrap (printExpression exp :: []) "GenericDefault"
and getUnaryOperator op =
	let name = (
	match op with
	| MINUS -> "Negative"
	| PLUS -> "Positive"
	| NOT -> "LogicalNot"
	| BNOT -> "BitwiseNot"
	| MEMOF -> "Dereference"
	| ADDROF -> "Reference"
	| PREINCR -> "PreIncrement"
	| PREDECR -> "PreDecrement"
	| POSINCR -> "PostIncrement"
	| POSDECR -> "PostDecrement"
	) in name
and printUnaryExpression op exp =
	wrap ((printExpression exp) :: []) (getUnaryOperator op)
and printBinaryExpression op exp1 exp2 =
	wrap ((printExpression exp1) :: (printExpression exp2) :: []) (getBinaryOperator op)
	(* wrap ((printBinaryOperator op exp1 exp2) :: []) "BinaryOperator" *)
	(* match op with
	| MUL | DIV | MOD | ADD | SUB
	| SHL | SHR | BAND | XOR | BOR
	| LT | LE | GT | GE | EQ | NE
	| AND | OR -> printBinaryPureOperator op exp1 exp2
	| ASSIGN | ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN 
	| BAND_ASSIGN | BOR_ASSIGN | XOR_ASSIGN | SHL_ASSIGN | SHR_ASSIGN 
		-> printBinaryAssignmentOperator op exp1 exp2 *)
and getBinaryOperator op =
	match op with
	| MUL -> "Multiply"
	| DIV -> "Divide"
	| MOD -> "Modulo"
	| ADD -> "Plus"
	| SUB -> "Minus"
	| SHL -> "LeftShift"
	| SHR -> "RightShift"
	| LT -> "LessThan"
	| LE -> "LessThanOrEqual"
	| GT -> "GreaterThan"
	| GE -> "GreaterThanOrEqual"
	| EQ -> "Equality"
	| NE -> "NotEquality"
	| BAND -> "BitwiseAnd"
	| XOR -> "BitwiseXor"
	| BOR -> "BitwiseOr"
	| AND -> "LogicalAnd"
	| OR -> "LogicalOr"
	| ASSIGN -> "Assign"
	| ADD_ASSIGN -> "AssignPlus"
	| SUB_ASSIGN -> "AssignMinus"
	| MUL_ASSIGN -> "AssignMultiply"
	| DIV_ASSIGN -> "AssignDivide"
	| MOD_ASSIGN -> "AssignModulo"
	| BAND_ASSIGN -> "AssignBitwiseAnd"
	| BOR_ASSIGN -> "AssignBitwiseOr"
	| XOR_ASSIGN -> "AssignBitwiseXor"
	| SHL_ASSIGN -> "AssignLeftShift"
	| SHR_ASSIGN -> "AssignRightShift"
and printSeq _ _ =
	(printString "Seq")
and printIf exp s1 s2 =
	wrap ((printExpression exp) :: (newBlockStatement s1) :: (newBlockStatement s2) :: []) "IfThenElse"
	
and makeBlockStatement stat =
	{ blabels = []; battrs = []; bstmts = stat :: []}
and newBlockStatement s =
	printBlockStatement (makeBlockStatement s)	
and printWhile exp stat =
	wrap ((printExpression exp) :: (newBlockStatement stat) :: []) "While"
and printDoWhile exp stat wloc =
	wrap ((printExpression exp) :: (newBlockStatement stat) :: (printCabsLoc wloc) :: []) "DoWhile3"
and printFor fc1 exp2 exp3 stat =
	let newForIdCell = (printRawInt ((counter := (!counter + 1)); !counter)) in
	wrap (newForIdCell :: (printForClause fc1) :: (printExpression exp2) :: (printExpression exp3) :: (newBlockStatement stat) :: []) "For5"
and printForClause fc = 
	match fc with
	| FC_EXP exp1 -> wrap ((printExpression exp1) :: []) "ForClauseExpression"
	| FC_DECL dec1 -> (printDef dec1)
and printBreak =
	kapply "Break"  nil
and printContinue =
	kapply "Continue"  nil
and printReturn exp =
	wrap ((printExpression exp) :: []) "Return"
and printSwitch exp stat =
	let newSwitchId = ((counter := (!counter + 1)); !counter) in
	switchStack := newSwitchId :: !switchStack;
	currentSwitchId := newSwitchId;
	let idCell = printRawInt newSwitchId in
	let retval = wrap (idCell :: (printExpression exp) :: (newBlockStatement stat) :: []) "Switch" in
	(* printCell "Switch" [Attrib ("id", string_of_int newSwitchId)] (printList (fun x -> x) ((printExpression exp) :: (printStatement stat) :: [])) in *)
	switchStack := List.tl !switchStack;
	currentSwitchId := List.hd !switchStack;
	retval 
and printCase exp stat =
	let switchIdCell = (printRawInt !currentSwitchId) in
	let caseIdCell = (printRawInt (counter := (!counter + 1); !counter)) in
	wrap (switchIdCell :: caseIdCell :: (printExpression exp) :: (printStatement stat) :: []) "Case"
and printCaseRange exp1 exp2 stat =
	wrap ((printExpression exp1) :: (printExpression exp2) :: (printStatement stat) :: []) "CaseRange"
and printDefault stat =
	let switchIdCell = (printRawInt !currentSwitchId) in
	wrap (switchIdCell :: (printStatement stat) :: []) "Default"
and printLabel str stat =
	wrap ((printIdentifier str) :: (printStatement stat) :: []) "Label"	
and printGoto name =
	wrap ((printIdentifier name) :: []) "Goto"
and printCompGoto exp =
	wrap ((printExpression exp) :: []) "CompGoto"
and printBlockStatement block =
	wrap ((printBlock block) :: []) "BlockStatement"
and printStatement a =
	match a with
	| NOP (loc) -> printStatementLoc (printNop) loc
	| COMPUTATION (exp, loc) -> printStatementLoc (printComputation exp) loc
	| BLOCK (blk, loc) -> printStatementLoc (printBlockStatement blk) loc
	| SEQUENCE (s1, s2, loc) -> printStatementLoc (printSeq s1 s2) loc
	| IF (exp, s1, s2, loc) -> printStatementLoc (printIf exp s1 s2) loc
	| WHILE (exp, stat, loc) -> printStatementLoc (printWhile exp stat) loc
	| DOWHILE (exp, stat, loc, wloc) -> printStatementLoc (printDoWhile exp stat wloc) loc
	| FOR (fc1, exp2, exp3, stat, loc) -> printStatementLoc (printFor fc1 exp2 exp3 stat) loc
	| BREAK (loc) -> printStatementLoc (printBreak) loc
	| CONTINUE (loc) -> printStatementLoc (printContinue) loc
	| RETURN (exp, loc) -> printStatementLoc (printReturn exp) loc
	| SWITCH (exp, stat, loc) -> printStatementLoc (printSwitch exp stat) loc
	| CASE (exp, stat, loc) -> printStatementLoc (printCase exp stat) loc
	| CASERANGE (exp1, exp2, stat, loc) -> printStatementLoc (printCaseRange exp1 exp2 stat) loc (* GCC's extension *)
	| DEFAULT (stat, loc) -> printStatementLoc (printDefault stat) loc
	| LABEL (str, stat, loc) -> printStatementLoc (printLabel str stat) loc
	| GOTO (name, loc) -> printStatementLoc (printGoto name) loc
	| COMPGOTO (exp, loc) -> printStatementLoc (printCompGoto exp) loc (* GCC's "goto *exp" *)
	| DEFINITION d -> printDef d
	| _ -> kapply "OtherStatement"  nil
	(* 
	| ASM (attrs, tlist, details, loc) -> "Assembly" 
	*)
	(* 
	 | TRY_EXCEPT of block * expression * block * cabsloc
	 | TRY_FINALLY of block * block * cabsloc
	*)
and printStatementLoc s l =
	wrap (s :: (printCabsLoc l) :: []) "StatementLoc"
and printStatementList a =
	printNewList printStatement a
and printEnumItemList a =
	printNewList printEnumItem a
and printBlockLabels a =
	printNewList (fun x -> x) (List.map printString a)
and printAttribute (a, b) =
	wrap ((printRawString a) :: (printExpressionList b) :: []) "Attribute"
and printEnumItem (str, expression, cabsloc) =
	match expression with
	| NOTHING -> wrap ((printIdentifier str) :: []) "EnumItem"
	| expression -> wrap ((printIdentifier str) :: (printExpression expression) :: []) "EnumItemInit"
	
and printSpecifier a =
	wrap (printSpecElemList a :: []) "Specifier"
and printSpecElemList a =
	printNewList printSpecElem a
and printSingleNameList a =
	printNewList printSingleName a
and printSpecElem a =
	match a with
	| SpecTypedef -> kapply "SpecTypedef"  nil
	| SpecMissingType -> kapply "MissingType"  nil
	| SpecCV cv -> 
		(match cv with
		| CV_CONST -> kapply "Const"  nil
		| CV_VOLATILE -> kapply "Volatile"  nil
		| CV_ATOMIC -> kapply "Atomic"  nil
		| CV_RESTRICT -> kapply "Restrict"  nil
		| CV_RESTRICT_RESERVED (kwd,loc) -> wrap (ktoken kwd "String"::printCabsLoc loc::[]) "RestrictReserved")
	| SpecAttr al -> printAttribute al
	| SpecStorage sto ->
		(match sto with
		| NO_STORAGE -> kapply "NoStorage"  nil
		| THREAD_LOCAL -> kapply "ThreadLocal"  nil
		| AUTO -> kapply "Auto"  nil
		| STATIC -> kapply "Static"  nil
		| EXTERN -> kapply "Extern"  nil
		| REGISTER -> kapply "Register"  nil)
	| SpecInline -> (* right now there is only inline, but in C1X there is _Noreturn *)
		kapply "Inline"  nil
	| SpecNoReturn -> 
		kapply "Noreturn"  nil
	| SpecAlignment a -> 
		(match a with
		| EXPR_ALIGNAS e -> printAlignasExpression e
		| TYPE_ALIGNAS (s, d) -> printAlignasType s d)
	| SpecType bt -> printTypeSpec bt
	| SpecPattern name -> wrap ((printIdentifier name) :: []) "SpecPattern"
and printAlignasExpression e = 
	wrap ((printExpression e) :: []) "AlignasExpression"
and printAlignasType s d =
	wrap ((printSpecifier s) :: (printDeclType d) :: []) "AlignasType"

and printTypeSpec = function
	Tvoid -> kapply "Void"  nil
	| Tchar -> kapply "Char"  nil
	| Tbool -> kapply "Bool"  nil
	| Tshort -> kapply "Short"  nil
	| Tint -> kapply "Int"  nil
	| Tlong -> kapply "Long"  nil
	| ToversizedInt -> kapply "OversizedInt"  nil
	| Tfloat -> kapply "Float"  nil
	| Tdouble -> kapply "Double"  nil
	| ToversizedFloat -> kapply "OversizedFloat"  nil
	| Tsigned -> kapply "Signed"  nil
	| Tunsigned -> kapply "Unsigned"  nil
	| Tnamed s -> wrap ((printIdentifier s) :: []) "Named"
	| Tstruct (a, b, c) -> printStructType a b c
	| Tunion (a, b, c) -> printUnionType a b c
	| Tenum (a, b, c) -> printEnumType a b c
	| TtypeofE e -> wrap ((printExpression e) :: []) "TypeofExpression"
	| TtypeofT (s, d) -> wrap ((printSpecifier s) :: (printDeclType d) :: []) "TypeofType"
	| TautoType -> kapply "AutoType" nil
	| Tcomplex -> kapply "Complex"  nil
	| Timaginary ->	kapply "Imaginary"  nil
	| Tatomic (s, d) ->	wrap ((printSpecifier s) :: (printDeclType d) :: []) "TAtomic"
and printStructType a b c =
	match b with
		| None -> wrap ((printIdentifier a) :: (printSpecElemList c) :: []) "StructRef"
		| Some b -> wrap ((printIdentifier a) :: (printFieldGroupList b) :: (printSpecElemList c) :: []) "StructDef"
and printUnionType a b c = 
	match b with
		| None -> wrap ((printIdentifier a) :: (printSpecElemList c) :: []) "UnionRef"
		| Some b -> wrap ((printIdentifier a) :: (printFieldGroupList b) :: (printSpecElemList c) :: []) "UnionDef"
and printEnumType a b c =
	match b with
		| None -> wrap ((printIdentifier a) :: (printSpecElemList c) :: []) "EnumRef"
		| Some b -> wrap ((printIdentifier a) :: (printEnumItemList b) :: (printSpecElemList c) :: []) "EnumDef"




