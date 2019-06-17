open Escape
open Cabs

let counter = ref 0
let currentSwitchId = ref 0
let switchStack = ref [0]
let realFilename = ref ""
let stringLiterals = ref []
let kore : bool ref = ref false

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

let kstring (s : string) : string =
  if !kore then s else "\"" ^ s ^ "\""

and k_string_escape str =
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

type attribute =
  Attrib of string * string

let buffer = ref (Buffer.create 1)

type 'a writer = 'a * (unit -> unit)

let printString (s : string) : unit -> unit = fun () -> Buffer.add_string !buffer s

let (^^) (a : string) (b : string) : unit -> unit = fun () -> (printString a (); printString b ())

let ksort (sort : string) : string =
  if !kore then ( "Sort" ^ sort ^ "{}" ) else sort

let ktoken (s : string) (sort : string) : string =
  if !kore then ("\dv{" ^ ksort sort ^ "}(\"" ^ k_string_escape s ^ "\")")
  else ("#token(\"" ^ k_string_escape s ^ "\", \"" ^ ksort sort ^ "\")")

let ktoken_string (s : string) : string = ktoken (kstring s) "String"
let ktoken_int (v : int) : string = ktoken (string_of_int v) "Int"
let ktoken_int_of_string (v : string) : string = ktoken v "Int"

let print_ktoken_string (s : string) : unit -> unit = printString (ktoken_string s)
let print_ktoken_int (v : int) : unit -> unit = printString (ktoken_int v)
let print_ktoken_int_of_string (v : string) : unit -> unit = printString (ktoken_int_of_string v)

let print_ktoken (s : string) (sort : string) : unit -> unit = printString (ktoken s sort)

let klabel (label : string) : string =
  let left = if !kore then "Lbl" else "`" in
  let right = if !kore then "{}" else "`" in
  (left ^ label ^ right)

let kapply (label : string) (contents : string) : string = klabel label ^ "(" ^ contents  ^ ")"

let print_kapply (label : string) (contents : unit -> unit) : unit -> unit =
  fun () -> printString (klabel label) (); printString "(" (); contents (); printString ")" ()

let print_kapply2 (label : string) (contents : string) : unit -> unit =
  printString (kapply label contents)

let wrap (children : (unit -> unit) list) (name) : unit -> unit =
  print_kapply name (fun () -> List.iteri (fun i a -> if i = (List.length children) - 1 then (a ()) else (a ();printString ", " ())) children)

let dot_klist : string = ".KList"

let print_dot_klist : unit -> unit = printString dot_klist

let printNewList f l =
  print_kapply "list" (List.fold_right (fun k l -> wrap [(wrap [k] "ListItem"); l] "_List_") (List.map f l) (print_kapply ".List" print_dot_klist))

(* this is where the recursive printer starts *)

let rec cabs_to_kast (f : file) (real_name : string) : string =
  kore := false;
  realFilename := real_name;
  cabs_to_k f

and cabs_to_kore (f : file) (real_name : string) : string =
  kore := true;
  realFilename := real_name;
  cabs_to_k f

and cabs_to_k ((filename, defs) : file) : string =
  buffer := Buffer.create 100;
  (printTranslationUnit filename defs buffer) ();
  Buffer.contents !buffer

and printTranslationUnit (filename : string) defs buffer =
  let filenameCell = print_ktoken_string !realFilename in
  let ast = printDefs defs in
  let strings = printStrings buffer in (* the evaluation order is all messed up if this has no argument *)
  wrap (filenameCell :: strings :: ast :: []) "TranslationUnit"

and printStrings buffer =
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
      printDefinitionLoc (wrap ((print_ktoken_string a) :: []) "GlobAsm") b
  | PRAGMA (a, b) ->
      printDefinitionLoc (wrap ((printExpression a) :: []) "Pragma") b
  | LINKAGE (a, b, c) ->
      printDefinitionLoc (wrap ((print_ktoken_string a) :: (printDefs c) :: []) "Linkage") b
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
and printCabsLoc a =
        wrap ((print_ktoken_string a.filename) :: (print_ktoken_string (if Filename.is_relative a.filename then Filename.concat (Sys.getcwd ()) a.filename else a.filename)) :: (printRawInt a.lineno) :: (printRawInt a.lineOffsetStart) :: (printRawBool a.systemHeader) :: []) "CabsLoc"

and hasInformation l =
  l.lineno <> -10
and printNameLoc s l =
  s
