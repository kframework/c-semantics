(* 
 *
 * Copyright (c) 2001-2002, 
 *  George C. Necula    <necula@cs.berkeley.edu>
 *  Scott McPeak        <smcpeak@cs.berkeley.edu>
 *  Wes Weimer          <weimer@cs.berkeley.edu>
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
 *)

(** This file was originally part of Hugues Casee's frontc 2.0, and has been 
 * extensively changed since. 
**
** 1.0	3.22.99	Hugues Cass�	First version.
** 2.0  George Necula 12/12/00: Many extensions
 **)

(*
** Types
*)

type cabsloc = {
 lineno : int;
 filename: string;
 byteno: int;
 ident : int;
 lineOffsetStart : int;
 systemHeader : bool;
}

type typeSpecifier = (* Merge all specifiers into one type *)
    Tvoid                             (* Type specifier ISO 6.7.2 *)
  | Tchar
  | Tbool
  | Tshort
  | Tint
  | Tlong
  | ToversizedInt
  | Tfloat
  | Tdouble
  | ToversizedFloat
  | Tsigned
  | Tunsigned
  | Tnamed of string
  (* each of the following three kinds of specifiers contains a field 
   * or item list iff it corresponds to a definition (as opposed to
   * a forward declaration or simple reference to the type); they
   * also have a list of __attribute__s that appeared between the
   * keyword and the type name (definitions only) *)
  | Tstruct of string * field_group list option * attribute list
  | Tunion of string * field_group list option * attribute list
  | Tenum of string * enum_item list option * attribute list
  | TtypeofE of expression                      (* GCC __typeof__ *)
  | TtypeofT of type_name       (* GCC __typeof__ *)
  | TautoType
  | Tcomplex
  | Timaginary
  | Tatomic of type_name

and storage =
    NO_STORAGE | AUTO | STATIC | EXTERN | REGISTER | THREAD_LOCAL

and funspec = 
    INLINE | VIRTUAL | EXPLICIT

and cvspec =
    CV_CONST | CV_VOLATILE | CV_RESTRICT | CV_RESTRICT_RESERVED of (string * cabsloc) | CV_ATOMIC

(* Type specifier elements. These appear at the start of a declaration *)
(* Everywhere they appear in this file, they appear as a 'spec_elem list', *)
(* which is not interpreted by cabs -- rather, this "word soup" is passed *)
(* on to the compiler.  Thus, we can represent e.g. 'int long float x' even *)
(* though the compiler will of course choke. *)
and spec_elem =
    SpecTypedef          
  | SpecCV of cvspec            (* const/volatile *)
  | SpecAttr of (string * expression list)       (* __attribute__ *)
  | SpecStorage of storage
  (* technically these two should be grouped too *)
  | SpecInline
  | SpecNoReturn
  
  | SpecAlignment of alignment_spec
  | SpecType of typeSpecifier
  | SpecMissingType
  | SpecPattern of string       (* specifier pattern variable *)

and alignment_spec =
	| EXPR_ALIGNAS of expression
	| TYPE_ALIGNAS of type_name
(* decided to go ahead and replace 'spec_elem list' with specifier *)
and specifier = spec_elem list
and type_name = specifier * decl_type


(* Declarator type. They modify the base type given in the specifier. Keep
 * them in the order as they are printed (this means that the top level
 * constructor for ARRAY and PTR is the inner-level in the meaning of the
 * declared type) *)
and decl_type =
 | JUSTBASE                               (* Prints the declared name *)
 | PARENTYPE of attribute list * decl_type * attribute list
                                          (* Prints "(attrs1 decl attrs2)".
                                           * attrs2 are attributes of the
                                           * declared identifier and it is as
                                           * if they appeared at the very end
                                           * of the declarator. attrs1 can
                                           * contain attributes for the
                                           * identifier or attributes for the
                                           * enclosing type.  *)
 | ARRAY of decl_type * attribute list * expression * specifier
                                          (* Prints "decl [ attrs exp ]".
                                           * decl is never a PTR. *)
 | PTR of attribute list * decl_type      (* Prints "* attrs decl" *)
 | PROTO of decl_type * single_name list * bool 
                                          (* Prints "decl (args[, ...])".
                                           * decl is never a PTR.*)
 | NOPROTO of decl_type * single_name list * bool 
                                          (* Prints "decl (args[, ...])".
                                           * decl is never a PTR.*)

