module OPTIONS-SORTS
     syntax Opt
endmodule

module OPTIONS-SYNTAX
     imports OPTIONS-SORTS
     imports INT
     imports STRING

     syntax Opt ::= Debug() [symbol]
                  | Link() [symbol]                         // Resolve uses to definitions.
                  | NoNativeFallback() [symbol]             // Don't attempt linking with native defs.
                  | EntryPoint(String) [symbol]              // Set the program entry point symbol.
                  | NoIO() [symbol]                          // Disable IO.
                  | UseNativeStdLib() [symbol]               // Prefer the native standard library
                  | Stack(Int) [symbol] | Heap(Int) [symbol] // Stack/heap bounds checking.
                  | Breakpoint(String, Int) [symbol]         // Set a breakpoint at a certain file/line.
                  | ActiveBreakpoint(String, Int) [symbol]   // Flags the active breakpoint.
                  | RecoverAll() [symbol]                        // Attempt recovery on all errors.
                  | InteractiveFail() [symbol]                   // Enter interactive mode when recovery fails.
                  | FatalErrors() [symbol]                       // Don't attempt any error recovery.
                  | Lint() [symbol]                              // Enable extra warnings.

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
     rule showOpt(FatalErrors()) => "fatal-errors"
     rule showOpt(Lint()) => "lint"
     rule showOpt(Opt::Opt) => showK(Opt) [owise]

endmodule
