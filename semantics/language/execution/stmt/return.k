module C-STMT-RETURN
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX

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
     
     rule [return-clean-local]:
          <k> (.K => deleteObject(Base)) ~> Return(_:KResult) ...</k>
          <local-addresses>... SetItem(Base:SymBase) => .Set ...</local-addresses>     
          [structural] 
          
     rule [fetch-all-locals]:
          <k> Return(_:KResult) ...</k>
          <local-addresses> .Set => Addresses </local-addresses>
          <block-stack> 
               ListItem(bag2K(_ <local-addresses> Addresses:Set </local-addresses>))
               => .List
          ...</block-stack>
          [structural] 

     //  this is used for returns with no return value as well, since we return
     //  "emptyValue", which will hopefully be cast to void
     rule [return]: 
          <k> Return(V:KResult) ~> _
               => sequencePoint 
               ~> cast(T, V) 
               ~> K
          </k>
          // We look up the function type in the caller's TU because this might
          // be a builtin (i.e., we're in a fake TU with no type env).
          <tu-id> OldTu </tu-id>
          <gtypes>... 
              F:CId |-> t(_, functionType(T:Type, _))
          ...</gtypes>
          <control>
               <curr-tu> _ => OldTu </curr-tu>
               <curr-function> (F:CId => CurrFun) </curr-function>
               <curr-function-params> _ => CurrFunParams </curr-function-params>
               <curr-program-loc> _ => CurrLoc </curr-program-loc>
               (<control-details>... 
                    <local>... <local-addresses> .Set </local-addresses> ...</local> 
                    <block-stack> .List </block-stack> 
               ...</control-details>  => C)
          </control>
          <call-stack>
               ListItem(bag2K(
                    <call-stack-frame>...
                         <continuation> K:K </continuation>
                         <stack-control>
                              <curr-tu> OldTu:String </curr-tu>
                              C:Bag
                         </stack-control>
                         <stack-curr-function>
                              CurrFun:K
                         </stack-curr-function>
                         <stack-curr-function-params>
                              CurrFunParams:List
                         </stack-curr-function-params>
                         <stack-curr-program-loc> 
                              CurrLoc:K
                         </stack-curr-program-loc>
                    ...</call-stack-frame>
               )) => .List
          ...</call-stack>
          [structural] 
endmodule
