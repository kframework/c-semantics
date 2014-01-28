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
          <k> (.K => deleteBlock(Loc)) ~> Return(_:KResult) ...</k>
          <localAddresses>... SetItem(Loc:SymLoc) => .Set ...</localAddresses>     
          [structural] 
          
     rule [fetch-all-locals]:
          <k> Return(_:KResult) ...</k>
          <localAddresses> .Set => Addresses </localAddresses>
          <blockStack> 
               ListItem(_ <localAddresses> Addresses:Set </localAddresses>)
               => .List
          ...</blockStack>
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
              F:Id |-> t(_, functionType(T:KResult, _))
          ...</gtypes>
          <control>
               <currTU> _ => OldTu </currTU>
               <currentFunction> (F:Id => CurrFun) </currentFunction>
               <currentProgramLoc> _ => CurrLoc </currentProgramLoc>
               (<controlDetails>... 
                    <local>... <localAddresses> .Set </localAddresses> ...</local> 
                    <blockStack> .List </blockStack> 
               ...</controlDetails>  => C)
          </control>
          <callStack>
               ListItem(
                    <callStackFrame>...
                         <continuation> K:K </continuation>
                         <stackControl>
                              <currTU> OldTu:String </currTU>
                              C:Bag
                         </stackControl>
                         <stackCurrentFunction>
                              CurrFun:K
                         </stackCurrentFunction>
                         <stackCurrentProgramLoc> 
                              CurrLoc:K
                         </stackCurrentProgramLoc>
                    ...</callStackFrame>
               ) => .List
          ...</callStack>
          [structural, large] 
endmodule
