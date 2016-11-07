module CITATIONS-SYNTAX
  imports STRING
  imports LIST
  syntax List ::= sourceReferences(String, String)   [function] // sourceReferences(ErrCode, Source) -> List{Reference}
  syntax KItem ::= reference(String, String)                    // reference(Section, Details)
endmodule

module CITATIONS
  imports CITATIONS-SYNTAX
  syntax List ::= "citationSources"                 [function]  // -> List{Source}
  rule citationSources => ListItem("C11") ListItem("CERT-C") ListItem("POSIX 2008") ListItem("C++14") ListItem("C++ Defect Reports")

  syntax List ::= citations(String)                 [function]  // citations(ErrCode) -> List{FlatCitation}
  syntax KItem ::= citation(String, String, String)             // citation(Source, Section, Details)

  rule citations(ErrCode:String) => sourcesReferences(ErrCode, citationSources)

  syntax List ::= sourcesReferences(String, List)    [function] // sourcesReferences(ErrCode, List{Source}) -> List{Citation}
  rule sourcesReferences(ErrCode:String, .List) => .List
  rule sourcesReferences(ErrCode:String, ListItem(Source:String) Sources:List)
       => cite(Source, sourceReferences(ErrCode, Source)) sourcesReferences(ErrCode:String, Sources:List)
  syntax List ::= cite(String, List)                 [function] // cite(Source, List{Reference}) -> List{Citation}
  rule cite(_, .List) => .List
  rule cite(Source:String, ListItem(reference(Section:String, Details:String)) References:List)
       => ListItem(citation(Source, Section, Details)) cite(Source:String, References:List)

  rule sourceReferences(_, _) => .List [owise]
endmodule
