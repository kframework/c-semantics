module LIBC-STDARG
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-TYPES-SYNTAX
     imports RETURN-SYNTAX

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
          // ,, "__kcc_va_inc"
          // ,, "__kcc_va_start"
          // ,, "__kcc_va_end"
          // ,, "__kcc_va_copy"


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

     // va_list __kcc_va_start(va_list* ap, void* pN);
     rule [va-start]:
          <k> builtin("__kcc_va_start", tv(Loc:SymLoc, T:PointerUType), _)
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
                    | "addVaList'" "(" Int "," RValue "," List ")"
     rule addVaList(N'::Int, VaListPtr::RValue, Args::HeatList)
          => addVaList'(N', VaListPtr, hListToList(Args))
          requires allRValueInHeatList(Args)
     rule <k> addVaList'(N'::Int, VaListPtr::RValue, Args::List)
               => Computation((* VaListPtr) := tv(opaque(N', utype(va_list)), utype(va_list)))
          ...</k>
          <va-lists>
               VaLists:Map (.Map => N' |-> Args)
          </va-lists>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <live-va-lists>... .Set => SetItem(N') ...</live-va-lists>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          [structural]

     syntax KItem ::= checkDead(K) [strict]
     rule <k> (.K => UNDEF("STDARG2",
                    "'va_start' or 'va_copy' used to reinitialize a va_list without an intervening call to va_end."))
               ~> checkDead(tv(opaque(N:Int, _), _))
          ...</k>
          <va-lists>... N |-> _ ...</va-lists>
          [structural]
     rule <k> checkDead(tv(V::CValue, _)) => .K ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool (fromOpaque(V) in_keys(VaLists))
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
     rule <k> lookupInCaller(X:CId) => lv(lnew(Base), T) ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <env>... X |-> Base:SymBase ...</env>
                         <types>... X |-> T:Type ...</types>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          [structural]

     rule <k> builtin("__kcc_va_inc", tv(opaque(N:Int, _), _)) => V ...</k>
          <va-lists>... N |-> ((ListItem(V:RValue) => .List) _:List) ...</va-lists>
          [structural]
     rule <k> (.K => UNDEF("STDARG3",
                    "'va_arg' called on an uninitialized va_list."))
               ~> builtin("__kcc_va_inc", tv(V::CValue, _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool (fromOpaque(V) in_keys(VaLists))
          [structural]
     rule <k> (.K => UNDEF("STDARG6",
                    "'va_arg' called with no arguments remaining."))
               ~> builtin("__kcc_va_inc", tv(opaque(N:Int, _), _))
          ...</k>
          <va-lists>... N |-> .List ...</va-lists>
          [structural]

     rule [va-copy]:
          <k> builtin("__kcc_va_copy", Dst:RValue, tv(opaque(Src:Int, _), _))
               => checkDead(* Dst)
               ~> addVaList'(!N:Int, Dst, Args)
               ~> voidVal
          ...</k>
          <va-lists>... Src |-> Args:List ...</va-lists>
          [structural]
     rule <k> (.K => UNDEF("STDARG4",
                    "'va_copy' called on an uninitialized source va_list."))
               ~> builtin("__kcc_va_copy", _, tv(V::CValue, _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool (fromOpaque(V) in_keys(VaLists))
          [structural]

     rule [va-end]:
          <k> builtin("__kcc_va_end", tv(opaque(N:Int, _), _)) => voidVal ...</k>
          <va-lists>... N |-> _ => .Map ...</va-lists>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <live-va-lists>... SetItem(N) => .Set ...</live-va-lists>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          [structural]
     rule <k> (.K => UNDEF("STDARG5",
                    "'va_end' called on an uninitialized va_list."))
               ~> builtin("__kcc_va_end", tv(V::CValue, _))
          ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <live-va-lists> VaLists:Set </live-va-lists>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          requires notBool (fromOpaque(V) in VaLists)
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
          requires variadic in getParams(T) andBool isLastParamCorrect(T)
          [structural]

     syntax Bool ::= isLastParamCorrect(Type) [function]
     rule isLastParamCorrect(t(_, _, functionType(_, _ ListItem(T::DType) ListItem(variadic))))
          => notBool (isRegisterType(type(T)) orBool isArrayOrFunctionType(type(T)) orBool argPromoteType(utype(T)) =/=Type utype(T))

     rule <k> (.K => UNDEF("STDARG1",
                    "'va_start' used in a function with fixed args."))
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

     rule <k> (.K => UNDEF("STDARG10",
                    "'va_start' called on function whose last fixed argument is declared with the register storage class."))
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
          <gtypes>... F |-> t(_, _, functionType(_, _ ListItem(T::DType) ListItem(variadic))) ...</gtypes>
          requires isRegisterType(type(T))

     rule <k> (.K => UNDEF("STDARG11",
                    "'va_start' called on function whose last fixed argument is declared with function or array type."))
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
          <gtypes>... F |-> t(_, _, functionType(_, _ ListItem(T::DType) ListItem(variadic))) ...</gtypes>
          requires isArrayOrFunctionType(type(T))

     rule <k> (.K => UNDEF("STDARG12",
                    "'va_start' called on function whose last fixed argument is not compatible with type after default argument promotions."))
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
          <gtypes>... F |-> t(_, _, functionType(_, _ ListItem(T::DType) ListItem(variadic))) ...</gtypes>
          requires argPromoteType(utype(T)) =/=Type utype(T)

     rule <k> (.K => UNDEF("STDARG9",
                    "Function exited without calling 'va_end' after 'va_start' or 'va_copy'."))
               ~> return(_:RValue) ...</k>
          <live-va-lists> VaLists:Set </live-va-lists>
          requires VaLists =/=K .Set
          [structural]

endmodule
