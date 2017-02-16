module LIBC-IO-SYNTAX
     imports INT-SYNTAX
     imports K-IO
     imports STRING-SYNTAX
     imports SYMLOC-SYNTAX

     syntax KItem ::= writeFD(FD, Int)
     syntax KItem ::= writeFD(FD, String)
     syntax KItem ::= unget(FD, String)
     syntax KItem ::= readFD(FD, Int)
     syntax KItem ::= flush(FD)
     syntax KItem ::= tell(FD)
     syntax KItem ::= seek(FD, Int, SeekWhence)
     syntax KItem ::= close(FD)
     syntax KItem ::= setBuf(FD, BufMode, Int)

     syntax ExecOpts ::= NoIO()

     syntax SeekWhence ::= "seekSet" | "seekCur"
     syntax BufMode ::= "fullBuf" | "lineBuf" | "noBuf"

     syntax FD ::= Int | String

     // getString returns the string without the null terminator
     syntax KItem ::= getString(K) [strict]
                    | getWString(K) [strict]
                    | getBytes(K, Int) [strict(1)]
     syntax KItem ::= "getString'" "(" SymLoc ")" [function]
                    | "getWString'" "(" SymLoc ")" [function]

     syntax RValue ::= str(String)

     syntax Int ::= pointerToInt(CValue) [function]
     syntax String ::= pointerToString(SymLoc) [function]

     syntax Int ::= "bufSiz" [function]

endmodule

