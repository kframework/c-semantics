module LIBC-IO-SYNTAX
     imports INT-SYNTAX
     imports K-IO
     imports STRING-SYNTAX
     imports SYMLOC-SYNTAX

     syntax KItem ::= writeFD(FD, Int)
     syntax KItem ::= writeFD(FD, String)
     syntax KItem ::= unget(FD, String)
     syntax KItem ::= readFD(FauxFD, Int)
     syntax KItem ::= flush(FD)
     syntax KItem ::= "flushAll"
     syntax KItem ::= tell(FD)
     syntax KItem ::= seek(FD, Int, SeekWhence)
     syntax KItem ::= close(FauxFD)
     syntax KItem ::= setBuf(FD, BufMode, Int)

     syntax SeekWhence ::= "seekSet" | "seekCur" | "seekEnd"
     syntax BufMode ::= "fullBuf" | "lineBuf" | "noBuf"

     syntax FD ::= Int
     syntax FauxFD ::= FD | String

     // getString returns the string without the null terminator
     syntax KItem ::= getString(K) [strict]
                    | getWString(K) [strict]
                    | getBytes(K, Int) [strict(1)]
     syntax KItem ::= "getString'" "(" SymLoc ")" [function]
                    | "getString'" "(" SymLoc "," Int ")" [function]
                    | "getWString'" "(" SymLoc ")" [function]
                    | "getWString'" "(" SymLoc "," Int ")" [function]

     syntax KItem ::= newFixedObject(K) [strict]

     syntax RValue ::= str(String)

     syntax Int ::= pointerToInt(SymLoc) [function]
     syntax String ::= pointerToString(SymLoc) [function]

     syntax Int ::= "bufSiz" [function]

     syntax LastFileOp ::= "noLastOp"
                         | "outputOp" | "flushOp"
                         | "seekOp"
                         | "inputOp"

     syntax KItem ::= setErrno(IOError) [function]

endmodule

