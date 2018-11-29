#!/bin/bash

read -r -d '' reformat_prelude << 'EOF'
my $commentLine="(?:(?<=\n) *?\/\/.*?\n)";
my $startingLine="(?:(?<=\n) *(?:rule|syntax|context).*?\n)";
my $token="(?:rule|syntax|context|import|module|endmodule)";
my $continuingLine="(?:(?<=\n)(?!$commentLine) *(?!$token)[^ \n].*?\n)";
EOF
export reformat_prelude

function reformat_apply() {
  cmd="$1"
  shift
  perl -0777 -i -pe "$reformat_prelude;$cmd" "$@"
}

export -f reformat_apply

function reformat() {
  function apply() {
    reformat_apply "$@"
  }

  # Clear trailing space
  apply 's/ *\n/\n/igs' "$@"

  # Create bubbles
  apply 's/($commentLine*$startingLine$continuingLine*)/<BUBBLE>\1<\/BUBBLE>/gs' "$@"

  # Add empty line between bubbles
  apply 's/<\/BUBBLE><BUBBLE>/<\/BUBBLE>\n<BUBBLE>/gs' "$@"

  # Clear bubbles
  apply 's/<BUBBLE>(.*?)<\/BUBBLE>/\1/gs' "$@"
}

export -f reformat

if [[ "$1" == "" ]]; then
  echo "Reformating all"
  find ./semantics/cpp -name "*.k" -print0 | xargs -0 bash -c  'reformat "$@"'
else
  reformat "$@"
fi
