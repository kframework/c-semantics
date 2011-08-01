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

(* open Pretty *)


(*
let debugFlag  = ref false              (* If set then print debugging info *)
*)
let verboseFlag = ref false

(**** Error reporting ****)  
exception Error
let s (d : 'a) = raise Error

let hadErrors = ref false

let logChannel : out_channel ref = ref stderr

(***** Handling parsing errors ********)
type parseinfo =
    { mutable  linenum: int      ; (* Current line *)
      mutable  linestart: int    ; (* The position in the buffer where the 
                                    * current line starts *)
      mutable fileName : string   ; (* Current file *)
      mutable hfile   : string   ; (* High-level file *)
      mutable hline   : int;       (* High-level line *)
      lexbuf          : Lexing.lexbuf;
	  mutable offsetFix : int; (* subtract this from buffer pos to get real pos *)
	  mutable savedOffset : int; (* when including a file, save old offset here *)
      inchan          : in_channel option; (* None, if from a string *)
      mutable   num_errors : int;  (* Errors so far *)
    }  
let dummyinfo = 
    { linenum   = 1;
      linestart = 0;
      fileName  = "" ;
      lexbuf    = Lexing.from_string "";
      inchan    = None;
	  offsetFix = 0;
	  savedOffset = 0;
      hfile     = "";
      hline     = 0;
      num_errors = 0;
    }

let current = ref dummyinfo
    
let rem_quotes str = String.sub str 1 ((String.length str) - 2)

(* Change \ into / in file names. To avoid complications with escapes *)
let cleanFileName str = 
  let str1 = 
    if str <> "" && String.get str 0 = '"' (* '"' ( *) 
    then rem_quotes str else str in
  let l = String.length str1 in
  let rec loop (copyto: int) (i: int) = 
    if i >= l then 
      String.sub str1 0 copyto
     else 
       let c = String.get str1 i in
       if c <> '\\' then begin
          String.set str1 copyto c; loop (copyto + 1) (i + 1)
       end else begin
          String.set str1 copyto '/';
          if i < l - 2 && String.get str1 (i + 1) = '\\' then
              loop (copyto + 1) (i + 2)
          else 
              loop (copyto + 1) (i + 1)
       end
  in
  loop 0 0

let readingFromStdin = ref false

let startParsing ?(useBasename=true) (fname: string) = 
  (* We only support one open file at a time *)
  if !current != dummyinfo then begin
     s (Printf.printf "Error: Errormsg.startParsing supports only one open file: You want to open %s and %s is still open\n" fname !current.fileName); 
  end; 
  let inchan = 
    try if fname = "-" then begin 
           readingFromStdin := true;
           stdin 
        end else begin
           readingFromStdin := false;
           open_in fname 
        end
    with e -> s (Printf.printf "Error: Cannot find input file %s (exception %s" 
                    fname (Printexc.to_string e)) in
  let lexbuf = Lexing.from_channel inchan in
  let i = 
    { linenum = 1; linestart = 0; 
      fileName = 
        cleanFileName (if useBasename then Filename.basename fname else fname);
      lexbuf = lexbuf; inchan = Some inchan;
	  offsetFix = 0;
	  savedOffset = 0;
      hfile = ""; hline = 0;
      num_errors = 0 } in

  current := i;
  lexbuf

let finishParsing () = 
  let i = !current in
  (match i.inchan with Some c -> close_in c | _ -> ());
  current := dummyinfo


(* Call this function to announce a new line *)
let newline () = 
  let i = !current in
  i.linenum <- 1 + i.linenum;
  i.linestart <- Lexing.lexeme_start i.lexbuf

let setCurrentLine (i: int) = 
  !current.linenum <- i

let setCurrentFile (n: string) = 
  !current.fileName <- cleanFileName n
 (*
let setOffsetFix (i: int) = 
  !current.offsetFix <- i
let saveOffset = 
  !current.savedOffset <- !current.offsetFix
*)

let max_errors = 20  (* Stop after 20 errors *)

let parse_warn (msg: string) : unit =
  (* Sometimes the Ocaml parser raises errors in symbol_start and symbol_end *)
  let token_start, token_end = 
    try Parsing.symbol_start (), Parsing.symbol_end ()
    with e -> begin 
      ignore (Printf.printf "Warning: Parsing raised %s\n" (Printexc.to_string e));
      0, 0
    end
  in
  let i = !current in
  let adjStart = 
    if token_start < i.linestart then 0 else token_start - i.linestart in
  let adjEnd = 
    if token_end < i.linestart then 0 else token_end - i.linestart in
  output_string 
    stderr
    (i.fileName ^ "[" ^ (string_of_int i.linenum) ^ ":" 
                        ^ (string_of_int adjStart) ^ "-" 
                        ^ (string_of_int adjEnd) 
                  ^ "]"
     ^ " : Warning: " ^ msg);
  output_string stderr "\n";
  flush stderr ;
  ()

let parse_error (msg: string) : 'a =
  (* Sometimes the Ocaml parser raises errors in symbol_start and symbol_end *)
  let token_start, token_end = 
    try Parsing.symbol_start (), Parsing.symbol_end ()
    with e -> begin 
      ignore (Printf.printf "Warning: Parsing raised %s\n" (Printexc.to_string e));
      0, 0
    end
  in
  let i = !current in
  let adjStart = 
    if token_start < i.linestart then 0 else token_start - i.linestart in
  let adjEnd = 
    if token_end < i.linestart then 0 else token_end - i.linestart in
  output_string 
    stderr
    (i.fileName ^ "[" ^ (string_of_int i.linenum) ^ ":" 
                        ^ (string_of_int adjStart) ^ "-" 
                        ^ (string_of_int adjEnd) 
                  ^ "]"
     ^ " : " ^ msg);
  output_string stderr "\n";
  flush stderr ;
  i.num_errors <- i.num_errors + 1;
  if i.num_errors > max_errors then begin
    output_string stderr "Too many errors. Aborting.\n" ;
    exit 1 
  end;
  hadErrors := true;
  raise Parsing.Parse_error

(* More parsing support functions: line, file, char count *)
let getPosition () : int * string * int * int = 
	let i = !current in
	let offset = Lexing.lexeme_start i.lexbuf in
  i.linenum, i.fileName, offset, (offset - i.linestart)
