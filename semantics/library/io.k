module LIBC-IO-SYNTAX
     syntax K ::= writeToFD(Int, Int)
     syntax K ::= writeToFD(Int, String)
     syntax K ::= readFromFD(Int)
     syntax K ::= readFromFD(Int, Int)
     syntax K ::= flush(Int)
     syntax K ::= "f-flush" "(" Int ")"

     syntax ExecOpts ::= "NOIO"
endmodule

module LIBC-IO
     imports LIBC-IO-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     // fixme these should be computational, unless I handle that at a higher
     // level
     rule [writeToFD-char]:
          <k> writeToFD(FD:Int, N:Int) => .K ...</k>
          <fid> FD </fid>
          <buff> 
               S:String => S:String +String chrChar(N:Int %Int 256)
          </buff>
          [observable]
     rule [writeToFD-string]:
          <k> writeToFD(FD:Int, S':String) => .K ...</k>
          <fid> FD </fid>
          <buff> S:String => S:String +String S':String </buff>
          [observable]
     rule [readFromFD-char]:
          <k> readFromFD(FD:Int) 
               => tv(ordChar(firstChar(S:String)), t(.Set, int))  
          ...</k>
          <fid> FD </fid>
          <buff> S:String => butFirstChar(S:String) </buff>
          // don't compare with "" in order to only treat string sort
          when lengthString(S:String) >Int 0
          [observable]

     rule [readFromFD-empty-buff]:
          <k> readFromFD(FD:Int) ...</k>
          <fid> FD </fid>
          <next-byte> .K => chrChar(#getc(FD)) </next-byte>
          <buff> "" </buff>
          [structural]
     rule <next-byte> Byte:String => .K </next-byte>
          <buff> Buff:String => Buff +String Byte </buff>
          [structural]
     rule <k> readFromFD(FD:Int) => tv(-1, t(.Set, int)) ...</k>
          <fid> FD </fid>
          <next-byte> #EOF </next-byte>
          [observable]

     rule <next-byte> chrChar((#EOF)::K) => #EOF </next-byte>
          [structural, simplification]

     syntax K ::= "f-sent" "(" Int "," String ")"
     syntax K ::= "f-sendString" "(" Int "," String ")"
     
     rule [flush]:
          <k> flush(FD:Int) => .K ...</k>
          <file-commands>... 
               . => f-flush(FD)
          </file-commands>
          [structural]
     rule [f-flush]:
          <file-commands>
               f-flush(FD:Int)
               => f-sendString(FD, S)
               ~> f-sent(FD, S)
          ...</file-commands>
          <file>...
               <fid> FD:Int </fid>
               <buff> S:String => "" </buff>
               <sending>... .List => ListItem(S) </sending>
          ...</file>
          [structural]

     rule [sendString-one]:
          <file-commands> 
               f-sendString(FD:Int, S:String) 
               => (#putc(FD, ordChar(firstChar(S)))
                    ~> f-sendString(FD, butFirstChar(S)))
          ...</file-commands>
          <options> Opts:Set </options>
          when (S =/=String "")
               andBool notBool (NOIO in Opts)
          [structural]
     rule <file-commands> 
               f-sendString(_, _) => .
          ...</file-commands>
          <options> SetItem(NOIO) ...</options>
          [structural]
     rule [sendString-done]:
          <file-commands> f-sendString(_, "") => . ...</file-commands>
          [structural]

     rule [f-sent]:
          <file-commands> f-sent(FD:Int, S:String) => . ...</file-commands>
          <file>...
               <fid> FD </fid>
               <sending> ListItem(S) => .List ...</sending>
               <done>... .List => ListItem(S) </done>
          ...</file>
          [structural]
          
     rule [combine-done]:
          <done> 
               ListItem(S:String) ListItem(S':String) 
               => ListItem(S +String S') 
          ...</done>
          [structural]
endmodule

