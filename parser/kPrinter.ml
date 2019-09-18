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
  | AutoSpecifier | TypeSpecifier | CabsLoc | CId | NoInit | RValue | StrictList
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
  | NoInit                -> "NoInit"
  | RValue                -> "RValue"
  | StrictList            -> "StrictList"
  | Constant              -> "Constant"
  | StringLiteral         -> "StringLiteral"
  | FloatConstant         -> "FloatConstant"
  | IntConstant           -> "IntConstant"

(* Getting/setting state. *)
let return (a : 'a) : 'a printer = fun s -> (a, s)

let (>>=) (m : 'a printer) (f : 'a -> 'b printer) : 'b printer = fun s ->
  let (a_intr, s_intr) = m s in
  (f a_intr) s_intr

let (>>) ma mb = ma >>= fun _ -> mb

let puts (str : string) : unit printer = fun s -> (Buffer.add_string s.buffer str, s)

let save_string_literal (str : csort -> unit printer) (sort : csort) : unit printer =
  str sort >> fun s -> ((), {s with string_literals = str sort :: s.string_literals})

let get_string_literals : ((unit printer) list) printer = fun s -> (s.string_literals, s)

let new_counter : int printer = fun s -> (s.counter + 1, {s with counter = s.counter + 1})

let push_switch : int printer = new_counter >>= fun counter s ->
  (counter, {s with switch_stack = counter :: s.switch_stack; current_switch_id = counter})

let pop_switch : unit printer = fun s ->
  ((), {s with switch_stack = List.tl s.switch_stack; current_switch_id = List.hd s.switch_stack})

let current_switch : int printer = fun s -> (s.current_switch_id, s)

(* Branch on whether kore is set. *)
let if_kore (kore_true : 'a printer) (kore_false : 'a printer) : 'a printer = fun s ->
   if s.kore then kore_true s else kore_false s

let if_kore_strict (kore_true : 'a) (kore_false : 'a) : 'a printer =
  if_kore
    (return kore_true)
    (return kore_false)

(* Function composition. *)
let (%) (g : 'b -> 'c) (f : 'a -> 'b) : 'a -> 'c = fun a -> g (f a)

(* Escaping. *)
let k_string_escape (str : string) : string =
  let char_escape : char -> string = function
    | '"'  -> "\\\""
    | '\\' -> "\\\\"
    | '\n' -> "\\n"
    | '\t' -> "\\t"
    | '\r' -> "\\r"
    | c when let code = Char.code c in code >= 32 && code < 127
           -> Printf.sprintf "%c" c
    | c    -> Printf.sprintf "\\x%02x" (Char.code c) in
  let buf = Buffer.create (String.length str) in
  String.iter (Buffer.add_string buf % char_escape) str; Buffer.contents buf

let kore_string_escape (str : string) : string =
  let char_escape : char -> string = function
    | '"'  -> "\\\""
    | '\\' -> "\\\\"
    | c when let code = Char.code c in code >= 32 && code < 127
           -> Printf.sprintf "%c" c
    | c    -> Printf.sprintf "\\x%02x" (Char.code c) in
  let buf = Buffer.create (String.length str) in
  String.iter (Buffer.add_string buf % char_escape) str; Buffer.contents buf

let klabel_char_escape_kore (buf: Buffer.t) : char -> unit =
  let apost s =
    if Buffer.length buf > 0 && Buffer.nth buf (Buffer.length buf - 1) = '\''
    then (Buffer.truncate buf (Buffer.length buf - 1); s) else "'" ^ s in
  Buffer.add_string buf % function
    | ' '  -> apost "Spce'"
    | '!'  -> apost "Bang'"
    | '"'  -> apost "Quot'"
    | '#'  -> apost "Hash'"
    | '$'  -> apost "Dolr'"
    | '%'  -> apost "Perc'"
    | '&'  -> apost "And'"
    | '\'' -> apost "Apos'"
    | '('  -> apost "LPar'"
    | ')'  -> apost "RPar'"
    | '*'  -> apost "Star'"
    | '+'  -> apost "Plus'"
    | ','  -> apost "Comm'"
    | '.'  -> apost "Stop'"
    | '/'  -> apost "Slsh'"
    | ':'  -> apost "Coln'"
    | ';'  -> apost "SCln'"
    | '<'  -> apost "-LT-'"
    | '='  -> apost "Eqls'"
    | '>'  -> apost "-GT-'"
    | '?'  -> apost "Ques'"
    | '@'  -> apost "-AT-'"
    | '['  -> apost "LSqB'"
    | '\\' -> apost "Bash'"
    | ']'  -> apost "RSqB'"
    | '^'  -> apost "Xor-'"
    | '_'  -> apost "Unds'"
    | '`'  -> apost "BQuo'"
    | '{'  -> apost "LBra'"
    | '|'  -> apost "Pipe'"
    | '}'  -> apost "RBra'"
    | '~'  -> apost "Tild'"
    | c    -> Printf.sprintf "%c" c

let klabel_escape_kore (str : string) : string =
  let buf = Buffer.create (String.length str) in
  String.iter (klabel_char_escape_kore buf) str; Buffer.contents buf

let klabel_escape_kast (str : string) : string = str

(* Atomic output functions. *)
let kstring (s : string) : string printer = if_kore_strict (kore_string_escape s) ("\"" ^ (k_string_escape s) ^ "\"")

let ksort (sort : csort) : unit printer =
  if_kore
    (puts "Sort" >> puts (csort_to_string sort) >> puts "{}")
    (puts (csort_to_string sort))

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
  | []       -> klabel label >> puts "(" >> (if_kore_strict "" ".KList" >>= puts) >> puts ")"
  | children -> klabel label >> puts "(" >> sequence children >> puts ")"

let kseq (contents : (unit printer) list) =
  puts "kseq{}(" >> sequence (contents @ [puts "dotk{}()"]) >> puts ")"

let inj (subsort : csort) (sort : csort) (contents : unit printer) : unit printer =
  puts "inj{" >> sequence [ksort subsort; ksort sort] >> puts "}(" >> contents >> puts ")"

let inject (subsort : csort) (sort : csort) (contents : unit printer) : unit printer =
  if subsort = sort then contents else
    if sort = K then if subsort = KItem then kseq [contents] else kseq [inj subsort KItem contents] else inj subsort sort contents

let ktoken (subsort : csort) (s : string) (sort : csort) : unit printer =
  if_kore
    (inject subsort sort (puts "\dv{" >> ksort subsort            >> puts "}(\""   >> puts s        >> puts "\")"))
    (puts "#token(\""                 >> puts (k_string_escape s) >> puts "\", \"" >> ksort subsort >> puts "\")")

let ktoken_string (s : string) (sort : csort) : unit printer    = kstring s >>= fun s -> ktoken String s sort
let ktoken_bool (v : bool) : csort -> unit printer              = ktoken Bool (if v then "true" else "false")
let ktoken_int (v : int) : csort -> unit printer                = ktoken Int (string_of_int v)
let ktoken_int_of_string (v : string) : csort -> unit printer   = ktoken Int v
let ktoken_float (v : float) : csort -> unit printer            = ktoken Float (string_of_float v)
let ktoken_float_of_string (v : string) : csort -> unit printer = ktoken Float v

let kapply (subsort : csort) (label : string) (contents : (unit printer) list) (sort : csort) : unit printer =
  if_kore
    (inject subsort sort (kapply_us label contents))
    (kapply_us label contents)

let kapply0 (subsort : csort) (label : string) : csort -> unit printer =
  kapply subsort label []

let kapply1 (subsort : csort) (label : string) (contents : unit printer) : csort -> unit printer =
  kapply subsort label [contents]

let list_of (f : 'a -> csort -> unit printer) (elems : 'a list) : csort -> unit printer =
  let op k l = kapply_us "_List_" [k; l] in
  let dot_list : unit printer = kapply0 KItem ".List" KItem in
  let items = List.map (fun x -> kapply1 KItem "ListItem" (f x KItem) KItem) elems in
  kapply1 StrictList "list" (List.fold_right op items dot_list)

(* This is where the recursive printer starts. *)

let cabs_loc a =
  let filename = if Filename.is_relative a.filename then Filename.concat (Sys.getcwd ()) a.filename else a.filename in
  kapply CabsLoc "CabsLoc"
    [ ktoken_string a.filename String
    ; ktoken_string filename String
    ; ktoken_int a.lineno Int
    ; ktoken_int a.lineOffsetStart Int
    ; ktoken_bool a.systemHeader Bool
    ]

let identifier = function
  | "" | "___missing_field_name" -> kapply0 CId "AnonymousName"
  | x                            -> kapply1 CId "Identifier" (ktoken_string x String)

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

let constant =
  let float_literal r =
    let split_significand significand = match Str.split_delim (Str.regexp "\.") significand with
        | [""; ""] -> ("0", "0")
        | [wp; ""] -> (wp, "0")
        | [""; fp] -> ("0", fp)
        | [wp; fp] -> (wp, fp)
        | [""]     -> ("0", "0")
        | [wp]     -> (wp, "0")
        | _        -> ("0", "0") in
    let hex_float_constant f =
      let [significand; exponentPart] = Str.split (Str.regexp "[pP]") f in
      let (wholePart, fractionalPart) = split_significand significand in
      let [exponentPart]              = Str.split (Str.regexp "[+]") exponentPart in
      let exponentPart                = int_of_string exponentPart in
      let significand                 = wholePart ^ "." ^ fractionalPart in
      let approx                      = (float_of_string ("0x" ^ significand)) *. (2. ** (float_of_int exponentPart)) in
      kapply FloatConstant "HexFloatConstant"
        [ ktoken_string significand String
        ; ktoken_int exponentPart Int
        ; ktoken_float approx Float
        ] in
    let dec_float_constant f =
      let (significand, exponentPart) = match Str.split (Str.regexp "[eE]") f with
        | [x]    -> (x, "0")
        | [x; y] -> (x, y) in
      let (wholePart, fractionalPart) = split_significand significand in
      let stringRep                   = wholePart ^ "." ^ fractionalPart ^ "e" ^ exponentPart in
      let [exponentPart]              = Str.split (Str.regexp "[+]") exponentPart in
      let exponentPart                = int_of_string exponentPart in
      let significand                 = wholePart ^ "." ^ fractionalPart in
      kapply FloatConstant "DecimalFloatConstant"
        [ ktoken_string significand String
        ; ktoken_int exponentPart Int
        ; ktoken_float_of_string stringRep Float
        ] in
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
      | ["F"] -> kapply1 Constant "LitF" (num Constant)
      | ["L"] -> kapply1 Constant "LitL" (num Constant)
      | []    -> kapply1 Constant "NoSuffix" (num Constant) in
  let int_literal i =
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
      | ("0x", _) | ("0X", _) -> kapply IntConstant "HexConstant" [ktoken_string (Str.string_after i 2) String]
      | (_, "0")              -> kapply IntConstant "OctalConstant" [ktoken_int_of_string (Str.string_after i 1) Int]
      | _                     -> kapply IntConstant "DecimalConstant" [ktoken_int_of_string i Int] in
    match tag with
      | ["U"; "L"; "L"] | ["L"; "L"; "U"] -> kapply1 Constant "LitULL" (num Constant)
      | ["L"; "L"]                        -> kapply1 Constant "LitLL" (num Constant)
      | ["U"; "L"] | ["L"; "U"]           -> kapply1 Constant "LitUL" (num Constant)
      | ["U"]                             -> kapply1 Constant "LitU" (num Constant)
      | ["L"]                             -> kapply1 Constant "LitL" (num Constant)
      | []                                -> kapply1 Constant "NoSuffix" (num Constant) in
  function
    | CONST_INT i      -> int_literal i
    | CONST_FLOAT r    -> float_literal r
    | CONST_CHAR c     -> kapply Constant "CharLiteral" [ktoken_int (interpret_character_constant c) Int]
    | CONST_WCHAR c    -> kapply Constant "WCharLiteral" [ktoken_int (interpret_wcharacter_constant c) Int]
    | CONST_STRING s   -> save_string_literal (kapply1 StringLiteral "StringLiteral" (ktoken_string s String))
    | CONST_WSTRING ws -> save_string_literal (kapply1 StringLiteral "WStringLiteral" (list_of (fun x -> ktoken_int (Int64.to_int x)) ws StrictList))

let rec specifier_elem : Cabs.spec_elem -> csort -> unit printer = function
  | SpecTypedef      -> kapply0 SpecifierElem "SpecTypedef"
  | SpecMissingType  -> kapply0 SpecifierElem "MissingType"
  | SpecCV cv        -> (match cv with
    | CV_CONST                       -> kapply0 Qualifier "Const"
    | CV_VOLATILE                    -> kapply0 Qualifier "Volatile"
    | CV_ATOMIC                      -> kapply0 Qualifier "Atomic"
    | CV_RESTRICT                    -> kapply0 Qualifier "Restrict"
    | CV_RESTRICT_RESERVED (kwd,loc) -> kapply Qualifier "RestrictReserved" [ktoken_string kwd String; cabs_loc loc CabsLoc])
  | SpecAttr (a, b)  -> kapply KItem "Attribute" [ktoken_string a String; list_of expression b StrictList]
  | SpecStorage sto  -> (match sto with
    | NO_STORAGE                     -> kapply0 StorageClassSpecifier "NoStorage"
    | THREAD_LOCAL                   -> kapply0 StorageClassSpecifier "ThreadLocal"
    | AUTO                           -> kapply0 AutoSpecifier "Auto"
    | STATIC                         -> kapply0 StorageClassSpecifier "Static"
    | EXTERN                         -> kapply0 StorageClassSpecifier "Extern"
    | REGISTER                       -> kapply0 StorageClassSpecifier "Register")
  | SpecInline       -> kapply0 FunctionSpecifier "Inline"
  | SpecNoReturn     -> kapply0 FunctionSpecifier "Noreturn"
  | SpecAlignment a  -> (match a with
    | EXPR_ALIGNAS e                 -> kapply SpecifierElem "AlignasExpression" [expression e KItem]
    | TYPE_ALIGNAS (s, d)            -> kapply SpecifierElem "AlignasType" [specifier s KItem; decl_type d KItem])
  | SpecType bt      -> type_spec bt
  | SpecPattern n    -> kapply SpecifierElem "SpecPattern" [identifier n CId]
and specifier a = kapply Specifier "Specifier" [list_of specifier_elem a StrictList]
and name (a, b, c, d) = kapply KItem "Name" [identifier a CId; decl_type b KItem; list_of specifier_elem c KItem]
and single_name (a, b) = kapply KItem "SingleName" [specifier a KItem; name b KItem]
and init_expression = function
  | NO_INIT         -> kapply0 NoInit "NoInit"
  | SINGLE_INIT exp -> kapply KItem "SingleInit" [expression exp KItem]
  | COMPOUND_INIT a -> kapply KItem "CompoundInit" [list_of init_fragment a StrictList]
and init_fragment (a, b) =
  let rec init_what = function
    | NEXT_INIT                      -> kapply0 KResult "NextInit"
    | INFIELD_INIT (id, what)        -> kapply KResult "InFieldInit" [identifier id CId; init_what what KItem]
    | ATINDEX_INIT (exp, what)       -> kapply KResult "AtIndexInit" [expression exp K; init_what what KItem]
    | ATINDEXRANGE_INIT (exp1, exp2) -> kapply KResult "AtIndexRangeInit" [expression exp1 KItem; expression exp2 KItem] in
  kapply KItem "InitFragment" [init_what a KItem; init_expression b KItem]
and block a sort = new_counter >>= fun blockNum ->
  kapply KItem "Block3" [ktoken_int blockNum Int; list_of ktoken_string a.blabels StrictList; list_of statement a.bstmts StrictList] sort

and decl_type = function
  | JUSTBASE            -> kapply0 KItem "JustBase"
  | PARENTYPE (a, b, c) -> kapply KItem "FunctionType" [decl_type b KItem]
  | ARRAY (a, b, c, d)  -> kapply KItem "ArrayType" [decl_type a KItem; expression c K; specifier (b@d) KItem]
  | PTR (a, b)          -> kapply KItem "PointerType" [specifier a Specifier; decl_type b KItem]
  | PROTO (a, b, c)     -> kapply KItem "Prototype" [decl_type a KItem; list_of single_name b StrictList; ktoken_bool c Bool]
  | NOPROTO (a, b, c)   -> kapply KItem "NoPrototype" [decl_type a KItem; list_of single_name b StrictList; ktoken_bool c Bool]

and expression =
  let generic_assoc = function
    | GENERIC_PAIR ((spec, declType), exp) -> kapply KItem "GenericPair" [specifier spec KItem; decl_type declType KItem; expression exp KItem]
    | GENERIC_DEFAULT exp                  -> kapply KItem "GenericDefault" [expression exp KItem] in
  let unary_expression op exp =
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
    kapply KItem (unary_operator op) [expression exp KItem] in
  let binary_expression op exp1 exp2 =
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
    kapply KItem (binary_operator op) [expression exp1 KItem; expression exp2 KItem] in
  function
    | OFFSETOF ((spec, declType), exp, loc)                      -> kapply KItem "OffsetOf" [specifier spec KItem; decl_type declType KItem; expression exp KItem]
    | TYPES_COMPAT ((spec1, declType1), (spec2, declType2), loc) -> kapply KItem "TypesCompat" [specifier spec1 KItem; decl_type declType1 KItem; specifier spec2 KItem; decl_type declType2 KItem]
    | GENERIC (exp, assocs)                                      -> kapply KItem "Generic" [expression exp K; list_of generic_assoc assocs StrictList]
    | LOCEXP (exp, loc)                                          -> expression exp
    | UNARY (op, exp1)                                           -> unary_expression op exp1
    | BINARY (op, exp1, exp2)                                    -> binary_expression op exp1 exp2
    | NOTHING                                                    -> kapply0 KItem "NothingExpression"
    | UNSPECIFIED                                                -> kapply0 RValue "UnspecifiedSizeExpression"
    | PAREN (exp1)                                               -> expression exp1
    | QUESTION (exp1, exp2, exp3)                                -> kapply KItem "Conditional" [expression exp1 KItem; expression exp2 KItem; expression exp3 KItem]
    (* Special case below for the compound literals. I don't know why this isn't in the ast... *)
    | CAST ((spec, declType), initExp)                           -> fun sort -> (new_counter >>= fun id -> match initExp with
        | NO_INIT         -> kapply1 KItem "Error" (puts "cast with a NO_INIT inside doesn't make sense") sort
        | SINGLE_INIT exp -> kapply KItem "Cast" [specifier spec K; decl_type declType KItem; expression exp K] sort
        | COMPOUND_INIT a -> kapply KItem "CompoundLiteral" [ktoken_int id Int; specifier spec KItem; decl_type declType KItem; kapply KItem "CompoundInit" [list_of init_fragment a StrictList] KItem] sort)
    | CALL (exp1, expList)                                       -> kapply KItem "Call" [expression exp1 KItem; list_of expression expList KItem]
    | COMMA expList                                              -> kapply KItem "Comma" [list_of expression expList StrictList]
    | CONSTANT (const)                                           -> kapply KItem "Constant" [constant const KItem]
    | VARIABLE name                                              -> identifier name
    | EXPR_SIZEOF exp                                            -> kapply KItem "SizeofExpression" [expression exp K]
    | TYPE_SIZEOF (spec, declType)                               -> kapply KItem "SizeofType" [specifier spec KItem; decl_type declType K]
    | EXPR_ALIGNOF exp                                           -> kapply KItem "AlignofExpression" [expression exp KItem]
    | TYPE_ALIGNOF (spec, declType)                              -> kapply KItem "AlignofType" [specifier spec KItem; decl_type declType KItem]
    | INDEX (exp, idx)                                           -> kapply KItem "ArrayIndex" [expression exp KItem; expression idx KItem]
    | MEMBEROF (exp, fld)                                        -> kapply KItem "Dot" [expression exp KItem; identifier fld CId]
    | MEMBEROFPTR (exp, fld)                                     -> kapply KItem "Arrow" [expression exp KItem; identifier fld CId]
    | GNU_BODY blk                                               -> kapply KItem "GnuBody" [block blk KItem]
    | BITMEMBEROF (exp, fld)                                     -> kapply KItem "DotBit" [expression exp KItem; identifier fld CId]
    | EXPR_PATTERN s                                             -> kapply KItem "ExpressionPattern" [ktoken_string s String]

and type_spec =
  let field (n, expOpt) = match expOpt with
    | None     -> kapply KItem "FieldName" [name n KItem]
    | Some exp -> kapply KItem "BitFieldName" [name n KItem; expression exp KItem] in
  let field_group (spec, fields) = kapply KItem "FieldGroup" [specifier spec KItem; list_of field fields StrictList] in
  let struct_type a c = function
    | None   -> kapply TypeSpecifier "StructRef" [identifier a CId; list_of specifier_elem c K]
    | Some b -> kapply TypeSpecifier "StructDef" [identifier a CId; list_of field_group b K; list_of specifier_elem c StrictList] in
  let union_type a c = function
    | None   -> kapply TypeSpecifier "UnionRef" [identifier a CId; list_of specifier_elem c K]
    | Some b -> kapply TypeSpecifier "UnionDef" [identifier a CId; list_of field_group b K; list_of specifier_elem c StrictList] in
  let enum_item (str, exp, _) = match exp with
    | NOTHING -> kapply KItem "EnumItem" [identifier str CId]
    | exp     -> kapply KItem "EnumItemInit" [identifier str CId; expression exp K] in
  let enum_type a c = function
    | None   -> kapply TypeSpecifier "EnumRef" [identifier a CId; list_of specifier_elem c K]
    | Some b -> kapply TypeSpecifier "EnumDef" [identifier a CId; list_of enum_item b K; list_of specifier_elem c StrictList] in
  function
    | Tvoid             -> kapply0 TypeSpecifier "Void"
    | Tchar             -> kapply0 TypeSpecifier "Char"
    | Tbool             -> kapply0 TypeSpecifier "Bool"
    | Tshort            -> kapply0 TypeSpecifier "Short"
    | Tint              -> kapply0 TypeSpecifier "Int"
    | Tlong             -> kapply0 TypeSpecifier "Long"
    | ToversizedInt     -> kapply0 TypeSpecifier "OversizedInt"
    | Tfloat            -> kapply0 TypeSpecifier "Float"
    | Tdouble           -> kapply0 TypeSpecifier "Double"
    | ToversizedFloat   -> kapply0 TypeSpecifier "OversizedFloat"
    | Tsigned           -> kapply0 TypeSpecifier "Signed"
    | Tunsigned         -> kapply0 TypeSpecifier "Unsigned"
    | Tnamed s          -> kapply TypeSpecifier "Named" [identifier s CId]
    | Tstruct (a, b, c) -> struct_type a c b
    | Tunion (a, b, c)  -> union_type a c b
    | Tenum (a, b, c)   -> enum_type a c b
    | TtypeofE e        -> kapply SpecifierElem "TypeofExpression" [expression e KItem]
    | TtypeofT (s, d)   -> kapply SpecifierElem "TypeofType" [specifier s KItem; decl_type d KItem]
    | TautoType         -> kapply0 TypeSpecifier "AutoType"
    | Tcomplex          -> kapply0 TypeSpecifier "Complex"
    | Timaginary        -> kapply0 TypeSpecifier "Imaginary"
    | Tatomic (s, d)    -> kapply SpecifierElem "TAtomic" [specifier s KItem; decl_type d KItem]

and definition : definition -> csort -> unit printer =
  let definition_loc a l         = if l.lineno <> -10 then kapply KItem "DefinitionLoc" [a KItem; cabs_loc l CabsLoc] else a in
  let definition_loc_range a b c = kapply KItem "DefinitionLocRange" [a KItem; cabs_loc b CabsLoc; cabs_loc c CabsLoc] in
  let init_name (a, b)           = kapply KItem "InitName" [name a KItem; init_expression b K] in
  let init_name_group (a, b)     = kapply KItem "InitNameGroup" [specifier a KItem; list_of init_name b StrictList] in
  let name_group (a, b)          = kapply KItem "NameGroup" [specifier a KItem; list_of name b StrictList] in
  function
    | FUNDEF (a, b, c, d)     -> definition_loc_range (kapply KItem "FunctionDefinition" [single_name a KItem; block b KItem]) c d
    | DECDEF (a, b)           -> definition_loc (kapply KItem "DeclarationDefinition" [init_name_group a KItem]) b
    | TYPEDEF (a, b)          -> definition_loc (kapply KItem "Typedef" [name_group a KItem]) b
    | ONLYTYPEDEF (a, b)      -> definition_loc (kapply KItem "OnlyTypedef" [specifier a KItem]) b
    | GLOBASM (a, b)          -> definition_loc (kapply KItem "GlobAsm" [ktoken_string a String]) b
    | PRAGMA (a, b)           -> definition_loc (kapply KItem "Pragma" [expression a KItem]) b
    | LINKAGE (a, b, c)       -> definition_loc (kapply KItem "Linkage" [ktoken_string a String; list_of definition c StrictList]) b
    | STATIC_ASSERT (a, b, c) -> definition_loc (kapply KItem "StaticAssert" [expression a K; constant b KItem]) c

and statement =
  let block_statement blk = kapply KItem "BlockStatement" [block blk KItem] in
  let new_block_statement s = block_statement { blabels = []; battrs = []; bstmts = [s] } in
  let for_clause = function
    | FC_EXP exp1  -> kapply1 KItem "ForClauseExpression" (expression exp1 KItem)
    | FC_DECL dec1 -> definition dec1 in
  let statement_loc s l = kapply KItem "StatementLoc" [s KItem; cabs_loc l CabsLoc] in
  let for_statement fc1 exp2 exp3 stat sort = new_counter >>= fun counter ->
    kapply KItem "For5" [ktoken_int counter Int; for_clause fc1 KItem; expression exp2 K; expression exp3 K; new_block_statement stat K] sort in
  let switch exp stat sort = push_switch >>= fun id ->
    kapply KItem "Switch" [ktoken_int id Int; expression exp K; new_block_statement stat K] sort
    >> pop_switch in
  let case exp stat sort = current_switch >>= fun switch_id -> new_counter >>= fun case_id ->
    kapply KItem "Case" [ktoken_int switch_id Int; ktoken_int case_id Int; expression exp K; statement stat K] sort in
  let default stat sort = current_switch >>= fun switch_id ->
    kapply KItem "Default" [ktoken_int switch_id Int; statement stat K] sort in
  function
    | NOP loc                           -> statement_loc (kapply0 KItem "Nop") loc
    | COMPUTATION (exp, loc)            -> statement_loc (kapply KItem "Computation" [expression exp K]) loc
    | BLOCK (blk, loc)                  -> statement_loc (block_statement blk) loc
    | IF (exp, s1, s2, loc)             -> statement_loc (kapply KItem "IfThenElse" [expression exp K; new_block_statement s1 K; new_block_statement s2 K]) loc
    | WHILE (exp, stat, loc)            -> statement_loc (kapply KItem "While" [expression exp K; new_block_statement stat K]) loc
    | DOWHILE (exp, stat, loc, wloc)    -> statement_loc (kapply KItem "DoWhile3" [expression exp K; new_block_statement stat KItem; cabs_loc wloc CabsLoc]) loc
    | FOR (fc1, exp2, exp3, stat, loc)  -> statement_loc (for_statement fc1 exp2 exp3 stat) loc
    | BREAK loc                         -> statement_loc (kapply0 KItem "Break") loc
    | CONTINUE loc                      -> statement_loc (kapply0 KItem "Continue") loc
    | RETURN (exp, loc)                 -> statement_loc (kapply KItem "Return" [expression exp K]) loc
    | SWITCH (exp, stat, loc)           -> statement_loc (switch exp stat) loc
    | CASE (exp, stat, loc)             -> statement_loc (case exp stat) loc
    | CASERANGE (exp1, exp2, stat, loc) -> statement_loc (kapply KItem "CaseRange" [expression exp1 KItem; expression exp2 KItem; statement stat KItem]) loc (* GCC's extension *)
    | DEFAULT (stat, loc)               -> statement_loc (default stat) loc
    | LABEL (str, stat, loc)            -> statement_loc (kapply KItem "Label" [identifier str CId; statement stat K]) loc
    | GOTO (name, loc)                  -> statement_loc (kapply KItem "Goto" [identifier name CId]) loc
    | COMPGOTO (exp, loc)               -> statement_loc (kapply KItem "CompGoto" [expression exp KItem]) loc (* GCC's "goto *exp" *)
    | DEFINITION d                      -> definition d
    | _                                 -> kapply0 KItem "OtherStatement"

let translation_unit (filename : string) (defs : definition list) (s : printer_state) =
  (* Finangling here to extract string literals. *)
  let (_, s_intr) = list_of definition defs StrictList s in
  let strings s   = get_string_literals >>= fun strings -> list_of (kapply1 KItem "Constant") strings s in
  let ast         = fun s -> (Buffer.add_buffer s.buffer s_intr.buffer; ((), s)) in
  kapply KItem "TranslationUnit" [ktoken_string filename String; strings StrictList; ast] KItem {s_intr with buffer = Buffer.create 100}

let cabs_to_kast (defs : definition list) (filename : string) : Buffer.t =
  let (_, final_state) = translation_unit filename defs init_state in
  Buffer.add_char final_state.buffer '\n'; final_state.buffer

let cabs_to_kore (defs : definition list) (filename : string) : Buffer.t =
  let (_, final_state) = translation_unit filename defs {init_state with kore = true} in
  Buffer.add_char final_state.buffer '\n'; final_state.buffer
