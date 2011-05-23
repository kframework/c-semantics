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


module E = Errormsg
(* open Trace *)
(* open Pretty *)

(* Output management *)
let out : out_channel option ref = ref None
let close_me = ref false

let close_output _ =
  match !out with
    None -> ()
  | Some o -> begin
      flush o;
      if !close_me then close_out o else ();
      close_me := false
  end

   (* Signal that we are in MS VC mode *)
let setMSVCMode () =
  Cprint.msvcMode := true

(* filename for patching *)
let patchFileName : string ref = ref ""      (* by default do no patching *)

(* patching file contents *)
let patchFile : Cabs.file option ref = ref None

(* whether to print the patched CABS files *)
let printPatchedFiles : bool ref = ref false

(* whether to print a file of prototypes after parsing *)
let doPrintProtos : bool ref = ref false

(* this seems like something that should be built-in.. *)
let isNone (o : 'a option) : bool =
begin
  match o with
  | Some _ -> false
  | None -> true
end

let printNotice = ref false


exception ParseError of string
exception CabsOnly

(* parse, and apply patching *)
let rec parse_to_cabs fname =
begin
  (* parse the patch file if it isn't parsed already *)
  if ((!patchFileName <> "") && (isNone !patchFile)) then (
    (* parse the patch file *)
    patchFile := Some(parse_to_cabs_inner !patchFileName);
    if !E.hadErrors then
      (failwith "There were parsing errors in the patch file")
  );

  (* now parse the file we came here to parse *)
  let cabs = parse_to_cabs_inner fname in
  if !E.hadErrors then 
    E.s (Printf.printf "There were parsing errors in %s" fname); cabs
end

and clexer lexbuf =
    Clexer.clear_white ();
    Clexer.clear_lexeme ();
    let token = Clexer.initial lexbuf in
    let white = Clexer.get_white () in
    let cabsloc = Clexer.currentLoc () in
    let lexeme = Clexer.get_extra_lexeme () ^ Lexing.lexeme lexbuf in
    white,lexeme,token,cabsloc

(* just parse *)
and parse_to_cabs_inner (fname : string) =
  try
    if !E.verboseFlag then ignore ((Printf.printf "Frontc is parsing %s\n" fname));
    flush !E.logChannel;
    let lexbuf = Clexer.init fname in
    (* let cabs = Stats.time "parse" (Cparser.interpret (Whitetrack.wraplexer clexer)) lexbuf in *)
	let cabs = Cparser.interpret (Whitetrack.wraplexer clexer) lexbuf in
    Whitetrack.setFinalWhite (Clexer.get_white ());
    Clexer.finish ();
    (fname, cabs)
  with (Sys_error msg) -> begin
    ignore (Printf.printf "Cannot open %s : %s\n" fname msg);
    Clexer.finish ();
    close_output ();
    raise (ParseError("Cannot open " ^ fname ^ ": " ^ msg ^ "\n"))
  end
  | Parsing.Parse_error -> begin
      ignore (Printf.printf "Parsing error");
      Clexer.finish ();
      close_output ();
      raise (ParseError("Parse error"))
  end
  | e -> begin
      ignore (Printf.printf "Caught %s while parsing\n" (Printexc.to_string e));
      Clexer.finish ();
      raise e
  end


let parse_helper fname =
  (*(trace "sm" (dprintf "parsing %s to Cabs\n" fname)); *)
  let cabs = parse_to_cabs fname in
  (* Now (return a function that will) convert to CIL *)
  fun _ ->
    (* (trace "sm" (dprintf "converting %s from Cabs to CIL\n" fname)); *)
    (* let cil = Stats.time "convert to CIL" Cabs2cil.convFile cabs in *)
	(* let cil = Cabs2cil.convFile cabs in
    if !doPrintProtos then (printPrototypes cabs); *)
    cabs

let parse fname = (fun () -> snd(parse_helper fname ()))

let parse_with_cabs fname = (fun () -> parse_helper fname ())