module LIBC-IO
     imports LIBC-IO-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports K-IO
     imports STRING
     imports BITS-SYNTAX
     imports OPTIONS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-OS-SETTINGS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-TYPES-SYNTAX

     rule writeFD(FD::FD, N:Int) => writeFD(FD, chrChar(N %Int 256))
          [structural]
     // Line buffered.
     rule <k> writeFD(FD::FD, S':String) => .K ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <read-buffer> RS:String </read-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          <feof> Eof:Bool </feof>
          <last-op> Op:LastFileOp => outputOp </last-op>
          requires findChar(S', "\n", 0) ==Int -1
               andBool notBool (Op ==K inputOp andBool (Eof impliesBool (RS =/=String "")))
          [observable]
     rule <k> writeFD(FD::FD, S':String) => flush(FD) ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <read-buffer> RS:String </read-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          <feof> Eof:Bool </feof>
          <last-op> Op:LastFileOp => outputOp </last-op>
          requires findChar(S', "\n", 0) =/=Int -1
               andBool notBool (Op ==K inputOp andBool (Eof impliesBool (RS =/=String "")))
          [observable]
     // Fully buffered.
     rule <k> writeFD(FD::FD, S':String) => .K ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <read-buffer> RS:String </read-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          <feof> Eof:Bool </feof>
          <last-op> Op:LastFileOp => outputOp </last-op>
          requires lengthString(S +String S') <Int N
               andBool notBool (Op ==K inputOp andBool (Eof impliesBool (RS =/=String "")))
          [observable]
     rule <k> writeFD(FD::FD, S':String) => flush(FD) ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <read-buffer> RS:String </read-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          <feof> Eof:Bool </feof>
          <last-op> Op:LastFileOp => outputOp </last-op>
          requires lengthString(S +String S') >=Int N
               andBool notBool (Op ==K inputOp andBool (Eof impliesBool (RS =/=String "")))
          [observable]
     // No buffer.
     rule <k> writeFD(FD::FD, S':String) => flush(FD) ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S') </pos>
          <write-buffer> S:String => S +String S' </write-buffer>
          <read-buffer> RS:String </read-buffer>
          <buffer-mode> noBuf </buffer-mode>
          <feof> Eof:Bool </feof>
          <last-op> Op:LastFileOp => outputOp </last-op>
          requires notBool (Op ==K inputOp andBool (Eof impliesBool (RS =/=String "")))
          [observable]
     rule <k> (.K => UNDEF("IO1", "Stream input operation followed by an output operation without an intervening call to a file positioning function."))
               ~> writeFD(FD::FD, _:String)
          ...</k>
          <fid> FD </fid>
          <feof> Eof:Bool </feof>
          <read-buffer> RS:String </read-buffer>
          <last-op> inputOp </last-op>
          requires Eof impliesBool (RS =/=String "")
          [structural]

     // TODO(chathhorn): need separate unget buffer.
     rule <k> unget(FD::FD, S':String) => .K ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos -Int 1 </pos>
          <next-byte> _ => .K </next-byte>
          <read-buffer> S:String => S' +String S </read-buffer>
          [observable]

     rule <k> readFD(FD::FD, N::Int) => flushAll ~> readFD'(FD, N) ...</k>
          <fid> FD </fid>
          <buffer-mode> noBuf </buffer-mode>
          [structural]
     rule <k> readFD(FD::FD, N::Int) => readFD'(FD, N) ...</k>
          <fid> FD </fid>
          <buffer-mode> Mode::BufMode </buffer-mode>
          requires Mode =/=K noBuf
          [structural]

     syntax KItem ::= "readFD'" "(" FauxFD "," Int ")"
     rule <k> readFD'(FD::FD, N::Int) => str(substrString(S, 0, N)) ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int N </pos>
          <read-buffer> S:String => substrString(S, N, lengthString(S)) </read-buffer>
          <last-op> Op:LastFileOp => inputOp </last-op>
          // don't compare with "" in order to only treat string sort
          requires lengthString(S) >=Int N
               andBool Op =/=K outputOp
          [observable]
     rule <k> readFD'(FD::FD, N::Int) => str(S) ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S) </pos>
          <feof> Eof:Bool </feof>
          <ferror> Err:Int </ferror>
          <read-buffer> S:String => "" </read-buffer>
          <last-op> Op:LastFileOp => inputOp </last-op>
          requires lengthString(S) <Int N
               andBool (Eof orBool Err =/=Int 0)
               andBool Op =/=K outputOp
          [observable]
     rule <k> readFD'(FD:String, N::Int) => str(S) ...</k>
          <fid> FD </fid>
          <pos> Pos:Int => Pos +Int lengthString(S) </pos>
          <feof> false => true </feof>
          <ferror> 0 </ferror>
          <read-buffer> S:String => "" </read-buffer>
          <last-op> Op:LastFileOp => inputOp </last-op>
          requires lengthString(S) <Int N
               andBool Op =/=K outputOp
          [observable]
     rule <k> (.K => fillBuffer(FD)) ~> readFD'(FD:Int, N::Int) ...</k>
          <fid> FD </fid>
          <feof> false </feof>
          <ferror> 0 </ferror>
          <read-buffer> S:String </read-buffer>
          requires lengthString(S) <Int N
          [structural]
     rule <k> (.K => UNDEF("IO2", "Stream output operation followed by an input operation without an intervening call to fflush or a file positioning function."))
               ~> readFD'(FD::FD, N::Int)
          ...</k>
          <fid> FD </fid>
          <last-op> outputOp </last-op>
          [structural]

     syntax KItem ::= fillBuffer(FD)
     rule <k> fillBuffer(FD::FD) => flushAll ~> fillBuffer'(FD) ...</k>
          <fid> FD </fid>
          <buffer-mode> lineBuf </buffer-mode>
          [structural]
     rule <k> fillBuffer(FD::FD) => fillBuffer'(FD) ...</k>
          <fid> FD </fid>
          <buffer-mode> Mode::BufMode </buffer-mode>
          requires Mode =/=K lineBuf
          [structural]

     syntax KItem ::= "fillBuffer'" "(" FD ")"
     rule <k> fillBuffer'(FD:Int) ...</k>
          <fid> FD </fid>
          <next-byte> .K => #getc(FD) </next-byte>
          [structural]
     rule <k> fillBuffer'(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> -1 </next-byte>
          <feof> _ => true </feof>
          [structural]
     // Line buffered.
     rule <k> fillBuffer'(FD::FD) ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          requires Byte =/=Int ordChar("\n")
               andBool Byte =/=Int -1
          [structural]
     rule <k> fillBuffer'(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> lineBuf </buffer-mode>
          requires Byte ==Int ordChar("\n")
          [structural]
     // Fully buffered.
     rule <k> fillBuffer'(FD::FD) ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          requires lengthString(S) +Int 1 <Int N
               andBool Byte =/=Int -1
          [structural]
     rule <k> fillBuffer'(FD::FD) => .K ...</k>
          <fid> FD </fid>
          <next-byte> Byte:Int => .K </next-byte>
          <read-buffer> S:String => S +String chrChar(Byte) </read-buffer>
          <buffer-mode> fullBuf </buffer-mode>
          <buffer-size> N:Int </buffer-size>
          requires lengthString(S) +Int 1 >=Int N
               andBool Byte =/=Int -1
          [structural]
     // No buffer.
     rule <k> fillBuffer'(FD::FD) => .K ...</k>
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
          <open-files>... FD |-> _ => .Map </open-files>
          (<file>... <fid> FD </fid> ...</file> => .Bag)
          [structural]
     rule <k> close(FD:String) => .K ...</k>
          <open-files>... FD |-> _ => .Map </open-files>
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
     rule seek(FD:Int, Offset::Int, seekEnd)
          => #seekEnd(FD, Offset)
          ~> seek'(FD)
          [structural]


     syntax KItem ::= "seek'" "(" Int ")"
     rule <k> seek'(FD:Int) => .K ...</k>
          <fid> FD </fid>
          <pos> _ => #tell(FD) </pos>
          <next-byte> _ => .K </next-byte>
          <read-buffer> _ => "" </read-buffer>
          <write-buffer> _ => "" </write-buffer>
          <last-op> _ => seekOp </last-op>
          [structural]

     rule <k> flushAll => flushAll'(keys(OpenFiles)) ...</k>
          <open-files> OpenFiles::Map </open-files>
          [structural]

     syntax KItem ::= "flushAll'" "(" Set ")"
     rule (.K => flush(FD)) ~> flushAll'((SetItem(FD::FD) => .Set) _)
          [structural]
     rule flushAll'(.Set) => .K
          [structural]

     rule <k> flush(FD:Int)
               => sendString(FD, S)
               ~> sent(FD, S)
          ...</k>
          <fid> FD </fid>
          <write-buffer> S:String => "" </write-buffer>
          <sending>... .List => ListItem(S) </sending>
          [structural]
     rule <k> flush(FD:Int) => .K ...</k>
          <open-files> OpenFiles::Map </open-files>
          requires notBool (FD in_keys(OpenFiles))
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

     rule getString'(Loc::SymLoc, N::Int) => getString'(Loc, N, "")

     rule getString'(Loc::SymLoc) => getString'(Loc, -1, "")

     syntax KItem ::= "getString'" "(" SymLoc "," Int "," String ")"
     rule (.K => reval(instantiate(Loc, type(unsigned-char))))
          ~> getString'(Loc::SymLoc => Loc +bytes 1, N::Int => N -Int 1, _)
          requires N =/=Int 0
          [structural]
     rule reval(tv(C:Int, _)) ~> getString'(Loc::SymLoc, N::Int, S::String)
          => getString'(Loc, N, S +String chrChar(C))
          requires C =/=Int 0
          [structural]
     rule reval(tv(0, _)) ~> getString'(_, _, S::String)
          => str(S)
          [structural]
     rule getString'(_, 0, S::String)
          => str(S)
          [structural]

     rule getWString(tv(Loc::SymLoc, _)) => getWString'(Loc, .K)
          [structural]

     rule getWString'(Loc::SymLoc, N::Int) => getWString'(Loc, N, "")

     rule getWString'(Loc::SymLoc) => getWString'(Loc, -1, "")

     syntax KItem ::= "getWString'" "(" SymLoc "," Int "," String ")"
     rule (.K => reval(instantiate(Loc, type(cfg:wcharut))))
          ~> getWString'(Loc::SymLoc => Loc +bytes byteSizeofType(type(cfg:wcharut)), N::Int => N -Int byteSizeofType(type(cfg:wcharut)), _)
          requires notBool (N >=Int 0 andBool N <Int byteSizeofType(type(cfg:wcharut)))
          [structural]
     rule reval(tv(C:Int, _)) ~> getWString'(Loc::SymLoc, N::Int, S::String)
          => getWString'(Loc, N, S +String chrChar(C))
          requires C =/=Int 0
          [structural]
     rule reval(tv(0, _)) ~> getWString'(_, _, S::String)
          => str(S)
          [structural]
     rule getWString'(_, N::Int, S::String)
          => str(S)
          requires N >=Int 0 andBool N <Int byteSizeofType(type(cfg:wcharut))
          [structural]

     rule getBytes(tv(Loc:SymLoc, _), N::Int) => getBytes'(Loc, N, "")
          [structural]

     syntax KItem ::= "getBytes'" "(" SymLoc "," Int "," String ")"
     rule (.K => reval(instantiate(Loc, type(unsigned-char))))
          ~> getBytes'(Loc::SymLoc => Loc +bytes 1, N::Int => N -Int 1, _)
          requires N >Int 0
          [structural]
     rule reval(tv(B:Int, _)) ~> getBytes'(Loc::SymLoc, N::Int, S::String)
          => getBytes'(Loc, N, S +String chrChar(B))
          [structural]
     rule reval(tv(encodedPtr(B:SymLoc, From::Int, To::Int), _)) ~> getBytes'(Loc::SymLoc, N::Int, S::String)
          => getBytes'(Loc, N, S +String chrChar(bitsValue(pointerToInt(B), From, To)))
          [structural]
     rule getBytes'(_, 0, S::String) => str(S)
          [structural]
     rule (.K => UNSPEC("IO3", "Reading an unspecified value."))
          ~> reval(tv(unknown(_), _)) ~> getBytes'(_, _, _)
          [structural]

     rule pointerToInt(Loc::SymLoc) => unknownToInt(cfg:pointerToInt(Loc, utype(int)))

     syntax Int ::= unknownToInt(CValue) [function]
     rule unknownToInt(V:Int) => V
     rule unknownToInt(unknown(V:Int)) => V
     rule unknownToInt(_) => 0 [owise]

     rule pointerToString(Loc::SymLoc) => zeroToNil(Base2String(pointerToInt(Loc), 16))

     syntax String ::= zeroToNil(String) [function]
     rule zeroToNil("0") => "(nil)"
     rule zeroToNil(S::String) => "0x" +String S [owise]

     rule bufSiz => 8192

     rule getErrno(#unknownIOError(I::Int)) => I
     rule setErrno(Err:IOError) => Computation(Identifier("errno") := tv(getErrno(Err), utype(int)))

     rule newFixedObject(tv(_, T::UType) #as V::RValue => getString(V))
          requires isCharType(innerType(T))
               andBool notBool isNull(V)
          [structural]
     rule newFixedObject(str(Value::String))
          => newFixedString(bnew(!_:Int, arr(char, lengthString(Value) +Int 1), libcFixed), Value)
          [structural]
     rule newFixedObject(tv(Loc:SymLoc, T::UType) #as V::RValue)
          => newFixedObject'(readBytes(Loc, byteSizeofType(innerType(T)), innerType(T)), innerType(T))
          requires notBool isCharType(innerType(T))
               andBool notBool isNull(V)
          [structural]
     rule newFixedObject(V::RValue) => V
          requires isNull(V)
          [structural]

     syntax KItem ::= "newFixedObject'" "(" K "," Type ")" [strict(1)]
     rule newFixedObject'(dataList(Bytes::List), T::Type)
          => newFixedBytes(bnew(!_:Int, T, libcFixed), Bytes, T)
          [structural]

     syntax KItem ::= newFixedString(SymBase, String)
     rule newFixedString(Base::SymBase, Value::String)
          => alloc(Base, arr(char, lengthString(Value) +Int 1), lengthString(Value) +Int 1)
          ~> initString(loc(Base, 0), Value)
          ~> tv(loc(Base, 0), utype(ptr(char)))
          [structural]

     syntax KItem ::= newFixedBytes(SymBase, List, Type)
     rule newFixedBytes(Base::SymBase, Bytes::List, T::Type)
          => alloc(Base, T, byteSizeofType(utype(T)))
          ~> initBytes(loc(Base, 0), Bytes)
          ~> tv(loc(Base, 0), utype(ptr(T)))
          [structural]

endmodule

