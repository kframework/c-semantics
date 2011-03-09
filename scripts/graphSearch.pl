use strict;
use GraphViz;

my $g = GraphViz->new();

# echo 'digraph {
	# page="8.5,11";
	# margin="0.25";
	# orientation="landscape";
	# ratio="compress";
	# size="10,7.5";
# ';

my %states = ();
my %arcs = ();

# Literal braces, vertical bars and angle brackets must be escaped.

my $state = "start";
my $currentStateNumber;
my $currentStateDestination;
my $currentState = "";
my $currentRule = "";
my $currentRuleName;
my @currentArc;

while (my $line = <STDIN>) {
	chomp($line);
	
	# handle start state
	if ($state eq "start") {
		# keep reading (and throwing away) until we hit a state
		if ($line =~ m/^state (\d+)/) {
			$currentStateNumber = $1;
			$states{$currentStateNumber} = "";
			$state = "state";
		}
		next;
	}
	
	# handle state state
	if ($state eq "state") {
		# keep reading until we hit an arc
		if ($line =~ m/^arc (\d+) ===> state (\d+) \((c?rl) $/) {
			$state = "arc";
			# meant to continue to next case
		} elsif ($line =~ m/^state (\d+)/) {
			$currentStateNumber = $1;
			$states{$currentStateNumber} = "";
			$state = "state";
			next;
		} else {
			$currentState .= $line;
			if ($line =~ m/"stdout"\(\.List\{K\}\) \|-> String "(.*)"\(\.List\{K\}\)/) {
				my $currentOutput = $1;
				$states{$currentStateNumber} = $currentOutput;
			}
			if ($line =~ m/< output > String "(.*)"\(\.List\{K\}\) <\/ output > /) {
				my $currentOutput = $1;
				$states{$currentStateNumber} = $currentOutput;
			}			
			next;
		}
	}
	
	# handle arc state
	if ($state eq "arc") {
		# keep reading until we hit a state or arc
		if ($line =~ m/^state (\d+)/) {
			$currentStateNumber = $1;
			$states{$currentStateNumber} = "";
			$state = "state";
		} elsif ($line =~ m/^arc (\d+) ===> state (\d+) \((c?rl) $/) {
			my $arcNumber = $1;
			$currentStateDestination = $2;
			$currentRule = $3;
			#$g->add_edge($currentStateNumber => $stateDestination);
			#@currentArc = ($currentStateNumber, $stateDestination);
			$arcs{$currentStateNumber}{$currentStateDestination} = "";
			$state = "arc";
			$currentRuleName = "";
		} else {
			$currentRule .= $line;
			if ($line =~ m/label ([\w-]+).*\] \.\)$/) {
				$currentRuleName = $1;
				$arcs{$currentStateNumber}{$currentStateDestination} = $currentRuleName;
			}
		}
		next;
	}
}

for my $node (keys %states) {
	$g->add_node($node, label => $states{$node});
}

for my $from (keys %arcs) {
	for my $to (keys %{$arcs{$from}}) {
		#print "$from, $to\n";
		#push(@{$HoA{$key}}, $value);
		$g->add_edge($from => $to, label => $arcs{$from}{$to});
	}
}

