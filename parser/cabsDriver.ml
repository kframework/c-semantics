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


(* main.ml *)
(* this module is the program entry point for the 'cilly' program, *)
(* which reads a C program file, parses it, translates it to the CIL *)
(* intermediate language, and then renders that back into C *)

module F = Frontc
(* module C = Cil *)
(* module CK = Check *)
module E = Errormsg
open Printf
open KPrinter

type outfile = 
    { fname: string;
      fchan: out_channel } 

let replace input output =
    Str.global_replace (Str.regexp_string input) output
	
let fileNames : string list ref = ref []
let recordFile fname = 
  fileNames := fname :: (!fileNames)
	
let noscores s = 
	(replace "_" "-" s)

let parse_helper fname =
  let cabs = F.parse_to_cabs fname in
  cabs

let parseOneFile (fname: string) =
  (* PARSE *)
  (* if !Cilutil.printStages then ignore (E.log "Parsing %s\n" fname); *)
  (*let cil = F.parse fname () in *)
  let cabs = parse_helper fname in
  cabs
let trueFilename : string ref = ref ""

(* True to output kore instead of kast. *)
let kore : bool ref = ref false

let rec processOneFile (cabs: Cabs.file) =
  begin (
    let (inputFilename, defs) = cabs in
    let ic = open_in inputFilename in
    let inputFilename = if compare !trueFilename "" == 0 then inputFilename else !trueFilename in
    let data = (if !kore then cabs_to_kore else cabs_to_kast) defs inputFilename in
    Buffer.output_buffer stdout data
  );
    if !E.hadErrors then E.s "Error: Error while processing file; see above for details.";
  end

(***** MAIN *****)  
let theMain () =
  let usageMsg = "Usage: cparser [options] source-files" in
  (* Processign of output file arguments *)
  let openFile (what: string) (takeit: outfile -> unit) (fl: string) = 
    if !E.verboseFlag then
      ignore (Printf.printf "Setting %s to %s\n" what fl);
    (try takeit { fname = fl;
                  fchan = open_out fl }
    with _ ->
      raise (Arg.Bad ("Cannot open " ^ what ^ " file " ^ fl)))
  in
  let outName = ref "" in
  (* sm: enabling this by default, since I think usually we
   * want 'cilly' transformations to preserve annotations; I
   * can easily add a command-line flag if someone sometimes
   * wants these suppressed *)
  (* C.print_CIL_Input := true; *)

  (*********** COMMAND LINE ARGUMENTS *****************)
  (* Construct the arguments for the features configured from the Makefile *)
  let blankLine = ("", Arg.Unit (fun _ -> ()), "") in
  
  let argDescr =
        [
            ("--trueName", Arg.String (fun x -> trueFilename := x),
                  "filename The original name of the file");
            ("--kore", Arg.Set kore,
                  " Output kore instead of kast")
        ] in
      begin
		(* this point in the code is the program entry point *)

		(* Stats.reset Stats.HardwareIfAvail; *)

		(* parse the command-line arguments *)
		Arg.parse (Arg.align argDescr) recordFile usageMsg;

		(* now we have just one CIL "file" to deal with *)
		let one =
			match !fileNames with
			  [one] -> parseOneFile one
			| [] -> E.s ("Error: No arguments for CIL")
			| _ -> E.s ("Error: Can only handle one input file")
		in

		if !E.hadErrors then
			E.s ("Error: Cabs2cil had some errors");
				
		(* process the CIL file (merged if necessary) *)
		processOneFile one
	end
;;
                                        (* Define a wrapper for main to 
                                         * intercept the exit *)
let failed = ref false 

let cleanup () = 
  (* if !E.verboseFlag || !Cilutil.printStats then
    Stats.print stderr "Timings:\n"; *)
  if !E.logChannel != stderr then 
    close_out (! E.logChannel);  
;;

begin 
  try 
    theMain (); 
  with F.CabsOnly -> (* this is OK *) ()
  | Frontc.ParseError _ -> failed := true
end;
cleanup ();
exit (if !failed then 1 else 0)

