module LIBC-IO-SYNTAX
     syntax K ::= "writeToFD" "(" Int "," Int ")"
     syntax K ::= "writeToFD" "(" Int "," String ")"
     syntax K ::= "readFromFD" "(" Int ")"
     syntax K ::= "readFromFD" "(" Int "," Int ")"
     syntax K ::= "flush" "(" Int ")"
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
          <k> 
               readFromFD(FD:Int) 
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
          <nextByte> .K => chrChar(#fReadByte(FD)) </nextByte>
          <buff> "" </buff>
          [structural]
     rule <nextByte> Byte:String => .K </nextByte>
          <buff> Buff:String => Buff +String Byte </buff>
          [structural]
     rule <k> readFromFD(FD:Int) => tv(-1, t(.Set, int)) ...</k>
          <fid> FD </fid>
          <nextByte> #EOF </nextByte>
          [observable]

     syntax K ::= "f-sent" "(" Int "," String ")"
     syntax K ::= "f-flush" "(" Int ")"
     syntax K ::= "f-sendString" "(" Int "," String ")"
     
     // can't lex string2KList correctly in #fPrint(N:Int,,
     // string2KList(S:String))
     rule [flush]:
          <k> flush(FD:Int) => .K ...</k>
          <fileCommands>... 
               .K
               => f-sendString(FD, S)
                    ~> f-sent(FD, S)
                    ~> f-flush(FD)
          </fileCommands>
          <file>...
               <fid> FD </fid>
               <buff> S:String => "" </buff>
               <sending>... .List => ListItem(S) </sending>
          ...</file>
          [structural]

     rule [sendString-one]:
          <fileCommands> 
               f-sendString(FD:Int, S:String) 
               => (#fPutByte(FD, ordChar(firstChar(S)))
                    ~> f-sendString(FD, butFirstChar(S)))
          ...</fileCommands>
          when S =/=String ""
          [structural]
     rule [sendString-done]:
          <fileCommands> f-sendString(_, "") => .K ...</fileCommands>
          [structural]

     rule [f-sent]:
          <files>...
               <fileCommands> f-sent(FD:Int, S:String) => .K ...</fileCommands>
               <fid> FD </fid>
               <sending> ListItem(S) => .List ...</sending>
               <done>... .List => ListItem(S) </done>
          ...</files>
          [structural]
     rule [f-flush]:
          <fileCommands> f-flush(FD:Int) => #flush(FD) ...</fileCommands>
          [structural]
          
     rule [combine-done]:
          <done> 
               ListItem(S:String) ListItem(S':String) 
               => ListItem(S +String S') 
          ...</done>
          [structural]
endmodule

