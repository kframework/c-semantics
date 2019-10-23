module CPP-COMMON-ENV-SYNTAX
     imports COMPAT-SORTS

     syntax DefaultArguments ::= defArgs(vals: StrictList, types: StrictList, cats: StrictList) [strict(1)]

     syntax DefaultArguments ::= DefaultArgumentsResult

     syntax DefaultArgumentsResult ::= defArgs(vals: StrictListResult, types: StrictListResult, cats: StrictListResult)

     syntax KResult ::= DefaultArgumentsResult
endmodule