(* The base type and the storage are common to all names. Each name might
 * contain type or storage modifiers *)
(* e.g.: int x, y; *)
and name_group = specifier * name list

(* The optional expression is the bitfield *)
and field_group = specifier * (name * expression option) list

(* like name_group, except the declared variables are allowed to have initializers *)
(* e.g.: int x=1, y=2; *)
and init_name_group = specifier * init_name list

(* The decl_type is in the order in which they are printed. Only the name of
 * the declared identifier is pulled out. The attributes are those that are
 * printed after the declarator *)
(* e.g: in "int *x", "*x" is the declarator; "x" will be pulled out as *)
(* the string, and decl_type will be PTR([], JUSTBASE) *)
and name = string * decl_type * attribute list * cabsloc

(* A variable declarator ("name") with an initializer *)
and init_name = name * (init_expression * cabsloc)

(* Single names are for declarations that cannot come in groups, like
 * function parameters and functions *)
and single_name = specifier * name


and enum_item = string * expression * cabsloc

(*
** Declaration definition (at toplevel)
*)
and definition =
   FUNDEF of single_name * block * cabsloc * cabsloc
 | DECDEF of init_name_group * cabsloc        (* global variable(s), or function prototype *)
 | TYPEDEF of name_group * cabsloc
 | ONLYTYPEDEF of specifier * cabsloc
 | GLOBASM of string * cabsloc
 | PRAGMA of expression * cabsloc
 | LINKAGE of string * cabsloc * definition list (* extern "C" { ... } *)
 (* toplevel form transformer, from the first definition to the *)
 (* second group of definitions *)
 | TRANSFORMER of definition * definition list * cabsloc
 (* expression transformer: source and destination *)
 | EXPRTRANSFORMER of expression * expression * cabsloc
 | STATIC_ASSERT of expression * constant * cabsloc (* the intention is for the constant to be a string literal *)
 | LTL_ANNOTATION of string * expression * cabsloc (* name, claim, loc; new by CME for special comments *)




(* the string is a file name, and then the list of toplevel forms *)
and file = string * definition list


(*
** statements
*)

(* A block contains a list of local label declarations ( GCC's ({ __label__ 
 * l1, l2; ... }) ) , a list of definitions and a list of statements  *)
and block = 
    { blabels: string list;
      battrs: attribute list;
      bstmts: statement list
    } 

(* GCC asm directives have lots of extra information to guide the optimizer *)
and asm_details =
    { aoutputs: (string option * string * expression) list; (* optional name, constraints and expressions for outputs *)
      ainputs: (string option * string * expression) list; (* optional name, constraints and expressions for inputs *)
      aclobbers: string list (* clobbered registers *)
    }