and printIdentifier a =
  print_kapply2 "ToIdentifier" (ktoken_string a)
and printName (a, b, c, d) = (* string * decl_type * attribute list * cabsloc *)
  if a = "" then
    printNameLoc (wrap ((print_kapply2 "AnonymousName" dot_klist) :: (printDeclType b) :: (printSpecElemList c) :: []) "Name") d
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
  | NO_INIT -> print_kapply2 "NoInit" dot_klist
  | SINGLE_INIT exp -> wrap ((printExpression exp) :: []) "SingleInit"
  | COMPOUND_INIT a -> wrap ((printInitFragmentList a) :: []) "CompoundInit"
and printInitExpressionForCast a castPrinter compoundLiteralPrinter = (* this is used when we are printing an init inside a cast, i.e., possibly a compound literal *)
  match a with
  | NO_INIT -> print_kapply2 "Error" "cast with a NO_INIT inside doesn't make sense"
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
  | NEXT_INIT -> print_kapply2 "NextInit" dot_klist
  | INFIELD_INIT (id, what) -> wrap ((printIdentifier id) :: (printInitWhat what) :: []) "InFieldInit"
  | ATINDEX_INIT (exp, what) -> wrap ((printExpression exp) :: (printInitWhat what) :: []) "AtIndexInit"
  | ATINDEXRANGE_INIT (exp1, exp2) -> wrap ((printExpression exp1) :: (printExpression exp2) :: []) "AtIndexRangeInit"
