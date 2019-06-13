open Escape
open Cabs

(* Types. *)

(* Printer state. *)
type printer_state =
  { kore : bool
  ; counter : int
  ; current_switch_id : int
  ; switch_stack : int list
  ; string_literals : (unit printer) list
  ; buffer : Buffer.t
  }

(* State monad. *)
and 'a printer = printer_state -> ('a * printer_state)

type attribute = Attrib of string * string

let init_state : printer_state =
  { kore = false
  ; counter = 0
  ; current_switch_id = 0
  ; switch_stack = [0]
  ; string_literals = []
  ; buffer = Buffer.create 100
  }

type csort =
  | K | KItem | KResult | Bool | Int | Float | String
  | Specifier | Qualifier | FunctionSpecifier | StorageClassSpecifier | SpecifierElem
  | AutoSpecifier | TypeSpecifier | CabsLoc | CId | Init | RValue | StrictList
  | Constant | StringLiteral | FloatConstant | IntConstant

let csort_to_string : csort -> string = function
  | K                     -> "K"
  | KItem                 -> "KItem"
  | KResult               -> "KResult"
  | Bool                  -> "Bool"
  | Int                   -> "Int"
  | Float                 -> "Float"
  | String                -> "String"
  | Specifier             -> "Specifier"
  | Qualifier             -> "Qualifier"
  | FunctionSpecifier     -> "FunctionSpecifier"
  | StorageClassSpecifier -> "StorageClassSpecifier"
  | SpecifierElem         -> "SpecifierElem"
  | AutoSpecifier         -> "AutoSpecifier"
  | TypeSpecifier         -> "TypeSpecifier"
  | CabsLoc               -> "CabsLoc"
  | CId                   -> "CId"
  | Init                  -> "Init"
  | RValue                -> "RValue"
  | StrictList            -> "StrictList"
  | Constant              -> "Constant"
  | StringLiteral         -> "StringLiteral"
  | FloatConstant         -> "FloatConstant"
  | IntConstant           -> "IntConstant"