print $g->as_text;



	# $state = substr($line, 0, strpos($line, ","));
	# echo "\"$state\" [label=\"";
	# preg_match("/state ([0-9]+)$/", $state, $matches);
	# $next_state = $matches[1] + 1;
	# $line = substr(strstr($line, ":"),2);
	# while (true) {
		# if ($line === "Bye.\n") break;
		# if (FALSE === $line) break;
		# if (preg_match('/arc 0 ===> state [0-9]+ \(/',$line)) break;
		# if (preg_match("/state $next_state, /", $line)) break; 
		# # $line = preg_replace('/KName\((.+?)\)/', '$1', $line, -1, $count);
		# # $line = preg_replace('/KInt\((.+?)\)/', '$1', $line, -1, $count);
		# # $line = preg_replace('/KBool\((.+?)\)/', '$1', $line, -1, $count);
		# # $line = preg_replace('/truev\((.+?)\)/', '$1', $line, -1, $count);
		# # $line = preg_replace('/pr~~/', 'pr', $line, -1, $count);
		# # $line = preg_replace('/freshName\(1\)/', 'a', $line, -1, $count);
		# # $line = preg_replace('/freshName\(2\)/', 'b', $line, -1, $count);
		# # $line = preg_replace('/pr\(1,b\)/', 'mkget(b)', $line, -1, $count);
		# # $line = preg_replace('/pr\(2,3\)/', 'mkset(3)', $line, -1, $count);
		# # $line = preg_replace('/pr\(2,4\)/', 'mkset(4)', $line, -1, $count);

		
		# # $line = preg_replace('/\\\\ b \. \\\\ c \. \\\\ m \. if~~~\(apply~~\(\\\\ x \. eq~~\(first~\(x\),1\),m\),seqList~\(~ \(become~\(apply~~\(b,c\)\),send~~\(apply~~\(\\\\ x \. second~\(x\),m\),c\)\)\),if~~~\(apply~~\(\\\\ x \. eq~~\(first~\(x\),2\),m\),become~\(apply~~\(b,apply~~\(\\\\ x \. second~\(x\),m\)\)\),become~\(apply~~\(b,c\)\)\)\)/', 'cellbody', $line, -1, $count);
		
		# # $line = preg_replace('/apply~~\(\\\\ x \. apply~~\(cellbody,\\\\ y \. apply~~\(apply~~\(x,x\),y\)\),\\\\ x \. apply~~\(cellbody,\\\\ y \. apply~~\(apply~~\(x,x\),y\)\)\)/', 'rec(cellbody)', $line, -1, $count);
		
		# # $line = preg_replace('/apply~~\(\\\\ x \. eq~~\(first~\(x\),2\),m\)/', 'set?(m)', $line, -1, $count);
		# # $line = preg_replace('/apply~~\(\\\\ x \. eq~~\(first~\(x\),1\),m\)/', 'get?(m)', $line, -1, $count);
		
		# # $line = preg_replace('/\\\\ m \. if~~~\(get\?\(m\),seqList~\(~ \(become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),0\)\),send~~\(apply~~\(\\\\ x \. second~\(x\),m\),0\)\)\),if~~~\(set\?\(m\),become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),apply~~\(\\\\ x \. second~\(x\),m\)\)\),become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),0\)\)\)\)/', 'cell(0)', $line, -1, $count);
		# # $line = preg_replace('/\\\\ m \. if~~~\(get\?\(m\),seqList~\(~ \(become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),3\)\),send~~\(apply~~\(\\\\ x \. second~\(x\),m\),3\)\)\),if~~~\(set\?\(m\),become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),apply~~\(\\\\ x \. second~\(x\),m\)\)\),become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),3\)\)\)\)/', 'cell(3)', $line, -1, $count);
		# # $line = preg_replace('/\\\\ m \. if~~~\(get\?\(m\),seqList~\(~ \(become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),4\)\),send~~\(apply~~\(\\\\ x \. second~\(x\),m\),4\)\)\),if~~~\(set\?\(m\),become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),apply~~\(\\\\ x \. second~\(x\),m\)\)\),become~\(apply~~\(\\\\ y \. apply~~\(rec\(cellbody\),y\),4\)\)\)\)/', 'cell(4)', $line, -1, $count);	
		
		# # echo strtr($line,array(
		# # "\n" => '\\l'
		# # , '\\' => '\\\\'
		# # # , '<' => '\<'
		# # # , '>' => '\>'
		# # ));
		# continue;
	# }
	# echo "\"] ;\n";
	# if (strpos($line, "arc ") !== 0) continue;
	# $arcs = 0;
	# while (true) {
		# if (FALSE === $line) break;
		# if (preg_match("/state $next_state, /", $line)) break; 
		# if (strpos($line, "arc ") === 0) {
			# $arcs++;
			# $state2 = strchr($line, "state ");
			# $state2 = substr($state2, 0, strpos($state2, " ", strpos($state2, " ") + 1));
			# if ($arcs > 1) echo ";\n";
			# echo "\"$state\" -> \"$state2\"";
		# }
		# if (preg_match('/\[label (.+)] .\)$/', $line, $matches)) {
			# echo '[label="'.$matches[1].'"]';
		# }
	# }
	# if ($arcs > 0) echo ";\n";
# } 
# echo "}\n";
