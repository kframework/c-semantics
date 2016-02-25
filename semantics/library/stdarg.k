module LIBC-STDARG
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-BUILTIN-SYNTAX

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
          // ,, "va_end"
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
     rule [va-start]:
          // TODO(chathhorn): verify arg is last param and not register.
          <k> builtin("__va_start", tv(Loc:SymLoc, T:PointerType), _)
               => checkVarArgs
               ~> checkDead(read(Loc, innerType(T)))
               ~> addVaList(!N:Int, tv(Loc, T), filterVarArgs(P))
               ~> voidVal
          ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <curr-function-params> P:List </curr-function-params>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          [structural]

     syntax KItem ::= addVaList(Int, RValue, HeatList) [strict(3)]
     rule <k> addVaList(N':Int, VaListPtr:RValue, Args:HeatList)
               => Computation((* VaListPtr) := tv(N', va_list))
          ...</k>
          <va-lists> VaLists:Map (.Map => N' |-> hListToList(Args)) </va-lists>
          requires allRValueInHeatList(Args)
          [structural]

     syntax KItem ::= checkDead(K) [strict]
     rule <k> (.K => UNDEF("STDARG2",
                    "'va_start' or 'va_copy' used to reinitialize a va_list without an intervening call to va_end.",
                    "7.16.1.4:3, J.2:1 item 142"))
               ~> checkDead(tv(N:Int, _))
          ...</k>
          <va-lists>... N |-> _ ...</va-lists>
          [structural]
     rule <k> checkDead(tv(N:Int, _)) => .K ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool N in_keys(VaLists)
          [structural]
     // Avoid triggering errors if it's a trap.
     rule checkDead(V:KResult) => .K
          requires getKLabel(V) =/=K #klabel(`tv`)
          [structural]

     syntax HeatList ::= filterVarArgs(List) [function]
     rule filterVarArgs(ListItem(vararg(N:Int)) P:List)
          => hItem(& (lookupInCaller(vararg(N)))) hs:: filterVarArgs(P)
     rule filterVarArgs(.List) => .HeatList
     rule filterVarArgs(ListItem(_) P:List) => filterVarArgs(P) [owise]

     syntax KItem ::= lookupInCaller(CId)
     rule <k> lookupInCaller(X:CId) => lv(lnew(Base, T), T) ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <env>... X |-> Base:SymBase ...</env>
                         <types>... X |-> T:Type ...</types>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          [structural]

     rule <k> builtin("__va_inc", tv(N:Int, _)) => V ...</k>
          <va-lists>... N |-> (ListItem(V:RValue) => .List) _:List ...</va-lists>
          [structural]
     rule <k> (.K => UNDEF("STDARG3",
                    "'va_arg' called on an uninitialized va_list.",
                    "7.16.1.1:2, J.2:1 item 136"))
               ~> builtin("__va_inc", tv(N:Int, _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool N in_keys(VaLists)
          [structural]

     // fixme can do lots of checks here too
     rule [va-copy]:
          <k> builtin("__va_copy", Dst:RValue, tv(Src:Int, _))
               => checkDead(* Dst)
               ~> Computation((* Dst) := tv(!N:Int, va_list))
               ~> voidVal
          ...</k>
          <va-lists>...
               Src |-> Args:List
               (.Map => !N |-> Args)
          ...</va-lists>
          [structural]
     rule <k> (.K => UNDEF("STDARG4",
                    "'va_copy' called on an uninitialized source va_list.",
                    "7.16.1.2:2, J.2:1 item 136"))
               ~> builtin("__va_copy", _, tv(Src:Int, _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool Src in_keys(VaLists)
          [structural]

     // fixme can do lots of checks here too
     rule [va-end]:
          <k> builtin("va_end", tv(N:Int, _)) => voidVal ...</k>
          <va-lists>... N |-> _ => .Map ...</va-lists>
          [structural]
     rule <k> (.K => UNDEF("STDARG5",
                    "'va_end' called on an uninitialized va_list.",
                    "7.16.1.3:2, J.2:1 item 136"))
               ~> builtin("va_end", tv(Src:Int, _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool Src in_keys(VaLists)
          [structural]

     syntax KItem ::= "checkVarArgs"
     rule <k> checkVarArgs => .K ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <curr-scope> blockScope(F:CId, _) </curr-scope>
                         <curr-tu> Tu:String </curr-tu>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          <tu-id> Tu </tu-id>
          <gtypes>... F |-> T:Type ...</gtypes>
          requires variadic in getParams(T)
          [structural]
     rule <k> (.K => UNDEF("STDARG1",
                    "'va_start' used in a function with fixed args.",
                    "6.9.1:8, J.2:1 item 87"))
                ~> checkVarArgs
          ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <curr-scope> blockScope(F:CId, _) </curr-scope>
                         <curr-tu> Tu:String </curr-tu>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          <tu-id> Tu </tu-id>
          <gtypes>... F |-> T:Type ...</gtypes>
          requires notBool variadic in getParams(T)
          [structural]

endmodule
