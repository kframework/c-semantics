module LIBC-STDARG
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

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
     // tool fixme, change Value to K and unquote error
     rule [va-start]:
          prepareBuiltin(Identifier("__va_start"), 
               ListItem(ApLoc:KResult)
               ListItem(ArgLoc:KResult))
          => Computation(*(ApLoc) := incSymbolic(ArgLoc))
               ~> voidVal
          [structural]
     
     rule [va-inc-start]:
          prepareBuiltin(Identifier("__va_inc"), 
               ListItem(ApLoc:RValue) 
               ListItem(Size:RValue))
          => va-inc-aux(ApLoc, Size, *ApLoc)
          [structural]
                    
     syntax K ::= "va-inc-aux" "(" RValue "," RValue "," K ")"
          [strict(3(context('reval), result(RValue)))]
     // fixme can do lots of checks here too
     rule [va-inc]:
          va-inc-aux(ApLoc:RValue, _, Ap:KResult)
          => Computation(*(ApLoc) := incSymbolic(Ap))
               ~> Ap:KResult
          [structural]                  
          
     // fixme can do lots of checks here too
     rule [va-copy]:
          prepareBuiltin(Identifier("__va_copy"), 
               ListItem(ApLoc:KResult) 
               ListItem(Other:KResult))
          => Computation(*(ApLoc) := Other) ~> voidVal
          [structural]
          
     // fixme can do lots of checks here too
     rule [va-end]:
          prepareBuiltin(Identifier("__va_end"),
               ListItem(_:KResult)) => voidVal
          [structural]
endmodule
