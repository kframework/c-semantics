module LIBC-LOCALE
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-IO-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX
     imports DELETE-OBJECT-SYNTAX

     rule (.K => newFixedObject(nativeCall("setlocale", ListItem(Cat) ListItem(Locale), .List)))
          ~> builtin("setlocale", Cat::RValue, Locale::RValue)
          [structural]
     rule <k> Ptr:RValue ~> builtin("setlocale", _, _)
               => deleteObject(base(Loc)) ~> Ptr
          ...</k>
          <setlocale> tv(Loc:SymLoc, _) #as OldPtr::RValue => Ptr </setlocale>
          requires notBool isNull(OldPtr)
          [structural]
     rule <k> Ptr:RValue ~> builtin("setlocale", _, _)
               => Ptr
          ...</k>
          <setlocale> OldPtr:RValue => Ptr </setlocale>
          requires isNull(OldPtr)
          [structural]

     rule (.K => newFixedObject(nativeCall("localeconv", .List, .List)))
          ~> builtin("localeconv")
          [structural]
     rule <k> Ptr:RValue ~> builtin("localeconv")
               => deleteObject(base(Loc)) ~> Ptr
          ...</k>
          <localeconv> tv(Loc:SymLoc, _) #as OldPtr::RValue => Ptr </localeconv>
          requires notBool isNull(OldPtr)
          [structural]
     rule <k> Ptr:RValue ~> builtin("localeconv")
               => Ptr
          ...</k>
          <localeconv> OldPtr:RValue => Ptr </localeconv>
          requires isNull(OldPtr)
          [structural]

endmodule
