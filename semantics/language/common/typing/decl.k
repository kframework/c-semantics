module C-TYPING-DECL
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-DECL-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= "giveGlobalType" "(" K "," Type ")"
     syntax K ::= "giveLocalType" "(" K "," Type ")"
     
     // FIXME these are here until I decide how to handle qualified types
     // rule [ignore-volatile]: t(S:Set, qualifiedType(t(S':Set, T:K), Volatile)) 
     //      => t(S:Set S':Set, T:K) 
     //      [structural, anywhere]
     // rule [ignore-atomic]: t(S:Set, qualifiedType(t(S':Set, T:K), Atomic)) 
     //      => t(S:Set S':Set, T:K) 
     //      [structural, anywhere]
     // rule [ignore-restrict]: t(S:Set, qualifiedType(t(S':Set, T:K), Restrict)) 
     //      => t(S:Set S':Set, T:K) 
     //      [structural, anywhere]
     // rule [ignore-auto]: t(S:Set, qualifiedType(t(S':Set, T:K), Auto)) 
     //      => t(S:Set S':Set, T:K) 
     //      [structural, anywhere]
     // rule [ignore-register]: t(S:Set, qualifiedType(t(S':Set, T:K), Register)) 
     //      => t(S:Set S':Set, T:K)
     //      [structural, anywhere]
     
     rule <k> giveType(X:Id, T:KResult) => 
               #if (Fun:Id ==K file-scope) 
               #then giveGlobalType(X:Id, unqualifyType(T:KResult)) 
               #else giveLocalType(X:Id, unqualifyType(T:KResult)) 
               #fi
          ...</k>
          <currentFunction> Fun:Id </currentFunction>
          [structural]
          
     rule <k> giveGlobalType(X:Id, T:KResult) => .K ...</k>
          <types> M:Map => M:Map[T:KResult / X:Id] </types>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <gtypes>
               M':Map => M':Map[T:KResult / X:Id]
          </gtypes>
          [structural]
     rule <k> giveLocalType(X:Id, T:KResult) => .K ...</k>
          <types> M:Map => M:Map[T:KResult / X:Id] </types>
          [structural]   
endmodule
