/*(*
 *
 * Copyright (c) 2001-2003,
 *  George C. Necula    <necula@cs.berkeley.edu>
 *  Scott McPeak        <smcpeak@cs.berkeley.edu>
 *  Wes Weimer          <weimer@cs.berkeley.edu>
 *  Ben Liblit          <liblit@cs.berkeley.edu>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. The names of the contributors may not be used to endorse or promote
 * products derived from this software without specific prior written
 * permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **)
(**
** 1.0	3.22.99	Hugues Cass�	First version.
** 2.0  George Necula 12/12/00: Practically complete rewrite.
*)
*/
%{
open Cabs
open Cabshelper
module E = Errormsg

let parse_error msg : unit =       (* sm: c++-mode highlight hack: -> ' <- *)
  E.parse_error msg
let parse_warn msg : unit =       (* sm: c++-mode highlight hack: -> ' <- *)
  E.parse_warn msg

let print = print_string

(* unit -> string option *)
(*
let getComments () =
  match !comments with
    [] -> None
  | _ ->
      let r = Some(String.concat "\n" (List.rev !comments)) in
      comments := [];
      r
*)

let cabslu = {lineno = -10;
	      filename = "cabs loc unknown";
	      byteno = -10;
              ident = 0;
			  lineOffsetStart = 0;
			  systemHeader = false;
			  }

(* cabsloc -> cabsloc *)
(*
let handleLoc l =
  l.clcomment <- getComments();
  l
*)

(*
** Expression building
*)
let smooth_expression lst =
  match lst with
    [] -> NOTHING
  | [expr] -> expr
  | _ -> COMMA (lst)


let currentFunctionName = ref "<outside any function>"

let announceFunctionName ((n, decl, _, _):name) =
  !Lexerhack.add_identifier n;
  (* Start a context that includes the parameter names and the whole body.
   * Will pop when we finish parsing the function body *)
  !Lexerhack.push_context ();
  (* Go through all the parameter names and mark them as identifiers *)
  let rec findProto = function
      PROTO (d, args, _) when isJUSTBASE d ->
        List.iter (fun (_, (an, _, _, _)) -> !Lexerhack.add_identifier an) args
    | PROTO (d, _, _) -> findProto d
    | NOPROTO (d, args, _) when isJUSTBASE d ->
        List.iter (fun (_, (an, _, _, _)) -> !Lexerhack.add_identifier an) args
    | NOPROTO (d, _, _) -> findProto d
    | PARENTYPE (_, d, _) -> findProto d
    | PTR (_, d) -> findProto d
    | ARRAY (d, _, _, _) -> findProto d
    | _ -> parse_error "Cannot find the prototype in a function definition";
           raise Parsing.Parse_error

  and isJUSTBASE = function
      JUSTBASE -> true
    | PARENTYPE (_, d, _) -> isJUSTBASE d
    | _ -> false
  in
  findProto decl;
  currentFunctionName := n



let applyPointer (ptspecs: attribute list list) (dt: decl_type)
       : decl_type =
  (* Outer specification first *)
  let rec loop = function
      [] -> dt
    | attrs :: rest -> PTR(attrs, loop rest)
  in
  loop ptspecs

let doDeclaration (loc: cabsloc) (specs: spec_elem list) (nl: init_name list) : definition =
  if isTypedef specs then begin
    (* Tell the lexer about the new type names *)
    List.iter (fun ((n, _, _, _), _) -> !Lexerhack.add_type n) nl;
    TYPEDEF ((specs, List.map (fun (n, _) -> n) nl), loc)
  end else
    if nl = [] then
      ONLYTYPEDEF (specs, loc)
    else begin
      (* Tell the lexer about the new variable names *)
      List.iter (fun ((n, _, _, _), _) -> !Lexerhack.add_identifier n) nl;
      DECDEF ((specs, nl), loc)
    end


let doFunctionDef (loc: cabsloc)
                  (lend: cabsloc)
                  (specs: spec_elem list)
                  (n: name)
                  (b: block) : definition =
  let fname = (specs, n) in
  FUNDEF (fname, b, loc, lend)


(* TODO(chathhorn): damnit, parser trying to be clever here. *)
let doOldParDecl (names: string list)
                 ((pardefs: name_group list), (isva: bool))
    : single_name list * bool =
  let findOneName n =
    (* Search in pardefs for the definition for this parameter *)
    let rec loopGroups = function
        [] -> (*chathhorn: ([SpecType Timaginary], (n, JUSTBASE, [], cabslu))*)
            let msg = Printf.sprintf "undeclared identifier in parameter identifier list" in
            parse_error msg;
            raise Parsing.Parse_error
      | (specs, names) :: restgroups ->
          let rec loopNames = function
              [] -> loopGroups restgroups
            | ((n',_, _, _) as sn) :: _ when n' = n -> (specs, sn)
            | _ :: restnames -> loopNames restnames
          in
          loopNames names
    in
    loopGroups pardefs
  in
  let args = List.map findOneName names in
  (args, isva)

let checkConnective (s : string) : unit =
begin
  (* checking this means I could possibly have more connectives, with *)
  (* different meaning *)
  if (s <> "to") then (
    parse_error "transformer connective must be 'to'";
    raise Parsing.Parse_error
  )
  else ()
end

let int64_to_char value =
  if (compare value (Int64.of_int 255) > 0) || (compare value Int64.zero < 0) then
    begin
      let msg = Printf.sprintf "cparser:intlist_to_string: character 0x%Lx too big" value in
      parse_error msg;
      raise Parsing.Parse_error
    end
  else
    Char.chr (Int64.to_int value)

(* takes a not-nul-terminated list, and converts it to a string. *)
let rec intlist_to_string (str: int64 list):string =
  match str with
    [] -> ""  (* add nul-termination *)
  | value::rest ->
      let this_char = int64_to_char value in
      (String.make 1 this_char) ^ (intlist_to_string rest)

let fst3 (result, _, _) = result
let snd3 (_, result, _) = result
let trd3 (_, _, result) = result

%}

%token <string * Cabs.cabsloc> IDENT
%token <string * Cabs.cabsloc> QUALIFIER
%token <int64 list * Cabs.cabsloc> CST_CHAR
%token <int64 list * Cabs.cabsloc> CST_WCHAR
%token <string * Cabs.cabsloc> CST_INT
%token <string * Cabs.cabsloc> CST_FLOAT
%token <string * Cabs.cabsloc> NAMED_TYPE

/* Each character is its own list element, and the terminating nul is not
   included in this list. */
%token <int64 list * Cabs.cabsloc> CST_STRING
%token <int64 list * Cabs.cabsloc> CST_WSTRING

%token EOF
%token<Cabs.cabsloc> CHAR INT BOOL DOUBLE FLOAT OVERSIZED_FLOAT VOID
%token<Cabs.cabsloc> ANYTYPE
%token<Cabs.cabsloc> ENUM STRUCT TYPEDEF UNION
%token<Cabs.cabsloc> SIGNED UNSIGNED LONG SHORT OVERSIZED_INT
%token<Cabs.cabsloc> VOLATILE EXTERN STATIC CONST RESTRICT AUTO REGISTER
%token<string * Cabs.cabsloc> RESTRICT_RESERVED
%token<Cabs.cabsloc> THREAD

%token<Cabs.cabsloc> ALIGNAS ATOMIC COMPLEX GENERIC IMAGINARY NORETURN STATIC_ASSERT THREAD_LOCAL

%token<Cabs.cabsloc> SIZEOF ALIGNOF

%token EQ PLUS_EQ MINUS_EQ STAR_EQ SLASH_EQ PERCENT_EQ
%token AND_EQ PIPE_EQ CIRC_EQ INF_INF_EQ SUP_SUP_EQ
%token ARROW DOT

%token EQ_EQ EXCLAM_EQ INF SUP INF_EQ SUP_EQ
%token<Cabs.cabsloc> PLUS MINUS STAR
%token SLASH PERCENT
%token<Cabs.cabsloc> TILDE AND
%token PIPE CIRC
%token<Cabs.cabsloc> EXCLAM AND_AND
%token PIPE_PIPE
%token INF_INF SUP_SUP
%token<Cabs.cabsloc> PLUS_PLUS MINUS_MINUS

%token RPAREN
%token<Cabs.cabsloc> LPAREN RBRACE
%token<Cabs.cabsloc> LBRACE
%token LBRACKET RBRACKET
%token COLON
%token<Cabs.cabsloc> SEMICOLON
%token COMMA ELLIPSIS QUEST

%token<Cabs.cabsloc> BREAK CONTINUE GOTO RETURN
%token<Cabs.cabsloc> SWITCH CASE DEFAULT
%token<Cabs.cabsloc> WHILE DO FOR
%token<Cabs.cabsloc> IF TRY EXCEPT FINALLY
%token ELSE

%token<Cabs.cabsloc> ATTRIBUTE INLINE ASM KCC_TYPEOF FUNCTION__ PRETTY_FUNCTION__
%token LABEL__
%token<Cabs.cabsloc> ATTRIBUTE_USED
%token BLOCKATTRIBUTE
%token<Cabs.cabsloc> DECLSPEC
%token<string * Cabs.cabsloc> MSASM MSATTR
%token<string * Cabs.cabsloc> PRAGMA_LINE
%token<Cabs.cabsloc> PRAGMA
%token PRAGMA_EOL

%token<Cabs.cabsloc> BEGINANNOTATION ENDANNOTATION
%token<Cabs.cabsloc> PROPERTY
%token LTL ATOM LTL_BUILTIN_TOK
%token BACKTICK BACKSLASH

/* sm: cabs tree transformation specification keywords */
%token<Cabs.cabsloc> AT_TRANSFORM AT_TRANSFORMEXPR AT_SPECIFIER AT_EXPR
%token AT_NAME

%token<Cabs.cabsloc> KCC_OFFSETOF KCC_TYPES_COMPAT KCC_AUTO_TYPE

/* operator precedence */
%nonassoc 	IF
%nonassoc 	ELSE

%left	COMMA
%right	EQ PLUS_EQ MINUS_EQ STAR_EQ SLASH_EQ PERCENT_EQ
                AND_EQ PIPE_EQ CIRC_EQ INF_INF_EQ SUP_SUP_EQ
%right	QUEST COLON
%left	PIPE_PIPE
%left	AND_AND
%left	PIPE
%left 	CIRC
%left	AND
%left	EQ_EQ EXCLAM_EQ
%left	INF SUP INF_EQ SUP_EQ
%left	INF_INF SUP_SUP
%left	PLUS MINUS
%left	STAR SLASH PERCENT CONST RESTRICT RESTRICT_RESERVED
VOLATILE
%right	EXCLAM TILDE PLUS_PLUS MINUS_MINUS CAST RPAREN ADDROF SIZEOF ALIGNOF
%left 	LBRACKET
%left	DOT ARROW LPAREN LBRACE
%right  NAMED_TYPE     /* We'll use this to handle redefinitions of
                        * NAMED_TYPE as variables */
%left   IDENT

/* Non-terminals informations */
%start interpret file
%type <Cabs.definition list> file interpret globals

%type <Cabs.definition> global


%type <Cabs.attribute list> attributes attributes_with_asm asmattr
%type <Cabs.statement> statement
%type <Cabs.constant * cabsloc> constant
%type <string * cabsloc> string_constant
%type <Cabs.expression * cabsloc> expression
%type <Cabs.expression> opt_expression
%type <Cabs.init_expression> init_expression
%type <Cabs.expression list * cabsloc> comma_expression
%type <Cabs.expression list * cabsloc> paren_comma_expression
%type <Cabs.expression list> arguments
%type <Cabs.expression list> bracket_comma_expression
%type <int64 list Queue.t * cabsloc> string_list
%type <int64 list * cabsloc> wstring_list

%type <Cabs.initwhat * Cabs.init_expression> initializer
%type <(Cabs.initwhat * Cabs.init_expression) list> initializer_list
%type <Cabs.initwhat> init_designators init_designators_opt

%type <spec_elem list * cabsloc> decl_spec_list
%type <typeSpecifier * cabsloc> type_spec
%type <Cabs.field_group list> struct_decl_list


%type <Cabs.name> old_proto_decl
%type <Cabs.single_name> parameter_decl
%type <Cabs.enum_item> enumerator
%type <Cabs.enum_item list> enum_list
%type <Cabs.definition> declaration function_def
%type <cabsloc * spec_elem list * name> function_def_start
%type <Cabs.spec_elem list * Cabs.decl_type> type_name
%type <Cabs.block * cabsloc * cabsloc> block
%type <Cabs.statement list> block_element_list
%type <string list> local_labels local_label_names
%type <string list> old_parameter_list_ne

%type <Cabs.init_name> init_declarator
%type <Cabs.init_name list> init_declarator_list
%type <Cabs.name> declarator
%type <Cabs.name * expression option> field_decl
%type <(Cabs.name * expression option) list> field_decl_list
%type <string * Cabs.decl_type> direct_decl
%type <Cabs.decl_type> abs_direct_decl abs_direct_decl_opt
%type <Cabs.decl_type * Cabs.attribute list> abstract_decl

 /* (* Each element is a "* <type_quals_opt>". *) */
%type <attribute list list * cabsloc> pointer pointer_opt
%type <Cabs.cabsloc> location
%type <Cabs.spec_elem * cabsloc> cvspec
%%

interpret:
  file EOF				{$1}
;
file: globals				{$1}
;
globals:
  /* empty */                           { [] }
| global globals                        { $1 :: $2 }
| SEMICOLON globals                     { $2 }
;

location:
   /* empty */                	{ currentLoc () }  %prec IDENT


/*** Global Definition ***/
global:
| declaration                           { $1 }
| function_def                          { $1 }
/*(* Some C header files are shared with the C++ compiler and have linkage
   * specification *)*/
| EXTERN string_constant declaration    { LINKAGE (fst $2, (*handleLoc*) (snd $2), [ $3 ]) }
| EXTERN string_constant LBRACE globals RBRACE
                                        { LINKAGE (fst $2, (*handleLoc*) (snd $2), $4)  }
| ASM LPAREN string_constant RPAREN SEMICOLON
                                        { GLOBASM (fst $3, (*handleLoc*) $1) }
| pragma                                { $1 }

/* transformer for a toplevel construct */
| AT_TRANSFORM LBRACE global RBRACE  IDENT/*to*/  LBRACE globals RBRACE {
    checkConnective(fst $5);
    TRANSFORMER($3, $7, $1)
  }
/* transformer for an expression */
| AT_TRANSFORMEXPR LBRACE expression RBRACE  IDENT/*to*/  LBRACE expression RBRACE {
    checkConnective(fst $5);
    EXPRTRANSFORMER(fst $3, fst $7, $1)
  }
| location error SEMICOLON { PRAGMA (VARIABLE "parse_error", $1) }
;

id_or_typename:
    IDENT				{fst $1}
|   NAMED_TYPE				{fst $1}
|   AT_NAME LPAREN IDENT RPAREN         { "@name(" ^ fst $3 ^ ")" }     /* pattern variable name */
;

maybecomma:
   /* empty */                          { () }
|  COMMA                                { () }
;

/* *** Expressions *** */

primary_expression:                     /*(* 6.5.1. *)*/
|		IDENT
				/* { VARIABLE (fst $1) } */
		        /* {LOCEXP ((VARIABLE (fst $1)), (snd $1)) } */
		        {LOCEXP (VARIABLE (fst $1), snd $1), snd $1 }
|        	constant
		        {LOCEXP (CONSTANT (fst $1), snd $1), snd $1 }
|		paren_comma_expression
		        {PAREN (smooth_expression (fst $1)), snd $1}
|		LPAREN block RPAREN
		        { GNU_BODY (fst3 $2), $1 }
|		IDENT bit_number
		        {let id = LOCEXP (VARIABLE (fst $1), snd $1), snd $1 in
                         BITMEMBEROF (fst id, $2), snd id}

     /*(* Next is Scott's transformer *)*/
|               AT_EXPR LPAREN IDENT RPAREN         /* expression pattern variable */
                         { EXPR_PATTERN(fst $3), $1 }
|		generic_selection { $1 }
;

postfix_expression:                     /*(* 6.5.2 *)*/
|               primary_expression
                        { $1 }
|		postfix_expression bracket_comma_expression
			{INDEX (fst $1, smooth_expression $2), snd $1}
|		postfix_expression LPAREN arguments RPAREN
			{CALL (fst $1, $3), snd $1}
|		postfix_expression DOT id_or_typename
		        {MEMBEROF (fst $1, $3), snd $1}
|		postfix_expression ARROW id_or_typename
		        {MEMBEROFPTR (fst $1, $3), snd $1}
|		postfix_expression PLUS_PLUS
		        {UNARY (POSINCR, fst $1), snd $1}
|		postfix_expression MINUS_MINUS
		        {UNARY (POSDECR, fst $1), snd $1}
/* (* We handle GCC constructor expressions *) */
|		LPAREN type_name RPAREN LBRACE initializer_list_opt RBRACE
		        { CAST($2, COMPOUND_INIT $5), $1 }
|		KCC_OFFSETOF LPAREN type_name COMMA offsetof_member_designator RPAREN
		        { OFFSETOF ($3, $5, $1), $1 }
|		KCC_TYPES_COMPAT LPAREN type_name COMMA type_name RPAREN
		        { TYPES_COMPAT ($3, $5, $1), $1 }
;

bit_number: /* Renesas extension for x.0 */
|		CST_FLOAT
		        { String.sub (fst $1) 1 (String.length (fst $1) - 1) }

offsetof_member_designator:	/* GCC extension for __builtin_offsetof */
|		id_or_typename
		        { VARIABLE ($1) }
|		offsetof_member_designator DOT IDENT
			{ MEMBEROF ($1, fst $3) }
|		offsetof_member_designator ARROW IDENT
		        { MEMBEROFPTR ($1, fst $3) }
|		offsetof_member_designator bracket_comma_expression
			{ INDEX ($1, smooth_expression $2) }
;

unary_expression:   /*(* 6.5.3 *)*/
|               postfix_expression
                        { $1 }
|		PLUS_PLUS unary_expression
		        {UNARY (PREINCR, fst $2), $1}
|		MINUS_MINUS unary_expression
		        {UNARY (PREDECR, fst $2), $1}
|		SIZEOF unary_expression
		        {EXPR_SIZEOF (fst $2), $1}
|	 	SIZEOF LPAREN type_name RPAREN
		        {let b, d = $3 in TYPE_SIZEOF (b, d), $1}
|		ALIGNOF unary_expression
		        {EXPR_ALIGNOF (fst $2), $1}
|	 	ALIGNOF LPAREN type_name RPAREN
		        {let b, d = $3 in TYPE_ALIGNOF (b, d), $1}
|		PLUS cast_expression
		        {UNARY (PLUS, fst $2), $1}
|		MINUS cast_expression
		        {UNARY (MINUS, fst $2), $1}
|		STAR cast_expression
		        {UNARY (MEMOF, fst $2), $1}
|		AND cast_expression				
		        {UNARY (ADDROF, fst $2), $1}
|		EXCLAM cast_expression
		        {UNARY (NOT, fst $2), $1}
|		TILDE cast_expression
		        {UNARY (BNOT, fst $2), $1}
|               AND_AND IDENT  { LABELADDR (fst $2), $1 }
;

cast_expression:   /*(* 6.5.4 *)*/
|              unary_expression
                         { $1 }
|		LPAREN type_name RPAREN cast_expression
		         { CAST($2, SINGLE_INIT (fst $4)), $1 }
;

multiplicative_expression:  /*(* 6.5.5 *)*/
|               cast_expression
                         { $1 }
|		multiplicative_expression STAR cast_expression
			{BINARY(MUL, fst $1, fst $3), snd $1}
|		multiplicative_expression SLASH cast_expression
			{BINARY(DIV, fst $1, fst $3), snd $1}
|		multiplicative_expression PERCENT cast_expression
			{BINARY(MOD, fst $1, fst $3), snd $1}
;

additive_expression:  /*(* 6.5.6 *)*/
|               multiplicative_expression
                        { $1 }
|		additive_expression PLUS multiplicative_expression
			{BINARY(ADD, fst $1, fst $3), snd $1}
|		additive_expression MINUS multiplicative_expression
			{BINARY(SUB, fst $1, fst $3), snd $1}
;

shift_expression:      /*(* 6.5.7 *)*/
|               additive_expression
                         { $1 }
|		shift_expression  INF_INF additive_expression
			{BINARY(SHL, fst $1, fst $3), snd $1}
|		shift_expression  SUP_SUP additive_expression
			{BINARY(SHR, fst $1, fst $3), snd $1}
;


relational_expression:   /*(* 6.5.8 *)*/
|               shift_expression
                        { $1 }
|		relational_expression INF shift_expression
			{BINARY(LT, fst $1, fst $3), snd $1}
|		relational_expression SUP shift_expression
			{BINARY(GT, fst $1, fst $3), snd $1}
|		relational_expression INF_EQ shift_expression
			{BINARY(LE, fst $1, fst $3), snd $1}
|		relational_expression SUP_EQ shift_expression
			{BINARY(GE, fst $1, fst $3), snd $1}
;

equality_expression:   /*(* 6.5.9 *)*/
|              relational_expression
                        { $1 }
|		equality_expression EQ_EQ relational_expression
			{BINARY(EQ, fst $1, fst $3), snd $1}
|		equality_expression EXCLAM_EQ relational_expression
			{BINARY(NE, fst $1, fst $3), snd $1}
;


bitwise_and_expression:   /*(* 6.5.10 *)*/
|               equality_expression
                       { $1 }
|		bitwise_and_expression AND equality_expression
			{BINARY(BAND, fst $1, fst $3), snd $1}
;

bitwise_xor_expression:   /*(* 6.5.11 *)*/
|               bitwise_and_expression
                       { $1 }
|		bitwise_xor_expression CIRC bitwise_and_expression
			{BINARY(XOR, fst $1, fst $3), snd $1}
;

bitwise_or_expression:   /*(* 6.5.12 *)*/
|               bitwise_xor_expression
                        { $1 }
|		bitwise_or_expression PIPE bitwise_xor_expression
			{BINARY(BOR, fst $1, fst $3), snd $1}
;

logical_and_expression:   /*(* 6.5.13 *)*/
|               bitwise_or_expression
                        { $1 }
|		logical_and_expression AND_AND bitwise_or_expression
			{BINARY(AND, fst $1, fst $3), snd $1}
;

logical_or_expression:   /*(* 6.5.14 *)*/
|               logical_and_expression
                        { $1 }
|		logical_or_expression PIPE_PIPE logical_and_expression
			{BINARY(OR, fst $1, fst $3), snd $1}
;

conditional_expression:    /*(* 6.5.15 *)*/
|               logical_or_expression
                         { $1 }
|		logical_or_expression QUEST opt_expression COLON conditional_expression
			{QUESTION (fst $1, $3, fst $5), snd $1}
;

/*(* The C spec says that left-hand sides of assignment expressions are unary
 * expressions. GCC allows cast expressions in there ! *)*/

assignment_expression:     /*(* 6.5.16 *)*/
|               conditional_expression
                         { $1 }
|		cast_expression EQ assignment_expression
			{BINARY(ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression PLUS_EQ assignment_expression
			{BINARY(ADD_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression MINUS_EQ assignment_expression
			{BINARY(SUB_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression STAR_EQ assignment_expression
			{BINARY(MUL_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression SLASH_EQ assignment_expression
			{BINARY(DIV_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression PERCENT_EQ assignment_expression
			{BINARY(MOD_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression AND_EQ assignment_expression
			{BINARY(BAND_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression PIPE_EQ assignment_expression
			{BINARY(BOR_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression CIRC_EQ assignment_expression
			{BINARY(XOR_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression INF_INF_EQ assignment_expression	
			{BINARY(SHL_ASSIGN, fst $1, fst $3), snd $1}
|		cast_expression SUP_SUP_EQ assignment_expression
			{BINARY(SHR_ASSIGN, fst $1, fst $3), snd $1}
;

expression:           /*(* 6.5.17 *)*/
                assignment_expression
                        { $1 }
;

constant:
    CST_INT				{CONST_INT (fst $1), snd $1}
|   CST_FLOAT				{CONST_FLOAT (fst $1), snd $1}
|   CST_CHAR				{CONST_CHAR (fst $1), snd $1}
|   CST_WCHAR				{CONST_WCHAR (fst $1), snd $1}
|   string_constant		        {CONST_STRING (fst $1), snd $1}
|   wstring_list			{CONST_WSTRING (fst $1), snd $1}
;

string_constant:
/* Now that we know this constant isn't part of a wstring, convert it
   back to a string for easy viewing. */
    string_list                         {
     let queue, location = $1 in
     let buffer = Buffer.create (Queue.length queue) in
     Queue.iter
       (List.iter
	  (fun value ->
	    let char = int64_to_char value in
	    Buffer.add_char buffer char))
       queue;
     Buffer.contents buffer, location
   }
;
one_string_constant:
/* Don't concat multiple strings.  For asm templates. */
    CST_STRING                          {intlist_to_string (fst $1) }
;
string_list:
    one_string                          {
      let queue = Queue.create () in
      Queue.add (fst $1) queue;
      queue, snd $1
    }
|   string_list one_string              {
      Queue.add (fst $2) (fst $1);
      $1
    }
;

wstring_list:
    CST_WSTRING                         { $1 }
|   wstring_list one_string             { (fst $1) @ (fst $2), snd $1 }
|   wstring_list CST_WSTRING            { (fst $1) @ (fst $2), snd $1 }
/* Only the first string in the list needs an L, so L"a" "b" is the same
 * as L"ab" or L"a" L"b". */

one_string:
    CST_STRING				{$1}
|   FUNCTION__                          {(Cabshelper.explodeStringToInts
					    !currentFunctionName), $1}
|   PRETTY_FUNCTION__                   {(Cabshelper.explodeStringToInts
					    !currentFunctionName), $1}
;

init_expression:
     expression         { SINGLE_INIT (fst $1) }
|    LBRACE initializer_list_opt RBRACE
			{ COMPOUND_INIT $2}

initializer_list:    /* ISO 6.7.8. Allow a trailing COMMA */
    initializer                             { [$1] }
|   initializer COMMA initializer_list_opt  { $1 :: $3 }
;
initializer_list_opt:
    /* empty */                             { [] }
|   initializer_list                        { $1 }
;
initializer:
    init_designators eq_opt init_expression { ($1, $3) }
|   gcc_init_designators init_expression { ($1, $2) }
|                       init_expression { (NEXT_INIT, $1) }
;
eq_opt:
   EQ                        { () }
   /*(* GCC allows missing = *)*/
|  /*(* empty *)*/               { () }
;
init_designators:
    DOT id_or_typename init_designators_opt      { INFIELD_INIT($2, $3) }
|   LBRACKET  expression RBRACKET init_designators_opt
                                        { ATINDEX_INIT(fst $2, $4) }
|   LBRACKET  expression ELLIPSIS expression RBRACKET
                                        { ATINDEXRANGE_INIT(fst $2, fst $4) }
;
init_designators_opt:
   /* empty */                          { NEXT_INIT }
|  init_designators                     { $1 }
;

gcc_init_designators:  /*(* GCC supports these strange things *)*/
   id_or_typename COLON                 { INFIELD_INIT($1, NEXT_INIT) }
;

arguments:
                /* empty */         { [] }
|               comma_expression    { fst $1 }
;

opt_expression:
	        /* empty */
	        	{NOTHING}
|	        comma_expression
	        	{smooth_expression (fst $1)}
;

comma_expression:
	        expression                        {[fst $1], snd $1}
|               expression COMMA comma_expression { fst $1 :: fst $3, snd $1 }
|               error COMMA comma_expression      { $3 }
;

comma_expression_opt:
                /* empty */         { NOTHING }
|               comma_expression    { smooth_expression (fst $1) }
;

paren_comma_expression:
  LPAREN comma_expression RPAREN                   { $2 }
| LPAREN error RPAREN                              { [], $1 }
;

bracket_comma_expression:
  LBRACKET comma_expression RBRACKET                   { fst $2 }
| LBRACKET error RBRACKET                              { [] }
;


/*** statements ***/
block: /* ISO 6.8.2 */
    block_begin local_labels block_attrs block_element_list RBRACE
                                         {!Lexerhack.pop_context();
                                          { blabels = $2;
                                            battrs = $3;
                                            bstmts = $4 },
					    $1, $5
                                         }
|   error location RBRACE                { { blabels = [];
                                             battrs  = [];
                                             bstmts  = [] },
					     $2, $3
                                         }
;
block_begin:
    LBRACE      		         {!Lexerhack.push_context (); $1}
;

block_attrs:
   /* empty */                                              { [] }
|  BLOCKATTRIBUTE paren_attr_list_ne
                                        { [SpecAttr ("__blockattribute__", $2)] }
;

/* statements and declarations in a block, in any order (for C99 support) */
block_element_list:
    /* empty */                          { [] }
|   declaration block_element_list       { DEFINITION($1) :: $2 }
|   statement block_element_list         { $1 :: $2 }
/*(* GCC accepts a label at the end of a block *)*/
|   IDENT COLON	                         { [ LABEL (fst $1, NOP (snd $1),
                                                    snd $1)] }
|   pragma block_element_list            { $2 }
;

local_labels:
   /* empty */                                       { [] }
|  LABEL__ local_label_names SEMICOLON local_labels  { $2 @ $4 }
;
local_label_names:
   IDENT                                 { [ fst $1 ] }
|  IDENT COMMA local_label_names         { fst $1 :: $3 }
;



statement:
    SEMICOLON		{NOP ((*handleLoc*) $1) }
|   comma_expression SEMICOLON
	        	{COMPUTATION (smooth_expression (fst $1), (*handleLoc*)(snd $1))}
|   block               {BLOCK (fst3 $1, (*handleLoc*)(snd3 $1))}
|   IF paren_comma_expression statement                    %prec IF
                	{IF (smooth_expression (fst $2), $3, NOP $1, $1)}
|   IF paren_comma_expression statement ELSE statement
	                {IF (smooth_expression (fst $2), $3, $5, (*handleLoc*) $1)}
|   SWITCH paren_comma_expression statement
                        {SWITCH (smooth_expression (fst $2), $3, (*handleLoc*) $1)}
|   WHILE paren_comma_expression statement
	        	{WHILE (smooth_expression (fst $2), $3, (*handleLoc*) $1)}
|   DO statement WHILE paren_comma_expression SEMICOLON
	        	         {DOWHILE (smooth_expression (fst $4), $2, (*handleLoc*) $1, $3)}
|   FOR LPAREN for_clause opt_expression
	        SEMICOLON opt_expression RPAREN statement
	                         {FOR ($3, $4, $6, $8, (*handleLoc*) $1)}
|   IDENT COLON attribute_nocv_list statement
		                 {(* The only attribute that should appear here
                                     is "unused". For now, we drop this on the
                                     floor, since unused labels are usually
                                     removed anyways by Rmtmps. *)
                                  LABEL (fst $1, $4, (snd $1))}
|   CASE expression COLON statement
	                         {CASE (fst $2, $4, (*handleLoc*) $1)}
|   CASE expression ELLIPSIS expression COLON statement
	                         {CASERANGE (fst $2, fst $4, $6, (*handleLoc*) $1)}
|   DEFAULT COLON
	                         {DEFAULT (NOP $1, (*handleLoc*) $1)}
|   RETURN SEMICOLON		 {RETURN (NOTHING, (*handleLoc*) $1)}
|   RETURN comma_expression SEMICOLON
	                         {RETURN (smooth_expression (fst $2), (*handleLoc*) $1)}
|   BREAK SEMICOLON     {BREAK ((*handleLoc*) $1)}
|   CONTINUE SEMICOLON	 {CONTINUE ((*handleLoc*) $1)}
|   GOTO IDENT SEMICOLON
		                 {GOTO (fst $2, (*handleLoc*) $1)}
|   GOTO STAR comma_expression SEMICOLON
                                 { COMPGOTO (smooth_expression (fst $3), (*handleLoc*) $1) }
|   ASM asmattr LPAREN asmtemplate asmoutputs RPAREN SEMICOLON
                        { ASM ($2, $4, $5, (*handleLoc*) $1) }
|   MSASM               { ASM ([], [fst $1], None, (*handleLoc*)(snd $1))}
|   TRY block EXCEPT paren_comma_expression block
                        { let b, _, _ = $2 in
                          let h, _, _ = $5 in
                          if not !Cprint.msvcMode then
                            parse_error "try/except in GCC code";
                          TRY_EXCEPT (b, COMMA (fst $4), h, (*handleLoc*) $1) }
|   TRY block FINALLY block
                        { let b, _, _ = $2 in
                          let h, _, _ = $4 in
                          if not !Cprint.msvcMode then
                            parse_error "try/finally in GCC code";
                          TRY_FINALLY (b, h, (*handleLoc*) $1) }

|   error location   SEMICOLON   { (NOP $2)}
;


for_clause:
    opt_expression SEMICOLON     { FC_EXP $1 }
|   declaration                  { FC_DECL $1 }
;

declaration:                                /* ISO 6.7.*/
    decl_spec_list init_declarator_list SEMICOLON
                                       { doDeclaration ((*handleLoc*)(snd $1)) (fst $1) $2 }
|   decl_spec_list SEMICOLON
                                       { doDeclaration ((*handleLoc*)(snd $1)) (fst $1) [] }
| STATIC_ASSERT LPAREN expression COMMA string_constant RPAREN {STATIC_ASSERT ((fst $3), CONST_STRING (fst $5), (snd $3))};
;
init_declarator_list:                       /* ISO 6.7 */
    init_declarator                              { [$1] }
|   init_declarator COMMA init_declarator_list   { $1 :: $3 }

;
init_declarator:                             /* ISO 6.7 */
    declarator                          { ($1, NO_INIT) }
|   declarator EQ init_expression
                                        { ($1, $3) }
;

decl_spec_list:                         /* ISO 6.7 */
                                        /* ISO 6.7.1 */
|   TYPEDEF decl_spec_list_opt          { SpecTypedef :: $2, $1  }
|   EXTERN decl_spec_list_opt           { SpecStorage EXTERN :: $2, $1 }
|   STATIC  decl_spec_list_opt          { SpecStorage STATIC :: $2, $1 }
|   AUTO   decl_spec_list_opt           { SpecStorage AUTO :: $2, $1 }
|   REGISTER decl_spec_list_opt         { SpecStorage REGISTER :: $2, $1}
|   THREAD_LOCAL decl_spec_list_opt     { SpecStorage THREAD_LOCAL :: $2, $1 }
                                        /* ISO 6.7.2 */
|   type_spec decl_spec_list_opt_no_named { SpecType (fst $1) :: $2, snd $1 }
                                        /* ISO 6.7.4 */
|   INLINE decl_spec_list_opt           { SpecInline :: $2, $1 }
|   NORETURN decl_spec_list_opt           { SpecNoReturn :: $2, $1 }
|   cvspec decl_spec_list_opt           { (fst $1) :: $2, snd $1 }
|   attribute_nocv decl_spec_list_opt   { (fst $1) :: $2, snd $1 }
/* specifier pattern variable (must be last in spec list) */
|   AT_SPECIFIER LPAREN IDENT RPAREN    { [ SpecPattern(fst $3) ], $1 }
|	alignment_specifier decl_spec_list_opt { SpecAlignment (fst $1) :: $2, snd $1 }
;
/* (* In most cases if we see a NAMED_TYPE we must shift it. Thus we declare
    * NAMED_TYPE to have right associativity  *) */
decl_spec_list_opt:
    /* empty */                         { [] } %prec NAMED_TYPE
|   decl_spec_list                      { fst $1 }
;
/* (* We add this separate rule to handle the special case when an appearance
    * of NAMED_TYPE should not be considered as part of the specifiers but as
    * part of the declarator. IDENT has higher precedence than NAMED_TYPE  *)
 */
decl_spec_list_opt_no_named:
    /* empty */                         { [] } %prec IDENT
|   decl_spec_list                      { fst $1 }
;
type_spec:   /* ISO 6.7.2 */
    VOID            { Tvoid, $1}
|   CHAR            { Tchar, $1 }
|   BOOL            { Tbool, $1 }
|   SHORT           { Tshort, $1 }
|   INT             { Tint, $1 }
|   LONG            { Tlong, $1 }
|   OVERSIZED_INT   { ToversizedInt, $1 }
|   FLOAT           { Tfloat, $1 }
|   DOUBLE          { Tdouble, $1 }
|   OVERSIZED_FLOAT { ToversizedFloat, $1 }
|   SIGNED          { Tsigned, $1 }
|   UNSIGNED        { Tunsigned, $1 }
|   STRUCT                 id_or_typename
                                                   { Tstruct ($2, None,    []), $1 }
|   STRUCT attribute_nocv_list id_or_typename
                                                   { Tstruct ($3, None,    $2), $1 }
|   STRUCT                 id_or_typename LBRACE struct_decl_list RBRACE
                                                   { Tstruct ($2, Some $4, []), $1 }
|   STRUCT                                LBRACE struct_decl_list RBRACE
                                                   { Tstruct ("", Some $3, []), $1 }
|   STRUCT attribute_nocv_list id_or_typename LBRACE struct_decl_list RBRACE
                                                   { Tstruct ($3, Some $5, $2), $1 }
|   STRUCT attribute_nocv_list                LBRACE struct_decl_list RBRACE
                                                   { Tstruct ("", Some $4, $2), $1 }
|   UNION                  id_or_typename
                                                   { Tunion  ($2, None,    []), $1 }
|   UNION                  id_or_typename LBRACE struct_decl_list RBRACE
                                                   { Tunion  ($2, Some $4, []), $1 }
|   UNION                                 LBRACE struct_decl_list RBRACE
                                                   { Tunion  ("", Some $3, []), $1 }
|   UNION  attribute_nocv_list id_or_typename LBRACE struct_decl_list RBRACE
                                                   { Tunion  ($3, Some $5, $2), $1 }
|   UNION  attribute_nocv_list                LBRACE struct_decl_list RBRACE
                                                   { Tunion  ("", Some $4, $2), $1 }
|   ENUM                   id_or_typename
                                                   { Tenum   ($2, None,    []), $1 }
|   ENUM                   id_or_typename LBRACE enum_list maybecomma RBRACE
                                                   { Tenum   ($2, Some $4, []), $1 }
|   ENUM                                  LBRACE enum_list maybecomma RBRACE
                                                   { Tenum   ("", Some $3, []), $1 }
|   ENUM   attribute_nocv_list id_or_typename LBRACE enum_list maybecomma RBRACE
                                                   { Tenum   ($3, Some $5, $2), $1 }
|   ENUM   attribute_nocv_list                LBRACE enum_list maybecomma RBRACE
                                                   { Tenum   ("", Some $4, $2), $1 }
|   NAMED_TYPE      { Tnamed (fst $1), snd $1 }
|   KCC_TYPEOF LPAREN expression RPAREN     { TtypeofE (fst $3), $1 }
|   KCC_TYPEOF LPAREN type_name RPAREN      { let s, d = $3 in
                                          TtypeofT (s, d), $1 }
|   KCC_AUTO_TYPE                       { TautoType, $1 }
|   COMPLEX        {
	parse_warn "Encountered _Complex type.  These are not yet supported, and are currently ignored.";
	Tcomplex, $1
}
|   IMAGINARY        {
	parse_warn "Encountered _Imaginary type.  These are not yet supported, and are currently ignored.";
	Timaginary, $1
}
/* shift reduce conflict with other ATOMIC */
|   ATOMIC LPAREN type_name RPAREN { let b, d = $3 in Tatomic (b, d), $1 }
;
/* parse_error "Struct declaration lists must contain at least one element."; raise Parsing.Parse_error */
struct_decl_list: /* (* ISO 6.7.2. Except that we allow empty structs. We
                      * also allow missing field names. *)
                   */
   /* empty */                           { [] }
|  decl_spec_list                 SEMICOLON struct_decl_list
                                         { (fst $1,
                                            [(missingFieldDecl, None)]) :: $3 }
/*(* GCC allows extra semicolons *)*/
|                                 SEMICOLON struct_decl_list
                                         { $2 }
|  decl_spec_list field_decl_list SEMICOLON struct_decl_list
                                          { (fst $1, $2)
                                            :: $4 }
/*(* MSVC allows pragmas in strange places *)*/
|  pragma struct_decl_list                { $2 }

|  error                          SEMICOLON struct_decl_list
                                          { $3 }
;
field_decl_list: /* (* ISO 6.7.2 *) */
    field_decl                           { [$1] }
|   field_decl COMMA field_decl_list     { $1 :: $3 }
;
field_decl: /* (* ISO 6.7.2. Except that we allow unnamed fields. *) */
|   declarator                      { ($1, None) }
|   declarator COLON expression attribute_nocv_list
                                    { let (n,decl,al,loc) = $1 in
                                      let al' = al @ $4 in
                                     ((n,decl,al',loc), Some (fst $3)) }
|              COLON expression     { (missingFieldDecl, Some (fst $2)) }
|              COLON expression attribute_nocv_list
                                    { (("___missing_field_name",JUSTBASE,$3,cabslu), Some (fst $2)) }
;

enum_list: /* (* ISO 6.7.2.2 *) */
    enumerator				{[$1]}
|   enum_list COMMA enumerator	        {$1 @ [$3]}
|   enum_list COMMA error               { $1 }
;
enumerator:	
    IDENT			{(fst $1, NOTHING, snd $1)}
|   IDENT EQ expression		{(fst $1, fst $3, snd $1)}
;


declarator:  /* (* ISO 6.7.5. Plus Microsoft declarators.*) */
   pointer_opt direct_decl attributes_with_asm
                               { let (n, decl) = $2 in
                                (n, applyPointer (fst $1) decl, $3, (snd $1)) }
;


direct_decl: /* (* ISO 6.7.5 *) */
                                   /* (* We want to be able to redefine named
                                    * types as variable names *) */
|   id_or_typename                 { ($1, JUSTBASE) }

|   LPAREN attributes declarator RPAREN
                                   { let (n,decl,al,loc) = $3 in
                                     (n, PARENTYPE($2,decl,al)) }

|   direct_decl LBRACKET array_insides RBRACKET
                                   { let (n, decl) = $1 in
										let (attrs, exp, qualifiers) = $3 in
                                     (n, ARRAY(decl, attrs, exp, qualifiers)) }

|   direct_decl parameter_list_startscope rest_par_list RPAREN
                                   { let (n, decl) = $1 in
                                     let (params, isva) = $3 in
                                     !Lexerhack.pop_context ();
                                     if params = [] then (n, NOPROTO(decl, [], false))
                                     else (n, PROTO(decl, params, isva))
                                   }
;
array_insides:
	| attributes comma_expression_opt	{ ($1, $2, []) }
	| attributes mycvspec_list comma_expression_opt	{ ($1, $3, $2) }
	| attributes STAR					{ ($1, UNSPECIFIED, []) } /* for [*] */
	| attributes error					{ ($1, NOTHING, []) }
;
mycvspec_list:
	| mycvspec { $1 :: [] }
	| mycvspec mycvspec_list { $1 :: $2 }

mycvspec:
	| STATIC { SpecStorage STATIC }
      | cvspec { fst $1 }
	
parameter_list_startscope:
    LPAREN                         { !Lexerhack.push_context () }
;
rest_par_list:
    /* empty */                    { ([], false) }
|   parameter_decl rest_par_list1  { let (params, isva) = $2 in
                                     ($1 :: params, isva)
                                   }
;
rest_par_list1:
    /* empty */                         { ([], false) }
|   COMMA ELLIPSIS                      { ([], true) }
|   COMMA parameter_decl rest_par_list1 { let (params, isva) = $3 in
                                          ($2 :: params, isva)
                                        }
;


parameter_decl: /* (* ISO 6.7.5 *) */
   decl_spec_list declarator              { (fst $1, $2) }
|  decl_spec_list abstract_decl           { let d, a = $2 in
                                            (fst $1, ("", d, a, cabslu)) }
|  decl_spec_list                         { (fst $1, ("", JUSTBASE, [], cabslu)) }
|  LPAREN parameter_decl RPAREN           { $2 }
;

/* (* Old style prototypes. Like a declarator *) */
old_proto_decl:
  pointer_opt direct_old_proto_decl   { let (n, decl, a) = $2 in
					  (n, applyPointer (fst $1) decl,
                                           a, snd $1)
                                      }

;

direct_old_proto_decl:
  direct_decl LPAREN old_parameter_list_ne RPAREN old_pardef_list
                                   { let par_decl, isva = doOldParDecl $3 $5 in
                                     let n, decl = $1 in
                                     (n, NOPROTO(decl, par_decl, isva), [])
                                   }
/* (* appears sometimes but generates a shift-reduce conflict. *)
| LPAREN STAR direct_decl LPAREN old_parameter_list_ne RPAREN RPAREN LPAREN RPAREN old_pardef_list
                                   { let par_decl, isva
                                             = doOldParDecl $5 $10 in
                                     let n, decl = $3 in
                                     (n, NOPROTO(decl, par_decl, isva), [])
                                   }
*/
;

old_parameter_list_ne:
|  IDENT                                       { [fst $1] }
|  IDENT COMMA old_parameter_list_ne           { let rest = $3 in
                                                 (fst $1 :: rest) }
;

old_pardef_list:
   /* empty */                            { ([], false) }
|  decl_spec_list old_pardef SEMICOLON ELLIPSIS
                                          { ([(fst $1, $2)], true) }
|  decl_spec_list old_pardef SEMICOLON old_pardef_list
                                          { let rest, isva = $4 in
                                            ((fst $1, $2) :: rest, isva)
                                          }
;

old_pardef:
   declarator                             { [$1] }
|  declarator COMMA old_pardef            { $1 :: $3 }
|  error                                  { [] }
;


pointer: /* (* ISO 6.7.5 *) */
   STAR attributes pointer_opt  { $2 :: fst $3, $1 }
;
pointer_opt:
   /**/                          { let l = currentLoc () in
                                   ([], l) }
|  pointer                       { $1 }
;

type_name: /* (* ISO 6.7.6 *) */
  decl_spec_list abstract_decl { let d, a = $2 in
                                 if a <> [] then begin
                                   parse_error "attributes in type name";
                                   raise Parsing.Parse_error
                                 end;
                                 (fst $1, d)
                               }
| decl_spec_list               { (fst $1, JUSTBASE) }
;
abstract_decl: /* (* ISO 6.7.6. *) */
  pointer_opt abs_direct_decl attributes  { applyPointer (fst $1) $2, $3 }
| pointer                                 { applyPointer (fst $1) JUSTBASE, [] }
;

abs_direct_decl: /* (* ISO 6.7.6. We do not support optional declarator for
                     * functions. Plus Microsoft attributes. See the
                     * discussion for declarator. *) */
|   LPAREN attributes abstract_decl RPAREN
                                   { let d, a = $3 in
                                     PARENTYPE ($2, d, a)
                                   }

|   LPAREN error RPAREN
                                   { JUSTBASE }

|   abs_direct_decl_opt LBRACKET comma_expression_opt RBRACKET
                                   { ARRAY($1, [], $3, []) }
/*(* The next should be abs_direct_decl_opt but we get conflicts *)*/
|   abs_direct_decl  parameter_list_startscope rest_par_list RPAREN
                                   { let (params, isva) = $3 in
                                     !Lexerhack.pop_context ();
                                     if params = [] then NOPROTO ($1, [], false)
                                     else PROTO ($1, params, isva)
                                   }
;
abs_direct_decl_opt:
    abs_direct_decl                 { $1 }
|   /* empty */                     { JUSTBASE }
;
function_def:  /* (* ISO 6.9.1 *) */
  function_def_start block
          { let (loc, specs, decl) = $1 in
            currentFunctionName := "<__FUNCTION__ used outside any functions>";
            !Lexerhack.pop_context (); (* The context pushed by
                                    * announceFunctionName *)
            doFunctionDef ((*handleLoc*) loc) (trd3 $2) specs decl (fst3 $2)
          }


function_def_start:  /* (* ISO 6.9.1 *) */
  decl_spec_list declarator
                            { announceFunctionName $2;
                              (snd $1, fst $1, $2)
                            }
| declarator
                            { announceFunctionName $1;
                              let (_, _, _, loc) = $1 in
                              (loc, (SpecMissingType :: []), $1)
                            }
/* (* Old-style function prototype *) */
| decl_spec_list old_proto_decl
                            { announceFunctionName $2;
                              (snd $1, fst $1, $2)
                            }
| old_proto_decl
                            { announceFunctionName $1;
                              let (_, _, _, loc) = $1 in
                              (loc, (SpecMissingType :: []), $1)
                            }
;

/* const/volatile as type specifier elements */
cvspec:
    CONST                               { SpecCV(CV_CONST), $1 }
|   RESTRICT                            { SpecCV(CV_RESTRICT), $1 }
|   RESTRICT_RESERVED                   { SpecCV(CV_RESTRICT_RESERVED $1), (snd $1) }
|   VOLATILE                            { SpecCV(CV_VOLATILE), $1 }
|   ATOMIC                              { SpecCV(CV_ATOMIC), $1 }
;

/*** GCC attributes ***/
attributes:
    /* empty */				{ []}
|   attribute attributes	        { fst $1 :: $2 }
;

/* (* In some contexts we can have an inline assembly to specify the name to
    * be used for a global. We treat this as a name attribute *) */
attributes_with_asm:
    /* empty */                         { [] }
|   attribute_nocv attributes_with_asm  { fst $1 :: $2 }
|   ASM LPAREN string_constant RPAREN attribute_nocv_list
                                        { SpecAttr ("__asm__", [CONSTANT(CONST_STRING (fst $3))]) :: $5 }
;

/* things like __attribute__, but no const/volatile */
attribute_nocv:
    ATTRIBUTE LPAREN paren_attr_list RPAREN
                                        { (SpecAttr ("__attribute__", $3)), $1 }
/*(*
|   ATTRIBUTE_USED                      { (SpecAttr ("__attribute__", [ VARIABLE "used" ])), $1 }
*)*/
|   DECLSPEC paren_attr_list_ne         { (SpecAttr ("__declspec", $2)), $1 }
|   MSATTR                              { (SpecAttr (fst $1, [])), snd $1 }
                                        /* ISO 6.7.3 */
|   THREAD                              { (SpecAttr ("__thread", [])), $1 }
|   QUALIFIER                           { (SpecAttr ("__attribute__", [VARIABLE(fst $1)])),snd $1 }
;

attribute_nocv_list:
    /* empty */				{ []}
|   attribute_nocv attribute_nocv_list  { fst $1 :: $2 }
;

/* __attribute__ plus const/volatile */
attribute:
    attribute_nocv         { (fst $1), (snd $1) }
|   CONST                  { SpecCV CV_CONST, $1 }
|   RESTRICT               { SpecCV CV_RESTRICT, $1 }
|   RESTRICT_RESERVED      { SpecCV (CV_RESTRICT_RESERVED $1), (snd $1) }
|   VOLATILE               { SpecCV CV_VOLATILE, $1 }
|   ATOMIC                 { SpecCV(CV_ATOMIC), $1 }
;

/** (* PRAGMAS and ATTRIBUTES *) ***/
pragma: 
| PRAGMA attr PRAGMA_EOL		{ PRAGMA ($2, $1) }
| PRAGMA attr SEMICOLON PRAGMA_EOL	{ PRAGMA ($2, $1) }
| PRAGMA_LINE                           { PRAGMA (VARIABLE (fst $1), 
                                                  snd $1) }
| PRAGMA LTL ltl_pragma PRAGMA_EOL { $3 }
| PRAGMA PRAGMA_EOL { PRAGMA (VARIABLE "", $1) }
;

ltl_pragma:
| IDENT COLON ltl_expression	{ LTL_ANNOTATION ((fst $1), (fst $3), (snd $1)) }

ltl_expression:
|	ltl_expression65 {$1}

ltl_expression53:
|	TILDE ltl_expression53 { LTL_NOT (fst $2), snd $2 }
|	LBRACKET RBRACKET ltl_expression53 { LTL_ALWAYS (fst $3), snd $3 }
|	INF SUP ltl_expression53 { LTL_EVENTUALLY (fst $3), snd $3 }
|	IDENT ltl_expression53 { LTL_O (fst $1, fst $2), snd $2 }
|	ltl_expression_last { $1 }

ltl_expression55:
|	ltl_expression55 SLASH BACKSLASH ltl_expression53 { LTL_AND (fst $1, fst $4), snd $4 }
|	ltl_expression53 {$1}

ltl_expression59:
|	ltl_expression59 BACKSLASH SLASH ltl_expression55 { LTL_OR (fst $1, fst $4), snd $4 }
|	ltl_expression55 {$1}

/* U, R, W */
ltl_expression63:
|	ltl_expression63 IDENT ltl_expression63 { LTL_URW (fst $2, fst $1, fst $3), snd $3 }
|	ltl_expression59 {$1}

ltl_expression65:
|	ltl_expression63 ARROW ltl_expression65 { LTL_IMPLIES (fst $1, fst $3), snd $3 }
|	ltl_expression63 {$1}


ltl_expression_last:
|	LPAREN ltl_expression RPAREN {$2}
|	ATOM LPAREN expression RPAREN	{ LTL_ATOM (fst $3), snd $3 }
|	LTL_BUILTIN_TOK LPAREN IDENT RPAREN	{ LTL_BUILTIN (fst $3), snd $3 }
;

/* (* We want to allow certain strange things that occur in pragmas, so we
    * cannot use directly the language of expressions *) */
primary_attr:
    IDENT				{ VARIABLE (fst $1) }
    /*(* The NAMED_TYPE here creates conflicts with IDENT *)*/
|   NAMED_TYPE				{ VARIABLE (fst $1) }
|   LPAREN attr RPAREN                  { $2 }
|   IDENT IDENT                          { CALL(VARIABLE (fst $1), [VARIABLE (fst $2)]) }
|   CST_INT                              { CONSTANT(CONST_INT (fst $1)) }
|   string_constant                      { CONSTANT(CONST_STRING (fst $1)) }
                                           /*(* Const when it appears in
                                            * attribute lists, is translated
                                            * to aconst *)*/
|   CONST                                { VARIABLE "aconst" }

|   IDENT COLON CST_INT                  { VARIABLE (fst $1 ^ ":" ^ fst $3) }

/*(* The following rule conflicts with the ? : attributes. We give it a very
   * low priority *)*/
|   CST_INT COLON CST_INT                { VARIABLE (fst $1 ^ ":" ^ fst $3) }

|   DEFAULT COLON CST_INT                { VARIABLE ("default:" ^ fst $3) }

                                            /*(** GCC allows this as an
                                             * attribute for functions,
                                             * synonim for noreturn **)*/
|   VOLATILE                             { VARIABLE ("__noreturn__") }
|  generic_selection { fst $1 }
;

generic_selection:
| GENERIC LPAREN assignment_expression COMMA generic_assoc_list RPAREN { GENERIC ((fst $3), $5), $1 }
;
generic_assoc_list:
    generic_assoc                             { [$1] }
|   generic_assoc_list COMMA generic_assoc  { $1 @ [$3] }
;
generic_assoc:
| DEFAULT COLON assignment_expression { GENERIC_DEFAULT (fst $3) }
| type_name COLON assignment_expression { let b, d = $1 in let typ = (b, d) in GENERIC_PAIR (typ, (fst $3)) }


postfix_attr:
    primary_attr                         { $1 }
                                         /* (* use a VARIABLE "" so that the
                                             * parentheses are printed *) */
|   IDENT LPAREN  RPAREN             { CALL(VARIABLE (fst $1), [VARIABLE ""]) }
|   IDENT paren_attr_list_ne         { CALL(VARIABLE (fst $1), $2) }

|   postfix_attr ARROW id_or_typename    {MEMBEROFPTR ($1, $3)}
|   postfix_attr DOT id_or_typename      {MEMBEROF ($1, $3)}
|   postfix_attr LBRACKET attr RBRACKET  {INDEX ($1, $3) }
;

/*(* Since in attributes we use both IDENT and NAMED_TYPE as indentifiers,
 * that leads to conflicts for SIZEOF and ALIGNOF. In those cases we require
 * that their arguments be expressions, not attributes *)*/
unary_attr:
    postfix_attr                         { $1 }
|   SIZEOF unary_expression              {EXPR_SIZEOF (fst $2) }
|   SIZEOF LPAREN type_name RPAREN
		                         {let b, d = $3 in TYPE_SIZEOF (b, d)}

|   ALIGNOF unary_expression             {EXPR_ALIGNOF (fst $2) }
|   ALIGNOF LPAREN type_name RPAREN      {let b, d = $3 in TYPE_ALIGNOF (b, d)}
|   PLUS cast_attr                      {UNARY (PLUS, $2)}
|   MINUS cast_attr                     {UNARY (MINUS, $2)}
|   STAR cast_attr		        {UNARY (MEMOF, $2)}
|   AND cast_attr
	                                {UNARY (ADDROF, $2)}
|   EXCLAM cast_attr    	        {UNARY (NOT, $2)}
|   TILDE cast_attr                     {UNARY (BNOT, $2)}
;

cast_attr:
    unary_attr                           { $1 }
;

multiplicative_attr:
    cast_attr                           { $1 }
|   multiplicative_attr STAR cast_attr  {BINARY(MUL ,$1 , $3)}
|   multiplicative_attr SLASH cast_attr	  {BINARY(DIV ,$1 , $3)}
|   multiplicative_attr PERCENT cast_attr {BINARY(MOD ,$1 , $3)}
;


additive_attr:
    multiplicative_attr                 { $1 }
|   additive_attr PLUS multiplicative_attr  {BINARY(ADD ,$1 , $3)}
|   additive_attr MINUS multiplicative_attr {BINARY(SUB ,$1 , $3)}
;

shift_attr:
    additive_attr                       { $1 }
|   shift_attr INF_INF additive_attr	{BINARY(SHL ,$1 , $3)}
|   shift_attr SUP_SUP additive_attr	{BINARY(SHR ,$1 , $3)}
;

relational_attr:
    shift_attr                          { $1 }
|   relational_attr INF shift_attr	{BINARY(LT ,$1 , $3)}
|   relational_attr SUP shift_attr	{BINARY(GT ,$1 , $3)}
|   relational_attr INF_EQ shift_attr	{BINARY(LE ,$1 , $3)}
|   relational_attr SUP_EQ shift_attr	{BINARY(GE ,$1 , $3)}
;

equality_attr:
    relational_attr                     { $1 }
|   equality_attr EQ_EQ relational_attr	    {BINARY(EQ ,$1 , $3)}
|   equality_attr EXCLAM_EQ relational_attr {BINARY(NE ,$1 , $3)}
;


bitwise_and_attr:
    equality_attr                       { $1 }
|   bitwise_and_attr AND equality_attr	{BINARY(BAND ,$1 , $3)}
;

bitwise_xor_attr:
    bitwise_and_attr                       { $1 }
|   bitwise_xor_attr CIRC bitwise_and_attr {BINARY(XOR ,$1 , $3)}
;

bitwise_or_attr:
    bitwise_xor_attr                      { $1 }
|   bitwise_or_attr PIPE bitwise_xor_attr {BINARY(BOR ,$1 , $3)}
;

logical_and_attr:
    bitwise_or_attr                             { $1 }
|   logical_and_attr AND_AND bitwise_or_attr	{BINARY(AND ,$1 , $3)}
;

logical_or_attr:
    logical_and_attr                           { $1 }
|   logical_or_attr PIPE_PIPE logical_and_attr {BINARY(OR ,$1 , $3)}
;

conditional_attr:
    logical_or_attr                        { $1 }
/* This is in conflict for now */
|   logical_or_attr QUEST conditional_attr COLON conditional_attr
                                          { QUESTION($1, $3, $5) }


attr: conditional_attr                    { $1 }
;

attr_list_ne:
|  attr                                  { [$1] }
|  attr COMMA attr_list_ne               { $1 :: $3 }
|  error COMMA attr_list_ne              { $3 }
;
attr_list:
  /* empty */                            { [] }
| attr_list_ne                           { $1 }
;
paren_attr_list_ne:
   LPAREN attr_list_ne RPAREN            { $2 }
|  LPAREN error RPAREN                   { [] }
;
paren_attr_list:
   LPAREN attr_list RPAREN               { $2 }
|  LPAREN error RPAREN                   { [] }
;
/*** GCC ASM instructions ***/
asmattr:
     /* empty */                        { [] }
|    VOLATILE  asmattr                  { (SpecCV CV_VOLATILE) :: $2 }
|    CONST asmattr                      { (SpecCV CV_CONST) :: $2 }
;
asmtemplate:
    one_string_constant                          { [$1] }
|   one_string_constant asmtemplate              { $1 :: $2 }
;
asmoutputs:
  /* empty */           { None }
| COLON asmoperands asminputs
                        { let (ins, clobs) = $3 in
                          Some {aoutputs = $2; ainputs = ins; aclobbers = clobs} }
;
asmoperands:
     /* empty */                        { [] }
|    asmoperandsne                      { List.rev $1 }
;
asmoperandsne:
     asmoperand                         { [$1] }
|    asmoperandsne COMMA asmoperand     { $3 :: $1 }
;
asmoperand:
     asmopname string_constant LPAREN expression RPAREN    { ($1, fst $2, fst $4) }
|    asmopname string_constant LPAREN error RPAREN         { ($1, fst $2, NOTHING ) }
;
asminputs:
  /* empty */                { ([], []) }
| COLON asmoperands asmclobber
                        { ($2, $3) }
;
asmopname:
    /* empty */                         { None }
|   LBRACKET IDENT RBRACKET             { Some (fst $2) }
;

asmclobber:
    /* empty */                         { [] }
| COLON asmcloberlst_ne                 { $2 }
;
asmcloberlst_ne:
   one_string_constant                           { [$1] }
|  one_string_constant COMMA asmcloberlst_ne     { $1 :: $3 }
;
alignment_specifier:
| ALIGNAS LPAREN type_name RPAREN {let b, d = $3 in TYPE_ALIGNAS (b, d), $1}
| ALIGNAS LPAREN unary_expression RPAREN {EXPR_ALIGNAS (fst $3), $1}
;





%%



