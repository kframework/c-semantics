module LIBC-STDIO
     imports C-CONFIGURATION
     imports INT
     imports K-IO
     imports STRING
     imports BITS-SYNTAX
     imports COMPAT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-EXECUTION-ERROR-SYNTAX
     imports C-IO-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-OS-SETTINGS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX
     imports LIBC-STDLIB-SYNTAX
     imports LIBC-TYPES-SYNTAX

     rule builtin("rewind", FDPtr::RValue)
          => fseek((* FDPtr), 0, 0) ~> discard
          ~> clearerr(* FDPtr)
          [structural]
     rule builtin("fseek", FDPtr::RValue, tv(Offset:Int, _), tv(Whence:Int, _))
          => fseek((* FDPtr), Offset, Whence)
          [structural]
     rule builtin("fsetpos", FDPtr::RValue, PosPtr::RValue)
          => fsetpos((* FDPtr), (* PosPtr))
          [structural]
     rule builtin("fflush", FDPtr::RValue)
          => fflush(* FDPtr)
          requires notBool isNull(FDPtr)
          [structural]
     rule builtin("fflush", FDPtr::RValue)
          => flushAll ~> success
          requires isNull(FDPtr)
          [structural]

     syntax KItem ::= fsetpos(K, K)
     context fsetpos(_, HOLE:KItem => reval(HOLE)) [result(RValue)]
     context fsetpos(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule <k> fsetpos(tv(opaque(FD:FD, _), _) #as V::RValue, tv(opaque(fpos(Path::String, Pos::Int), _), _))
               => fseek(V, Pos, 0)
          ...</k>
          <fid> FD </fid>
          <uri> Path </uri>
          [structural]
     rule <k> fsetpos(V:RValue, _) => setErrno(#EBADF) ~> eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]
     rule <k> (.K => UNDEF("STDIO9", "'fsetpos': called to set a position that was not returned by a previous successful call to the fgetpos function on a stream associated with the same file."))
               ~> fsetpos(tv(opaque(FD:FD, _), _), tv(V::CValue, _))
          ...</k>
          <fid> FD </fid>
          <uri> Path':String </uri>
          requires fposPath(V) =/=String Path'
          [structural]

     syntax FauxFD ::= getFD(RValue) [function]
     rule getFD(tv(opaque(FD:FD, _), _)) => FD
     rule getFD(_) => "" [owise]

     syntax String ::= fposPath(CValue) [function]
     rule fposPath(opaque(fpos(Path::String, _), _)) => Path
     rule fposPath(_) => "" [owise]

     syntax KItem ::= fflush(K)
     context fflush(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> fflush(tv(opaque(FD:Int, _), _))
               => flush(FD)
               ~> success
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <last-op> Op:LastFileOp => flushOp </last-op>
          requires isWritable(Mode) andBool (Op =/=K inputOp)
          [structural]
     rule <k> fflush(V:RValue) => setErrno(#EBADF) ~> eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
     rule <k> (.K => UNDEF("STDIO7", "'fflush': called on an input stream or an input/output stream on which the most recent operation was input."))
               ~> fflush(tv(opaque(FD:Int, _), _))
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <last-op> Op:LastFileOp </last-op>
          requires notBool (isWritable(Mode) andBool (Op =/=K inputOp))
          [structural]

     syntax KItem ::= fseek(K, Int, Int)
     context fseek(HOLE:KItem => reval(HOLE), _, _) [result(RValue)]
     rule fseek(tv(opaque(FD:Int, _), _), Offset::Int, 0)
          => flush(FD)
          ~> seek(FD, Offset, seekSet)
          ~> cleareof(FD)
          ~> success
          [structural]
     rule fseek(tv(opaque(FD:Int, _), _), Offset::Int, 1)
          => flush(FD)
          ~> seek(FD, Offset, seekCur)
          ~> cleareof(FD)
          ~> success
          [structural]
     rule fseek(tv(opaque(FD:Int, _), _), Offset::Int, 2)
          => flush(FD)
          ~> seek(FD, Offset, seekEnd)
          ~> cleareof(FD)
          ~> success
          [structural]

     rule builtin("ftell", FDPtr::RValue)
          => ftell(* FDPtr)
          [structural]
     rule builtin("fgetpos", FDPtr::RValue, PosPtr::RValue)
          => fgetpos((* FDPtr), PosPtr)
          [structural]

     syntax KItem ::= ftell(K)
     context ftell(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule (.K => tell(FD))
          ~> ftell(tv(opaque(FD:Int, _), _))
          [structural]
     rule tv(Pos:Int, _) ~> ftell(_)
          => tv(Pos, utype(long-int))
          [structural]

     syntax KItem ::= fgetpos(K, RValue)
                    | fpos(String, Int)
     context fgetpos(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule <k> (.K => tell(FD))
               ~> fgetpos(tv(opaque(FD:Int, _), _), _)
          ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires FD in_keys(OpenFiles)
          [structural]
     rule <k> fgetpos(V:RValue, _) => setErrno(#EBADF) ~> eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]
     rule <k> tv(Pos:Int, _) ~> fgetpos(tv(opaque(FD:Int, _), _), PosPtr::RValue)
               => Computation((* PosPtr) := tv(opaque(fpos(Path, Pos), utype(fpos_t)), utype(fpos_t)))
               ~> success
          ...</k>
          <fid> FD </fid>
          <uri> Path:String </uri>
          [structural]

     rule builtin("fputc", tv(N:Int, _), FDPtr::RValue)
          => fputc(N, (* FDPtr))
          [structural]
     rule builtin("_IO_putc" => "putc", _, _)
          [structural]
     rule builtin("putc", tv(N:Int, _), FDPtr::RValue)
          => fputc(N, (* FDPtr))
          [structural]
     rule builtin("putchar", tv(N:Int, _))
          => fputc(N, stdout)
          [structural]

     syntax KItem ::= fputc(Int, K)
     context fputc(_, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> fputc(N::Int, tv(opaque(FD:Int, _), _))
               => writeFD(FD, N)
               ~> tv(N, utype(int))
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          requires isWritable(Mode)
          [structural]
     rule <k> fputc(_, V:RValue) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]
     rule <k> fputc(N::Int, tv(opaque(FD:Int, _), _))
               => eof
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <ferror> _ => getErrno(#EBADF) </ferror>
          requires notBool isWritable(Mode)
          [structural]

     rule builtin("fgetc", FDPtr::RValue)
          => fgetc(* FDPtr)
          [structural]
     rule builtin("_IO_getc" => "getc", _)
          [structural]
     rule builtin("getc", FDPtr::RValue)
          => fgetc(* FDPtr)
          [structural]
     rule builtin("getchar")
          => fgetc(stdin)
          [structural]
     rule builtin("ungetc", tv(C:Int, _), FDPtr::RValue)
          => ungetc(C, (* FDPtr))
          requires C =/=K value(eof)
          [structural]
     rule builtin("ungetc", tv(C:Int, _), _)
          => eof
          requires C ==K value(eof)
          [structural]

     syntax KItem ::= fgetc(K)
     context fgetc(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> (.K => readFD(FD, 1))
               ~> fgetc(tv(opaque(FD:Int, _), _))
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          requires isReadable(Mode)
          [structural]
     rule <k> fgetc(V:RValue) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]
     rule <k> fgetc(tv(opaque(FD:Int, _), _))
               => eof
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <ferror> _ => getErrno(#EBADF) </ferror>
          requires notBool isReadable(Mode)
          [structural]
     rule str(S::String) ~> fgetc(_)
          => tv(ordChar(firstChar(S)), utype(int))
          requires lengthString(S) >Int 0
          [structural]
     rule str("") ~> fgetc(_) => eof
          [structural]

     syntax KItem ::= ungetc(Int, K)
     context ungetc(_, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> ungetc(C::Int, tv(opaque(FD:Int, _), _))
               => unget(FD, chrChar(C))
               ~> cleareof(FD)
               ~> tv(C, utype(int))
          ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires FD in_keys(OpenFiles)
          [structural]
     rule <k> ungetc(_, V:RValue) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]

     rule builtin("feof", FDPtr::RValue) => feof(* FDPtr)
          [structural]
     rule builtin("ferror", FDPtr::RValue) => ferror(* FDPtr)
          [structural]
     rule builtin("fileno", FDPtr::RValue) => fileno(* FDPtr)
          [structural]

     syntax KItem ::= feof(K)
     context feof(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> feof(tv(opaque(FD:Int, _), _)) => tv(1, utype(int)) ...</k>
          <fid> FD </fid>
          <read-buffer> "" </read-buffer>
          <feof> true </feof>
          [structural]
     rule <k> feof(tv(opaque(FD:Int, _), _)) => tv(0, utype(int)) ...</k>
          <fid> FD </fid>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          requires notBool (Buffer ==K "" andBool Eof)
          [structural]
     rule <k> feof(V:RValue) => tv(0, utype(int)) ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]

     syntax KItem ::= ferror(K)
     context ferror(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> ferror(tv(opaque(FD:Int, _), _)) => tv(1, utype(int)) ...</k>
          <fid> FD </fid>
          <ferror> Err:Int </ferror>
          requires Err =/=Int 0
          [structural]
     rule <k> ferror(tv(opaque(FD:Int, _), _)) => tv(0, utype(int)) ...</k>
          <fid> FD </fid>
          <ferror> 0 </ferror>
          [structural]
     rule <k> ferror(V:RValue) => tv(0, utype(int)) ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool (notBool getFD(V) in_keys(OpenFiles))
          [structural]

     syntax KItem ::= fileno(K)
     context fileno(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> fileno(tv(opaque(FD:Int, _), _)) => tv(FD, utype(int)) ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires FD in_keys(OpenFiles)
          [structural]
     rule <k> fileno(V:RValue) => setErrno(#EBADF) ~> eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]

     rule builtin("clearerr", FDPtr::RValue)
          => clearerr(* FDPtr)
          [structural]

     syntax KItem ::= clearerr(K)
     context clearerr(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> clearerr(tv(opaque(FD:Int, _), _))
               => cleareof(FD) ~> voidVal
          ...</k>
          <fid> FD </fid>
          <ferror> _ => 0 </ferror>
          [structural]
     rule <k> clearerr(V:RValue) => voidVal ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]

     syntax KItem ::= cleareof(Int)
     rule <k> cleareof(FD::Int) => .K ...</k>
          <fid> FD </fid>
          <feof> _ => false </feof>
          [structural]

     rule builtin("fclose", FDPtr::RValue) => fclose(* FDPtr, FDPtr)
          requires notBool isNull(FDPtr)
          [structural]
     rule builtin("fclose", FDPtr::RValue) => eof
          requires isNull(FDPtr)
          [structural]

     syntax KItem ::= fclose(K, RValue)
                    | "fclose'" "(" Int ")"
     context fclose(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule fclose(tv(opaque(FD:Int, _), _), tv(Loc::SymLoc, _))
          => deleteObject(base(Loc))
          ~> fclose'(FD)
          [structural]
     rule <k> fclose'(FD::Int)
               => flush(FD)
               ~> close(FD)
               ~> success
          ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires FD in_keys(OpenFiles)
          [structural]
     rule <k> fclose'(FD::Int) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires notBool (FD in_keys(OpenFiles))
          [structural]

     rule builtin("fopen", Filename::RValue, Mode::RValue)
          => alloc(bnew(!FDLoc:Int, file, libc), file, byteSizeofType(type(file)))
          ~> fopen(bnew(!FDLoc, file, libc), getString(Filename), getString(Mode))
          [structural]
     rule builtin("freopen", Filename::RValue, Mode::RValue, tv(Loc:SymLoc, T::UType))
          => freopen(Filename, Mode, base(Loc), (* tv(stripProv(Loc), T)))
          requires notBool isNull(tv(Loc, T))
          [structural]
     rule builtin("freopen", _, _, FDPtr::RValue)
          => tv(NullPointer, utype(pointerType(type(file))))
          requires isNull(FDPtr)
          [structural]
     rule builtin("tmpnam", S::RValue)
          => nativeCall("tmpnam", ListItem(S), .List)
          [structural]
     rule (.K => Call(Identifier("tmpnam"),
               list(ListItem(tv(0, utype(pointerType(type(char))))))))
          ~> builtin("tmpfile")
          [structural]
     // TODO(chathhorn): delete on close and program exit?
     rule S:RValue ~> builtin("tmpfile")
          => alloc(bnew(!FDLoc:Int, file, libc), file, byteSizeofType(type(file)))
          ~> fopen(bnew(!FDLoc, file, libc), getString(S), str("wb+"))
          [structural]

     // TODO(chathhorn): need another level of indirection here so e.g.
     // stdin/out can be redirected.
     syntax KItem ::= freopen(RValue, RValue, SymBase, K)
     context freopen(_, _, _, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule freopen(Filename::RValue, Mode::RValue, Base:SymBase, tv(opaque(FD:Int, T::UType), T'::UType))
          => fclose'(FD) ~> discard
          ~> fopen(Base, getString(Filename), getString(Mode))
          requires notBool isNull(Filename)
          [structural]
     rule <k> freopen(Filename::RValue, Mode::RValue, Base:SymBase, tv(opaque(FD:Int, T::UType), T'::UType))
               => fclose'(FD) ~> discard
               ~> fopen(Base, Filename', getString(Mode))
          ...</k>
          <fid> FD </fid>
          <uri> Filename':String </uri>
          requires isNull(Filename)
          [structural]

     syntax KItem ::= fopen(SymBase, KItem, KItem) [strict(2,3)]
     rule fopen(Base::SymBase, str(Filename::String), str(Mode::String))
          => fopen'(Base, Filename, Mode, #open(Filename, Mode))
          requires isReadable(Mode) orBool isWritable(Mode) orBool isReadWritable(Mode)
          [structural]
     rule (.K => UNDEF("STDIO8", "'fopen' or 'freopen': invalid open mode \"" +String Mode +String "\"."))
          ~> fopen(_, _, str(Mode::String))
          requires notBool (isReadable(Mode) orBool isWritable(Mode) orBool isReadWritable(Mode))
          [structural]

     syntax KItem ::= "fopen'" "(" SymBase "," String "," String "," K ")"
     rule <k> fopen'(Base::SymBase, Filename::String, Mode::String, FD:Int)
               => Computation(fileLVal(Base) := tv(opaque(FD, utype(file)), utype(file)))
               ~> & fileLVal(Base)
          ...</k>
          <open-files>... .Map => FD |-> printStackTrace(L, Tu, Sc, Loc, Env) </open-files>
          <call-stack> L:List </call-stack>
          <curr-tu> Tu::String </curr-tu>
          <renv> Env::Map </renv>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> Sc:Scope </curr-scope>
          <files>...
               (.Bag =>
                    <file>...
                         <fid> FD </fid>
                         <uri> Filename </uri>
                         <mode> Mode </mode>
                    ...</file>
               )
          ...</files>
          [structural]

     rule <k> fopen'(_, _, _, Err:IOError)
              => setErrno(Err)
              ~> tv(NullPointer, utype(pointerType(type(file))))
          ...</k>

     rule builtin("setbuf", FDPtr::RValue, tv(Loc:SymLoc, _) #as BufPtr::RValue)
          => trapBuf(Loc, bufSiz)
          ~> setbuf((* FDPtr), fullBuf, bufSiz) ~> discard
          ~> voidVal
          requires notBool isNull(BufPtr)
          [structural]
     rule builtin("setbuf", FDPtr::RValue, BufPtr::RValue)
          => setbuf((* FDPtr), noBuf, bufSiz) ~> discard
          ~> voidVal
          requires isNull(BufPtr)
          [structural]
     rule builtin("setbuffer", FDPtr::RValue, tv(Loc:SymLoc, _) #as BufPtr::RValue, tv(Sz:Int, _))
          => trapBuf(Loc, Sz)
          ~> setbuf((* FDPtr), fullBuf, Sz) ~> discard
          ~> voidVal
          requires notBool isNull(BufPtr)
          [structural]
     rule builtin("setbuffer", FDPtr::RValue, BufPtr::RValue, tv(Sz:Int, _))
          => setbuf((* FDPtr), noBuf, Sz) ~> discard
          ~> voidVal
          requires isNull(BufPtr)
          [structural]
     rule builtin("setvbuf", FDPtr::RValue, tv(Loc:SymLoc, _), tv(0, _), tv(Sz:Int, _))
          => trapBuf(Loc, Sz)
          ~> setbuf((* FDPtr), fullBuf, Sz)
          [structural]
     rule builtin("setvbuf", FDPtr::RValue, tv(Loc:SymLoc, _), tv(1, _), tv(Sz:Int, _))
          => trapBuf(Loc, Sz)
          ~> setbuf((* FDPtr), lineBuf, Sz)
          [structural]
     rule builtin("setvbuf", FDPtr::RValue, tv(Loc:SymLoc, _), tv(2, _), tv(Sz:Int, _))
          => trapBuf(Loc, Sz)
          ~> setbuf((* FDPtr), noBuf, Sz)
          [structural]
     rule builtin("setlinebuf", FDPtr::RValue)
          => setbuf((* FDPtr), lineBuf, bufSiz) ~> discard
          ~> voidVal
          [structural]

     syntax KItem ::= trapBuf(SymLoc, Int)
     rule trapBuf(Loc::SymLoc, Sz::Int)
          => initBytes(stripProv(Loc), times(Sz, piece(trap, cfg:bitsPerByte)))
          requires notBool isNull(tv(Loc, utype(pointerType(type(void)))))
               andBool Sz >Int 0
     rule trapBuf(_, _) => .K [owise]

     syntax KItem ::= setbuf(K, BufMode, Int)
     context setbuf(HOLE:KItem => reval(HOLE), _, _) [result(RValue)]
     rule <k> setbuf(tv(opaque(FD:Int, _), _), Mode::BufMode, Sz::Int)
               => setBuf(FD, Mode, Sz)
               ~> success
          ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires FD in_keys(OpenFiles)
          [structural]
     rule <k> setbuf(V:RValue, _, _) => setErrno(#EBADF) ~> eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]

     rule builtin("fread", Ptr::RValue, tv(Size:Int, _), tv(NMemb:Int, _), FDPtr::RValue)
          => fread(Ptr, Size, NMemb, (* FDPtr))
          [structural]
     rule (.K => fscanf(stdin, str("%[^\n]"), ListItem(Ptr)))
          ~> builtin("gets", Ptr::RValue)
          [structural]
     rule tv(1, _) ~> builtin("gets", Ptr::RValue) => Ptr
          [structural]
     rule tv(N::CValue, _) ~> builtin("gets", Ptr::RValue) => tv(NullPointer, utype(pointerType(type(char))))
          requires N =/=K 1
          [structural]
     rule builtin("fgets", Ptr::RValue, tv(NMemb:Int, _), FDPtr::RValue)
          => fgets(Ptr, NMemb, (* FDPtr))
          [structural]

     syntax KItem ::= fread(RValue, Int, Int, K)
     context fread(_, _, _, HOLE:KItem => reval(HOLE)) [result(RValue)]

     rule <k> fread(tv(Loc:SymLoc, _), Size::Int, NMemb::Int, tv(opaque(FD:Int, _), _))
               => fread'(Loc, Size, readFD(FD, Size *Int NMemb))
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          requires isReadable(Mode)
          [structural]
     rule <k> fread(_, _, _, tv(opaque(FD:Int, _), _))
               => eof
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <ferror> _ => getErrno(#EBADF) </ferror>
          requires notBool isReadable(Mode)
          [structural]
     rule <k> fread(_, _, _, V:RValue) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]

     syntax KItem ::= "fread'" "(" SymLoc "," Int "," KItem ")" [strict(3)]
     rule fread'(Loc:SymLoc, Size::Int, str(Read::String))
          => writeChars(Loc, Read)
          ~> trapBuf(Loc +bytes lengthString(Read), Size -Int (lengthString(Read) %Int Size))
          ~> tv(lengthString(Read) /Int Size, utype(size_t))
          requires (lengthString(Read) %Int Size) =/=Int 0
          [structural]
     rule fread'(Loc:SymLoc, Size::Int, str(Read::String))
          => writeChars(Loc, Read)
          ~> tv(lengthString(Read) /Int Size, utype(size_t))
          requires (lengthString(Read) %Int Size) ==Int 0
          [structural]

     syntax KItem ::= fgets(RValue, Int, K)
     context fgets(_, _, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule fgets(Ptr::RValue, NMemb::Int, _) => Ptr
          requires NMemb <Int 1
          [structural]
     rule fgets(Ptr::RValue, 1, _)
          => Computation((* Ptr) := tv(0, utype(innerType(type(Ptr)))))
          ~> Ptr
          [structural]
     rule (.K => fscanf(FD, str("%" +String showInt(NMemb -Int 1) +String "[^\n]"), ListItem(Ptr)))
          ~> fgets(Ptr::RValue, NMemb::Int, FD:RValue)
          requires NMemb >Int 1
          [structural]
     rule <k> V:RValue ~> fgets(tv(Loc:SymLoc, _), NMemb::Int, tv(opaque(FD::Int, _), _))
               => trapBuf(Loc, NMemb)
               ~> tv(NullPointer, utype(pointerType(type(char))))
          ...</k>
          <fid> FD </fid>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          requires V ==K eof andBool notBool (Buffer ==K "" andBool Eof)
          [structural]
     rule <k> tv(V:Int, _) ~> fgets(tv(Loc:SymLoc, _), NMemb::Int, tv(opaque(FD::Int, _), _))
               => trapBuf(Loc, NMemb)
               ~> tv(NullPointer, utype(pointerType(type(char))))
          ...</k>
          <fid> FD </fid>
          <read-buffer> "" </read-buffer>
          <feof> true </feof>
          requires V =/=Int 1
          [structural]
     rule <k> (tv(0, _) => str("")) ~> fgets(_, _, tv(opaque(FD::Int, _), _)) ...</k>
          <fid> FD </fid>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          requires notBool (Buffer ==K "" andBool Eof)
          [structural]
     rule (tv(1, _) => getString(Ptr)) ~> fgets(Ptr::RValue, _, _)
          [structural]
     rule str(S::String) ~> fgets(Ptr::RValue, NMemb::Int, _)
          => Ptr
          requires lengthString(S) >=Int NMemb -Int 1
          [structural]
     rule (str(S::String) => readNewline(Ptr + lengthString(S), FD)) ~> fgets(Ptr::RValue, NMemb::Int, FD:RValue)
          requires lengthString(S) <Int NMemb -Int 1
          [structural]
     rule doneReadNewline ~> fgets(Ptr::RValue, NMemb::Int, _) => Ptr
          [structural]

     syntax KItem ::= readNewline(K, RValue)
     syntax KResult ::= "doneReadNewline"
     context readNewline(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule (.K => fscanf(FD, str("%1[\n]"), ListItem(Ptr)))
          ~> readNewline(Ptr:RValue, FD::RValue)
          [structural]
     rule _:RValue ~> readNewline(_, _) => doneReadNewline
          [structural]

     //////////////////////////

     // C1X Here we might want to assume different threads cannot interleave
     // wrt printf, based on 7.1.4:5.  However, 7.1.4:4 seems to say exactly
     // the opposite.

     // on second thought, it probably is saying that while the shared data is
     // protected against races, it can still be interleaved

     // fixme despite the above, still need to handle interleaving of user data
     // read during evaluation of printf.  should use something like a buffer
     // to do this
     rule [printf]:
          builtin*("printf", Format::RValue, VarArgs:List)
          => fprintf(stdout, formatter(getString(Format), VarArgs))
          [structural]
     rule [fprintf]:
          builtin*("fprintf", FDPtr::RValue, Format::RValue, VarArgs:List)
          => fprintf((* FDPtr), formatter(getString(Format), VarArgs))
          [structural]
     rule [fputs]:
          builtin("fputs", Str::RValue, FDPtr::RValue)
          => fprintf(* FDPtr, formatter(str("%s"), ListItem(Str)))
          [structural]
     rule [puts]:
          builtin("puts", Str::RValue)
          => fprintf(stdout, formatter(str("%s\n"), ListItem(Str)))
          [structural]
     rule builtin("fwrite", Ptr::RValue, tv(Size:Int, _), tv(NMemb:Int, _), FDPtr::RValue)
          => fwrite(getBytes(Ptr, Size *Int NMemb), Size, (* FDPtr))
          [structural]

     syntax KItem ::= fprintf(K, KItem) [strict(2)]
     context fprintf(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule <k> fprintf(tv(opaque(FD:Int, _), _), formattedResult(S:String))
               => writeFD(FD, S)
               ~> tv(lengthString(S), utype(int))
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          requires isWritable(Mode)
          [structural]
     rule <k> fprintf(tv(opaque(FD:Int, _), _), formattedResult(S:String))
               => eof
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <ferror> _ => getErrno(#EBADF) </ferror>
          requires notBool isWritable(Mode)
          [structural]
     rule <k> fprintf(V:RValue, _) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]

     syntax KItem ::= fwrite(KItem, Int, K) [strict(1)]
     context fwrite(_, _, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> fwrite(str(S::String), Size::Int, tv(opaque(FD:Int, _), _))
               => writeFD(FD, S)
               ~> tv(lengthString(S) /Int Size, utype(size_t))
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          requires isWritable(Mode)
          [structural]
     rule <k> fwrite(str(S::String), Size::Int, tv(opaque(FD:Int, _), _))
               => eof
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <ferror> _ => getErrno(#EBADF) </ferror>
          requires notBool isWritable(Mode)
          [structural]
     rule <k> fwrite(_, _, V:RValue) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]

     syntax List ::= derefList(List) [function]
     rule derefList(.List) => .List
     rule derefList(ListItem(X:KItem) L::List) => ListItem(* X) derefList(L)

     rule [vprintf]:
          <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vprintf", _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule (.K => errorUninitVaList)
          ~> builtin("vprintf", _, tv(V::CValue, _))
          requires opaque(...) :/=K V
          [structural]
     rule <k> (.K => errorUninitVaList)
               ~> builtin("vprintf", _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool VaList in_keys(VaLists)
          [structural]
     rule H:HeatList ~> builtin("vprintf", Format::RValue, _)
          => fprintf(stdout, formatter(getString(Format), hListToList(H)))
          requires isKResult(H)
          [structural]

     syntax KItem ::= "errorUninitVaList" [function]
     rule errorUninitVaList => UNDEF("STDIO3", "'v*printf': uninitialized va_list argument.")

     rule [vfprintf]:
          <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vfprintf", _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule (.K => errorUninitVaList)
          ~> builtin("vfprintf", _, _, tv(V::CValue, _))
          requires opaque(...) :/=K V
          [structural]
     rule <k> (.K => errorUninitVaList)
               ~> builtin("vfprintf", _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool VaList in_keys(VaLists)
          [structural]
     rule H:HeatList ~> builtin("vfprintf", FDPtr::RValue, Format::RValue, _)
          => fprintf((* FDPtr), formatter(getString(Format), hListToList(H)))
          requires isKResult(H)
          [structural]

     rule builtin*("sprintf", Dest::RValue, Format::RValue, VarArgs:List)
          => sprintf(formatter(getString(Format), VarArgs), Dest)
          [structural]

     syntax KItem ::= sprintf(KItem, K) [strict(1)]
     context sprintf(_, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule sprintf(formattedResult(S:String), tv(Dest::SymLoc, _))
          => writeString(Dest, S)
          ~> tv(lengthString(S), utype(int))
          [structural]

     rule builtin*("asprintf", Dest::RValue, Format::RValue, VarArgs:List)
          => asprintf(formatter(getString(Format), VarArgs), Dest)
          [structural]

     syntax KItem ::= asprintf(KItem, RValue) [strict(1)]
     rule asprintf(formattedResult(S:String), Dest::RValue)
          => Computation((* Dest) := alignedAlloc(1, lengthString(S) +Int 1))
          ~> sprintf(formattedResult(S), (* Dest))
          [structural]

     rule <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vsprintf", _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule (.K => errorUninitVaList)
          ~> builtin("vsprintf", _, _, tv(V::CValue, _))
          requires opaque(...) :/=K V
          [structural]
     rule <k> (.K => errorUninitVaList)
               ~> builtin("vsprintf", _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool VaList in_keys(VaLists)
          [structural]
     rule H:HeatList ~> builtin("vsprintf", Dest::RValue, Format::RValue, _)
          => sprintf(formatter(getString(Format), hListToList(H)), Dest)
          requires isKResult(H)
          [structural]

     rule <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vasprintf", _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule (.K => errorUninitVaList)
          ~> builtin("vasprintf", _, _, tv(V::CValue, _))
          requires opaque(...) :/=K V
          [structural]
     rule <k> (.K => errorUninitVaList)
               ~> builtin("vasprintf", _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool VaList in_keys(VaLists)
          [structural]
     rule H:HeatList ~> builtin("vasprintf", Dest::RValue, Format::RValue, _)
          => asprintf(formatter(getString(Format), hListToList(H)), Dest)
          requires isKResult(H)
          [structural]

     syntax KItem ::= snprintf(KItem, SymLoc, Int) [strict(1)]
     rule [snprintf]:
          builtin*("snprintf", tv(Dest:SymLoc, _), tv(Len:Int, _), Format::RValue, VarArgs:List)
          => snprintf(formatter(getString(Format), VarArgs), Dest, Len)
          [structural]
     rule [snprintf-done-nz]:
          snprintf(formattedResult(S:String), Dest:SymLoc, Len:Int)
          => writeString(Dest, substrString(S, 0, minInt(lengthString(S), Len -Int 1)))
          ~> tv(lengthString(S), utype(int))
          requires Len >Int 0
          [structural]
     rule [snprintf-done-0]:
          snprintf(formattedResult(S:String), _, 0)
          => tv(lengthString(S), utype(int))
          [structural]

     rule [vsnprintf]:
          <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vsnprintf", _, _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule (.K => errorUninitVaList)
          ~> builtin("vsnprintf", _, _, _, tv(V::CValue, _))
          requires opaque(...) :/=K V
          [structural]
     rule <k> (.K => errorUninitVaList)
               ~> builtin("vsnprintf", _, _, _, tv(opaque(VaList::Int, _), _))
          ...</k>
          <va-lists> VaLists:Map </va-lists>
          requires notBool VaList in_keys(VaLists)
          [structural]
     rule H:HeatList ~> builtin("vsnprintf", tv(Dest::SymLoc, _), tv(Len::Int, _), Format::RValue, _)
          => snprintf(formatter(getString(Format), hListToList(H)), Dest,  Len)
          requires isKResult(H)
          [structural]

     rule builtin*("__isoc99_scanf" => "scanf", _:RValue, _)
          [structural]
     rule builtin*("scanf", Format::RValue, VarArgs:List)
          => fscanf(stdin, getString(Format), VarArgs)
          [structural]
     rule builtin*("__isoc99_fscanf" => "fscanf", _, _, _)
          [structural]
     rule builtin*("fscanf", FDPtr::RValue, Format::RValue, VarArgs:List)
          => fscanf((* FDPtr), getString(Format), VarArgs)
          [structural]
     rule builtin("__isoc99_vfscanf" => "vfscanf", _, _, _)
          [structural]
     rule <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vfscanf", _, _, tv(VaList::Int, _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule H:HeatList ~> builtin("vfscanf", FDPtr::RValue, Format::RValue, _)
          => fscanf((* FDPtr), getString(Format), hListToList(H))
          requires isKResult(H)
          [structural]
     rule builtin("__isoc99_vscanf" => "vscanf", _, _)
          [structural]
     rule <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vscanf", _, tv(VaList::Int, _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule H:HeatList ~> builtin("vscanf", Format::RValue, _)
          => fscanf(stdin, getString(Format), hListToList(H))
          requires isKResult(H)
          [structural]
     rule builtin*("__isoc99_sscanf" => "sscanf", _, _, _)
          [structural]
     rule builtin*("sscanf", Str::RValue, Format::RValue, VarArgs:List)
          => fscanf(getString(Str), getString(Format), VarArgs)
          [structural]
     rule builtin("__isoc99_vsscanf" => "vsscanf", _, _, _)
          [structural]
     rule <k> (.K => toHeatList(derefList(VarArgs)))
               ~> builtin("vsscanf", _, _, tv(VaList::Int, _))
          ...</k>
          <va-lists>... VaList |-> VarArgs:List ...</va-lists>
          [structural]
     rule H:HeatList ~> builtin("vsscanf", Str::RValue, Format::RValue, _)
          => fscanf(getString(Str), getString(Format), hListToList(H))
          requires isKResult(H)
          [structural]

     syntax KItem ::= fscanf(K, KItem, List) [strict(2)]
     context fscanf(HOLE:KItem => reval(HOLE), _, _) [result(RValue)]
     rule <k> fscanf(tv(opaque(FD:Int, _), _), str(S::String), VarArgs::List)
               => fscanf'(FD, VarArgs, parseFormat(stringToList(S)), 0, "", 0)
          ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires FD in_keys(OpenFiles)
          [structural]
     rule <k> fscanf(tv(_, _) #as V:RValue, _, _) => eof ...</k>
          <open-files> OpenFiles:Map </open-files>
          requires (getFD(V) ==K "")
               orBool notBool (getFD(V) in_keys(OpenFiles))
          [structural]
     rule <k> fscanf(str(FD::String), str(S::String), VarArgs::List)
               => fscanf'(FD, VarArgs, parseFormat(stringToList(S)), 0, "", 0)
          ...</k>
          <open-files>... .Map => FD |-> printStackTrace(L, Tu, Sc, Loc, Env) </open-files>
          <call-stack> L:List </call-stack>
          <curr-tu> Tu::String </curr-tu>
          <renv> Env::Map </renv>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> Sc:Scope </curr-scope>
          <files>...
               (.Bag =>
                    <file>...
                         <fid> FD </fid>
                         <read-buffer> FD </read-buffer>
                    ...</file>
               )
          ...</files>
          [structural]

     // FD, args, parsed format string, number matched, current item, number of chars read
     syntax KItem ::= "fscanf'" "(" FauxFD "," List "," List "," Int "," String "," Int")"
     rule <k> (.K => readFD(FD, 1))
               ~> fscanf'(FD::FauxFD, _, ListItem(D::Directive) _, _, Item::String, _)
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          <ferror> 0 </ferror>
          requires isReadable(Mode)
               andBool notBool atFieldWidth(Item, D)
               andBool notBool (Buffer ==K "" andBool Eof)
          [structural]
     rule <k> fscanf'(FD::FD, _, ListItem(D::Directive) _, Matched::Int, Item::String, _)
               => #if Matched ==Int 0 #then eof #else tv(Matched, utype(int)) #fi
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          <ferror> Err:Int </ferror>
          requires notBool ((Buffer ==K "" andBool Eof) orBool atFieldWidth(Item, D))
               andBool Err =/=Int 0
               andBool isReadable(Mode)
          [structural]
     rule <k> fscanf'(FD::FD, _, _, Matched::Int, _, _)
               => #if Matched ==Int 0 #then eof #else tv(Matched, utype(int)) #fi
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <ferror> _ => getErrno(#EBADF) </ferror>
          requires notBool isReadable(Mode)
          [structural]
     rule <k> fscanf'(FD::FD, _,
               (ListItem(whitespace) => .List) _,
               _,
               _ => "",
               _)
          ...</k>
          <fid> FD </fid>
          <read-buffer> "" </read-buffer>
          <feof> true </feof>
          [structural]
     rule <k> (.K => writeItem(D, Item, Arg, NRead))
               ~> fscanf'(FD::FD, (ListItem(Arg::RValue) => .List) _,
                    (ListItem(%(Wr::WriteBehavior, _, _, _) #as D::Directive) => .List) _,
                    M::Int => #if isReadCountDirective(D) #then M #else M +Int 1 #fi,
                    Item::String => "",
                    NRead::Int)
          ...</k>
          <fid> FD </fid>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          requires ((Buffer ==K "" andBool Eof) orBool atFieldWidth(Item, D)) andBool isCompleteItem(Item, D)
               andBool (Wr ==K dirWrite orBool Wr ==K dirAlloc)
          [structural]
     rule <k> fscanf'(FD::FD, _,
                    (ListItem(%(dirRead, _, _, _) #as D::Directive) => .List) _,
                    M::Int => M +Int 1,
                    Item::String => "",
                    _)
          ...</k>
          <fid> FD </fid>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          requires ((Buffer ==K "" andBool Eof) orBool atFieldWidth(Item, D)) andBool isCompleteItem(Item, D)
          [structural]
     rule <k> fscanf'(FD::FD, _,
                    ListItem(D::Directive) _,
                    Matched::Int,
                    Item::String,
                    _)
               => #if isString(FD) #then close(FD) #else .K #fi
               ~> #if (Matched ==Int 0) andBool notBool atFieldWidth(Item, D)
                    #then eof #else tv(Matched, utype(int)) #fi
          ...</k>
          <fid> FD </fid>
          <mode> Mode:String </mode>
          <read-buffer> Buffer::String </read-buffer>
          <feof> Eof:Bool </feof>
          <ferror> 0 </ferror>
          requires ((Buffer ==K "" andBool Eof) orBool atFieldWidth(Item, D)) andBool notBool isCompleteItem(Item, D)
               andBool isReadable(Mode)
          [structural]
     rule fscanf'(FD::FD, _,
               .List,
               Matched::Int,
               _,
               _)
          => #if isString(FD) #then close(FD) #else .K #fi
          ~> tv(Matched, utype(int))
          [structural]

     rule (str(C::String) => .K)
          ~> fscanf'(_, _,
               ListItem(D:Directive) _,
               _,
               Item::String => Item +String C,
               N::Int => N +Int 1)
          requires inScanSet(C, D, Item)
          [structural]
     rule str(C::String)
          ~> fscanf'(_, _,
               (ListItem(stringDir(D:String)) => .List) _,
               _,
               Item::String => "",
               _)
          requires notBool inScanSet(C, stringDir(D), Item) andBool Item =/=String ""
          [structural]
     rule str(C::String)
          ~> fscanf'(_, _,
               (ListItem(whitespace) => .List) _,
               _,
               _ => "",
               _)
          requires notBool isWhitespace(C)
          [structural]
     rule (.K => writeItem(D, Item, Arg, NRead))
          ~> str(C::String)
          ~> fscanf'(_, (ListItem(Arg::RValue) => .List) _,
               (ListItem(%(Wr::WriteBehavior, _, _, _) #as D::Directive) => .List) _,
               M::Int => #if isReadCountDirective(D) #then M #else M +Int 1 #fi,
               Item::String => "",
               NRead::Int)
          requires notBool inScanSet(C, D, Item) andBool isCompleteItem(Item, D)
               andBool (Wr ==K dirWrite orBool Wr ==K dirAlloc)
          [structural]
     rule str(C::String)
          ~> fscanf'(_, _,
               (ListItem(%(dirRead, _, _, _) #as D::Directive) => .List) _,
               M::Int => M +Int 1,
               Item::String => "",
               _)
          requires notBool inScanSet(C, D, Item) andBool isCompleteItem(Item, D)
          [structural]
     rule str(C::String)
          ~> fscanf'(_, _,
               (ListItem(%% #as D::Directive) => .List) _,
               _,
               Item::String => "",
               _)
          requires notBool inScanSet(C, D, Item)
               andBool isCompleteItem(Item, D)
          [structural]

     rule str(C::String)
          ~> fscanf'(FD::FD, _,
               ListItem(D::Directive) _,
               Matched::Int,
               Item::String,
               _)
          => #if isString(FD) #then close(FD) #else unget(FD, C) #fi
          ~> #if (Matched ==Int 0) andBool (C ==K "")
               #then eof #else tv(Matched, utype(int)) #fi
          requires notBool inScanSet(C, D, Item)
               andBool D =/=K whitespace
               andBool notBool isCompleteItem(Item, D)
          [structural]
     rule str(C::String)
          ~> fscanf'(FD::FD, _,
               .List,
               Matched::Int,
               _,
               _)
          => #if isString(FD) #then close(FD) #else unget(FD, C) #fi
          ~> tv(Matched, utype(int))
          [structural]

     syntax Bool ::= isReadCountDirective(Directive) [function]
     rule isReadCountDirective(%(_, _, _, "n")) => true
     rule isReadCountDirective(_) => false [owise]

     syntax KItem ::= writeItem(Directive, String, K, Int)
     context writeItem(_, _, HOLE:KItem => reval(HOLE), _) [result(RValue)]

     rule writeItem(%(dirAlloc, Width::Int, "", "c"), Item::String, Loc:RValue, N::Int)
          => Computation((* Loc) := alignedAlloc(cfg:alignofMalloc, lengthString(Item)))
          ~> writeItem(%(dirWrite, Width, "", "c"), Item, (* Loc), N)
     rule writeItem(%(dirAlloc, Width::Int, "l", "c"), Item::String, Loc:RValue, N::Int)
          => Computation((* Loc) := alignedAlloc(cfg:alignofMalloc, lengthString(Item) *Int byteSizeofType(type(cfg:wcharut))))
          ~> writeItem(%(dirWrite, Width, "l", "c"), Item, (* Loc), N)

     rule writeItem(%(dirAlloc, Width::Int, "", "s"), Item::String, Loc:RValue, N::Int)
          => Computation((* Loc) := alignedAlloc(cfg:alignofMalloc, lengthString(Item) +Int 1))
          ~> writeItem(%(dirWrite, Width, "", "s"), Item, (* Loc), N)
     rule writeItem(%(dirAlloc, Width::Int, "l", "s"), Item::String, Loc:RValue, N::Int)
          => Computation((* Loc) := alignedAlloc(cfg:alignofMalloc, lengthString(Item) *Int byteSizeofType(type(cfg:wcharut)) +Int 1))
          ~> writeItem(%(dirWrite, Width, "l", "s"), Item, (* Loc), N)

     rule writeItem(%(dirAlloc, Width::Int, "", D::String), Item::String, Loc:RValue, N::Int)
          => Computation((* Loc) := alignedAlloc(cfg:alignofMalloc, lengthString(Item) +Int 1))
          ~> writeItem(%(dirWrite, Width, "", "s"), Item, (* Loc), N)
          requires firstChar(D) ==String "["
     rule writeItem(%(dirAlloc, Width::Int, "l", D::String), Item::String, Loc:RValue, N::Int)
          => Computation((* Loc) := alignedAlloc(cfg:alignofMalloc, lengthString(Item) *Int byteSizeofType(type(cfg:wcharut)) +Int 1))
          ~> writeItem(%(dirWrite, Width, "l", "s"), Item, (* Loc), N)
          requires firstChar(D) ==String "["

     rule writeItem(%(dirWrite, _, "", "c"), Item::String, tv(Loc:SymLoc, _), _)
          => writeChars(Loc, Item)
     rule writeItem(%(dirWrite, _, "l", "c"), Item::String, tv(Loc:SymLoc, _), _)
          => writeWChars(Loc, stringToList(Item))

     rule writeItem(%(dirWrite, _, "", "s"), Item::String, tv(Loc:SymLoc, _), _)
          => writeString(Loc, Item)
     rule writeItem(%(dirWrite, _, "l", "s"), Item::String, tv(Loc:SymLoc, _), _)
          => writeWString(Loc, stringToList(Item))

     rule writeItem(%(dirWrite, _, "", D::String), Item::String, tv(Loc:SymLoc, _), _)
          => writeString(Loc, Item)
          requires firstChar(D) ==String "["
     rule writeItem(%(dirWrite, _, "l", D::String), Item::String, tv(Loc:SymLoc, _), _)
          => writeWString(Loc, stringToList(Item))
          requires firstChar(D) ==String "["

     rule writeItem(%(dirWrite, _, Length::String, "d"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(Item, 10), utype(getFormatType'("%d", Length)))))
     rule writeItem(%(dirWrite, _, Length::String, "i"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(Item, 0), utype(getFormatType'("%i", Length)))))
          requires notBool has0xPrefix(Item)
     rule writeItem(%(dirWrite, _, Length::String, "i"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(strip0xPrefix(Item), 16), utype(getFormatType'("%i", Length)))))
          requires has0xPrefix(Item)
     rule writeItem(%(dirWrite, _, Length::String, "o"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(Item, 8), utype(getFormatType'("%o", Length)))))
     rule writeItem(%(dirWrite, _, Length::String, "u"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(Item, 10), utype(getFormatType'("%u", Length)))))
     rule writeItem(%(dirWrite, _, Length::String, "x"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(Item, 16), utype(getFormatType'("%x", Length)))))
          requires notBool has0xPrefix(Item)
     rule writeItem(%(dirWrite, _, Length::String, "x"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(String2Base(strip0xPrefix(Item), 16), utype(getFormatType'("%x", Length)))))
          requires has0xPrefix(Item)

     rule writeItem(%(dirWrite, _, Length::String, "p"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(cfg:intToPointer(String2Base(Item, 16), utype(getFormatType'("%p", Length))), utype(getFormatType'("%p", Length)))))
          requires notBool has0xPrefix(Item)
               andBool toUpperCase(Item) =/=String "(NIL)"
     rule writeItem(%(dirWrite, _, Length::String, "p"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(cfg:intToPointer(String2Base(strip0xPrefix(Item), 16), utype(getFormatType'("%p", Length))), utype(getFormatType'("%p", Length)))))
          requires has0xPrefix(Item)
               andBool toUpperCase(Item) =/=String "(NIL)"
     rule writeItem(%(dirWrite, _, Length::String, "p"), Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(NullPointer, utype(getFormatType'("%p", Length)))))
          requires toUpperCase(Item) ==String "(NIL)"

     rule writeItem(%(dirWrite, _, Length::String, D::String) #as D'::Directive, Item::String, Ptr:RValue, _)
          => Computation((* Ptr) := stringToFloat(Item, utype(innerType(type(Ptr))), utype(getFormatType'("%" +String D, Length))))
          requires isFloatDirective(D')

     rule writeItem(%(dirWrite, _, Length::String, "n"), _, Ptr:RValue, M::Int)
          => Computation((* Ptr) := cast(utype(innerType(type(Ptr))), tv(M, utype(int))))

     syntax KItem ::= stringToFloat(String, UType, UType)
     rule stringToFloat(S::String, T::UType, ut(_, float))
          => allocString(obj(!N:Int, 1, libc), S)
          ~> stringToFloat'(obj(!N, 1, libc), T, Call(Identifier("strtof"), list(
               ListItem(tv(lnew(obj(0, 1, string(S))), utype(pointerType(type(char)))))
               ListItem(tv(NullPointer, utype(pointerType(type(pointerType(type(char))))))))))
     rule stringToFloat(S::String, T::UType, ut(_, double))
          => allocString(obj(!N:Int, 1, libc), S)
          ~> stringToFloat'(obj(!N, 1, libc), T, Call(Identifier("strtod"), list(
               ListItem(tv(lnew(obj(0, 1, string(S))), utype(pointerType(type(char)))))
               ListItem(tv(NullPointer, utype(pointerType(type(pointerType(type(char))))))))))
     rule stringToFloat(S::String, T::UType, ut(_, long-double))
          => allocString(obj(!N:Int, 1, libc), S)
          ~> stringToFloat'(obj(!N, 1, libc), T, Call(Identifier("strtold"), list(
               ListItem(tv(lnew(obj(0, 1, string(S))), utype(pointerType(type(char)))))
               ListItem(tv(NullPointer, utype(pointerType(type(pointerType(type(char))))))))))

     syntax KItem ::= "stringToFloat'" "(" SymBase "," UType "," K ")"
     context stringToFloat'(_, _, HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule stringToFloat'(Base::SymBase, T::UType, V:RValue)
          => deleteObject(Base) ~> cast(T, V)
          [structural]

     syntax Directive ::= "%" "(" WriteBehavior "," Int "," String "," String ")"
                        | "%%"
                        | "whitespace"
                        | stringDir(String)
     syntax WriteBehavior ::= "dirWrite" | "dirAlloc" | "dirRead"

     // (Input char, current directive, item read so far.)
     syntax Bool ::= inScanSet(String, Directive, String) [function]
     rule inScanSet(C::String, stringDir(C), "") => true
     rule inScanSet("%", %%, "") => true
     rule inScanSet(C::String, whitespace, _) => isWhitespace(C)
     rule inScanSet(C::String, %(_, _, _, "c"), _) => C =/=String ""
     rule inScanSet(C::String, %(_, _, _, "s"), _) => C =/=String "" andBool notBool isWhitespace(C)

     rule inScanSet(C::String, %(_, _, _, "d"), _) => true
          requires isDigit(C, 10)
     rule inScanSet(C::String, %(_, _, _, "d"), "") => true
          requires isSign(C)

     rule inScanSet(C::String, %(_, _, _, "i"), _) => true
          requires isDigit(C, 16)
     rule inScanSet(C::String, %(_, _, _, "i"), "") => true
          requires isSign(C)
     rule inScanSet("x", %(_, _, _, "i"), I::String) => true
          requires isXPrefix(I)
     rule inScanSet("X", %(_, _, _, "i"), I::String) => true
          requires isXPrefix(I)

     rule inScanSet(C::String, %(_, _, _, "o"), _) => true
          requires isDigit(C, 8)
     rule inScanSet(C::String, %(_, _, _, "o"), "") => true
          requires isSign(C)

     rule inScanSet(C::String, %(_, _, _, "u"), _) => true
          requires isDigit(C, 10)
     rule inScanSet(C::String, %(_, _, _, "u"), "") => true
          requires isSign(C)

     rule inScanSet(C::String, %(_, _, _, "x"), _) => true
          requires isDigit(C, 16)
     rule inScanSet(C::String, %(_, _, _, "x"), "") => true
          requires isSign(C)
     rule inScanSet("x", %(_, _, _, "x"), I::String) => true
          requires isXPrefix(I)
     rule inScanSet("X", %(_, _, _, "x"), I::String) => true
          requires isXPrefix(I)

     rule inScanSet(C::String, %(_, _, _, "p"), _) => true
          requires isDigit(C, 16)
     rule inScanSet(C::String, %(_, _, _, "p"), "") => true
          requires isSign(C)
     rule inScanSet("x", %(_, _, _, "p"), I::String) => true
          requires isXPrefix(I)
     rule inScanSet("X", %(_, _, _, "p"), I::String) => true
          requires isXPrefix(I)
     rule inScanSet(C::String, %(_, _, _, "p"), I::String) => true
          requires inNil(C, I)

     // Floating point.
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool inInfinity(C, I)
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool inNan(C, I)
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool isDigit(C, 10)
               andBool notBool has0xPrefix(I)
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool isDigit(C, 16)
               andBool has0xPrefix(I)
               andBool notBool hasRadix(I)
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool isDigit(C, 2)
               andBool has0xPrefix(I)
               andBool hasRadix(I)
     rule inScanSet(C::String, D::Directive, "") => true
          requires isFloatDirective(D)
               andBool isSign(C)
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool isSign(C)
               // Must both have radix & it's the last char.
               andBool hasRadix(I)
               andBool (toUpperCase(lastChar(I)) ==String "E"
                    orBool toUpperCase(lastChar(I)) ==String "P")
     rule inScanSet(".", D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool notBool hasDot(I)
               andBool notBool hasRadix(I)
     rule inScanSet("x", D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool isXPrefix(I)
     rule inScanSet("X", D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool isXPrefix(I)
     rule inScanSet(C::String, D::Directive, I::String) => true
          requires isFloatDirective(D)
               andBool hasRadix(C) andBool notBool hasRadix(I)
               andBool hasDigit(I)

     // Scan list (e.g., "[^]abc]").
     rule inScanSet(C::String, %(_, _, _, D::String), _)
          => ((substrString(D, 0, 2) ==String "[^")
                    andBool (findChar(D, C, 2) ==Int -1))
               orBool ((substrString(D, 0, 2) =/=String "[^")
                    andBool (findChar(D, C, 1) =/=Int -1))
          requires firstChar(D) ==String "["

     rule inScanSet(_, _, _) => false [owise]

     syntax Bool ::= inNil(String, String) [function]
                   | "inNil'" "(" String "," String ")" [function]
     rule inNil(C::String, I::String)
          => inNil'(toUpperCase(C), toUpperCase(stripSign(I)))
     rule inNil'("(", "") => true
     rule inNil'("N", "(") => true
     rule inNil'("I", "(N") => true
     rule inNil'("L", "(NI") => true
     rule inNil'(")", "(NIL") => true
     rule inNil'(_, _) => false [owise]

     syntax Bool ::= inInfinity(String, String) [function]
                   | "inInfinity'" "(" String "," String ")" [function]
     rule inInfinity(C::String, I::String)
          => inInfinity'(toUpperCase(C), toUpperCase(stripSign(I)))
     rule inInfinity'("I", "") => true
     rule inInfinity'("N", "I") => true
     rule inInfinity'("F", "IN") => true
     rule inInfinity'("I", "INF") => true
     rule inInfinity'("N", "INFI") => true
     rule inInfinity'("I", "INFIN") => true
     rule inInfinity'("T", "INFINI") => true
     rule inInfinity'("Y", "INFINIT") => true
     rule inInfinity'(_, _) => false [owise]

     syntax Bool ::= inNan(String, String) [function]
                   | "inNan'" "(" String "," String ")" [function]
     rule inNan(C::String, I::String) => inNan'(toUpperCase(C), toUpperCase(I))
     rule inNan'("N", "") => true
     rule inNan'("A", "N") => true
     rule inNan'("N", "NA") => true
     rule inNan'(_, _) => false [owise]

     // Given that all characters are in the scan set, is this a complete item?
     syntax Bool ::= isCompleteItem(String, Directive) [function]
     rule isCompleteItem("", D::Directive) => isReadCountDirective(D) orBool D ==K whitespace
     rule isCompleteItem(Item::String, D::Directive) => false
          requires isNumericDirective(D) andBool notBool hasDigit(strip0xPrefix(Item))
               andBool toUpperCase(Item) =/=String "(NIL)"
     rule isCompleteItem(Item::String, D::Directive) => false
          requires isNumericDirective(D) andBool isSign(lastChar(Item))
     rule isCompleteItem(Item::String, %(_, _, _, "p")) => false
          requires toUpperCase(Item) ==String "("
               orBool toUpperCase(Item) ==String "(N"
               orBool toUpperCase(Item) ==String "(NI"
               orBool toUpperCase(Item) ==String "(NIL"
     rule isCompleteItem(Item::String, D::Directive) => false
          requires isFloatDirective(D)
               andBool (toUpperCase(stripSign(Item)) ==String "N"
                    orBool toUpperCase(stripSign(Item)) ==String "NA"
                    orBool toUpperCase(stripSign(Item)) ==String "I"
                    orBool toUpperCase(stripSign(Item)) ==String "IN"
                    orBool toUpperCase(stripSign(Item)) ==String "INFI"
                    orBool toUpperCase(stripSign(Item)) ==String "INFIN"
                    orBool toUpperCase(stripSign(Item)) ==String "INFINI"
                    orBool toUpperCase(stripSign(Item)) ==String "INFINIT")
     rule isCompleteItem(_, _) => true [owise]

     syntax Bool ::= isNumericDirective(Directive) [function]
     rule isNumericDirective(%(_, _, _, "d")) => true
     rule isNumericDirective(%(_, _, _, "i")) => true
     rule isNumericDirective(%(_, _, _, "o")) => true
     rule isNumericDirective(%(_, _, _, "u")) => true
     rule isNumericDirective(%(_, _, _, "x")) => true
     rule isNumericDirective(%(_, _, _, "p")) => true
     rule isNumericDirective(D::Directive) => isFloatDirective(D) [owise]

     syntax Bool ::= isFloatDirective(Directive) [function]
     rule isFloatDirective(%(_, _, _, "a")) => true
     rule isFloatDirective(%(_, _, _, "e")) => true
     rule isFloatDirective(%(_, _, _, "f")) => true
     rule isFloatDirective(%(_, _, _, "g")) => true
     rule isFloatDirective(_) => false [owise]

     syntax Bool ::= atFieldWidth(String, Directive) [function]
     rule atFieldWidth(S::String, %(_, Width::Int, _, _))
          => lengthString(S) ==Int Width
          requires Width >Int 0
     rule atFieldWidth(_, _) => false [owise]

     syntax Bool ::= isSign(String) [function]
     rule isSign("+") => true
     rule isSign("-") => true
     rule isSign(_) => false [owise]

     syntax Bool ::= isXPrefix(String) [function]
     rule isXPrefix(S::String) => stripSign(S) ==String "0"

     syntax Bool ::= hasDot(String) [function]
     rule hasDot(S::String) => findChar(S, ".", 0) >=Int 0

     syntax Bool ::= hasPosSign(String) [function]
     rule hasPosSign(S::String) => firstChar(S) ==String "+"
          requires lengthString(S) >=Int 1
     rule hasPosSign(_) => false [owise]

     syntax Bool ::= hasNegSign(String) [function]
     rule hasNegSign(S::String) => firstChar(S) ==String "-"
          requires lengthString(S) >=Int 1
     rule hasNegSign(_) => false [owise]

     syntax String ::= stripSign(String) [function]
     rule stripSign(S::String) => stripSign(butFirstChar(S))
          requires lengthString(S) >=Int 1
               andBool (isSign(firstChar(S)) orBool isWhitespace(firstChar(S)))
     rule stripSign(S::String) => S [owise]

     syntax Bool ::= has0xPrefix(String) [function]
     rule has0xPrefix(S::String) => toUpperCase(substrString(stripSign(S), 0, 2)) ==String "0X"
          requires lengthString(stripSign(S)) >=Int 2
     rule has0xPrefix(_) => false [owise]

     syntax String ::= strip0xPrefix(String) [function]
     rule strip0xPrefix(S::String) => "+" +String substrString(stripSign(S), 2, lengthString(S))
          requires has0xPrefix(S) andBool hasPosSign(S)
     rule strip0xPrefix(S::String) => "-" +String substrString(stripSign(S), 2, lengthString(S))
          requires has0xPrefix(S) andBool hasNegSign(S)
     rule strip0xPrefix(S::String) => substrString(stripSign(S), 2, lengthString(S))
          requires has0xPrefix(S) andBool notBool (hasPosSign(S) orBool hasNegSign(S))
     rule strip0xPrefix(S::String) => S [owise]

     syntax ParseResult ::= parseResult(Directive, List)

     syntax List ::= parseFormat(List) [function]
     rule parseFormat(L::List) => parseFormat'(parseDirective(L), false)
          requires L =/=K .List
     rule parseFormat(.List) => .List

     syntax List ::= "parseFormat'" "(" ParseResult "," Bool ")" [function]
     rule parseFormat'(parseResult(D::Directive, L::List), false)
          => ListItem(whitespace) ListItem(normalizeDirective(D)) parseFormat(L)
          requires isSpaceSkipDirective(D)
     rule parseFormat'(parseResult(D::Directive, L::List), true)
          => ListItem(normalizeDirective(D)) parseFormat(L)
          requires isSpaceSkipDirective(D)
     rule parseFormat'(parseResult(D::Directive, .List), _)
          => ListItem(normalizeDirective(D))
          requires notBool isSpaceSkipDirective(D)
     rule parseFormat'(parseResult(D::Directive, L::List), _)
          => ListItem(normalizeDirective(D)) parseFormat'(parseDirective(L), D ==K whitespace)
          [owise]

     // Does this directive require skipping leading whitespace?
     syntax Bool ::= isSpaceSkipDirective(Directive) [function]
     rule isSpaceSkipDirective(stringDir(_)) => false
     rule isSpaceSkipDirective(whitespace) => false
     rule isSpaceSkipDirective(%(_, _, _, D::String)) => false
          requires firstChar(D) ==String "["
     rule isSpaceSkipDirective(%(_, _, _, "c")) => false
     rule isSpaceSkipDirective(%(_, _, _, "n")) => false
     rule isSpaceSkipDirective(_) => true [owise]

     syntax Directive ::= normalizeDirective(Directive) [function]
     rule normalizeDirective(%(Write::WriteBehavior, 0, Length::String, "c"))
          => %(Write, 1, Length, "c")
     rule normalizeDirective(%(Write::WriteBehavior, Width::Int, Length::String, "X"))
          => %(Write, Width, Length, "x")
     rule normalizeDirective(%(Write::WriteBehavior, Width::Int, Length::String, "A"))
          => %(Write, Width, Length, "a")
     rule normalizeDirective(%(Write::WriteBehavior, Width::Int, Length::String, "E"))
          => %(Write, Width, Length, "e")
     rule normalizeDirective(%(Write::WriteBehavior, Width::Int, Length::String, "F"))
          => %(Write, Width, Length, "f")
     rule normalizeDirective(%(Write::WriteBehavior, Width::Int, Length::String, "G"))
          => %(Write, Width, Length, "g")
     rule normalizeDirective(D::Directive) => D [owise]

     syntax ParseResult ::= parseDirective(List) [function]
     rule parseDirective(ListItem(C:String) L::List)
          => parseResult(whitespace, eatWhitespace(L))
          requires isWhitespace(C)
     rule parseDirective(ListItem(C:String) L::List)
          => parseResult(stringDir(C), L)
          requires C =/=String "%" andBool notBool isWhitespace(C)
     rule parseDirective(ListItem("%") ListItem("%") L::List)
          => parseResult(%%, L)
     rule parseDirective(ListItem("%") ListItem("*") L::List)
          => parseResult(%
               ( dirRead
               , parseDigits(L)
               , parseLengthMod(eatDigits(L))
               , parseConvSpec(eatLengthMod(eatDigits(L)))
               ), eatConvSpec(eatLengthMod(eatDigits(L))))
     rule parseDirective(ListItem("%") ListItem("m") L::List)
          => parseResult(%
               ( dirAlloc
               , parseDigits(L)
               , parseLengthMod(eatDigits(L))
               , parseConvSpec(eatLengthMod(eatDigits(L)))
               ), eatConvSpec(eatLengthMod(eatDigits(L))))
     rule parseDirective(ListItem("%") L::List)
          => parseResult(%
               ( dirWrite
               , parseDigits(L)
               , parseLengthMod(eatDigits(L))
               , parseConvSpec(eatLengthMod(eatDigits(L)))
               ), eatConvSpec(eatLengthMod(eatDigits(L))))
          [owise]

     syntax Bool ::= isWhitespace(String) [function]
     rule isWhitespace(C::String)
          => (ordChar(C) >=Int 9 andBool ordChar(C) <=Int 13)
               orBool C ==String " "
          requires C =/=String ""
     rule isWhitespace(_) => false [owise]

     syntax Bool ::= isDigit(String, Int) [function]
     rule isDigit(C::String, Base::Int)
          => ordChar(C) >=Int ordChar("0") andBool ordChar(C) <Int (ordChar("0") +Int Base)
          requires Base <=Int 10
               andBool C =/=String ""
     rule isDigit(C::String, Base::Int)
          => isDigit(C, 10)
               orBool (ordChar(C) >=Int ordChar("a")
                    andBool ordChar(C) <Int (ordChar("a") +Int (Base -Int 10)))
               orBool (ordChar(C) >=Int ordChar("A")
                    andBool ordChar(C) <Int (ordChar("A") +Int (Base -Int 10)))
          requires Base >Int 10
               andBool C =/=String ""
     rule isDigit(_, _) => false [owise]

     syntax Bool ::= hasDigit(String) [function]
     rule hasDigit(S::String)
          => findChar(S, "0", 0) =/=Int -1
               orBool findChar(S, "1", 0) =/=Int -1
               orBool findChar(S, "2", 0) =/=Int -1
               orBool findChar(S, "3", 0) =/=Int -1
               orBool findChar(S, "4", 0) =/=Int -1
               orBool findChar(S, "5", 0) =/=Int -1
               orBool findChar(S, "6", 0) =/=Int -1
               orBool findChar(S, "7", 0) =/=Int -1
               orBool findChar(S, "8", 0) =/=Int -1
               orBool findChar(S, "9", 0) =/=Int -1
               orBool findChar(S, "a", 0) =/=Int -1 orBool findChar(S, "A", 0) =/=Int -1
               orBool findChar(S, "b", 0) =/=Int -1 orBool findChar(S, "B", 0) =/=Int -1
               orBool findChar(S, "c", 0) =/=Int -1 orBool findChar(S, "C", 0) =/=Int -1
               orBool findChar(S, "d", 0) =/=Int -1 orBool findChar(S, "D", 0) =/=Int -1
               orBool findChar(S, "e", 0) =/=Int -1 orBool findChar(S, "E", 0) =/=Int -1
               orBool findChar(S, "f", 0) =/=Int -1 orBool findChar(S, "F", 0) =/=Int -1

     syntax Bool ::= hasRadix(String) [function]
     rule hasRadix(S::String)
          => findChar(S, "p", 0) =/=Int -1 orBool findChar(S, "P", 0) =/=Int -1
          requires has0xPrefix(S)
     rule hasRadix(S::String)
          => findChar(S, "e", 0) =/=Int -1 orBool findChar(S, "E", 0) =/=Int -1
          [owise]

     syntax List ::= eatWhitespace(List) [function]
     rule eatWhitespace(ListItem(C:String) L::List)
          => eatWhitespace(L)
          requires isWhitespace(C)
     rule eatWhitespace(L::List) => L [owise]

     syntax Int ::= parseDigits(List) [function]
     rule parseDigits(L::List) => String2Int(fst(parseDigits'(L)))
     syntax List ::= eatDigits(List) [function]
     rule eatDigits(L::List) => snd(parseDigits'(L))

     syntax ParseStrResult ::= parseStrResult(String, List)

     syntax ParseStrResult ::= "parseDigits'" "(" List ")" [function]
     rule parseDigits'(ListItem(C:String) L::List)
          => parseStrResult(C +String fst(parseDigits'(L)), snd(parseDigits'(L)))
          requires isDigit(C, 10)
     rule parseDigits'(L::List)
          => parseStrResult("", L) [owise]

     syntax String ::= parseString(String, List) [function]
     rule parseString(S::String, L::List) => fst(parseString'(S, L))
     syntax List ::= eatString(String, List) [function]
     rule eatString(S::String, L::List) => snd(parseString'(S, L))

     syntax ParseStrResult ::= "parseString'" "(" String "," List ")" [function]
     rule parseString'(S::String, ListItem(C:String) L::List)
          => parseStrResult(C +String fst(parseString'(S, L)), snd(parseString'(S, L)))
          requires C =/=String S
     rule parseString'(_, L::List)
          => parseStrResult("", L) [owise]

     syntax String ::= parseLengthMod(List) [function]
     rule parseLengthMod(L::List) => fst(parseLengthMod'(L))
     syntax List ::= eatLengthMod(List) [function]
     rule eatLengthMod(L::List) => snd(parseLengthMod'(L))

     syntax ParseStrResult ::= "parseLengthMod'" "(" List ")" [function]
     rule parseLengthMod'(ListItem("h") ListItem("h") L::List)
          => parseStrResult("hh", L)
     rule parseLengthMod'(ListItem("h") L::List)
          => parseStrResult("h", L)
          requires notBool atHead("h", L)
     rule parseLengthMod'(ListItem("l") L::List)
          => parseStrResult("l", L)
          requires notBool atHead("l", L)
     rule parseLengthMod'(ListItem("l") ListItem("l") L::List)
          => parseStrResult("ll", L)
     rule parseLengthMod'(ListItem(C:String) L::List)
          => parseStrResult(C, L)
          requires C ==String "j"
               orBool C ==String "z"
               orBool C ==String "t"
               orBool C ==String "L"
     rule parseLengthMod'(L::List) => parseStrResult("", L) [owise]

     syntax String ::= parseConvSpec(List) [function]
     rule parseConvSpec(L::List) => fst(parseConvSpec'(L))
     syntax List ::= eatConvSpec(List) [function]
     rule eatConvSpec(L::List) => snd(parseConvSpec'(L))

     syntax ParseStrResult ::= "parseConvSpec'" "(" List ")" [function]
     rule parseConvSpec'(ListItem(C:String) L::List)
          => parseStrResult(C, L)
          requires C ==String "d"
               orBool C ==String "i"
               orBool C ==String "o"
               orBool C ==String "u"
               orBool C ==String "x" orBool C ==String "X"
               orBool C ==String "a" orBool C ==String "A"
               orBool C ==String "e" orBool C ==String "E"
               orBool C ==String "f" orBool C ==String "F"
               orBool C ==String "g" orBool C ==String "G"
               orBool C ==String "c"
               orBool C ==String "s"
               orBool C ==String "p"
               orBool C ==String "n"
     rule parseConvSpec'(ListItem("[") ListItem("^") ListItem("]") L::List)
          => parseStrResult("[^]" +String expandRanges(parseString("]", L)), tail(eatString("]", L)))
     rule parseConvSpec'(ListItem("[") ListItem("^") L::List)
          => parseStrResult("[^" +String expandRanges(parseString("]", L)), tail(eatString("]", L)))
          requires notBool atHead("]", L)
     rule parseConvSpec'(ListItem("[") ListItem("]") L::List)
          => parseStrResult("[]" +String expandRanges(parseString("]", L)), tail(eatString("]", L)))
     rule parseConvSpec'(ListItem("[") L::List)
          => parseStrResult("[" +String expandRanges(parseString("]", L)), tail(eatString("]", L)))
          requires notBool atHead("^", L) andBool notBool atHead("]", L)
     rule parseConvSpec'(L::List) => parseStrResult("", L) [owise]

     syntax Bool ::= atHead(String, List) [function]
     rule atHead(S::String, ListItem(S) _) => true
     rule atHead(_, _) => false [owise]

     syntax List ::= tail(List) [function]
     rule tail(ListItem(_) L::List) => L
     rule tail(_) => .List [owise]

     syntax String ::= fst(ParseStrResult) [function, klabel(fstParseStr)]
     rule fst(parseStrResult(S::String, _)) => S

     syntax List ::= snd(ParseStrResult) [function, klabel(sndParseStr)]
     rule snd(parseStrResult(_, L::List)) => L

     syntax String ::= expandRanges(String) [function]
     rule expandRanges(S::String) => expandRanges'(firstChar(S), stringToList(butFirstChar(S)))
          requires lengthString(S) >=Int 3
     rule expandRanges(S::String) => S [owise]

     syntax String ::= "expandRanges'" "(" String "," List ")" [function]
     rule expandRanges'(C::String, ListItem(C'::String) L::List)
          => C +String expandRanges'(C', L)
          requires C' =/=String "-" orBool L ==K .List
     rule expandRanges'(C::String, ListItem("-") ListItem(End::String) L::List)
          => C +String expandRanges'(chrChar(ordChar(C) +Int 1), ListItem("-") ListItem(End) L)
          requires ordChar(C) <Int (ordChar(End) -Int 1)
     rule expandRanges'(C::String, ListItem("-") ListItem(End::String) L::List)
          => C +String expandRanges'(End, L)
          requires ordChar(C) >=Int (ordChar(End) -Int 1) andBool ordChar(C) <=Int ordChar(End)
     rule expandRanges'(C::String, ListItem("-") ListItem(End::String) L::List)
          => C +String "-" +String expandRanges'(End, L)
          requires ordChar(C) >Int ordChar(End)
     rule expandRanges'(C::String, .List) => C

     syntax KItem ::= formatter(KItem, List) [strict(1)]
     rule [format-start]:
          <k> formatter(str(S::String), VarArgs::List)
               => formatter'(VarArgs)
          ...</k>
          (.Bag =>
               <formatting>...
                    <format> stringToList(S) </format>
               ...</formatting>
          )
          [structural]

     syntax String ::= ifEmpty(String, String) [function]
     rule ifEmpty("", S::String) => S
     rule ifEmpty(S::String, _)  => S [owise]

     syntax String ::= defaultZero(String) [function]
     rule defaultZero(S::String) => ifEmpty(S, "0")

     syntax String ::= defaultOne(String) [function]
     rule defaultOne(S::String) => ifEmpty(S, "1")

     syntax RValue ::= formattedResult(K)

     syntax KItem ::= "formatter'" "(" List ")"
     rule <k> formatter'(_)
               => formattedResult(listToString(Result))
          ...</k>
          <format> .List </format>
          <format-result> Result:List </format-result>
          <format-state> "normal" </format-state>
          [structural]

     rule [format-normal]:
          <k> formatter'(_) ...</k>
          <format> ListItem(S:String) => .List ...</format>
          <format-result>... .List => ListItem(S) </format-result>
          <format-state> "normal" </format-state>
          requires S =/=String "%"
          [structural]

     rule [format-reset]:
          <k> formatter'(_) ...</k>
          <format-pad-zero> _ => false </format-pad-zero>
          <format-alt-form> _ => false </format-alt-form>
          <format-field-width> _ => "" </format-field-width>
          <format-precision> _ => "" </format-precision>
          <format-length> _ => "" </format-length>
          <format-state> "reset" => "normal" </format-state>
          [structural]

     rule [format-%]:
          <k> formatter'(_) ...</k>
          <format> ListItem("%") => .List ...</format>
          <format-state> "normal" => "%" </format-state>
          [structural]

     // %[flags][width][.precision][length]type

     /*@ \source[n1570]{\para{7.21.6.1}{4}}
     Each conversion specification is introduced by the character \texttt{\%}.
     After the \texttt{\%}, the following appear in sequence:
     \begin{itemize}
     \item Zero or more flags (in any order) that modify the meaning of the
     conversion specification.

     \item An optional minimum field width. If the converted value has fewer
     characters than the field width, it is padded with spaces (by default) on
     the left (or right, if the left adjustment flag, described later, has been
     given) to the field width. The field width takes the form of an asterisk
     \texttt{*} (described later) or a nonnegative decimal integer.)

     \item An optional precision that gives the minimum number of digits to
     appear for the \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x},
     and \texttt{X} conversions, the number of digits to appear after the
     decimal-point character for \texttt{a}, \texttt{A}, \texttt{e},
     \texttt{E}, \texttt{f}, and \texttt{F} conversions, the maximum number of
     significant digits for the \texttt{g} and \texttt{G} conversions, or the
     maximum number of bytes to be written for s conversions. The precision
     takes the form of a period (\texttt{.}) followed either by an asterisk
     \texttt{*} (described later) or by an optional decimal integer; if only
     the period is specified, the precision is taken as zero. If a precision
     appears with any other conversion specifier, the behavior is undefined.

     \item An optional length modifier that specifies the size of the argument.

     \item A conversion specifier character that specifies the type of
     conversion to be applied.

     \end{itemize}
     */

     /*@ \fromStandard{\source[n1570]{\para{7.21.6.1}{5}}}{
     As noted above, a field width, or precision, or both, may be indicated by
     an asterisk. In this case, an \cinline{int} argument supplies the field
     width or precision. The arguments specifying field width, or precision, or
     both, shall appear (in that order) before the argument (if any) to be
     converted. A negative field width argument is taken as a \texttt{-} flag
     followed by a positive field width. A negative precision argument is taken
     as if the precision were omitted. }*/

     /*@ \fromStandard{\source[n1570]{\para{7.21.6.1}{6}}}{
     The flag characters and their meanings are:
     \begin{description}

     \item[\texttt{-}] \broken{The result of the conversion is left-justified
     within the field. (It is right-justified if this flag is not specified.)}

     \item[\texttt{+}] \broken{The result of a signed conversion always begins
     with a plus or minus sign. (It begins with a sign only when a negative
     value is converted if this flag is not specified.)}

     \item[\emph{space}] \broken{If the first character of a signed conversion
     is not a sign, or if a signed conversion results in no characters, a space
     is prefixed to the result. If the \emph{space} and \texttt{+} flags both
     appear, the \emph{space} flag is ignored.}

     \item[\texttt{\#}] \broken{The result is converted to an ``alternative
     form''. For \texttt{o} conversion, it increases the precision, if and only
     if necessary, to force the first digit of the result to be a zero (if the
     value and precision are both 0, a single 0 is printed). For \texttt{x} (or
     \texttt{X}) conversion, a nonzero result has \texttt{0x} (or \texttt{0X})
     prefixed to it. For \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E},
     \texttt{f}, \texttt{F}, \texttt{g}, and \texttt{G} conversions, the result
     of converting a floating-point number always contains a decimal-point
     character, even if no digits follow it. (Normally, a decimal-point
     character appears in the result of these conversions only if a digit
     follows it.) For \texttt{g} and \texttt{G} conversions, trailing zeros are
     \emph{not} removed from the result. For other conversions, the behavior is
     undefined.}

     \item[\texttt{0}] \broken{For \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, \texttt{X}, \texttt{a}, \texttt{A}, \texttt{e},
     \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, and \texttt{G}
     conversions, leading zeros (following any indication of sign or base) are
     used to pad to the field width rather than performing space padding,
     except when converting an infinity or NaN. If the \texttt{0} and
     \texttt{-} flags both appear, the \texttt{0} flag is ignored. For
     \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u}, \texttt{x}, and \texttt{X}
     conversions, if a precision is specified, the \texttt{0} flag is ignored.}
     \end{description}
     For other conversions, the behavior is undefined.
     }*/

     rule [format-%0]:
          <k> formatter'(_) ...</k>
          <format-pad-zero> _ => true </format-pad-zero>
          <format-field-width> "" </format-field-width>
          <format> ListItem("0") => .List ...</format>
          <format-state> "%" </format-state>
          [structural]
     rule <k> formatter'(_) ...</k>
          <format-alt-form> _ => true </format-alt-form>
          <format-field-width> "" </format-field-width>
          <format> ListItem("#") => .List ...</format>
          <format-state> "%" </format-state>
          [structural]
     rule <k> formatter'(_) ...</k>
          <format-field-width> W:String => W +String "0" </format-field-width>
          <format> ListItem("0") => .List ...</format>
          <format-state> "%" </format-state>
          requires W =/=K ""
          [structural]
     rule <k> formatter'(_) ...</k>
          <format> ListItem(C:String) => .List ...</format>
          <format-field-width> W:String => W +String C </format-field-width>
          <format-state> "%" </format-state>
          requires isSign(C) orBool (isDigit(C, 10) andBool C =/=String "0")
          [structural]
     rule <k> formatter'(_) ...</k>
          <format> ListItem("*") => .List ...</format>
          <format-field-width> "" => "*" </format-field-width>
          <format-state> "%" </format-state>

     rule <k> formatter'(_) ...</k>
          <format> ListItem(".") => .List ...</format>
          <format-precision> "" </format-precision>
          <format-state> "%" => "%." </format-state>
          [structural]

     rule <k> formatter'(_) ...</k>
          <format> ListItem(C:String) => .List ...</format>
          <format-precision> P:String => P +String C </format-precision>
          <format-state> "%." </format-state>
          requires isDigit(C, 10)
          [structural]
     rule <k> formatter'(_) ...</k>
          <format> ListItem(C:String) ...</format>
          <format-precision> P:String </format-precision>
          <format-state> "%." => "%" </format-state>
          requires P =/=K ""
               andBool notBool isDigit(C, 10) andBool C =/=K "*"
          [structural]
     rule <k> formatter'(_) ...</k>
          <format> ListItem(C:String) ...</format>
          <format-precision> "" => "0" </format-precision>
          <format-state> "%." => "%" </format-state>
          requires notBool isDigit(C, 10) andBool C =/=K "*"
          [structural]

     rule <k> formatter'(_) ...</k>
          <format> ListItem("*") => .List ...</format>
          <format-precision> "" => "*" </format-precision>
          <format-state> "%." => "%" </format-state>

     rule <k> (.K => UNDEF("STDIO10",
               "'printf': Invalid conversion specifier with '#' flag."))
              ~> formatter'(_)
          ...</k>
          <format-alt-form> true </format-alt-form>
          <format-state> State::String </format-state>
          requires State ==String "%d"
               orBool State ==String "%i"
               orBool State ==String "%u"
               orBool State ==String "%c"
               orBool State ==String "%s"
               orBool State ==String "%p"
               orBool State ==String "%n"
               orBool State ==String "%%"

     rule <k> (.K => UNDEF("STDIO11",
               "'printf': Invalid conversion specifier with '0' flag."))
              ~> formatter'(_)
          ...</k>
          <format-pad-zero> true </format-pad-zero>
          <format-state> State::String </format-state>
          requires State ==String "%c"
               orBool State ==String "%s"
               orBool State ==String "%p"
               orBool State ==String "%n"
               orBool State ==String "%%"

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{d},\texttt{i}]
     The \cinline{int} argument is converted to signed decimal in the style
     \emph{[-]dddd}. \broken{The precision specifies the minimum number of
     digits to appear; if the value being converted can be represented in fewer
     digits, it is expanded with leading zeros. The default precision is 1. The
     result of converting a zero value with a precision of zero is no
     characters.}
     \end{description}
     */

     rule [format-%d-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem(S:String) => .List ...</format>
          <format-precision> P:String => #if P ==String "" #then "1" #else P #fi </format-precision>
          <format-pad-zero> Z::Bool => #if P ==String "" #then Z #else false #fi </format-pad-zero>
          <format-state> "%" => "%d" </format-state>
          requires S ==String "d" orBool S ==String "i"
          [structural]

     rule <k> formatter'(_) ...</k>
          <format-arg> S:SymLoc => unknown(0) </format-arg>
          <format-state> State::String </format-state>
          requires notBool isPointerType(getFormatType'(State, ""))
     rule <k> formatter'(_) ...</k>
          <format-arg> encodedPtr(_, _, _) => unknown(0) </format-arg>
          <format-state> State::String </format-state>
          requires notBool isPointerType(getFormatType'(State, ""))

     rule <k> (.K => UNSPEC("STDIO2", "Printing an unspecified value.")) ~> formatter'(_) ...</k>
          <format-arg> unknown(_) </format-arg>

     rule <k> formatter'(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-field-width> W:String </format-field-width>
          <format-alt-form> false </format-alt-form>
          <format-result>...
               .List => ListItem(
                        formatPrecisionWidth(showInt(D),
                                             String2Int(defaultOne(P)),
                                             Z, "",
                                             String2Int(defaultZero(W))))
          </format-result>
          <format-state> "%d" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{o},\texttt{u},\texttt{x},\texttt{X}]
     The \cinline{unsigned int} argument is converted to unsigned octal
     (\texttt{o}), unsigned decimal (\texttt{u}), or unsigned hexadecimal
     notation (\texttt{x} or \texttt{X}) in the style \emph{dddd}; the letters
     \texttt{abcdef} are used for \texttt{x} conversion and the letters
     \texttt{ABCDEF} for \texttt{X} conversion. \broken{The precision specifies
     the minimum number of digits to appear; if the value being converted can
     be represented in fewer digits, it is expanded with leading zeros. The
     default precision is 1. The result of converting a zero value with a
     precision of zero is no characters.}
     \end{description}
     */
     rule [format-%o-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("o") => .List ...</format>
          <format-precision> P:String => #if P ==String "" #then "1" #else P #fi </format-precision>
          <format-pad-zero> Z::Bool => #if P ==String "" #then Z #else false #fi </format-pad-zero>
          <format-state> "%" => "%o" </format-state>
          [structural]
     rule [format-%o]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-alt-form> Hash:Bool </format-alt-form>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(
                        formatPrecisionWidth(Base2String(D, 8),
                                             String2Int(defaultOne(P)),
                                             Z, #if Hash #then "0" #else "" #fi,
                                             String2Int(defaultZero(W))))
          </format-result>
          <format-state> "%o" => "reset" </format-state>
          [structural]
     rule [format-%u-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("u") => .List ...</format>
          <format-precision> P:String => #if P ==String "" #then "1" #else P #fi </format-precision>
          <format-pad-zero> Z::Bool => #if P ==String "" #then Z #else false #fi </format-pad-zero>
          <format-state> "%" => "%u" </format-state>
          [structural]
     rule [format-%u]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-alt-form> false </format-alt-form>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(
                        formatPrecisionWidth(showInt(D),
                                             String2Int(defaultOne(P)),
                                             Z, "",
                                             String2Int(defaultZero(W))))
          </format-result>
          <format-state> "%u" => "reset" </format-state>
          [structural]
     rule [format-%x-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("x") => .List ...</format>
          <format-precision> P:String => #if P ==String "" #then "1" #else P #fi </format-precision>
          <format-pad-zero> Z::Bool => #if P ==String "" #then Z #else false #fi </format-pad-zero>
          <format-state> "%" => "%x" </format-state>
          [structural]
     rule [format-%x]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-alt-form> Hash:Bool </format-alt-form>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(
                        formatPrecisionWidth(Base2String(D, 16),
                                             String2Int(defaultOne(P)),
                                             Z, #if Hash #then "0x" #else "" #fi,
                                             String2Int(defaultZero(W))))
          </format-result>
          <format-state> "%x" => "reset" </format-state>
          [structural]
     rule [format-%X-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("X") => .List ...</format>
          <format-precision> P:String => #if P ==String "" #then "1" #else P #fi </format-precision>
          <format-pad-zero> Z::Bool => #if P ==String "" #then Z #else false #fi </format-pad-zero>
          <format-state> "%" => "%X" </format-state>
          [structural]
     rule [format-%X]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Int => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-alt-form> Hash:Bool </format-alt-form>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(
                        toUpperCase(formatPrecisionWidth(Base2String(D, 16),
                                             String2Int(defaultOne(P)),
                                             Z, #if Hash #then "0X" #else "" #fi,
                                             String2Int(defaultZero(W)))))
          </format-result>
          <format-state> "%X" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{f},\texttt{F}]
     A \cinline{double} argument representing a floating-point number is
     converted to decimal notation in the style \emph{[-]ddd.ddd},
     \broken{where the number of digits after the decimal-point character is
     equal to the precision specification. If the precision is missing, it is
     taken as 6; if the precision is zero and the \texttt{\#} flag is not
     specified, no decimal-point character appears. If a decimal-point
     character appears, at least one digit appears before it. The value is
     rounded to the appropriate number of digits.}

     A \cinline{double} argument representing an infinity is converted in one
     of the styles \emph{[-]inf} or \emph{[-]infinity}---which style is
     implementation-defined.  A \cinline{double} argument representing a NaN is
     converted in one of the styles \emph{[-]nan} or
     \emph{[-]nan}(\emph{n-char-sequence})---which style, and the meaning of
     any \emph{n-char-sequence}, is implementation-defined. The \texttt{F}
     conversion specifier produces \cinline{INF}, \cinline{INFINITY}, or
     \cinline{NAN} instead of \cinline{inf}, \cinline{infinity}, or
     \cinline{nan}, respectively.
     \end{description}
     */

     //TODO(traiansf): missing formatting for long double
     //TODO(traiansf): width specs for floats are not working
     //TODO(dwightguth): support alternate form
     rule [format-%f-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("f") => .List ...</format>
          <format-state> "%" => "%f" </format-state>
          [structural]
     rule [format-%f]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(padString(
                    showFloat(setPrecision(D, String2Int(ifEmpty(P, "6")))),
                    String2Int(defaultZero(W)),
                    #if Z #then "0" #else " " #fi))
          </format-result>
          <format-state> "%f" => "reset" </format-state>
          [structural]
     rule [format-%F-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("F") => .List ...</format>
          <format-state> "%" => "%F" </format-state>
          [structural]
     rule [format-%F]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(padString(
                    toUpperCase(showFloat(setPrecision(D, String2Int(ifEmpty(P, "6"))))),
                    String2Int(defaultZero(W)),
                    #if Z #then "0" #else " " #fi))
          </format-result>
          <format-state> "%F" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{e},\texttt{E}]
     \broken{A \cinline{double} argument representing a floating-point number
     is converted in the style \emph{[-]d.ddde$\pm{}$dd}, where there is one
     digit (which is nonzero if the argument is nonzero) before the
     decimal-point character and the number of digits after it is equal to the
     precision; if the precision is missing, it is taken as 6; if the precision
     is zero and the \texttt{\#} flag is not specified, no decimal-point
     character appears. The value is rounded to the appropriate number of
     digits. The \texttt{E} conversion specifier produces a number with
     \texttt{E} instead of e introducing the exponent. The exponent always
     contains at least two digits, and only as many more digits as necessary to
     represent the exponent. If the value is zero, the exponent is zero.}

     \broken{A double argument representing an infinity or NaN is converted in
     the style of an \texttt{f} or \texttt{F} conversion specifier.}

     \end{description}
     */

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{g},\texttt{G}]
     A \cinline{double} argument representing a floating-point number is
     converted in style \texttt{f} or \texttt{e} (or in style \texttt{F} or
     \texttt{E} in the case of a \texttt{G} conversion specifier), depending on
     the value converted and the precision. \broken{Let $P$ equal the precision
     if nonzero, 6 if the precision is omitted, or 1 if the precision is zero.
     Then, if a conversion with style \texttt{E} would have an exponent of
     $X$:}
     \begin{itemize}

     \item \broken{if $P > X = -4$, the conversion is with style \texttt{f} (or
     \texttt{F}) and precision $P - (X + 1)$.}

     \item \broken{otherwise, the conversion is with style \texttt{e} (or
     \texttt{E}) and precision $P - 1$.}

     \end{itemize}
     \broken{Finally, unless the \texttt{\#} flag is used, any trailing zeros
     are removed from the fractional portion of the result and the
     decimal-point character is removed if there is no fractional portion
     remaining.}

     A \cinline{double} argument representing an infinity or NaN is converted
     in the style of an \texttt{f} or \texttt{F} conversion specifier.
     \end{description}
     */
     rule [format-%g-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("g") => .List ...</format>
          <format-state> "%" => "%g" </format-state>
          [structural]
     rule [format-%g]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(padString(
                    showFloat(setPrecision(D, String2Int(ifEmpty(P, "6")))),
                    String2Int(defaultZero(W)),
                    #if Z #then "0" #else " " #fi))
          </format-result>
          <format-state> "%g" => "reset" </format-state>
          [structural]
     rule [format-%G-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("G") => .List ...</format>
          <format-state> "%" => "%G" </format-state>
          [structural]
     rule [format-%G]:
          <k> formatter'(_) ...</k>
          <format-arg> D:Float => .K </format-arg>
          <format-precision> P:String </format-precision>
          <format-pad-zero> Z:Bool </format-pad-zero>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(padString(
                    toUpperCase(showFloat(setPrecision(D, String2Int(ifEmpty(P, "6"))))),
                    String2Int(defaultZero(W)),
                    #if Z #then "0" #else " " #fi))
          </format-result>
          <format-state> "%G" => "reset" </format-state>
          [structural]

     /* \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{a},\texttt{A}]
     \ldots
     \end{description}
     */

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{c}]
     If no \texttt{l} length modifier is present, the \cinline{int} argument is
     converted to an \cinline{unsigned char}, and the resulting character is
     written.

     \broken{If an \texttt{l} length modifier is present, the \cinline{wint_t}
     argument is converted as if by an \texttt{ls} conversion specification
     with no precision and an argument that points to the initial element of a
     two-element array of \cinline{wchar_t}, the first element containing the
     \cinline{wint_t} argument to the \texttt{lc} conversion specification and
     the second a null wide character.}
     \end{description}
     */
     rule [format-%c-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("c") => .List ...</format>
          <format-state> "%" => "%c" </format-state>
          [structural]
     rule [format-%c]:
          <k> formatter'(_) ...</k>
          <format-arg> C:Int => .K </format-arg>
          <format-pad-zero> false </format-pad-zero>
          <format-alt-form> false </format-alt-form>
          <format-result>...
               .List => ListItem(chrChar(((C:Int %Int 256) +Int 256)
                    %Int 256))
          </format-result>
          <format-state> "%c" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{s}]
     If no \texttt{l} length modifier is present, the argument shall be a
     pointer to the initial element of an array of character type. Characters
     from the array are written up to (but not imports) the terminating null
     character. \broken{If the precision is specified, no more than that many
     bytes are written.} If the precision is not specified or is greater than
     the size of the array, the array shall contain a null character.

     \broken{If an \texttt{l} length modifier is present, the argument shall be
     a pointer to the initial element of an array of \cinline{wchar_t} type.
     Wide characters from the array are converted to multibyte characters (each
     as if by a call to the \cinline{wcrtomb} function, with the conversion
     state described by an \cinline{mbstate_t} object initialized to zero
     before the first wide character is converted) up to and imports a
     terminating null wide character. The resulting multibyte characters are
     written up to (but not imports) the terminating null character (byte). If
     no precision is specified, the array shall contain a null wide character.
     If a precision is specified, no more than that many bytes are written
     (imports shift sequences, if any), and the array shall contain a null wide
     character if, to equal the multibyte character sequence length given by
     the precision, the function would need to access a wide character one past
     the end of the array. In no case is a partial multibyte character
     written.}
     \end{description}
     */
     rule [format-%s-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("s") => .List ...</format>
          <format-state> "%" => "%s" </format-state>
          [structural]
     rule [format-%s]:
          <k> (.K => getString'(Loc, String2Int(ifEmpty(P, "-1"))))
               ~> formatter'(_)
          ...</k>
          <format-length> Len::String </format-length>
          <format-precision> P::String </format-precision>
          <format-pad-zero> false </format-pad-zero>
          <format-alt-form> false </format-alt-form>
          <format-arg> Loc:SymLoc => .K </format-arg>
          <format-state> "%s" => "%s-read" </format-state>
          requires Len =/=String "l"
          [structural]
     rule [format-%ls]:
          <k> (.K => getWString'(Loc, String2Int(ifEmpty(P, "-1"))))
               ~> formatter'(_)
          ...</k>
          <format-length> "l" </format-length>
          <format-precision> P::String </format-precision>
          <format-pad-zero> false </format-pad-zero>
          <format-alt-form> false </format-alt-form>
          <format-arg> Loc:SymLoc => .K </format-arg>
          <format-state> "%s" => "%s-read" </format-state>
          [structural]
     rule [format-%s-done]:
          <k> (str(S:String) => .K)
               ~> formatter'(_)
          ...</k>
          <format-result>...
               .List => ListItem(S)
          </format-result>
          <format-state> "%s-read" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{p}]
     The argument shall be a pointer to \cinline{void}. The value of the
     pointer is converted to a sequence of printing characters, in an
     implementation-defined manner.
     \end{description}
     */
     rule [format-%p-start]:
          <k> formatter'(Args:List) => formatter-next(Args) ...</k>
          <format> ListItem("p") => .List ...</format>
          <format-state> "%" => "%p" </format-state>
          [structural]
     rule [format-%p]:
          <k> formatter'(_) ...</k>
          <format-arg> Loc:SymLoc => .K </format-arg>
          <format-precision> "" </format-precision>
          <format-alt-form> false </format-alt-form>
          <format-pad-zero> false </format-pad-zero>
          <format-field-width> W:String </format-field-width>
          <format-result>...
               .List => ListItem(padString(pointerToString(Loc), String2Int(defaultZero(W)), " "))
          </format-result>
          <format-state> "%p" => "reset" </format-state>
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{n}]
     \broken{The argument shall be a pointer to signed integer into which is
     \emph{written} the number of characters written to the output stream so
     far by this call to \cinline{fprintf}. No argument is converted, but one
     is consumed. If the conversion specification includes any flags, a field
     width, or a precision, the behavior is undefined.}
     \end{description}
     */

     /*@ \source[n1570]{\para{7.21.6.1}{8}}
     \begin{description}
     \item[\texttt{\%}]
     A \texttt{\%} character is written. No argument is converted. The complete
     conversion specification shall be \texttt{\%\%}.
     \end{description}
     */
     rule [format-%%]:
          <k> formatter'(_) ...</k>
          <format> ListItem("%") => .List ...</format>
          <format-state> "%" => "%%" </format-state>
          [structural]
     rule <k> formatter'(_) ...</k>
          <format-field-width> "" </format-field-width>
          <format-alt-form> false </format-alt-form>
          <format-pad-zero> false </format-pad-zero>
          <format-length> "" </format-length>
          <format-precision> "" </format-precision>
          <format-result>...
               .List => ListItem("%")
          </format-result>
          <format-state> "%%" => "reset" </format-state>
          [structural]

     rule [format-%l]:
          <k> formatter'(_) ...</k>
          <format> ListItem(Char:String) => .List ...</format>
          <format-state> "%" </format-state>
          <format-length>
               Length:String => Length +String Char
          </format-length>
          requires Char ==String "l"
               orBool Char ==String "h"
               orBool Char ==String "j"
               orBool Char ==String "z"
               orBool Char ==String "t"
          [structural]

     syntax KItem ::= "formatter-next" "(" List ")"
     rule <k> formatter-next(ListItem(V:RValue) Args:List)
              => formatter-arg(nextvarg(V, getFormatType), Args)
          ...</k>
          <format-field-width> W::String </format-field-width>
          <format-precision> P::String </format-precision>
          requires W =/=String "*" andBool P =/=String "*"
          [structural]
     rule (.K => UNDEF("STDIO12", "Insufficient arguments supplied for the format string."))
          ~> formatter-next(.List)
          [structural]

     rule <k> formatter-next(ListItem(V:RValue) Args:List)
              => formatter-width(nextvarg(V, type(int)), Args)
          ...</k>
          <format-field-width> "*" </format-field-width>
          [structural]

     rule <k> formatter-next(ListItem(V:RValue) Args:List)
              => formatter-prec(nextvarg(V, type(int)), Args)
          ...</k>
          <format-field-width> W::String </format-field-width>
          <format-precision> "*" </format-precision>
          requires W =/=String "*"
          [structural]

     syntax KItem ::= "formatter-arg" "(" KItem "," List ")" [strict(1)]
     rule <k> formatter-arg(tv(V::CValue, _), Args:List)
               => formatter'(Args)
          ...</k>
          <format-arg> _ => V </format-arg>
          [structural]
     syntax KItem ::= "formatter-prec" "(" KItem "," List ")" [strict(1)]
     rule <k> formatter-prec(tv(V:Int, _), Args:List)
               => formatter-next(Args)
          ...</k>
          <format-precision> _ => showInt(V) </format-precision>
          [structural]
     syntax KItem ::= "formatter-width" "(" KItem "," List ")" [strict(1)]
     rule <k> formatter-width(tv(V:Int, _), Args:List)
               => formatter-next(Args)
          ...</k>
          <format-field-width> _ => showInt(V) </format-field-width>
          [structural]

     syntax KItem ::= nextvarg(RValue, KItem) [strict(2)]
     rule <k> nextvarg(tv(V:CValue, T'::UType), T:Type) => tv(V, utype(T)) ...</k>
          <format-state> State:String </format-state>
          <format-length> Length:String </format-length>
          requires utype(T) ==Type T'
               orBool (isIntegerType(T) andBool promote(utype(T)) ==Type T')
               orBool (State ==K "%s" andBool Length ==K "" andBool isPointerToCharType(T') andBool isPointerType(T))
          [structural]
     rule <k> (.K => UNDEF("STDIO1",
               "'printf': Mismatch between the type expected by the conversion specifier "
               +String State +String " and the type of the argument.") )
          ~> nextvarg(tv(V:CValue, T'::UType), T:Type)
          ...</k>
          <format-state> State:String </format-state>
          <format-length> Length:String </format-length>
          requires notBool (utype(T) ==Type T'
               orBool (isIntegerType(T) andBool promote(utype(T)) ==Type T')
               orBool (State ==K "%s" andBool Length ==K "" andBool isPointerToCharType(T') andBool isPointerType(T)))
          [structural]

     /*@ \source[n1570]{\para{7.21.6.1}{7}}
     The length modifiers and their meanings are:
     \begin{description}
     \item[\texttt{hh}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{signed char} or \cinline{unsigned char} argument (the argument
     will have been promoted according to the integer promotions, but its value
     shall be converted to \cinline{signed char} or \cinline{unsigned char}
     before printing); or that a following \texttt{n} conversion specifier
     applies to a pointer to a \cinline{signed char} argument.}

     \item[\texttt{h}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{short int} or \cinline{unsigned short int} argument (the argument
     will have been promoted according to the integer promotions, but its value
     shall be converted to \cinline{short int} or \cinline{unsigned short int}
     before printing); or that a following \texttt{n} conversion specifier
     applies to a pointer to a \cinline{short int} argument.}

     \item[\texttt{l} (ell)]
     Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u},
     \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{long
     int} or \cinline{unsigned long int} argument; that a following \texttt{n}
     conversion specifier applies to a pointer to a \cinline{long int}
     argument; \broken{that a following \texttt{c} conversion specifier applies
     to a \cinline{wint_t} argument; that a following \texttt{s} conversion
     specifier applies to a pointer to a \cinline{wchar_t} argument}; or has no
     effect on a following \texttt{a}, \texttt{A}, \texttt{e}, \texttt{E},
     \texttt{f}, \texttt{F}, \texttt{g}, or \texttt{G} conversion specifier.

     \item[\texttt{ll} (ell-ell)]
     Specifies that a following \texttt{d}, \texttt{i}, \texttt{o}, \texttt{u},
     \texttt{x}, or \texttt{X} conversion specifier applies to a \cinline{long
     long int} or \cinline{unsigned long long int} argument; or that a
     following \texttt{n} conversion specifier applies to a pointer to a
     \cinline{long long int} argument.

     \item[\texttt{j}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to an
     \cinline{intmax_t} or \cinline{uintmax_t} argument; or that a following
     \texttt{n} conversion specifier applies to a pointer to an
     \cinline{intmax_t} argument.}

     \item[\texttt{z}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{size_t} or the corresponding signed integer type argument; or
     that a following \texttt{n} conversion specifier applies to a pointer to a
     signed integer type corresponding to \cinline{size_t} argument.}

     \item[\texttt{t}]
     \broken{Specifies that a following \texttt{d}, \texttt{i}, \texttt{o},
     \texttt{u}, \texttt{x}, or \texttt{X} conversion specifier applies to a
     \cinline{ptrdiff_t} or the corresponding unsigned integer type argument;
     or that a following \texttt{n} conversion specifier applies to a pointer
     to a \cinline{ptrdiff_t} argument.}

     \item[\texttt{L}]
     \broken{Specifies that a following \texttt{a}, \texttt{A}, \texttt{e},
     \texttt{E}, \texttt{f}, \texttt{F}, \texttt{g}, or \texttt{G} conversion
     specifier applies to a \cinline{long double} argument.}

     \end{description}
     If a length modifier appears with any conversion specifier other than as
     specified above, the behavior is undefined.
     */

     syntax String ::= padString(String, Int, String) [function]
                     | "padString'" "(" String "," Int "," String ")" [function]

     rule padString(X::String, W::Int, _) => X
          requires lengthString(X) >=Int absInt(W)
     rule padString(X::String, W::Int, P::String)
          => padString'(X, (absInt(W) -Int lengthString(X)) *Int signInt(W), P)
          requires lengthString(X) <Int absInt(W)

     rule padString'(X::String, W::Int, P::String) => padString'(X +String " ", W +Int 1, P)
          requires W <Int 0
     rule padString'(X::String, W::Int, P::String) => padString'(P +String X, W -Int 1, P)
          requires W >Int 0
     rule padString'(X::String, W::Int, _) => X
          requires W ==Int 0

    syntax String ::= "formatPrecisionWidth" "(" String "," Int "," Bool "," String "," Int ")" [function]
                    | "formatPrecisionWidth'" "(" String "," Int "," Bool "," String "," Int ")" [function]
                    | "formatPrecisionWidth''" "(" String "," Int "," String "," Int ")" [function]

    rule formatPrecisionWidth(V::String, P::Int, Z::Bool, Prefix::String, W::Int)
         => formatPrecisionWidth'(V, P, #if W <Int 0 #then false #else Z #fi, Prefix, W)
         requires V =/=String "0" orBool P =/=Int 0 orBool Prefix ==String "0"
    rule formatPrecisionWidth("0", 0, Z::Bool, Prefix::String, W::Int)
         => formatPrecisionWidth'("", 0, #if W <Int 0 #then false #else Z #fi, Prefix, W)
         requires Prefix =/=String "0"

    rule formatPrecisionWidth'(V::String, P::Int, true, Prefix::String, W::Int)
         => formatPrecisionWidth''(V, maxInt(P, W -Int lengthString(Prefix)), Prefix, 0)
    rule formatPrecisionWidth'(V::String, P::Int, false, Prefix::String, W::Int)
         => formatPrecisionWidth''(V, P, Prefix, W)

    rule formatPrecisionWidth''(V::String, P::Int, "0", W::Int)
         => padString(#fun(V2::String => #if firstChar(V2) ==String "0" #then V2 #else "0" +String V2 #fi)(padString(V, P, "0")), W, " ")
    rule formatPrecisionWidth''(V::String, P::Int, Prefix::String, W::Int)
         => padString(padString(V, P, "0"), W, " ")
         requires ((V ==String "0" orBool V ==String "") andBool (Prefix ==String "0x" orBool Prefix ==String "0X")) orBool Prefix ==String ""
    rule formatPrecisionWidth''(V::String, P::Int, Prefix::String, W::Int)
         => padString(Prefix +String padString(V, P, "0"), W, " ")
         requires V =/=String "0" andBool V =/=String "" andBool (Prefix ==String "0x" orBool Prefix ==String "0X")

     syntax Int ::= signInt(Int) [function]
     rule signInt(X::Int) => X /Int absInt(X)

     syntax Float ::= setPrecision(Float, Int) [function]
     // TODO(chathhorn)
     rule setPrecision(F::Float, _) => F

     syntax KItem ::= "getFormatType"
     rule <k> getFormatType => getFormatType'(State, Length) ...</k>
          <format-length> Length::String </format-length>
          <format-state> State::String </format-state>
          requires notBool isNoType(getFormatType'(State, Length))
          [structural]
     syntax KItem ::= invalidLength(String)
     rule <k> getFormatType
               => UNDEF("STDIO13", "Invalid length modifier '" +String Length +String "' for conversion specifier '" +String State +String "' in a format string.")
               ~> invalidLength(State::String)
          ...</k>
          <format-length> Length::String </format-length>
          <format-state> State::String </format-state>
          requires isNoType(getFormatType'(State, Length))
          [structural]

     syntax Type ::= "getFormatType'" "(" String "," String ")" [function]
     rule getFormatType'("%a", "") => type(double)
     rule getFormatType'("%A", "") => type(double)
     rule getFormatType'("%e", "") => type(double)
     rule getFormatType'("%E", "") => type(double)
     rule getFormatType'("%f", "") => type(double)
     rule getFormatType'("%F", "") => type(double)
     rule getFormatType'("%g", "") => type(double)
     rule getFormatType'("%G", "") => type(double)
     rule getFormatType'("%a", "L") => type(long-double)
     rule getFormatType'("%A", "L") => type(long-double)
     rule getFormatType'("%e", "L") => type(long-double)
     rule getFormatType'("%E", "L") => type(long-double)
     rule getFormatType'("%f", "L") => type(long-double)
     rule getFormatType'("%F", "L") => type(long-double)
     rule getFormatType'("%g", "L") => type(long-double)
     rule getFormatType'("%G", "L") => type(long-double)

     rule getFormatType'("%c", "") => type(int)
     rule getFormatType'("%c", "l") => type(cfg:wintut)
     rule getFormatType'("%s", "") => type(pointerType(type(char)))
     rule getFormatType'("%s", "l") => type(pointerType(type(cfg:wcharut)))

     rule getFormatType'("%p", "") => type(pointerType(type(void)))

     rule getFormatType'("%d", "hh") => type(signed-char)
     rule getFormatType'("%i", "hh") => type(signed-char)
     rule getFormatType'("%o", "hh") => type(unsigned-char)
     rule getFormatType'("%u", "hh") => type(unsigned-char)
     rule getFormatType'("%x", "hh") => type(unsigned-char)
     rule getFormatType'("%X", "hh") => type(unsigned-char)
     rule getFormatType'("%n", "hh") => type(pointerType(type(signed-char)))

     rule getFormatType'("%d", "h") => type(short-int)
     rule getFormatType'("%i", "h") => type(short-int)
     rule getFormatType'("%o", "h") => type(unsigned-short-int)
     rule getFormatType'("%u", "h") => type(unsigned-short-int)
     rule getFormatType'("%x", "h") => type(unsigned-short-int)
     rule getFormatType'("%X", "h") => type(unsigned-short-int)
     rule getFormatType'("%n", "h") => type(pointerType(type(short-int)))

     rule getFormatType'("%d", "") => type(int)
     rule getFormatType'("%i", "") => type(int)
     rule getFormatType'("%o", "") => type(unsigned-int)
     rule getFormatType'("%u", "") => type(unsigned-int)
     rule getFormatType'("%x", "") => type(unsigned-int)
     rule getFormatType'("%X", "") => type(unsigned-int)
     rule getFormatType'("%n", "") => type(pointerType(type(int)))

     rule getFormatType'("%a", "l") => type(double)
     rule getFormatType'("%A", "l") => type(double)
     rule getFormatType'("%e", "l") => type(double)
     rule getFormatType'("%E", "l") => type(double)
     rule getFormatType'("%f", "l") => type(double)
     rule getFormatType'("%F", "l") => type(double)
     rule getFormatType'("%g", "l") => type(double)
     rule getFormatType'("%G", "l") => type(double)
     rule getFormatType'("%d", "l") => type(long-int)
     rule getFormatType'("%i", "l") => type(long-int)
     rule getFormatType'("%o", "l") => type(unsigned-long-int)
     rule getFormatType'("%u", "l") => type(unsigned-long-int)
     rule getFormatType'("%x", "l") => type(unsigned-long-int)
     rule getFormatType'("%X", "l") => type(unsigned-long-int)
     rule getFormatType'("%n", "l") => type(pointerType(type(long-int)))

     rule getFormatType'("%d", "ll") => type(long-long-int)
     rule getFormatType'("%i", "ll") => type(long-long-int)
     rule getFormatType'("%o", "ll") => type(unsigned-long-long-int)
     rule getFormatType'("%u", "ll") => type(unsigned-long-long-int)
     rule getFormatType'("%x", "ll") => type(unsigned-long-long-int)
     rule getFormatType'("%X", "ll") => type(unsigned-long-long-int)
     rule getFormatType'("%n", "ll") => type(pointerType(type(long-long-int)))

     rule getFormatType'("%d", "z") => type(correspondingSignedType(utype(cfg:sizeut)))
     rule getFormatType'("%i", "z") => type(correspondingSignedType(utype(cfg:sizeut)))
     rule getFormatType'("%o", "z") => type(cfg:sizeut)
     rule getFormatType'("%u", "z") => type(cfg:sizeut)
     rule getFormatType'("%x", "z") => type(cfg:sizeut)
     rule getFormatType'("%X", "z") => type(cfg:sizeut)
     rule getFormatType'("%n", "z") => type(pointerType(type(correspondingSignedType(utype(cfg:sizeut)))))

     rule getFormatType'("%d", "t") => type(cfg:ptrdiffut)
     rule getFormatType'("%i", "t") => type(cfg:ptrdiffut)
     rule getFormatType'("%o", "t") => type(correspondingUnsignedType(utype(cfg:ptrdiffut)))
     rule getFormatType'("%u", "t") => type(correspondingUnsignedType(utype(cfg:ptrdiffut)))
     rule getFormatType'("%x", "t") => type(correspondingUnsignedType(utype(cfg:ptrdiffut)))
     rule getFormatType'("%X", "t") => type(correspondingUnsignedType(utype(cfg:ptrdiffut)))
     rule getFormatType'("%n", "t") => type(pointerType(type(cfg:sizeut)))

     rule getFormatType'(D::String, "") => type(pointerType(type(char)))
          requires substrString(D, 0, 2) ==String "%["
     rule getFormatType'(D::String, "l") => type(pointerType(type(cfg:wcharut)))
          requires substrString(D, 0, 2) ==String "%["

     rule getFormatType'(_, _) => type(no-type) [owise]

     syntax Bool ::= isPointerToCharType(UType) [function]
     rule isPointerToCharType(ut(_, pointerType(t(_, _, char)))) => true
     rule isPointerToCharType(ut(_, pointerType(t(_, _, unsigned-char)))) => true
     rule isPointerToCharType(ut(_, pointerType(t(_, _, signed-char)))) => true
     rule isPointerToCharType(_) => false [owise]

     syntax Bool ::= isReadWritable(String) [function]
     rule isReadWritable("r+") => true
     rule isReadWritable("w+") => true
     rule isReadWritable("w+x") => true
     rule isReadWritable("a+") => true
     rule isReadWritable("r+b") => true
     rule isReadWritable("rb+") => true
     rule isReadWritable("w+b") => true
     rule isReadWritable("wb+") => true
     rule isReadWritable("w+bx") => true
     rule isReadWritable("wb+x") => true
     rule isReadWritable("a+b") => true
     rule isReadWritable("ab+") => true
     rule isReadWritable(_) => false [owise]

     syntax Bool ::= isReadable(String) [function]
     rule isReadable("r") => true
     rule isReadable("rb") => true
     rule isReadable(M::String) => isReadWritable(M) [owise]

     syntax Bool ::= isWritable(String) [function]
     rule isWritable("w") => true
     rule isWritable("wx") => true
     rule isWritable("a") => true
     rule isWritable("wb") => true
     rule isWritable("wbx") => true
     rule isWritable("ab") => true
     rule isWritable(M::String) => isReadWritable(M) [owise]

endmodule

