open Escape
open Cabs

(* Types. *)

(* Printer state. *)
type printer_state =
  {
    kore : bool;
    counter : int;
    current_switch_id : int;
    switch_stack : int list;
    string_literals : (unit printer) list;
    buffer : Buffer.t ref;
  }

(* State monad. *)
and 'a printer = printer_state -> ('a * printer_state)

type attribute = Attrib of string * string

let init_state : printer_state =
  {
    kore = false;
    counter = 0;
    current_switch_id = 0;
    switch_stack = [0];
    string_literals = [];
    buffer = ref (Buffer.create 100);
  }

(* Monad morphisms. *)
let return (a : 'a) : 'a printer = fun s -> (a, s)

let (>>=) (m : 'a printer) (f : 'a -> 'b printer) : 'b printer = fun s ->
  let (a_intr, s_intr) = m s in
  (f a_intr) s_intr

let (>>) (ma : 'a printer) (mb : 'b printer) : 'b printer = ma >>= fun _ -> mb

let puts (str : string) : unit printer = fun s -> (Buffer.add_string !(s.buffer) str, s)

let save_string_literal (str : unit printer) : unit printer =
  str >> fun s -> ((), {s with string_literals = str :: s.string_literals})

let get_string_literals : ((unit printer) list) printer = fun s -> (s.string_literals, s)

let new_counter : int printer = fun s -> (s.counter + 1, {s with counter = s.counter + 1})

let push_switch : int printer = new_counter >>= fun counter s ->
  (counter, {s with switch_stack = counter :: s.switch_stack; current_switch_id = counter})

let pop_switch : unit printer = fun s ->
  ((), {s with switch_stack = List.tl s.switch_stack; current_switch_id = List.hd s.switch_stack})

let current_switch : int printer = fun s -> (s.current_switch_id, s)

let kore : bool printer = fun s -> (s.kore, s)

let if_kore_lazy (kore_true : 'a printer) (kore_false : 'a printer) : 'a printer = kore >>= fun k ->
  if k then kore_true else kore_false

let if_kore (kore_true : 'a) (kore_false : 'a) : 'a printer = if_kore_lazy (return kore_true) (return kore_false)

(* Generic helpers. *)
let fold_right1 (f : 'a -> 'b -> 'a) (l : 'b list) : 'a = match List.rev l with
  | x :: xs -> List.fold_right f xs x

let fold_left1 (f : 'a -> 'b -> 'a) (l : 'b list) : 'a = match l with
  | x :: xs -> List.fold_left f x xs

(* Function composition. *)
let (%) (g : 'b -> 'c) (f : 'a -> 'b) : 'a -> 'c = fun a -> g (f a)

(* Given a character constant (like 'a' or 'abc') as a list of 64-bit
 * values, turn it into a CIL constant.  Multi-character constants are
 * treated as multi-digit numbers with radix given by the bit width of
 * the specified type (either char or wchar_t). *)
(* CME: actually, this is based on the code in CIL *)
let reduce_multichar (radix : int) : int64 list -> int64 =
  List.fold_left (fun acc -> Int64.add (Int64.shift_left acc radix)) Int64.zero

let interpret_character_constant char_list =
  Int64.to_int (reduce_multichar 8 char_list)

let interpret_wcharacter_constant char_list =
  Int64.to_int (reduce_multichar 32 char_list)

(* Escaping. *)
let k_char_escape (buf: Buffer.t) : char -> unit = Buffer.add_string buf % function
| '"'  -> "\\\""
| '\\' -> "\\\\"
| '\n' -> "\\n"
| '\t' -> "\\t"
| '\r' -> "\\r"
| c when let code = Char.code c in code >= 32 && code < 127
       -> Printf.sprintf "%c" c
| c    -> Printf.sprintf "\\x%02x" (Char.code c)

let k_string_escape (str : string) : string =
  let buf = Buffer.create (String.length str) in
  String.iter (k_char_escape buf) str; Buffer.contents buf

let klabel_char_escape_kore (buf: Buffer.t) : char -> unit =
  let opt_apost s =
    if (Buffer.length buf > 0) && (Buffer.nth buf (Buffer.length buf - 1) = '\'')
    then (Buffer.truncate buf (Buffer.length buf - 1); s) else ("'" ^ s)
  in
  Buffer.add_string buf % function
  | '_' -> opt_apost "Unds'"
  | '.' -> opt_apost "Stop'"
  | '(' -> opt_apost "LPar'"
  | ')' -> opt_apost "RPar'"
  | c   -> Printf.sprintf "%c" c

let klabel_escape (str : string) : string printer =
  let buf = Buffer.create (String.length str) in
  if_kore (String.iter (klabel_char_escape_kore buf) str; Buffer.contents buf) str

(* Atomic output. *)
let kstring (s : string) : string printer = if_kore s ("\"" ^ s ^ "\"")

let dot_klist : unit printer = puts ".KList"

let ksort (sort : string) : unit printer =
  if_kore_lazy (puts "Sort" >> puts sort >> puts "{}") (puts sort)

let ktoken (sort : string) (s : string) : unit printer =
  if_kore_lazy
    (puts "\dv{"      >> ksort sort               >> puts "}(\""   >> puts (k_string_escape s) >> puts "\")")
    (puts "#token(\"" >> puts (k_string_escape s) >> puts "\", \"" >> ksort sort               >> puts "\")")

let ktoken_string (s : string) : unit printer          = kstring s >>= ktoken "String"
let ktoken_bool (v : bool) : unit printer              = ktoken "Bool" (if v then "true" else "false")
let ktoken_int (v : int) : unit printer                = ktoken "Int" (string_of_int v)
let ktoken_int_of_string (v : string) : unit printer   = ktoken "Int" v
let ktoken_float (v : float) : unit printer            = ktoken "Float" (string_of_float v)
let ktoken_float_of_string (v : string) : unit printer = ktoken "Float" v

let klabel (label : string) : unit printer =
  (if_kore "Lbl" "`" >>= puts) >> puts label >> (if_kore "{}" "`" >>= puts)

let kapply (label : string) (children : (unit printer) list) : unit printer =
  klabel label >> puts "(" >> fold_left1 (fun a b -> (a >> (puts ", ") >> b)) children >> puts ")"

let kapply0 (label : string) : unit printer =
  kapply label [dot_klist]

let kapply1 (label : string) (contents : unit printer) : unit printer =
  kapply label [contents]

(* TODO *)

let dot_list : unit printer = kapply0 ".List"

let list_of f l =
  let elems = List.map f l in
  let op = fun k l -> kapply "_List_" [kapply1 "ListItem" k; l] in
  kapply1 "list" (List.fold_right op elems dot_list)

(* This is where the recursive printer starts. *)

let rec cabs_to_kast (defs : definition list) (filename : string) : Buffer.t =
  let (_, final_state) = printTranslationUnit filename defs init_state in
  Buffer.add_char !(final_state.buffer) '\n'; !(final_state.buffer)

and cabs_to_kore (defs : definition list) (filename : string) : Buffer.t =
  let (_, final_state) = printTranslationUnit filename defs {init_state with kore = true} in
  Buffer.add_char !(final_state.buffer) '\n'; !(final_state.buffer)

and printTranslationUnit (filename : string) defs s =
  (* Finangling here to extract string literals. *)
  let (_, s_intr)   = printDefs defs s in
  let fn            = ktoken_string filename in
  let print_strings = get_string_literals >>= fun strings -> list_of (kapply1 "Constant") strings in
  let ast           = fun s -> (Buffer.add_buffer !(s.buffer) !(s_intr.buffer); ((), s)) in
  kapply "TranslationUnit" [fn; print_strings; ast] {s_intr with buffer = ref (Buffer.create 100)}

and printDefs defs = list_of printDef defs

and printDef = function
  | FUNDEF (a, b, c, d)       -> printDefinitionLocRange (kapply "FunctionDefinition" [printSingleName a; printBlock b]) c d
  | DECDEF (a, b)             -> printDefinitionLoc (kapply "DeclarationDefinition" [printInitNameGroup a]) b
  | TYPEDEF (a, b)            -> printDefinitionLoc (kapply "Typedef" [printNameGroup a]) b
  | ONLYTYPEDEF (a, b)        -> printDefinitionLoc (kapply "OnlyTypedef" [printSpecifier a]) b
  | GLOBASM (a, b)            -> printDefinitionLoc (kapply "GlobAsm" [ktoken_string a]) b
  | PRAGMA (a, b)             -> printDefinitionLoc (kapply "Pragma" [printExpression a]) b
  | LINKAGE (a, b, c)         -> printDefinitionLoc (kapply "Linkage" [ktoken_string a; printDefs c]) b
  | TRANSFORMER (a, b, c)     -> printDefinitionLoc (kapply "Transformer" [printDef a; printDefs b]) c
  | EXPRTRANSFORMER (a, b, c) -> printDefinitionLoc (kapply "ExprTransformer" [printExpression a; printExpression b]) c
  | LTL_ANNOTATION (a, b, c)  -> printDefinitionLoc (kapply "LTLAnnotation" [printIdentifier a; printExpression b]) c
  | STATIC_ASSERT (a, b, c)   -> printDefinitionLoc (kapply "StaticAssert" [printExpression a; printConstant b]) c

and printDefinitionLoc a l = if hasInformation l then kapply "DefinitionLoc" [a; printCabsLoc l] else a
and printDefinitionLocRange a b c = kapply "DefinitionLocRange" [a; printCabsLoc b; printCabsLoc c]
and printSingleName (a, b) = kapply "SingleName" [printSpecifier a; printName b]
and printAttr a b = kapply "Attributekapplyper" [a; printSpecElemList b]
and printBlock a = new_counter >>= fun blockNum ->
  kapply "Block3" [ktoken_int blockNum; printBlockLabels a.blabels; printStatementList a.bstmts]
and printCabsLoc a =
  let filename = if Filename.is_relative a.filename then Filename.concat (Sys.getcwd ()) a.filename else a.filename in
  kapply "CabsLoc" [ktoken_string a.filename; ktoken_string filename; ktoken_int a.lineno; ktoken_int a.lineOffsetStart; ktoken_bool a.systemHeader]

and hasInformation l = l.lineno <> -10
and printNameLoc s _ = s
and printIdentifier a =
  kapply1 "ToIdentifier" (ktoken_string a)
(* string * decl_type * attribute list * cabsloc *)
and printName (a, b, c, d) =
  let name = if a = "" then kapply0 "AnonymousName" else printIdentifier a in
  printNameLoc (kapply "Name" [name; printDeclType b; printSpecElemList c]) d
and printInitNameGroup (a, b) = kapply "InitNameGroup" [printSpecifier a; printInitNameList b]
and printNameGroup (a, b) = kapply "NameGroup" [printSpecifier a; printNameList b]
and printNameList a = list_of printName a
and printInitNameList a = list_of printInitName a
and printFieldGroupList a = list_of printFieldGroup a
and printFieldGroup (spec, fields) =
  kapply "FieldGroup" [printSpecifier spec; printFieldList fields]
and printFieldList a = list_of printField a
and printField (name, expOpt) = match expOpt with
  | None     -> kapply "FieldName" [printName name]
  | Some exp -> kapply "BitFieldName" [printName name; printExpression exp]
and printInitName (a, b) =
  kapply "InitName" [printName a; printInitExpression b]
and printInitExpression = function
  | NO_INIT         -> kapply0 "NoInit"
  | SINGLE_INIT exp -> kapply "SingleInit" [printExpression exp]
  | COMPOUND_INIT a -> kapply "CompoundInit" [printInitFragmentList a]
(* This is used when we are printing an init inside a cast, i.e., possibly a compound literal. *)
and printInitExpressionForCast a castPrinter compoundLiteralPrinter = match a with
  | NO_INIT         -> kapply1 "Error" (puts "cast with a NO_INIT inside doesn't make sense")
  | SINGLE_INIT exp -> castPrinter (printExpression exp)
  | COMPOUND_INIT a -> compoundLiteralPrinter (kapply "CompoundInit" [printInitFragmentList a])
and printInitFragmentList a = list_of printInitFragment a
and printGenericAssocs assocs = list_of printGenericAssoc assocs
and printInitFragment (a, b) = kapply "InitFragment" [printInitWhat a; printInitExpression b]
and printInitWhat = function
  | NEXT_INIT                      -> kapply0 "NextInit"
  | INFIELD_INIT (id, what)        -> kapply "InFieldInit" [printIdentifier id; printInitWhat what]
  | ATINDEX_INIT (exp, what)       -> kapply "AtIndexInit" [printExpression exp; printInitWhat what]
  | ATINDEXRANGE_INIT (exp1, exp2) -> kapply "AtIndexRangeInit" [printExpression exp1; printExpression exp2]
and printDeclType = function
  | JUSTBASE            -> kapply0 "JustBase"
  | PARENTYPE (a, b, c) -> printParenType a b c
  | ARRAY (a, b, c, d)  -> printArrayType a b c d
  | PTR (a, b)          -> printPointerType a b
  | PROTO (a, b, c)     -> printProtoType a b c
  | NOPROTO (a, b, c)   -> printNoProtoType a b c
and printParenType a b c =
  kapply "FunctionType" [printDeclType b]
and printArrayType a b c d =
  kapply "ArrayType" [printDeclType a; printExpression c; printSpecifier (b@d)]
and printPointerType a b =
  kapply "PointerType" [printSpecifier a; printDeclType b]
and printProtoType a b c =
  let variadicCell = ktoken_bool c in
  kapply "Prototype" [printDeclType a; printSingleNameList b; variadicCell]
and printNoProtoType a b c =
  let variadicCell = ktoken_bool c in
  kapply "NoPrototype" [printDeclType a; printSingleNameList b; variadicCell]
and printNop = kapply0 "Nop"
and printComputation exp = kapply "Computation" [printExpression exp]
and printExpressionList defs = list_of printExpression defs

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
  | CONST_INT i      -> printIntLiteral i
  | CONST_FLOAT r    -> printFloatLiteral r
  | CONST_CHAR c     -> kapply "CharLiteral" [ktoken_int (interpret_character_constant c)]
  | CONST_WCHAR c    -> kapply "WCharLiteral" [ktoken_int (interpret_wcharacter_constant c)]
  | CONST_STRING s   -> save_string_literal (printStringLiteral s)
  | CONST_WSTRING ws -> save_string_literal (printWStringLiteral ws)
and printStringLiteral s = kapply1 "StringLiteral" (ktoken_string s)
and printWStringLiteral ws = kapply1 "WStringLiteral" (list_of (fun i -> ktoken_int (Int64.to_int i)) ws)
and splitFloat (xs, i) =
  let lastOne = if String.length i > 1 then String.uppercase (Str.last_chars i 1) else "x" in
  let newi    = Str.string_before i (String.length i - 1) in
  match lastOne with
  | "x" -> (xs, i)
  | "L" -> splitFloat("L" :: xs, newi)
  | "F" -> splitFloat("F" :: xs, newi)
  | _   -> (xs, i)
and splitInt (xs, i) =
  let lastOne = if String.length i > 1 then String.uppercase (Str.last_chars i 1) else "x" in
  let newi    = Str.string_before i (String.length i - 1) in
  match lastOne with
  | "x" -> (xs, i)
  | "U" -> splitInt ("U" :: xs, newi)
  | "L" -> splitInt ("L" :: xs, newi)
  | _   -> (xs, i)
and printHexFloatConstant f =
  let [significand; exponentPart] = Str.split (Str.regexp "[pP]") f in
  let wholePart :: fractionalPart = Str.split_delim (Str.regexp "\.") significand in
  let wholePart                   = if wholePart = "" then "0" else wholePart in
  let fractionalPart              = (match fractionalPart with
    | []   -> "0"
    | [""] -> "0"
    | [x]  -> x)
  in
  let [exponentPart]              = Str.split (Str.regexp "[+]") exponentPart in
  let exponentPart                = int_of_string exponentPart in
  let significand                 = wholePart ^ "." ^ fractionalPart in
  let approx                      = float_of_string ("0x" ^ significand) in
  let approx                      = approx *. (2. ** (float_of_int exponentPart)) in
  let exponentPart                = ktoken_int exponentPart in
  let significandPart             = ktoken_string significand in
  let approxPart                  = ktoken_float approx in
  kapply "HexFloatConstant" [significandPart; exponentPart; approxPart]
and printDecFloatConstant f =
  let f                           = Str.split (Str.regexp "[eE]") f in
  let (significand, exponentPart) = (match f with
    | [x]    -> (x, "0")
    | [x; y] -> (x, y))
  in
  let wholePart :: fractionalPart = Str.split_delim (Str.regexp "\.") significand in
  let wholePart                   = (if wholePart = "" then "0" else wholePart) in
  let fractionalPart              = (match fractionalPart with
    | []   -> "0"
    | [""] -> "0"
    | [x]  -> x)
  in
  let stringRep                   = wholePart ^ "." ^ fractionalPart ^ "e" ^ exponentPart in
  let [exponentPart]              = Str.split (Str.regexp "[+]") exponentPart in
  let exponentPart                = int_of_string exponentPart in
  let significand                 = wholePart ^ "." ^ fractionalPart in
  let significandPart             = ktoken_string significand in
  let exponentPart                = ktoken_int exponentPart in
  let approxPart                  = ktoken_float_of_string stringRep in
  kapply "DecimalFloatConstant" [significandPart; exponentPart; approxPart]

and printFloatLiteral r =
  let (tag, r) = splitFloat ([], r) in
  let num = (
    let firstTwo = if (String.length r > 2) then (Str.first_chars r 2) else ("xx") in
      if (firstTwo = "0x" or firstTwo = "0X") then
        let nonPrefix = Str.string_after r 2 in
          printHexFloatConstant nonPrefix
      else printDecFloatConstant r)
  in
  match tag with
  | ["F"] -> kapply "LitF" [num]
  | ["L"] -> kapply "LitL" [num]
  | []    -> kapply "NoSuffix" [num]
and printHexConstant (i : string) = kapply "HexConstant" [ktoken_string i]
and printOctConstant (i : string) = kapply "OctalConstant" [ktoken_int_of_string i]
and printDecConstant (i : string) = kapply "DecimalConstant" [ktoken_int_of_string i]
and printIntLiteral i =
  let (tag, i) = splitInt ([], i) in
  let num = (
    let firstTwo = if String.length i > 2 then Str.first_chars i 2 else "xx" in
    let firstOne = if String.length i > 1 then Str.first_chars i 1 else "x" in
      if firstTwo = "0x" or firstTwo = "0X" then printHexConstant (Str.string_after i 2)
      else (if firstOne = "0" then printOctConstant (Str.string_after i 1) else (printDecConstant i)))
  in
  match tag with
  | ["U"; "L"; "L"] | ["L"; "L"; "U"] -> kapply1 "LitULL" num
  | ["L"; "L"]                        -> kapply1 "LitLL" num
  | ["U"; "L"] | ["L"; "U"]           -> kapply1 "LitUL" num
  | ["U"]                             -> kapply1 "LitU" num
  | ["L"]                             -> kapply1 "LitL" num
  | []                                -> kapply1 "NoSuffix" num

and printExpression = function
  | OFFSETOF ((spec, declType), exp, loc)                      -> kapply "OffsetOf" [printSpecifier spec; printDeclType declType; printExpression exp]
  | TYPES_COMPAT ((spec1, declType1), (spec2, declType2), loc) -> kapply "TypesCompat" [printSpecifier spec1; printDeclType declType1; printSpecifier spec2; printDeclType declType2]
  | GENERIC (exp, assocs)                                      -> kapply "Generic" [printExpression exp; printGenericAssocs assocs]
  | LOCEXP (exp, loc)                                          -> printExpression exp
  | UNARY (op, exp1)                                           -> printUnaryExpression op exp1
  | BINARY (op, exp1, exp2)                                    -> printBinaryExpression op exp1 exp2
  | NOTHING                                                    -> kapply0 "NothingExpression"
  | UNSPECIFIED                                                -> kapply0 "UnspecifiedSizeExpression"
  | PAREN (exp1)                                               -> printExpression exp1
  | QUESTION (exp1, exp2, exp3)                                -> kapply "Conditional" [printExpression exp1; printExpression exp2; printExpression exp3]
  (* Special case below for the compound literals. I don't know why this isn't in the ast... *)
  | CAST ((spec, declType), initExp)                           -> new_counter >>= (fun id ->
    let castPrinter x            = kapply "Cast" [printSpecifier spec; printDeclType declType; x] in
    let compoundLiteralIdCell    = ktoken_int id in
    let compoundLiteralPrinter x = kapply "CompoundLiteral" [compoundLiteralIdCell; printSpecifier spec; printDeclType declType; x]
    in printInitExpressionForCast initExp castPrinter compoundLiteralPrinter)
    (* A CAST can actually be a constructor expression *)
  | CALL (exp1, expList)                                       -> kapply "Call" [printExpression exp1; printExpressionList expList]
  | COMMA expList                                              -> kapply "Comma" [printExpressionList expList]
  | CONSTANT (const)                                           -> kapply "Constant" [printConstant const]
  | VARIABLE name                                              -> printIdentifier name
  | EXPR_SIZEOF exp1                                           -> kapply "SizeofExpression" [printExpression exp1]
  | TYPE_SIZEOF (spec, declType)                               -> kapply "SizeofType" [printSpecifier spec; printDeclType declType]
  | EXPR_ALIGNOF exp                                           -> kapply "AlignofExpression" [printExpression exp]
  | TYPE_ALIGNOF (spec, declType)                              -> kapply "AlignofType" [printSpecifier spec; printDeclType declType]
  | INDEX (exp, idx)                                           -> kapply "ArrayIndex" [printExpression exp; printExpression idx]
  | MEMBEROF (exp, fld)                                        -> kapply "Dot" [printExpression exp; printIdentifier fld]
  | MEMBEROFPTR (exp, fld)                                     -> kapply "Arrow" [printExpression exp; printIdentifier fld]
  | GNU_BODY block                                             -> kapply "GnuBody" [printBlock block]
  | BITMEMBEROF (exp, fld)                                     -> kapply "DotBit" [printExpression exp; printIdentifier fld]
  | EXPR_PATTERN s                                             -> kapply "ExpressionPattern" [ktoken_string s]
  | LTL_ALWAYS e                                               -> kapply "LTLAlways" [printExpression e]
  | LTL_IMPLIES (e1, e2)                                       -> kapply "LTLImplies" [printExpression e1; printExpression e2]
  | LTL_EVENTUALLY e                                           -> kapply "LTLEventually" [printExpression e]
  | LTL_NOT e                                                  -> kapply "LTLNot" [printExpression e]
  | LTL_ATOM e                                                 -> kapply "LTLAtom" [printExpression e]
  | LTL_BUILTIN e                                              -> kapply "LTLBuiltin" [printIdentifier e]
  | LTL_AND (e1, e2)                                           -> kapply "LTLAnd" [printExpression e1; printExpression e2]
  | LTL_OR (e1, e2)                                            -> kapply "LTLOr" [printExpression e1; printExpression e2]
  | LTL_URW ("U", e1, e2)                                      -> kapply "LTLUntil" [printExpression e1; printExpression e2]
  | LTL_URW ("R", e1, e2)                                      -> kapply "LTLRelease" [printExpression e1; printExpression e2]
  | LTL_URW ("W", e1, e2)                                      -> kapply "LTLWeakUntil" [printExpression e1; printExpression e2]
  | LTL_O ("O", e)                                             -> kapply "LTLNext" [printExpression e]
and printGenericAssoc = function
  | GENERIC_PAIR ((spec, declType), exp) -> kapply "GenericPair" [printSpecifier spec; printDeclType declType; printExpression exp]
  | GENERIC_DEFAULT exp                  -> kapply "GenericDefault" [printExpression exp]
and getUnaryOperator = function
  | MINUS   -> "Negative"
  | PLUS    -> "Positive"
  | NOT     -> "LogicalNot"
  | BNOT    -> "BitwiseNot"
  | MEMOF   -> "Dereference"
  | ADDROF  -> "Reference"
  | PREINCR -> "PreIncrement"
  | PREDECR -> "PreDecrement"
  | POSINCR -> "PostIncrement"
  | POSDECR -> "PostDecrement"
and printUnaryExpression op exp = kapply (getUnaryOperator op) [printExpression exp]
and printBinaryExpression op exp1 exp2 = kapply (getBinaryOperator op) [printExpression exp1; printExpression exp2]
and getBinaryOperator = function
  | MUL         -> "Multiply"
  | DIV         -> "Divide"
  | MOD         -> "Modulo"
  | ADD         -> "Plus"
  | SUB         -> "Minus"
  | SHL         -> "LeftShift"
  | SHR         -> "RightShift"
  | LT          -> "LessThan"
  | LE          -> "LessThanOrEqual"
  | GT          -> "GreaterThan"
  | GE          -> "GreaterThanOrEqual"
  | EQ          -> "Equality"
  | NE          -> "NotEquality"
  | BAND        -> "BitwiseAnd"
  | XOR         -> "BitwiseXor"
  | BOR         -> "BitwiseOr"
  | AND         -> "LogicalAnd"
  | OR          -> "LogicalOr"
  | ASSIGN      -> "Assign"
  | ADD_ASSIGN  -> "AssignPlus"
  | SUB_ASSIGN  -> "AssignMinus"
  | MUL_ASSIGN  -> "AssignMultiply"
  | DIV_ASSIGN  -> "AssignDivide"
  | MOD_ASSIGN  -> "AssignModulo"
  | BAND_ASSIGN -> "AssignBitwiseAnd"
  | BOR_ASSIGN  -> "AssignBitwiseOr"
  | XOR_ASSIGN  -> "AssignBitwiseXor"
  | SHL_ASSIGN  -> "AssignLeftShift"
  | SHR_ASSIGN  -> "AssignRightShift"
and printIf exp s1 s2 = kapply "IfThenElse" [printExpression exp; newBlockStatement s1; newBlockStatement s2]

and makeBlockStatement stat = { blabels = []; battrs = []; bstmts = [stat]}
and newBlockStatement s = printBlockStatement (makeBlockStatement s)
and printWhile exp stat = kapply "While" [printExpression exp; newBlockStatement stat]
and printDoWhile exp stat wloc = kapply "DoWhile3" [printExpression exp; newBlockStatement stat; printCabsLoc wloc]
and printFor fc1 exp2 exp3 stat = new_counter >>= (fun counter ->
  let newForIdCell = ktoken_int counter in
  kapply "For5" [newForIdCell; printForClause fc1; printExpression exp2; printExpression exp3; newBlockStatement stat])
and printForClause fc =
  match fc with
  | FC_EXP exp1  -> kapply "ForClauseExpression" [printExpression exp1]
  | FC_DECL dec1 -> printDef dec1
and printBreak = kapply0 "Break"
and printContinue = kapply0 "Continue"
and printReturn exp = kapply "Return" [printExpression exp]
and printSwitch exp stat = push_switch >>= fun newSwitchId ->
  let idCell = ktoken_int newSwitchId in
  let retval = kapply "Switch" [idCell; printExpression exp; newBlockStatement stat] in
  retval >> pop_switch
and printCase exp stat = current_switch >>= fun currentSwitchId -> new_counter >>= fun counter ->
  let switchIdCell = ktoken_int currentSwitchId in
  let caseIdCell = ktoken_int counter in
  kapply "Case" [switchIdCell; caseIdCell; printExpression exp; printStatement stat]
and printCaseRange exp1 exp2 stat = kapply "CaseRange" [printExpression exp1; printExpression exp2; printStatement stat]
and printDefault stat = current_switch >>= fun currentSwitchId ->
  let switchIdCell = ktoken_int currentSwitchId in
  kapply "Default" [switchIdCell; printStatement stat]
and printLabel str stat = kapply "Label" [printIdentifier str; printStatement stat]
and printGoto name = kapply "Goto" [printIdentifier name]
and printCompGoto exp = kapply "CompGoto" [printExpression exp]
and printBlockStatement block = kapply "BlockStatement" [printBlock block]
and printStatement = function
  | NOP loc                           -> printStatementLoc (printNop) loc
  | COMPUTATION (exp, loc)            -> printStatementLoc (printComputation exp) loc
  | BLOCK (blk, loc)                  -> printStatementLoc (printBlockStatement blk) loc
  | IF (exp, s1, s2, loc)             -> printStatementLoc (printIf exp s1 s2) loc
  | WHILE (exp, stat, loc)            -> printStatementLoc (printWhile exp stat) loc
  | DOWHILE (exp, stat, loc, wloc)    -> printStatementLoc (printDoWhile exp stat wloc) loc
  | FOR (fc1, exp2, exp3, stat, loc)  -> printStatementLoc (printFor fc1 exp2 exp3 stat) loc
  | BREAK loc                         -> printStatementLoc (printBreak) loc
  | CONTINUE loc                      -> printStatementLoc (printContinue) loc
  | RETURN (exp, loc)                 -> printStatementLoc (printReturn exp) loc
  | SWITCH (exp, stat, loc)           -> printStatementLoc (printSwitch exp stat) loc
  | CASE (exp, stat, loc)             -> printStatementLoc (printCase exp stat) loc
  | CASERANGE (exp1, exp2, stat, loc) -> printStatementLoc (printCaseRange exp1 exp2 stat) loc (* GCC's extension *)
  | DEFAULT (stat, loc)               -> printStatementLoc (printDefault stat) loc
  | LABEL (str, stat, loc)            -> printStatementLoc (printLabel str stat) loc
  | GOTO (name, loc)                  -> printStatementLoc (printGoto name) loc
  | COMPGOTO (exp, loc)               -> printStatementLoc (printCompGoto exp) loc (* GCC's "goto *exp" *)
  | DEFINITION d                      -> printDef d
  | _                                 -> kapply0 "OtherStatement"
and printStatementLoc s l = kapply "StatementLoc" [s; printCabsLoc l]
and printStatementList a = list_of printStatement a
and printEnumItemList a = list_of printEnumItem a
and printBlockLabels a = list_of puts a
and printAttribute (a, b) = kapply "Attribute" [ktoken_string a; printExpressionList b]
and printEnumItem (str, exp, cabsloc) = match exp with
  | NOTHING -> kapply "EnumItem" [printIdentifier str]
  | exp     -> kapply "EnumItemInit" [printIdentifier str; printExpression exp]

and printSpecifier a = kapply "Specifier" [printSpecElemList a]
and printSpecElemList a = list_of printSpecElem a
and printSingleNameList a = list_of printSingleName a
and printSpecElem = function
  | SpecTypedef      -> kapply0 "SpecTypedef"
  | SpecMissingType  -> kapply0 "MissingType"
  | SpecCV cv        -> (match cv with
    | CV_CONST                       -> kapply0 "Const"
    | CV_VOLATILE                    -> kapply0 "Volatile"
    | CV_ATOMIC                      -> kapply0 "Atomic"
    | CV_RESTRICT                    -> kapply0 "Restrict"
    | CV_RESTRICT_RESERVED (kwd,loc) -> kapply "RestrictReserved" [ktoken_string kwd; printCabsLoc loc])
  | SpecAttr al      -> printAttribute al
  | SpecStorage sto  -> (match sto with
    | NO_STORAGE                     -> kapply0 "NoStorage"
    | THREAD_LOCAL                   -> kapply0 "ThreadLocal"
    | AUTO                           -> kapply0 "Auto"
    | STATIC                         -> kapply0 "Static"
    | EXTERN                         -> kapply0 "Extern"
    | REGISTER                       -> kapply0 "Register")
  | SpecInline       -> kapply0 "Inline"
  | SpecNoReturn     -> kapply0 "Noreturn"
  | SpecAlignment a  -> (match a with
    | EXPR_ALIGNAS e                 -> printAlignasExpression e
    | TYPE_ALIGNAS (s, d)            -> printAlignasType s d)
  | SpecType bt      -> printTypeSpec bt
  | SpecPattern name -> kapply "SpecPattern" [printIdentifier name]
and printAlignasExpression e = kapply "AlignasExpression" [printExpression e]
and printAlignasType s d = kapply "AlignasType" [printSpecifier s; printDeclType d]

and printTypeSpec = function
  | Tvoid             -> kapply0 "Void"
  | Tchar             -> kapply0 "Char"
  | Tbool             -> kapply0 "Bool"
  | Tshort            -> kapply0 "Short"
  | Tint              -> kapply0 "Int"
  | Tlong             -> kapply0 "Long"
  | ToversizedInt     -> kapply0 "OversizedInt"
  | Tfloat            -> kapply0 "Float"
  | Tdouble           -> kapply0 "Double"
  | ToversizedFloat   -> kapply0 "OversizedFloat"
  | Tsigned           -> kapply0 "Signed"
  | Tunsigned         -> kapply0 "Unsigned"
  | Tnamed s          -> kapply "Named" [printIdentifier s]
  | Tstruct (a, b, c) -> printStructType a b c
  | Tunion (a, b, c)  -> printUnionType a b c
  | Tenum (a, b, c)   -> printEnumType a b c
  | TtypeofE e        -> kapply "TypeofExpression" [printExpression e]
  | TtypeofT (s, d)   -> kapply "TypeofType" [printSpecifier s; printDeclType d]
  | TautoType         -> kapply0 "AutoType"
  | Tcomplex          -> kapply0 "Complex"
  | Timaginary        -> kapply0 "Imaginary"
  | Tatomic (s, d)    -> kapply "TAtomic" [printSpecifier s; printDeclType d]
and printStructType a b c = match b with
  | None   -> kapply "StructRef" [printIdentifier a; printSpecElemList c]
  | Some b -> kapply "StructDef" [printIdentifier a; printFieldGroupList b; printSpecElemList c]
and printUnionType a b c = match b with
  | None   -> kapply "UnionRef" [printIdentifier a; printSpecElemList c]
  | Some b -> kapply "UnionDef" [printIdentifier a; printFieldGroupList b; printSpecElemList c]
and printEnumType a b c = match b with
  | None   -> kapply "EnumRef" [printIdentifier a; printSpecElemList c]
  | Some b -> kapply "EnumDef" [printIdentifier a; printEnumItemList b; printSpecElemList c]