module LIBC-IO
     imports BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports K-IO
     imports LIBC-IO-SYNTAX
     imports LIBC-SYNTAX
     imports STRING

     rule writeFD(FD::FD, N:Int) => writeFD(FD, chrChar(N %Int 256))
          [structural]
     // Line buffered.
     rule <k> writeFD(FD::FD, S':String) => .K ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          requires findChar(S', "\n", 0) ==Int -1
          [observable]
     rule <k> writeFD(FD::FD, S':String) => flush(FD) ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          requires findChar(S', "\n", 0) =/=Int -1
          [observable]
     // Fully buffered.
     rule <k> writeFD(FD::FD, S':String) => .K ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          requires lengthString(S +String S') <Int N
          [observable]
     rule <k> writeFD(FD::FD, S':String) => flush(FD) ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          requires lengthString(S +String S') >=Int N
          [observable]
     // No buffer.
     rule <k> writeFD(FD::FD, S':String) => flush(FD) ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <buffer-mode> noBuf </buffer-mode>
          [observable]

     // TODO(chathhorn): need separate unget buffer.
     rule <k> unget(FD::FD, S':String) => .K ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos -Int 1 </pos>
          <next-byte> _ => .K </next-byte>
          <read-buffer> S:String => S' +String S </read-buffer>
          [observable]

     rule <k> readFD(FD::FD, N::Int) => str(substrString(S, 0, N)) ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int N </pos>
          <read-buffer> S:String => substrString(S, N, lengthString(S)) </read-buffer>
          // don't compare with "" in order to only treat string sort
          requires lengthString(S) >=Int N
          [observable]
     rule <k> readFD(FD::FD, N::Int) => str(S) ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S) </pos>
          <feof> Eof:Bool </feof>
          <ferror> Err:K </ferror>
          <read-buffer> S:String => "" </read-buffer>
          requires lengthString(S) <Int N
               andBool (Eof ==K true orBool Err =/=K .K)
          [observable]
     rule <k> readFD(FD:String, N::Int) => str(S) ...</k>
          <fid> FD </fid>
          <pos> Pos::Int => Pos +Int lengthString(S) </pos>
          <read-buffer> S:String </read-buffer>
          requires lengthString(S) <Int N
          [observable]
     rule <k> (.K => fillBuffer(FD)) ~> readFD(FD:Int, N::Int) ...</k>
          <fid> FD </fid>
          <feof> false </feof>
          <ferror> .K </ferror>
          <read-buffer> S:String </read-buffer>
          requires lengthString(S) <Int N
          [structural]

     syntax KItem ::= fillBuffer(FD)
     rule <k> fillBuffer(FD:Int) ...</k>
          <fid> FD </fid>
          <next-byte> .K => #getc(FD) </next-byte>
          [structural]
     rule <k> fillBuffer(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> -1 </next-byte>
          <feof> _ => true </feof>
          [structural]
     // Line buffered.
     rule <k> fillBuffer(FD::FD) ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          requires Byte =/=Int ordChar("\n")
               andBool Byte =/=Int -1
          [structural]
     rule <k> fillBuffer(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          requires Byte ==Int ordChar("\n")
          [structural]
     // Fully buffered.
     rule <k> fillBuffer(FD::FD) ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          requires lengthString(S) +Int 1 <Int N
               andBool Byte =/=Int -1
          [structural]
     rule <k> fillBuffer(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          requires lengthString(S) +Int 1 >=Int N
               andBool Byte =/=Int -1
          [structural]
     // No buffer.
     rule <k> fillBuffer(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> noBuf </buffer-mode>
          requires Byte =/=Int -1
          [structural]

     rule <k> setBuf(FD:Int, Mode::BufMode, Sz::Int) => .K ...</k>
          <fid> FD </fid>
          <buffer-mode> _ => Mode </buffer-mode>
          <buffer-size> _ => Sz </buffer-size>
          [structural]

     rule <k> close(FD:Int) => #close(FD) ...</k>
          <open-files>... SetItem(FD) => .Set </open-files>
          (<file>... <fid> FD </fid> ...</file> => .Bag)
          [structural]
     rule <k> close(FD:String) => .K ...</k>
          <open-files>... SetItem(FD) => .Set </open-files>
          (<file>... <fid> FD </fid> ...</file> => .Bag)
          [structural]

     rule seek(FD:Int, Offset::Int, seekSet)
          => #seek(FD, Offset) ~> seek'(FD)
          [structural]
     rule <k> seek(FD:Int, Offset::Int, seekCur)
               => #seek(FD, Pos +Int Offset)
               ~> seek'(FD)
          ...</k>
          <fid> FD </fid>
          <pos> Pos:Int </pos>
          [structural]

     syntax KItem ::= "seek'" "(" Int ")"
     rule <k> seek'(FD:Int) => .K ...</k>
          <fid> FD </fid>
          <pos> _ => #tell(FD) </pos>
          <next-byte> _ => .K </next-byte>
          <read-buffer> _ => "" </read-buffer>
          <write-buffer> _ => "" </write-buffer>
          [structural]

     rule <k> flush(FD:Int)
               => sendString(FD, S)
               ~> sent(FD, S)
          ...</k>
          <fid> FD </fid>
          <write-buffer> S:String => "" </write-buffer>
          <sending>... .List => ListItem(S) </sending>
          [structural]

     rule <k> tell(FD::FD) => Pos ...</k>
          <fid> FD </fid>
          <pos> Pos:Int </pos>
          [observable]

     syntax KItem ::= sendString(Int, String)
     rule <k> sendString(FD::Int, S::String)
               => #putc(FD, ordChar(firstChar(S)))
               ~> sendString(FD, butFirstChar(S))
          ...</k>
          <options> Opts::Set </options>
          requires lengthString(S) >Int 0
               andBool notBool (NoIO() in Opts)
     rule <k> sendString(FD::Int, S::String) => .K ...</k>
          <options> Opts::Set </options>
          requires lengthString(S) <=Int 0
               orBool (NoIO() in Opts)

     syntax KItem ::= sent(Int, String)
     rule <k> sent(FD::Int, S::String) => .K ...</k>
          <fid> FD </fid>
          <sending> ListItem(S) => .List ...</sending>
          <done> Sent::String => Sent +String S </done>
          [structural]

     rule getString(tv(Loc:SymLoc, _)) => getString'(Loc)
          [structural]

     rule getString'(Loc::SymLoc) => getString'(Loc, "")

     syntax KItem ::= "getString'" "(" SymLoc "," String ")"
     rule (.K => read(Loc, type(unsigned-char)))
          ~> getString'(Loc::SymLoc => Loc +bytes 1, _)
          [structural]
     rule tv(C:Int, _) ~> getString'(Loc::SymLoc, S::String)
          => getString'(Loc, S +String chrChar(C))
          requires C =/=Int 0
          [structural]
     rule tv(0, _) ~> getString'(_, S::String)
          => str(S)
          [structural]

     rule getWString(tv(Loc::SymLoc, _)) => getWString'(Loc)
          [structural]

     rule getWString'(Loc::SymLoc) => getWString'(Loc, "")

     syntax KItem ::= "getWString'" "(" SymLoc "," String ")"
     rule (.K => read(Loc, type(cfg:wcharut)))
          ~> getWString'(Loc::SymLoc => Loc +bytes byteSizeofType(type(cfg:wcharut)), _)
          [structural]
     rule tv(C:Int, _) ~> getWString'(Loc::SymLoc, S::String)
          => getWString'(Loc, S +String chrChar(C))
          requires C =/=Int 0
          [structural]
     rule tv(0, _) ~> getWString'(_, S::String)
          => str(S)
          [structural]

     rule getBytes(tv(Loc:SymLoc, _), N::Int) => getBytes'(Loc, N, "")
          [structural]

     syntax KItem ::= "getBytes'" "(" SymLoc "," Int "," String ")"
     rule (.K => read(Loc, type(unsigned-char)))
          ~> getBytes'(Loc::SymLoc => Loc +bytes 1, N::Int => N -Int 1, _)
          requires N >Int 0
          [structural]
     rule tv(B:Int, _) ~> getBytes'(Loc::SymLoc, N::Int, S::String)
          => getBytes'(Loc, N, S +String chrChar(B))
          [structural]
     rule tv(encodedValue(B:SymLoc, From::Int, To::Int), _) ~> getBytes'(Loc::SymLoc, N::Int, S::String)
          => getBytes'(Loc, N, S +String chrChar(bitsValue(pointerToInt(cfg:pointerToInt(B, utype(int))), From, To)))
          [structural]
     rule getBytes'(_, 0, S::String) => str(S)
          [structural]

     rule pointerToInt(V:Int) => V
     rule pointerToInt(_) => 0 [owise]

     rule pointerToString(Loc:SymLoc)
          => "[sym(" +String symBaseToString(base(Loc)) +String ") + "
               +String Int2String(offset(Loc)) +String "]"
          requires notBool isNativeLoc(Loc)
               andBool Loc =/=K NullPointer

     rule pointerToString(Loc:SymLoc => stripProv(Loc))
          requires isNativeLoc(Loc)
     rule pointerToString(loc(0 @ nativeAddress(), Addr:Int))
          => "0x" +String Base2String(Addr, 16)

     rule pointerToString(NullPointer) => "NullPointer"

     syntax String ::= symBaseToString(SymBase) [function]
     rule symBaseToString(B:Int @ threadLocal(Th:Int))
          => Int2String(B) +String " @ "
          +String "threadLocal(" +String Int2String(Th) +String ")"
     rule symBaseToString(B:Int @ alloc)
          => Int2String(B) +String " @ "
          +String "allocated"
     rule symBaseToString(B:Int @ static(Tu:String))
          => Int2String(B) +String " @ "
          +String "static(" +String substrString(Tu, 0, lengthString(Tu) -Int 36) +String ")"
     rule symBaseToString(B:Int @ link(Tu:String))
          => Int2String(B) +String " @ "
          +String "link(" +String substrString(Tu, 0, lengthString(Tu) -Int 36) +String ")"
     rule symBaseToString(B:Int @ auto(Th:Int))
          => Int2String(B) +String " @ "
          +String "auto(" +String Int2String(Th) +String ")"

     rule bufSiz => 8192

endmodule

