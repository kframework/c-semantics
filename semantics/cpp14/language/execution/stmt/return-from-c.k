module C-CPP-EXECUTION-STMT-RETURN
     imports C-CONFIGURATION
     imports RETURN-SYNTAX
     imports CPP-STMT-RETURN-SYNTAX
     imports C-CPP-VAL-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule <k> return(V:RValue => convertValToCPP(V)) ...</k>
          <call-stack>
               ListItem(
                    <call-stack-frame>...
                         <stack-lang-linkage> CPPLinkage </stack-lang-linkage>
                    ...</call-stack-frame>
               )
          ...</call-stack>

endmodule