and statement =
   NOP of cabsloc
 | COMPUTATION of expression * cabsloc
 | BLOCK of block * cabsloc
 | IF of expression * statement * statement * cabsloc
 | WHILE of expression * statement * cabsloc
 | DOWHILE of expression * statement * cabsloc * cabsloc
 | FOR of for_clause * expression * expression * statement * cabsloc
 | BREAK of cabsloc
 | CONTINUE of cabsloc
 | RETURN of expression * cabsloc
 | SWITCH of expression * statement * cabsloc
 | CASE of expression * statement * cabsloc
 | CASERANGE of expression * expression * statement * cabsloc
 | DEFAULT of statement * cabsloc
 | LABEL of string * statement * cabsloc
 | GOTO of string * cabsloc
 | COMPGOTO of expression * cabsloc (* GCC's "goto *exp" *)
 | DEFINITION of definition (*definition or declaration of a variable or type*)
 | ASM of attribute list * (* typically only volatile and const *)
          string list * (* template *)
          asm_details option * (* extra details to guide GCC's optimizer *)
          cabsloc
   (** MS SEH *)
 | TRY_EXCEPT of block * expression * block * cabsloc
 | TRY_FINALLY of block * block * cabsloc
 
and for_clause = 
   FC_EXP of expression
 | FC_DECL of definition

(*
** Expressions
*)
and binary_operator =
    ADD | SUB | MUL | DIV | MOD
  | AND | OR
  | BAND | BOR | XOR | SHL | SHR
  | EQ | NE | LT | GT | LE | GE
  | ASSIGN
  | ADD_ASSIGN | SUB_ASSIGN | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN
  | BAND_ASSIGN | BOR_ASSIGN | XOR_ASSIGN | SHL_ASSIGN | SHR_ASSIGN

and unary_operator =
    MINUS | PLUS | NOT | BNOT | MEMOF | ADDROF
  | PREINCR | PREDECR | POSINCR | POSDECR

and expression =
    NOTHING
  | UNSPECIFIED
  | OFFSETOF of type_name * expression * cabsloc
  | TYPES_COMPAT of type_name * type_name * cabsloc
  | LOCEXP of expression * cabsloc
  | UNARY of unary_operator * expression
  | LABELADDR of string  (* GCC's && Label *)
  | BINARY of binary_operator * expression * expression
  | QUESTION of expression * expression * expression

   (* A CAST can actually be a constructor expression *)
  | CAST of type_name * init_expression

    (* There is a special form of CALL in which the function called is
       __builtin_va_arg and the second argument is sizeof(T). This 
       should be printed as just T *)
  | CALL of expression * expression list
  | COMMA of expression list
  | CONSTANT of constant
  | PAREN of expression
  | VARIABLE of string
  | EXPR_SIZEOF of expression
  | TYPE_SIZEOF of type_name
  | EXPR_ALIGNOF of expression
  | TYPE_ALIGNOF of type_name
  | INDEX of expression * expression
  | MEMBEROF of expression * string
  | MEMBEROFPTR of expression * string
  | GNU_BODY of block
  | BITMEMBEROF of expression * string
  | EXPR_PATTERN of string     (* pattern variable, and name *)
  | GENERIC of expression * (generic_association list)
  
  | LTL_TRUE
  | LTL_FALSE
  | LTL_ATOM of expression
  | LTL_BUILTIN of string
  | LTL_NOT of expression
  | LTL_AND of expression * expression
  | LTL_OR of expression * expression
  | LTL_ALWAYS of expression
  | LTL_IMPLIES of expression * expression
  | LTL_EVENTUALLY of expression
  | LTL_URW of string * expression * expression
  | LTL_O of string * expression
(*   | LTL_UNTIL of expression * expression
  | LTL_RELEASE of expression * expression *)
  
and generic_association =
	| GENERIC_PAIR of type_name * expression
	| GENERIC_DEFAULT of expression

and constant =
  | CONST_INT of string   (* the textual representation *)
  | CONST_FLOAT of string (* the textual representaton *)
  | CONST_CHAR of int64 list
  | CONST_WCHAR of int64 list
  | CONST_STRING of string
  | CONST_WSTRING of int64 list 
    (* ww: wstrings are stored as an int64 list at this point because
     * we might need to feed the wide characters piece-wise into an 
     * array initializer (e.g., wchar_t foo[] = L"E\xabcd";). If that
     * doesn't happen we will convert it to an (escaped) string before
     * passing it to Cil. *) 

and init_expression =
  | NO_INIT
  | SINGLE_INIT of expression
  | COMPOUND_INIT of (initwhat * (init_expression * cabsloc)) list

and initwhat =
    NEXT_INIT
  | INFIELD_INIT of string * initwhat
  | ATINDEX_INIT of expression * initwhat
  | ATINDEXRANGE_INIT of expression * expression
 

                                        (* Each attribute has a name and some
                                         * optional arguments *)
and attribute = spec_elem