and printDeclType a =
  (match a with
  | JUSTBASE -> print_kapply2 "JustBase" dot_klist
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
  let variadicName = if c then "true" else "false" in
  let variadicCell = print_ktoken variadicName "Bool" in
  wrap ((printDeclType a) :: (printSingleNameList b) :: variadicCell :: []) "Prototype"
and printNoProtoType a b c =
  let variadicName = if c then "true" else "false" in
  let variadicCell = print_ktoken variadicName "Bool" in
  wrap ((printDeclType a) :: (printSingleNameList b) :: variadicCell :: []) "NoPrototype"
and printNop =
  print_kapply2 "Nop" dot_klist
and printComputation exp =
  wrap ((printExpression exp) :: []) "Computation"
and printExpressionList defs =
  printNewList printExpression defs

and printRawFloat f =
  printRawFloatString (string_of_float f)
and printRawFloatString s =
  print_ktoken s "Float"
and printRawInt i =
  printRawIntString (string_of_int i)
and printRawIntString s =
  print_ktoken s "Int"
and printRawBool b =
  printRawBoolString (string_of_bool b)
and printRawBoolString s =
  print_ktoken s "Bool"
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
  let result = wrap [print_ktoken_string s] "StringLiteral" in
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
  let significandPart = print_ktoken_string significand in
  let significandPart = significandPart in
  let exponentPart = exponentPart in
  let approxPart = printRawFloat approx in
  (wrap (significandPart :: exponentPart :: approxPart :: []) "HexFloatConstant")
and printDecFloatConstant f =
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

  let significandPart = print_ktoken_string significand in
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
  wrap [print_ktoken_string i] "HexConstant"
and printOctConstant (i : string) =
  wrap [printRawIntString i] "OctalConstant"
and printDecConstant (i : string) =
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

and printExpression exp =
  match exp with
  | OFFSETOF ((spec, declType), exp, loc) -> printExpressionLoc (wrap ((printSpecifier spec) :: (printDeclType declType) :: (printExpression exp) :: []) "OffsetOf") loc
  | TYPES_COMPAT ((spec1, declType1), (spec2, declType2), loc) -> printExpressionLoc (wrap ((printSpecifier spec1) :: (printDeclType declType1) :: (printSpecifier spec2) :: (printDeclType declType2) :: []) "TypesCompat") loc
  | GENERIC (exp, assocs) -> wrap (printExpression exp :: printGenericAssocs assocs :: []) "Generic"
  | LOCEXP (exp, loc) -> printExpressionLoc (printExpression exp) loc
  | UNARY (op, exp1) -> printUnaryExpression op exp1
  | BINARY (op, exp1, exp2) -> printBinaryExpression op exp1 exp2
  | NOTHING -> print_kapply2 "NothingExpression" dot_klist
  | UNSPECIFIED -> print_kapply2 "UnspecifiedSizeExpression" dot_klist
  | PAREN (exp1) -> (printExpression exp1)
  | QUESTION (exp1, exp2, exp3) -> wrap ((printExpression exp1) :: (printExpression exp2) :: (printExpression exp3) :: []) "Conditional"
  (* Special case below for the compound literals. I don't know why this isn't in the ast... *)
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
  | EXPR_PATTERN s -> wrap ((print_ktoken_string s) :: []) "ExpressionPattern"
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
  print_kapply2 "Break" dot_klist
and printContinue =
  print_kapply2 "Continue" dot_klist
and printReturn exp =
  wrap ((printExpression exp) :: []) "Return"
and printSwitch exp stat =
  let newSwitchId = ((counter := (!counter + 1)); !counter) in
  switchStack := newSwitchId :: !switchStack;
  currentSwitchId := newSwitchId;
  let idCell = printRawInt newSwitchId in
  let retval = wrap (idCell :: (printExpression exp) :: (newBlockStatement stat) :: []) "Switch" in
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
  | _ -> print_kapply2 "OtherStatement" dot_klist
and printStatementLoc s l =
  wrap (s :: (printCabsLoc l) :: []) "StatementLoc"
and printStatementList a =
  printNewList printStatement a
and printEnumItemList a =
  printNewList printEnumItem a
and printBlockLabels a =
  printNewList (fun x -> x) (List.map printString a)
and printAttribute (a, b) =
  wrap ((print_ktoken_string a) :: (printExpressionList b) :: []) "Attribute"
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
  | SpecTypedef -> print_kapply2 "SpecTypedef" dot_klist
  | SpecMissingType -> print_kapply2 "MissingType" dot_klist
  | SpecCV cv ->
    (match cv with
    | CV_CONST -> print_kapply2 "Const" dot_klist
    | CV_VOLATILE -> print_kapply2 "Volatile" dot_klist
    | CV_ATOMIC -> print_kapply2 "Atomic" dot_klist
    | CV_RESTRICT -> print_kapply2 "Restrict" dot_klist
    | CV_RESTRICT_RESERVED (kwd,loc) -> wrap (print_ktoken kwd "String"::printCabsLoc loc::[]) "RestrictReserved")
  | SpecAttr al -> printAttribute al
  | SpecStorage sto ->
    (match sto with
    | NO_STORAGE -> print_kapply2 "NoStorage" dot_klist
    | THREAD_LOCAL -> print_kapply2 "ThreadLocal" dot_klist
    | AUTO -> print_kapply2 "Auto" dot_klist
    | STATIC -> print_kapply2 "Static" dot_klist
    | EXTERN -> print_kapply2 "Extern" dot_klist
    | REGISTER -> print_kapply2 "Register" dot_klist)
  | SpecInline ->
    print_kapply2 "Inline" dot_klist
  | SpecNoReturn ->
    print_kapply2 "Noreturn" dot_klist
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
  Tvoid -> print_kapply2 "Void" dot_klist
  | Tchar -> print_kapply2 "Char" dot_klist
  | Tbool -> print_kapply2 "Bool" dot_klist
  | Tshort -> print_kapply2 "Short" dot_klist
  | Tint -> print_kapply2 "Int" dot_klist
  | Tlong -> print_kapply2 "Long" dot_klist
  | ToversizedInt -> print_kapply2 "OversizedInt" dot_klist
  | Tfloat -> print_kapply2 "Float" dot_klist
  | Tdouble -> print_kapply2 "Double" dot_klist
  | ToversizedFloat -> print_kapply2 "OversizedFloat" dot_klist
  | Tsigned -> print_kapply2 "Signed" dot_klist
  | Tunsigned -> print_kapply2 "Unsigned" dot_klist
  | Tnamed s -> wrap ((printIdentifier s) :: []) "Named"
  | Tstruct (a, b, c) -> printStructType a b c
  | Tunion (a, b, c) -> printUnionType a b c
  | Tenum (a, b, c) -> printEnumType a b c
  | TtypeofE e -> wrap ((printExpression e) :: []) "TypeofExpression"
  | TtypeofT (s, d) -> wrap ((printSpecifier s) :: (printDeclType d) :: []) "TypeofType"
  | TautoType -> print_kapply2 "AutoType"dot_klist
  | Tcomplex -> print_kapply2 "Complex" dot_klist
  | Timaginary ->  print_kapply2 "Imaginary" dot_klist
  | Tatomic (s, d) ->  wrap ((printSpecifier s) :: (printDeclType d) :: []) "TAtomic"
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
