module C-RACES
     imports C-CONFIGURATION
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-ERROR-SYNTAX

     // TODO(chathhorn): Silly way to do things. Probably need to allow
     // multiple error cells at least. Also, add more details (loc?).
     // FIXME possible to miss dataraces with bitfields
     rule [read-write-race]:
          <k> (.K => UNDEF("CEER4", "Have a read-write datarace.")) ~>
               read(Loc:SymLoc, T:Type)
          ...</k>
          <k> (.K => UNDEF("CEER4", "Have a read-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]

      rule [write-write-race]:
          <k> (.K => UNDEF("CEER5", "Have a write-write datarace.")) ~>
               write(Loc:SymLoc, _, T:Type)
          ...</k>
          <k> (.K => UNDEF("CEER5", "Have a write-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]
endmodule
