
open Cabs
open Cabshelper

(* This isn't the most efficient way to do things.
 * It would probably be better to not reparse rather
 * than keep the tokens in memory *)
 
(* In particular, most of the tokens we hold will be
   header files that we don't need *)

(* map cabslocs to token indexes *)

(* TODO: gather until end of line, then decide where to split *)

(* NOTE: If you find yourself getting lots of nomatch errors with
 * parens in them, then that may mean you are printing 
 * a cabs file that has had it's parens removed *)

let tokenmap : ((string * int),int) Hashtbl.t = Hashtbl.create 1000
let nextidx = ref 0

let gonebad = ref false

(* array of tokens and whitespace *)
let tokens = GrowArray.make 0 (GrowArray.Elem  ("",""))

let cabsloc_to_str cabsloc =
    cabsloc.filename ^ ":" ^ string_of_int cabsloc.lineno ^ ":" ^ 
    string_of_int cabsloc.byteno ^ ":" ^ 
    string_of_int cabsloc.ident

let lastline = ref 0

let wraplexer_enabled lexer lexbuf = 
    let white,lexeme,token,cabsloc = lexer lexbuf in
    GrowArray.setg tokens !nextidx (white,lexeme);
    Hashtbl.add tokenmap (cabsloc.filename,cabsloc.byteno) !nextidx;
    nextidx := !nextidx + 1;
    token

let wraplexer_disabled lexer lexbuf = 
    let white,lexeme,token,cabsloc = lexer lexbuf in
    token

let enabled = ref false

let wraplexer lexer =
    if !enabled then wraplexer_enabled lexer 
    else wraplexer_disabled lexer
    
let finalwhite = ref "\n"    
    
let setFinalWhite w = finalwhite := w 
