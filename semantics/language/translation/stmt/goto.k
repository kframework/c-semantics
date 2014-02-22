module C-STMT-GOTO
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     rule <k> Goto(Lbl:Id) => . ...</k>
          <curr-function> F:Id </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F |-> map((_ (Lbl |-> _))) 
          ...</goto-map>
          [structural]
          
endmodule
