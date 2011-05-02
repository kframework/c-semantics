mod CHAIN is including LOOP-MODE + META-LEVEL .
  op compile : -> System .
  op idle : -> State .
  var Q Q' : Qid . var QIL QIL' TERM : QidList . var FM : Module . var T : Term .
  eq compile = [nil, idle, 
 'Usage: 'rew 'in '<ModuleName> 'and-then '<ModuleName> ': '<Term> '. ] .

  op error : -> [Module] .
  var Str : String . var M FM' : Module . var OPDS : OpDeclSet .  

  op metaRewrite : Module Term ~> Term .
  eq metaRewrite(M, T) = getTerm(metaRewrite(M, T, unbounded)) .


  rl ['rew 'in Q 'and-then Q' ': TERM  'wer QIL, idle, QIL']
  => [QIL, idle, metaPrettyPrint(upModule(Q', false), (metaRewrite(upModule(Q', false), (metaRewrite(upModule(Q, false), getTerm(metaParse(upModule(Q, false), TERM, anyType)))))))] .
endm

