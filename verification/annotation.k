require "domains.k"
require "../semantics/language/translation/translation.k"
require "../semantics/language/common/common.k"
require "../semantics/settings.k"
require "../semantics/extensions.k"
require "int_set.k"
require "tree_pattern.k"

module KORE-COMPAT
  imports BASIC-K
  syntax KBott ::= "(" K ")" [bracket]
endmodule

module ANNOTATION-SYNTAX
  imports REQUIRES-ENSURES
  imports RULE-CELLS
  imports K-SORT-LATTICE

  imports ID
  imports INT
  imports K-EQUAL

  imports C-SYNTAX
  imports C-SYMLOC-SYNTAX
  imports C-CONFIGURATION

  imports TREE-PATTERN-SYNTAX
  imports INT-SET-SYNTAX

  syntax KVariable ::= r"(\\$|!|\\?)?([A-Z][A-Za-z0-9']*|_)"   [token, autoReject, hook(org.kframework.kore.KVariable)]

  syntax KBott ::= KVariable ":" Sort [klabel(LogicalVariable), format(%s%s%s)]
  syntax Sort ::= r"[A-Z][A-Za-z0-9]*" [token]

  syntax RuleContent ::= K "returns" K [klabel(#ruleReturns)]
                       | K "returns" K "requires" K [klabel(#ruleReturnsRequires)]
                       | K "returns" K "ensures" K [klabel(#ruleReturnsEnsures)]
                       | K "returns" K "requires" K "ensures" K [klabel(#ruleReturnsRequiresEnsures)]

  syntax SymLoc ::= Id
  syntax Int ::= Id
endmodule

module ANNOTATION
  imports C-CONFIGURATION
endmodule
