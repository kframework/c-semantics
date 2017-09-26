module LIBC-LOCALE
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX

     rule (.K => newFixedObject(nativeCall("setlocale", ListItem(Cat) ListItem(Locale), .List)))
          ~> builtin("setlocale", Cat::RValue, Locale::RValue)
          [structural]
     rule <k> Ptr:RValue ~> builtin("setlocale", _, _)
               => Ptr
          ...</k>
          <setlocale> .K => Ptr </setlocale>
          [structural]
     rule <k> Ptr:RValue ~> builtin("setlocale", _, _)
               => deleteObject(base(Loc)) ~> Ptr
          ...</k>
          <setlocale> tv(Loc:SymLoc, _) => Ptr </setlocale>
          [structural]

     rule (.K => newFixedObject(nativeCall("localeconv", .List, .List)))
          ~> builtin("localeconv")
          [structural]
     rule <k> Ptr:RValue ~> builtin("localeconv")
               => Ptr
          ...</k>
          <localeconv> .K => Ptr </localeconv>
          [structural]
     rule <k> Ptr:RValue ~> builtin("localeconv")
               => deleteObject(base(Loc)) ~> Ptr
          ...</k>
          <localeconv> tv(Loc:SymLoc, _) => Ptr </localeconv>
          [structural]

endmodule
