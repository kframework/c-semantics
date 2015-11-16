module LIBC-STDARG
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX

     imports C-CONFIGURATION

     /*@ \fromStandard{\source[n1570]{\para{7.16}{1--3}}}{

     The header \header{<stdarg.h>} declares a type and defines four macros,
     for advancing through a list of arguments whose number and types are not
     known to the called function when it is translated.

     A function may be called with a variable number of arguments of varying
     types. As described in 6.9.1, its parameter list contains one or more
     parameters. The rightmost parameter plays a special role in the access
     mechanism, and will be designated $\mathit{parmN}$ in this description.

     The type declared \cdisplay{va_list} which is a complete object type
     suitable for holding information needed by the macros \cinline{va_start},
     \cinline{va_arg}, \cinline{va_end}, and \cinline{va_copy}. If access to
     the varying arguments is desired, the called function shall declare an
     object (generally referred to as ap in this subclause) having type
     \cinline{va_list}. The object \cinline{ap} may be passed as an argument to
     another function; if that function invokes the \cinline{va_arg} macro with
     parameter \cinline{ap}, the value of \cinline{ap} in the calling function
     is indeterminate and shall be passed to the \cinline{va_end} macro prior
     to any further reference to \cinline{ap}.

     }*/

     ////////////////////////////--
     // Stdarg.h
     ////////////////////////////--
          // ,, "__va_inc"
          // ,, "__va_start"
          // ,, "__va_end"
          // ,, "__va_copy"


     /*@ \fromStandard{\source[n1570]{\para{7.16.1}{1}}}{
     The \cinline{va_start} and \cinline{va_arg} macros described in this
     subclause shall be implemented as macros, not functions. It is unspecified
     whether \cinline{va_copy} and \cinline{va_end} are macros or identifiers
     declared with external linkage. If a macro definition is suppressed in
     order to access an actual function, or a program defines an external
     identifier with the same name, the behavior is undefined. Each invocation
     of the \cinline{va_start} and \cinline{va_copy} macros shall be matched by
     a corresponding invocation of the \cinline{va_end} macro in the same
     function.
     }*/

     // va_list __va_start(va_list* ap, void* pN);
     // fixme can add lots of checks here
     // tool fixme, change RValue to K and unquote error
     rule [va-start]:
          prepareBuiltin(Identifier("__va_start"),
               hrItem(ApLoc:KResult) hs::
               hrItem(ArgLoc:KResult))
          => checkVarArgs ~> Computation(*(ApLoc) := incSymbolic(ArgLoc)) ~> voidVal
          [structural]

     rule [va-inc-start]:
          prepareBuiltin(Identifier("__va_inc"),
               hrItem(ApLoc:KResult) hs::
               hrItem(Size:KResult))
          => va-inc-aux(ApLoc, Size, *ApLoc)
          [structural]

     syntax KItem ::= "va-inc-aux" "(" K "," K "," K ")"
     context va-inc-aux((HOLE:KItem => reval(HOLE)), _, _) [result(RValue)]
     context va-inc-aux(_, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     context va-inc-aux(_, _, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     // fixme can do lots of checks here too
     rule [va-inc]:
          va-inc-aux(ApLoc:RValue, _, Ap:RValue)
          => Computation(*(ApLoc) := incSymbolic(Ap)) ~> Ap
          [structural]

     // fixme can do lots of checks here too
     rule [va-copy]:
          prepareBuiltin(Identifier("__va_copy"),
               hrItem(ApLoc:KResult) hs::
               hrItem(Other:KResult))
          => Computation(*(ApLoc) := Other) ~> voidVal
          [structural]

     // fixme can do lots of checks here too
     rule [va-end]:
          prepareBuiltin(Identifier("__va_end"), hrItem(_:KResult))
          => voidVal
          [structural]

     syntax KItem ::= "checkVarArgs"
     rule [va-start]:
          <k> checkVarArgs => .K ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-curr-scope> blockScope(F:CId, _) </stack-curr-scope>
                    <stack-curr-tu> Tu:String </stack-curr-tu>
               ...</call-stack-frame>)
          ...</call-stack>
          <tu-id> Tu </tu-id>
          <gtypes>... F |-> T:Type ...</gtypes>
          requires variadic in getParams(T)
          [structural]
     rule <k> (.K => UNDEF("STDARG1", "'va_start' used in function with fixed args.", "6.9.1:8, J.2:1 item 87"))
                ~> checkVarArgs
          ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-curr-scope> blockScope(F:CId, _) </stack-curr-scope>
                    <stack-curr-tu> Tu:String </stack-curr-tu>
               ...</call-stack-frame>)
          ...</call-stack>
          <tu-id> Tu </tu-id>
          <gtypes>... F |-> T:Type ...</gtypes>
          requires notBool variadic in getParams(T)
          [structural]

endmodule
