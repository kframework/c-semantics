module C-IO-SYNTAX
     syntax K ::= "writeToFD" "(" Int "," Int ")"
     syntax K ::= "writeToFD" "(" Int "," String ")"
     syntax K ::= "readFromFD" "(" Int ")"
     syntax K ::= "readFromFD" "(" Int "," Int ")"
     syntax K ::= "flush" "(" Int ")"
endmodule

module C-IO
     // fixme these should be computational, unless I handle that at a higher
     // level
     rule [writeToFD-char]:
          <k> writeToFD(FD:Int, N:Int) => .K ...</k>
          <fid> FD:Int </fid>
          <buff> 
               S:String => S:String +String #charString(N:Int %Int 256)
          </buff>
          [observable]
     rule [writeToFD-string]:
          <k> writeToFD(FD:Int, S':String) => .K ...</k>
          <fid> FD:Int </fid>
          <buff> S:String => S:String +String S':String </buff>
          [observable]
     rule [readFromFD-char]:
          <k> 
               readFromFD(FD:Int) 
               => tv(asciiString(firstChar(S:String)), t(.Set, int))  
          ...</k>
          <fid> FD:Int </fid>
          <buff> S:String => butFirstChar(S:String) </buff>
          // don't compare with "" in order to only treat string sort
          when lengthString(S:String) >Int 0
          [observable]
     rule [readFromFD-empty-buff]:
          <k> readFromFD(FD:Int) ...</k>
          <fid> FD:Int </fid>
          <buff> "" => "" +String #charString(#fReadByte(FD:Int)) </buff>
          [structural]
     rule [readFromFD-eof]:
          <k> readFromFD(FD:Int) => tv(-1, t(.Set, int)) ...</k>
          <fid> FD:Int </fid>
          <buff> #EOF </buff>
          [observable]

     rule [make-eof]:
          "" +String #charString(#EOF) => #EOF
          [structural, anywhere]
          
     syntax K ::= "f-sent" "(" Int "," String ")"
     syntax K ::= "f-flush" "(" Int ")"
     syntax K ::= "f-sendString" "(" Int "," String ")"
     
     // can't lex string2KList correctly in #fPrint(N:Int,,
     // string2KList(S:String))
     rule [flush]:
          <k> flush(N:Int) => .K ...</k>
          <fileCommands>... .K
               => f-sendString(N:Int, S:String)
               ~> f-sent(N:Int, S:String)
               ~> f-flush(N:Int)
          </fileCommands>
          <file>...
               <fid> N:Int </fid>
               <buff> S:String => "" </buff>
               <sending>... .List => ListItem(S:String) </sending>
          ...</file>
          [structural]

     rule [sendString-one]:
          <fileCommands> f-sendString(N:Int, S:String) 
               => (#fPutByte(N:Int, asciiString(firstChar(S:String)))
               ~> f-sendString(N:Int, butFirstChar(S:String)))
          ...</fileCommands>
          when S:String =/=String ""
          [structural]
     rule [sendString-done]:
          <fileCommands> f-sendString(_:Int, "") => .K ...</fileCommands>
          [structural]

     rule [f-sent]:
          <files>...
               <fileCommands> f-sent(N:Int, S:String) => .K ...</fileCommands>
               <fid> N:Int </fid>
               <sending> ListItem(S:String) => .List ...</sending>
               <done>... .List => ListItem(S:String) </done>
          ...</files>
          [structural]
     rule [f-flush]:
          <fileCommands> f-flush(N:Int) => #flush(N:Int) ...</fileCommands>
          [structural]
          
     rule [combine-done]:
          <done> 
               ListItem(S:String) ListItem(S':String) 
               => ListItem(S:String +String S':String) 
          ...</done>
          [structural]
endmodule

