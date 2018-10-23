module OPTIONS-SORTS
     syntax Opt
     syntax TransOpt
     syntax ExecOpt
     syntax Opt ::= TransOpt | ExecOpt
endmodule

module OPTIONS-SYNTAX
     imports OPTIONS-SORTS
     imports INT
     imports STRING

     syntax TransOpt ::= Debug()
                       | Link()                       // Resolve uses to definitions.
                       | NoNativeFallback()           // Don't attempt linking with native defs.

     syntax ExecOpt ::= EntryPoint(String)            // Set the program entry point symbol.
                      | NoIO()                        // Disable IO.
                      | UseNativeStdLib()             // Prefer the native standard library
                      | Stack(Int) | Heap(Int)        // Stack/heap bounds checking.
                      | Breakpoint(String, Int)       // Set a breakpoint at a certain file/line.
                      | ActiveBreakpoint(String, Int) // Flags the active breakpoint.

     syntax Opt ::= RecoverAll()                      // Attempt recovery on all errors.
                  | InteractiveFail()                 // Enter interactive mode when recovery fails.

     syntax String ::= showOpt(Opt) [function]

endmodule

module OPTIONS
     imports OPTIONS-SYNTAX
     imports COMPAT-SYNTAX

     rule showOpt(Debug()) => "debug-mode"
     rule showOpt(Link()) => "link"
     rule showOpt(NoNativeFallback()) => "no-native-fallback"
     rule showOpt(EntryPoint(S::String)) => "entry-point=" +String S
     rule showOpt(Breakpoint(F::String, L::Int)) => "breakpoint=" +String F +String ":" +String showInt(L)
     rule showOpt(ActiveBreakpoint(F::String, L::Int)) => "breakpoint=" +String F +String ":" +String showInt(L)
     rule showOpt(NoIO()) => "no-io"
     rule showOpt(UseNativeStdLib()) => "use-native-std-lib"
     rule showOpt(Stack(N::Int)) => "stack=" +String showInt(N)
     rule showOpt(Heap(N::Int)) => "heap=" +String showInt(N)
     rule showOpt(RecoverAll()) => "recover-all"
     rule showOpt(InteractiveFail()) => "interactive-fail"
     rule showOpt(Opt::Opt) => showK(Opt) [owise]

endmodule
