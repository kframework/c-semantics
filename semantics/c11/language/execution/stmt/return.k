module C-STMT-RETURN
     imports RETURN-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports DELETE-OBJECT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8.6.4}{2}}}{
     A \cinline{return} statement terminates execution of the current function
     and returns control to its caller. A function may have any number of
     \cinline{return} statements.
     }

     \fromStandard{\source[n1570]{\para{6.8.6.4}{3}}}{
     If a \cinline{return} statement with an expression is executed, the value
     of the expression is returned to the caller as the value of the function
     call expression. If the expression has a type different from the return
     type of the function in which it appears, the value is converted as if by
     assignment to an object having the return type of the function.
     }*/

     // Return (from C function)
     rule <k> Return(V:RValue) => Return'(cast(T, V)) ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <gtypes>...
               F |-> t(_, Mods:Set, functionType(T::UType, _))
          ...</gtypes>
          requires notBool (Noreturn() in Mods)
          [structural]

     rule <k> Return(V:RValue) => Return'(cast(T, V)) ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> "builtin" </curr-tu>
          <types>...
               F |-> t(_, Mods:Set, functionType(T::UType, _))
          ...</types>
          requires notBool (Noreturn() in Mods)
          [structural]
     rule <k> Return(V:RValue) => Return'(cast(T, V)) ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> "native" </curr-tu>
          <types>...
               F |-> t(_, Mods:Set, functionType(T::UType, _))
          ...</types>
          requires notBool (Noreturn() in Mods)
          [structural]

     rule <k> (.K => UNDEF("ESR1", "Return from a function declared _Noreturn."))
               ~> Return(_)
          ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <gtypes>...
               F:CId |-> t(_, Mods:Set, _)
          ...</gtypes>
          requires Noreturn() in Mods
          [structural]

     rule <k> (.K => UNDEF("ESR1", "Return from a function declared _Noreturn."))
               ~> Return(_)
          ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> "native" </curr-tu>
          <types>...
               F:CId |-> t(_, Mods:Set, _)
          ...</types>
          requires Noreturn() in Mods
          [structural]

     syntax KItem ::= "Return'" "(" K ")"
     context Return'(HOLE:KItem => reval(HOLE)) [result(RValue)]

     /* recursively exits each Block wrapped in BlockStatement */
     rule <k> (.K => popBlock) ~> Return'(_:RValue) ...</k>
          <block-history> ListItem(_) ...</block-history>
          <block-stack> ListItem(_) ...</block-stack>
          [structural]
     /* delete the locals when the function body is not wrapped in Block */
     rule <k> Return'(V:RValue)
               => deleteObjects(Locals)
               ~> exitRestrictBlock(Locals)
               ~> return(V)
          ...</k>
          <local-addresses> Locals::Set </local-addresses>
          <block-history> .List </block-history>
          <block-stack> .List </block-stack>
          [structural]

     // Return (to C function)

     //  this is used for returns with no return value as well, since we return
     //  "emptyValue", which will hopefully be cast to void
     rule <k> return(V:RValue) ~> _
               => sequencePoint
               ~> checkUse(stripConstants(V))
               ~> K
          </k>
          (<function-control>
               <curr-tu> Tu::String </curr-tu>
               <curr-scope> blockScope(X::CId, _) </curr-scope>
               <live-va-lists> .Set </live-va-lists>
               <block-stack> .List </block-stack>
          ...</function-control> => <function-control> C </function-control>)
          <called-functions> Calls::Map => decrementCalled(X, Tu, Calls) </called-functions>
          <call-stack>
               ListItem(
                    <call-stack-frame>
                         <continuation> K:K </continuation>
                         <stack-function-control>
                              <function-control> C::Bag </function-control>
                         </stack-function-control>
                         <stack-lang-linkage> CLinkage </stack-lang-linkage>
                    </call-stack-frame>
               ) => .List
          ...</call-stack>
          [structural]

     syntax Map ::= decrementCalled(CId, String, Map) [function]
     rule decrementCalled(X::CId, Tu::String, (kpair(X, Tu) |-> 1) Calls::Map)
          => Calls
     rule decrementCalled(X::CId, Tu::String, (kpair(X, Tu) |-> N::Int) Calls::Map)
          => (kpair(X, Tu) |-> (N -Int 1)) Calls
          [owise]

endmodule