(* Monad morphisms. *)
let return (a : 'a) : 'a printer = fun s -> (a, s)

let (>>=) (m : 'a printer) (f : 'a -> 'b printer) : 'b printer = fun s ->
  let (a_intr, s_intr) = m s in
  (f a_intr) s_intr

let (>>) (ma : 'a printer) (mb : 'b printer) : 'b printer = ma >>= fun _ -> mb

let puts (str : string) : unit printer = fun s -> (Buffer.add_string s.buffer str, s)

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

let if_kore (kore_true : 'a printer) (kore_false : 'a printer) : 'a printer = kore >>= fun k ->
  if k then kore_true else kore_false

let if_kore_strict (kore_true : 'a) (kore_false : 'a) : 'a printer = if_kore (return kore_true) (return kore_false)

(* Function composition. *)
let (%) (g : 'b -> 'c) (f : 'a -> 'b) : 'a -> 'c = fun a -> g (f a)

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
    if Buffer.length buf > 0 && Buffer.nth buf (Buffer.length buf - 1) = '\''
    then (Buffer.truncate buf (Buffer.length buf - 1); s) else "'" ^ s in
  Buffer.add_string buf % function
    | '_' -> opt_apost "Unds'"
    | '.' -> opt_apost "Stop'"
    | '(' -> opt_apost "LPar'"
    | ')' -> opt_apost "RPar'"
    | c   -> Printf.sprintf "%c" c

let klabel_escape_kore (str : string) : string =
  let buf = Buffer.create (String.length str) in
  String.iter (klabel_char_escape_kore buf) str; Buffer.contents buf

let klabel_escape_kast (str : string) : string = str

(* Atomic output functions. *)
let kstring (s : string) : string printer = if_kore_strict s ("\"" ^ s ^ "\"")

let ksort (sort : csort) : unit printer =
  if_kore
    (puts "Sort" >> puts (csort_to_string sort) >> puts "{}")
    (puts (csort_to_string sort))

let ktoken (sort : csort) (s : string) : unit printer =
  if_kore
    (puts "\dv{"      >> ksort sort               >> puts "}(\""   >> puts (k_string_escape s) >> puts "\")")
    (puts "#token(\"" >> puts (k_string_escape s) >> puts "\", \"" >> ksort sort               >> puts "\")")

let ktoken_string (s : string) : unit printer          = kstring s >>= ktoken String
let ktoken_bool (v : bool) : unit printer              = ktoken Bool (if v then "true" else "false")
let ktoken_int (v : int) : unit printer                = ktoken Int (string_of_int v)
let ktoken_int_of_string (v : string) : unit printer   = ktoken Int v
let ktoken_float (v : float) : unit printer            = ktoken Float (string_of_float v)
let ktoken_float_of_string (v : string) : unit printer = ktoken Float v

let sequence : (unit printer) list -> unit printer =
  let fold_left1 (f : 'a -> 'a -> 'a) : 'a list -> 'a = function
    | x :: xs -> List.fold_left f x xs in
  fold_left1 (fun a b -> (a >> puts ", " >> b))

let klabel (label : string) : unit printer =
  if_kore
    (puts "Lbl" >> puts (klabel_escape_kore label) >> puts "{}")
    (puts "`"   >> puts (klabel_escape_kast label) >> puts "`")

(* Unsorted kapply (kapply without injections). *)
let kapply_us (label : string) : (unit printer) list -> unit printer = function
  | []       -> klabel label >> puts "(" >> if_kore_strict "" ".KList" >>= puts >> puts ")"
  | children -> klabel label >> puts "(" >> sequence children >> puts ")"

let kapply0_us (label : string) : unit printer =
  kapply_us label []

let kapply1_us (label : string) (contents : unit printer) : unit printer =
  kapply_us label [contents]

let kseq (contents : (unit printer) list) =
  puts "kseq{}(" >> sequence (contents @ [puts "dotk{}()"]) >> puts ")"

let inj (subsort : csort) (sort : csort) (contents : unit printer) : unit printer =
  puts "inj{" >> sequence [ksort subsort; ksort sort] >> puts "}(" >> contents >> puts ")"

let inject (subsort : csort) (sort : csort) (contents : unit printer) : unit printer =
  if subsort = sort then contents else
    if sort = K then kseq [contents] else inj subsort sort contents

let kapply (subsort : csort) (sort : csort) (label : string) (contents : (unit printer) list) : unit printer =
  if_kore
    (inject subsort sort (kapply_us label contents))
    (kapply_us label contents)

let kapply0 (subsort : csort) (sort : csort) (label : string) : unit printer =
  kapply subsort sort label []

let kapply1 (subsort : csort) (sort : csort) (label : string) (contents : unit printer) : unit printer =
  kapply subsort sort label [contents]

let dot_list : unit printer = kapply0 KItem KItem ".List"

let list_of2 (f : 'a -> unit printer) (sort : csort) (elems : 'a list) : unit printer =
  let op k l = kapply_us "_List_" [k; l] in
  let items = List.map (fun x -> kapply1_us "ListItem" (f x)) elems in
  kapply1 StrictList sort "list" (List.fold_right op items dot_list)

let list_of (f : csort -> 'a -> unit printer) (sort : csort) : 'a list -> unit printer = list_of2 (f KItem) sort

(* This is where the recursive printer starts. *)

let cabs_loc sort a =
  let filename = if Filename.is_relative a.filename then Filename.concat (Sys.getcwd ()) a.filename else a.filename in
  kapply CabsLoc sort "CabsLoc" [ktoken_string a.filename; ktoken_string filename; ktoken_int a.lineno; ktoken_int a.lineOffsetStart; ktoken_bool a.systemHeader]

let identifier sort = function
  | "" | "___missing_field_name" -> kapply0 CId sort "AnonymousName"
  | x                            -> kapply1 CId sort "Identifier" (ktoken_string x)


(* Given a character constant (like 'a' or 'abc') as a list of 64-bit
 * values, turn it into a CIL constant.  Multi-character constants are
 * treated as multi-digit numbers with radix given by the bit width of
 * the specified type (either char or wchar_t). *)
let reduce_multichar (radix : int) : int64 list -> int64 =
  List.fold_left (fun acc -> Int64.add (Int64.shift_left acc radix)) Int64.zero

let interpret_character_constant char_list =
  Int64.to_int (reduce_multichar 8 char_list)

let interpret_wcharacter_constant char_list =
  Int64.to_int (reduce_multichar 32 char_list)

let constant sort =
  let float_literal sort r =
    let hex_float_constant f =
      let [significand; exponentPart] = Str.split (Str.regexp "[pP]") f in
      let (wholePart, fractionalPart) = match Str.split_delim (Str.regexp "\.") significand with
        | [""; ""] -> ("0", "0")
        | [w; ""]  -> (w, "0")
        | [""; f]  -> ("0", f)
        | [w; f]   -> (w, f)
        | _        -> ("0", "0") in
      let [exponentPart]              = Str.split (Str.regexp "[+]") exponentPart in
      let exponentPart                = int_of_string exponentPart in
      let significand                 = wholePart ^ "." ^ fractionalPart in
      let approx                      = (float_of_string ("0x" ^ significand)) *. (2. ** (float_of_int exponentPart)) in
      kapply FloatConstant Constant "HexFloatConstant" [ktoken_string significand; ktoken_int exponentPart; ktoken_float approx] in
    let dec_float_constant f =
      let (significand, exponentPart) = match Str.split (Str.regexp "[eE]") f with
        | [x]    -> (x, "0")
        | [x; y] -> (x, y) in
      let (wholePart, fractionalPart) = match Str.split_delim (Str.regexp "\.") significand with
        | [""; ""] -> ("0", "0")
        | [w; ""]  -> (w, "0")
        | [""; f]  -> ("0", f)
        | [w; f]   -> (w, f)
        | _        -> ("0", "0") in
      let stringRep                   = wholePart ^ "." ^ fractionalPart ^ "e" ^ exponentPart in
      let [exponentPart]              = Str.split (Str.regexp "[+]") exponentPart in
      let exponentPart                = int_of_string exponentPart in
      let significand                 = wholePart ^ "." ^ fractionalPart in
      kapply FloatConstant Constant "DecimalFloatConstant" [ktoken_string significand; ktoken_int exponentPart; ktoken_float_of_string stringRep] in
    let rec splitFloat (xs, i) =
      let lastOne = if String.length i > 1 then String.uppercase (Str.last_chars i 1) else "x" in
      let newi    = Str.string_before i (String.length i - 1) in
      match lastOne with
        | "x" -> (xs, i)
        | "L" -> splitFloat ("L" :: xs, newi)
        | "F" -> splitFloat ("F" :: xs, newi)
        | _   -> (xs, i) in
    let (tag, r) = splitFloat ([], r) in
    let firstTwo = if String.length r > 2 then Str.string_before r 2 else "xx" in
    let num = match firstTwo with
        | "0x" | "0X" -> hex_float_constant (Str.string_after r 2)
        | _           -> dec_float_constant r in
    match tag with
      | ["F"] -> kapply1 Constant sort "LitF" num
      | ["L"] -> kapply1 Constant sort "LitL" num
      | []    -> kapply1 Constant sort "NoSuffix" num in
  let int_literal sort i =
    let hex_constant (i : string) = kapply IntConstant Constant "HexConstant" [ktoken_string i] in
    let oct_constant (i : string) = kapply IntConstant Constant "OctalConstant" [ktoken_int_of_string i] in
    let dec_constant (i : string) = kapply IntConstant Constant "DecimalConstant" [ktoken_int_of_string i] in
    let rec splitInt (xs, i) =
      let lastOne = if String.length i > 1 then String.uppercase (Str.last_chars i 1) else "x" in
      let newi    = Str.string_before i (String.length i - 1) in
      match lastOne with
        | "x" -> (xs, i)
        | "U" -> splitInt ("U" :: xs, newi)
        | "L" -> splitInt ("L" :: xs, newi)
        | _   -> (xs, i) in
    let (tag, i) = splitInt ([], i) in
    let firstTwo = if String.length i > 2 then Str.string_before i 2 else "xx" in
    let firstOne = if String.length i > 1 then Str.string_before i 1 else "x" in
    let num = match (firstTwo, firstOne) with
      | ("0x", _) | ("0X", _) -> hex_constant (Str.string_after i 2)
      | (_, "0")              -> oct_constant (Str.string_after i 1)
      | _                     -> dec_constant i in
    match tag with
      | ["U"; "L"; "L"] | ["L"; "L"; "U"] -> kapply1 Constant sort "LitULL" num
      | ["L"; "L"]                        -> kapply1 Constant sort "LitLL" num
      | ["U"; "L"] | ["L"; "U"]           -> kapply1 Constant sort "LitUL" num
      | ["U"]                             -> kapply1 Constant sort "LitU" num
      | ["L"]                             -> kapply1 Constant sort "LitL" num
      | []                                -> kapply1 Constant sort "NoSuffix" num in
  function
    | CONST_INT i      -> int_literal sort i
    | CONST_FLOAT r    -> float_literal sort r
    | CONST_CHAR c     -> kapply Constant sort "CharLiteral" [ktoken_int (interpret_character_constant c)]
    | CONST_WCHAR c    -> kapply Constant sort "WCharLiteral" [ktoken_int (interpret_wcharacter_constant c)]
    | CONST_STRING s   -> save_string_literal (kapply1 StringLiteral sort "StringLiteral" (ktoken_string s))
    | CONST_WSTRING ws -> save_string_literal (kapply1 StringLiteral sort "WStringLiteral" (list_of2 (fun i -> ktoken_int (Int64.to_int i)) KItem ws))

let rec specifier_elem sort = function
  | SpecTypedef      -> kapply0 SpecifierElem sort "SpecTypedef"
  | SpecMissingType  -> kapply0 SpecifierElem sort "MissingType"
  | SpecCV cv        -> (match cv with
    | CV_CONST                       -> kapply0 Qualifier sort "Const"
    | CV_VOLATILE                    -> kapply0 Qualifier sort "Volatile"
    | CV_ATOMIC                      -> kapply0 Qualifier sort "Atomic"
    | CV_RESTRICT                    -> kapply0 Qualifier sort "Restrict"
    | CV_RESTRICT_RESERVED (kwd,loc) -> kapply Qualifier sort "RestrictReserved" [ktoken_string kwd; cabs_loc CabsLoc loc])
  | SpecAttr (a, b)  -> kapply KItem sort "Attribute" [ktoken_string a; list_of expression KItem b]
  | SpecStorage sto  -> (match sto with
    | NO_STORAGE                     -> kapply0 StorageClassSpecifier sort "NoStorage"
    | THREAD_LOCAL                   -> kapply0 StorageClassSpecifier sort "ThreadLocal"
    | AUTO                           -> kapply0 AutoSpecifier sort "Auto"
    | STATIC                         -> kapply0 StorageClassSpecifier sort "Static"
    | EXTERN                         -> kapply0 StorageClassSpecifier sort "Extern"
    | REGISTER                       -> kapply0 StorageClassSpecifier sort "Register")
  | SpecInline       -> kapply0 FunctionSpecifier sort "Inline"
  | SpecNoReturn     -> kapply0 FunctionSpecifier sort "Noreturn"
  | SpecAlignment a  -> (match a with
    | EXPR_ALIGNAS e                 -> kapply SpecifierElem sort "AlignasExpression" [expression KItem e]
    | TYPE_ALIGNAS (s, d)            -> kapply SpecifierElem sort "AlignasType" [specifier KItem s; decl_type KItem d])
  | SpecType bt      -> type_spec sort bt
  | SpecPattern n    -> kapply SpecifierElem sort "SpecPattern" [identifier CId n]
and specifier sort a = kapply Specifier sort "Specifier" [list_of specifier_elem KItem a]
and name sort (a, b, c, d) = kapply KItem sort "Name" [identifier CId a; decl_type KItem b; list_of specifier_elem KItem c]
and single_name sort (a, b) = kapply KItem sort "SingleName" [specifier KItem a; name KItem b]
and init_expression sort = function
  | NO_INIT         -> kapply0 Init sort "NoInit"
  | SINGLE_INIT exp -> kapply KItem sort "SingleInit" [expression KItem exp]
  | COMPOUND_INIT a -> kapply KItem sort "CompoundInit" [list_of init_fragment KItem a]
and init_fragment sort (a, b) =
  let rec init_what sort = function
    | NEXT_INIT                      -> kapply0 KResult sort "NextInit"
    | INFIELD_INIT (id, what)        -> kapply KResult sort "InFieldInit" [identifier CId id; init_what KItem what]
    | ATINDEX_INIT (exp, what)       -> kapply KResult sort "AtIndexInit" [expression K exp; init_what KItem what]
    | ATINDEXRANGE_INIT (exp1, exp2) -> kapply KResult sort "AtIndexRangeInit" [expression KItem exp1; expression KItem exp2] in
  kapply KItem sort "InitFragment" [init_what KItem a; init_expression KItem b]
and block sort a = new_counter >>= fun blockNum ->
  kapply KItem sort "Block3" [ktoken_int blockNum; list_of2 puts KItem a.blabels; list_of statement KItem a.bstmts]

and decl_type sort = function
  | JUSTBASE            -> kapply0 KItem sort "JustBase"
  | PARENTYPE (a, b, c) -> kapply KItem sort "FunctionType" [decl_type KItem b]
  | ARRAY (a, b, c, d)  -> kapply KItem sort "ArrayType" [decl_type KItem a; expression K c; specifier KItem (b@d)]
  | PTR (a, b)          -> kapply KItem sort "PointerType" [specifier Specifier a; decl_type KItem b]
  | PROTO (a, b, c)     -> kapply KItem sort "Prototype" [decl_type KItem a; list_of single_name KItem b; ktoken_bool c]
  | NOPROTO (a, b, c)   -> kapply KItem sort "NoPrototype" [decl_type KItem a; list_of single_name KItem b; ktoken_bool c]

and expression sort =
  let generic_assoc sort = function
    | GENERIC_PAIR ((spec, declType), exp) -> kapply KItem sort "GenericPair" [specifier KItem spec; decl_type KItem declType; expression KItem exp]
    | GENERIC_DEFAULT exp                  -> kapply KItem sort "GenericDefault" [expression KItem exp] in
  let unary_expression sort op exp =
    let unary_operator = function
      | MINUS   -> "Negative"
      | PLUS    -> "Positive"
      | NOT     -> "LogicalNot"
      | BNOT    -> "BitwiseNot"
      | MEMOF   -> "Dereference"
      | ADDROF  -> "Reference"
      | PREINCR -> "PreIncrement"
      | PREDECR -> "PreDecrement"
      | POSINCR -> "PostIncrement"
      | POSDECR -> "PostDecrement" in
    kapply KItem sort (unary_operator op) [expression KItem exp] in
  let binary_expression sort op exp1 exp2 =
    let binary_operator = function
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
      | SHR_ASSIGN  -> "AssignRightShift" in
    kapply KItem sort (binary_operator op) [expression KItem exp1; expression KItem exp2] in
  function
    | OFFSETOF ((spec, declType), exp, loc)                      -> kapply KItem sort "OffsetOf" [specifier KItem spec; decl_type KItem declType; expression KItem exp]
    | TYPES_COMPAT ((spec1, declType1), (spec2, declType2), loc) -> kapply KItem sort "TypesCompat" [specifier KItem spec1; decl_type KItem declType1; specifier KItem spec2; decl_type KItem declType2]
    | GENERIC (exp, assocs)                                      -> kapply KItem sort "Generic" [expression K exp; list_of generic_assoc KItem assocs]
    | LOCEXP (exp, loc)                                          -> expression sort exp
    | UNARY (op, exp1)                                           -> unary_expression sort op exp1
    | BINARY (op, exp1, exp2)                                    -> binary_expression sort op exp1 exp2
    | NOTHING                                                    -> kapply0 KItem sort "NothingExpression"
    | UNSPECIFIED                                                -> kapply0 RValue sort "UnspecifiedSizeExpression"
    | PAREN (exp1)                                               -> expression sort exp1
    | QUESTION (exp1, exp2, exp3)                                -> kapply KItem sort "Conditional" [expression KItem exp1; expression KItem exp2; expression KItem exp3]
    (* Special case below for the compound literals. I don't know why this isn't in the ast... *)
    | CAST ((spec, declType), initExp)                           -> (new_counter >>= fun id -> match initExp with
        | NO_INIT         -> kapply1 KItem sort "Error" (puts "cast with a NO_INIT inside doesn't make sense") (* TODO(chathhorn): handle error better. *)
        | SINGLE_INIT exp -> kapply KItem sort "Cast" [specifier K spec; decl_type KItem declType; expression K exp]
        | COMPOUND_INIT a -> kapply KItem sort "CompoundLiteral" [ktoken_int id; specifier K spec; decl_type KItem declType; kapply_us "CompoundInit" [list_of init_fragment KItem a]])
    | CALL (exp1, expList)                                       -> kapply KItem sort "Call" [expression K exp1; list_of expression K expList]
    | COMMA expList                                              -> kapply KItem sort "Comma" [list_of expression KItem expList]
    | CONSTANT (const)                                           -> kapply KItem sort "Constant" [constant KItem const]
    | VARIABLE name                                              -> identifier sort name
    | EXPR_SIZEOF exp1                                           -> kapply KItem sort "SizeofExpression" [expression K exp1]
    | TYPE_SIZEOF (spec, declType)                               -> kapply KItem sort "SizeofType" [specifier KItem spec; decl_type K declType]
    | EXPR_ALIGNOF exp                                           -> kapply KItem sort "AlignofExpression" [expression KItem exp]
    | TYPE_ALIGNOF (spec, declType)                              -> kapply KItem sort "AlignofType" [specifier KItem spec; decl_type KItem declType]
    | INDEX (exp, idx)                                           -> kapply KItem sort "ArrayIndex" [expression KItem exp; expression KItem idx]
    | MEMBEROF (exp, fld)                                        -> kapply KItem sort "Dot" [expression KItem exp; identifier CId fld]
    | MEMBEROFPTR (exp, fld)                                     -> kapply KItem sort "Arrow" [expression KItem exp; identifier CId fld]
    | GNU_BODY blk                                               -> kapply KItem sort "GnuBody" [block KItem blk]
    | BITMEMBEROF (exp, fld)                                     -> kapply KItem sort "DotBit" [expression KItem exp; identifier CId fld]
    | EXPR_PATTERN s                                             -> kapply KItem sort "ExpressionPattern" [ktoken_string s]

and type_spec sort =
  let field sort (n, expOpt) = match expOpt with
    | None     -> kapply KItem sort "FieldName" [name KItem n]
    | Some exp -> kapply KItem sort "BitFieldName" [name KItem n; expression KItem exp] in
  let field_group sort (spec, fields) = kapply KItem sort "FieldGroup" [specifier KItem spec; list_of field KItem fields] in
  let struct_type sort a c = function
    | None   -> kapply TypeSpecifier sort "StructRef" [identifier CId a; list_of specifier_elem K c]
    | Some b -> kapply TypeSpecifier sort "StructDef" [identifier CId a; list_of field_group K b; list_of specifier_elem KItem c] in
  let union_type sort a c = function
    | None   -> kapply TypeSpecifier sort "UnionRef" [identifier CId a; list_of specifier_elem K c]
    | Some b -> kapply TypeSpecifier sort "UnionDef" [identifier CId a; list_of field_group K b; list_of specifier_elem KItem c] in
  let enum_item sort (str, exp, _) = match exp with
    | NOTHING -> kapply KItem sort "EnumItem" [identifier CId str]
    | exp     -> kapply KItem sort "EnumItemInit" [identifier CId str; expression K exp] in
  let enum_type sort a c = function
    | None   -> kapply TypeSpecifier sort "EnumRef" [identifier CId a; list_of specifier_elem K c]
    | Some b -> kapply TypeSpecifier sort "EnumDef" [identifier CId a; list_of enum_item K b; list_of specifier_elem KItem c] in
  function
    | Tvoid             -> kapply0 TypeSpecifier sort "Void"
    | Tchar             -> kapply0 TypeSpecifier sort "Char"
    | Tbool             -> kapply0 TypeSpecifier sort "Bool"
    | Tshort            -> kapply0 TypeSpecifier sort "Short"
    | Tint              -> kapply0 TypeSpecifier sort "Int"
    | Tlong             -> kapply0 TypeSpecifier sort "Long"
    | ToversizedInt     -> kapply0 TypeSpecifier sort "OversizedInt"
    | Tfloat            -> kapply0 TypeSpecifier sort "Float"
    | Tdouble           -> kapply0 TypeSpecifier sort "Double"
    | ToversizedFloat   -> kapply0 TypeSpecifier sort "OversizedFloat"
    | Tsigned           -> kapply0 TypeSpecifier sort "Signed"
    | Tunsigned         -> kapply0 TypeSpecifier sort "Unsigned"
    | Tnamed s          -> kapply TypeSpecifier sort "Named" [identifier CId s]
    | Tstruct (a, b, c) -> struct_type sort a c b
    | Tunion (a, b, c)  -> union_type sort a c b
    | Tenum (a, b, c)   -> enum_type sort a c b
    | TtypeofE e        -> kapply SpecifierElem sort "TypeofExpression" [expression KItem e]
    | TtypeofT (s, d)   -> kapply SpecifierElem sort "TypeofType" [specifier KItem s; decl_type KItem d]
    | TautoType         -> kapply0 TypeSpecifier sort "AutoType"
    | Tcomplex          -> kapply0 TypeSpecifier sort "Complex"
    | Timaginary        -> kapply0 TypeSpecifier sort "Imaginary"
    | Tatomic (s, d)    -> kapply SpecifierElem sort "TAtomic" [specifier KItem s; decl_type KItem d]

and definition (sort : csort) : definition -> unit printer =
  let definition_loc sort a l = if l.lineno <> -10 then kapply KItem sort "DefinitionLoc" [a; cabs_loc CabsLoc l] else a in
  let definition_loc_range sort a b c = kapply KItem sort "DefinitionLocRange" [a; cabs_loc CabsLoc b; cabs_loc CabsLoc c] in
  let init_name sort (a, b) = kapply KItem sort "InitName" [name KItem a; init_expression K b] in
  let init_name_group sort (a, b) = kapply KItem sort "InitNameGroup" [specifier KItem a; list_of init_name KItem b] in
  let name_group sort (a, b) = kapply KItem sort "NameGroup" [specifier KItem a; list_of name KItem b] in
  function
    | FUNDEF (a, b, c, d)     -> definition_loc_range sort (kapply_us "FunctionDefinition" [single_name KItem a; block KItem b]) c d
    | DECDEF (a, b)           -> definition_loc sort (kapply_us "DeclarationDefinition" [init_name_group KItem a]) b
    | TYPEDEF (a, b)          -> definition_loc sort (kapply_us "Typedef" [name_group KItem a]) b
    | ONLYTYPEDEF (a, b)      -> definition_loc sort (kapply_us "OnlyTypedef" [specifier KItem a]) b
    | GLOBASM (a, b)          -> definition_loc sort (kapply_us "GlobAsm" [ktoken_string a]) b
    | PRAGMA (a, b)           -> definition_loc sort (kapply_us "Pragma" [expression KItem a]) b
    | LINKAGE (a, b, c)       -> definition_loc sort (kapply_us "Linkage" [ktoken_string a; list_of definition KItem c]) b
    | STATIC_ASSERT (a, b, c) -> definition_loc sort (kapply_us "StaticAssert" [expression K a; constant KItem b]) c

and statement sort =
  let block_statement sort blk = kapply KItem sort "BlockStatement" [block KItem blk] in
  let new_block_statement sort s = block_statement sort { blabels = []; battrs = []; bstmts = [s] } in
  let for_clause sort = function
    | FC_EXP exp1  -> kapply1 KItem sort "ForClauseExpression" (expression KItem exp1)
    | FC_DECL dec1 -> definition sort dec1 in
  let statement_loc s l = kapply KItem sort "StatementLoc" [s; cabs_loc CabsLoc l] in
  let printFor sort fc1 exp2 exp3 stat = new_counter >>= fun counter ->
    kapply KItem sort "For5" [ktoken_int counter; for_clause KItem fc1; expression K exp2; expression K exp3; new_block_statement K stat] in
  let printSwitch sort exp stat = push_switch >>= fun id ->
    kapply KItem sort "Switch" [ktoken_int id; expression K exp; new_block_statement K stat]
    >> pop_switch in
  let printCase sort exp stat = current_switch >>= fun switch_id -> new_counter >>= fun case_id ->
    kapply KItem sort "Case" [ktoken_int switch_id; ktoken_int case_id; expression K exp; statement K stat] in
  let default sort stat = current_switch >>= fun switch_id ->
    kapply KItem sort "Default" [ktoken_int switch_id; statement K stat] in
  function
    | NOP loc                           -> statement_loc (kapply0_us "Nop") loc
    | COMPUTATION (exp, loc)            -> statement_loc (kapply_us "Computation" [expression K exp]) loc
    | BLOCK (blk, loc)                  -> statement_loc (block_statement KItem blk) loc
    | IF (exp, s1, s2, loc)             -> statement_loc (kapply_us "IfThenElse" [expression K exp; new_block_statement K s1; new_block_statement K s2]) loc
    | WHILE (exp, stat, loc)            -> statement_loc (kapply_us "While" [expression K exp; new_block_statement K stat]) loc
    | DOWHILE (exp, stat, loc, wloc)    -> statement_loc (kapply_us "DoWhile3" [expression K exp; new_block_statement KItem stat; cabs_loc CabsLoc wloc]) loc
    | FOR (fc1, exp2, exp3, stat, loc)  -> statement_loc (printFor KItem fc1 exp2 exp3 stat) loc
    | BREAK loc                         -> statement_loc (kapply0_us "Break") loc
    | CONTINUE loc                      -> statement_loc (kapply0_us "Continue") loc
    | RETURN (exp, loc)                 -> statement_loc (kapply_us "Return" [expression K exp]) loc
    | SWITCH (exp, stat, loc)           -> statement_loc (printSwitch KItem exp stat) loc
    | CASE (exp, stat, loc)             -> statement_loc (printCase KItem exp stat) loc
    | CASERANGE (exp1, exp2, stat, loc) -> statement_loc (kapply_us "CaseRange" [expression KItem exp1; expression KItem exp2; statement KItem stat]) loc (* GCC's extension *)
    | DEFAULT (stat, loc)               -> statement_loc (default KItem stat) loc
    | LABEL (str, stat, loc)            -> statement_loc (kapply_us "Label" [identifier CId str; statement K stat]) loc
    | GOTO (name, loc)                  -> statement_loc (kapply_us "Goto" [identifier CId name]) loc
    | COMPGOTO (exp, loc)               -> statement_loc (kapply_us "CompGoto" [expression KItem exp]) loc (* GCC's "goto *exp" *)
    | DEFINITION d                      -> definition sort d
    | _                                 -> kapply0 KItem sort "OtherStatement"

let translation_unit (filename : string) (defs : definition list) (s : printer_state) =
  (* Finangling here to extract string literals. *)
  let (_, s_intr) = list_of definition KItem defs s in
  let fn          = ktoken_string filename in
  let strings     = get_string_literals >>= fun strings -> list_of2 (kapply1_us "Constant") KItem strings in
  let ast         = fun s -> (Buffer.add_buffer s.buffer s_intr.buffer; ((), s)) in
  kapply KItem K "TranslationUnit" [fn; strings; ast] {s_intr with buffer = Buffer.create 100}

let  cabs_to_kast (defs : definition list) (filename : string) : Buffer.t =
  let (_, final_state) = translation_unit filename defs init_state in
  Buffer.add_char final_state.buffer '\n'; final_state.buffer

let cabs_to_kore (defs : definition list) (filename : string) : Buffer.t =
  let (_, final_state) = translation_unit filename defs {init_state with kore = true} in
  Buffer.add_char final_state.buffer '\n'; final_state.buffer
