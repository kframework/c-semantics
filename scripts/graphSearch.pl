use strict;

my %states = (); # stateId => stateLabel
my %arcs = (); # startArcId => endArcId => arcLabel
my %errorStates = (); # stateId => errorKind
my %goodFinal = (); # stateId => ""


sub graphSearch {
	require GraphViz;
	my ($outFilename, @input) = (@_);
	my $retval = "";
	# my $numArgs = $#ARGV + 1;
	# if ($numArgs != 1) {
		# die "You need to supply an argument that is the output filename for the dot code\n";
	# }
	# my $outFilename = $ARGV[0];

	my $g = GraphViz->new();

	# echo 'digraph {
		# page="8.5,11";
		# margin="0.25";
		# orientation="landscape";
		# ratio="compress";
		# size="10,7.5";
	# ';


	# Literal braces, vertical bars and angle brackets must be escaped.

	my $state = "start";
	my $currentStateNumber;
	my $currentStateDestination;
	my $currentState = "";
	my $currentRule = "";
	my $currentRuleName;
	my @currentArc;
	
	my $seenMain = 0;

	my @solutions;

	for my $line (@input) {
	#while (my $line = <STDIN>) {
		chomp($line);
			
		# handle start state
		if ($state eq "start") {
			if ($line =~ m/^Solution (\d+) /) {
				$state = "solution";
			} elsif ($line =~ m/^No solution./) {
				$state = "state";
			}
		}		
		
		if ($state eq "solution") {
			if ($line =~ m/^Solution (\d+) /) {
				my $numSolutions = $1;
				push(@solutions, {});
				$solutions[-1]->{'num'} = $numSolutions;
			}
			if ($line =~ m/< errorCell > # "(.*)"\(\.List\{K\}\) <\/ errorCell >/) {
				$solutions[-1]->{'error'} = $1;
			}
			if ($line =~ m/< output > # "(.*)"\(\.List\{K\}\) <\/ output >/) {
				$solutions[-1]->{'output'} = $1;
			}
			if ($line =~ m/< resultValue > \('tv\)\.KLabel\(kList\("List`{K`}2K_"\)\(# (-?\d+)\(\.List\{K\}\)\),,\('t\)\.KLabel\(Set2KLabel \.\(\.List\{K\}\),,\('int\)\.KLabel\(\.List\{K\}\)\)\) <\/ resultValue >/) {
				$solutions[-1]->{'retval'} = $1;
			}
			if ($line =~ m/"stdout"\(\.List\{K\}\) \|-> # "(.*)"\(\.List\{K\}\)/) {
				$solutions[-1]->{'output'} = $1;
			}
			if ($line =~ m/< currentProgramLoc > \('CabsLoc\)\.KLabel\(# "(.*)"\(\.List\{K\}\),,# (\d+)\(\.List\{K\}\),,# (\d+)\(\.List\{K\}\),,# (\d+)\(\.List\{K\}\)\) <\/ currentProgramLoc >/) {
				$solutions[-1]->{'file'} = $1;
				$solutions[-1]->{'line'} = $2;
				# $myOffsetStart = $3;
				# $myOffsetEnd = $4;
			}
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
			if ($line =~ m/^arc (\d+) ===> state (\d+) \((c?rl) /) {
				$state = "arc";
				# meant to continue to next case
			} elsif ($line =~ m/^state (\d+)/) {
				$currentStateNumber = $1;
				$states{$currentStateNumber} = "";
				$state = "state";
				next;
			} else {
				$currentState .= $line;
				if ($line =~ m/"stdout"\(\.List\{K\}\) \|-> # "(.*)"\(\.List\{K\}\)/) {
					my $currentOutput = $1;
					$states{$currentStateNumber} = $currentOutput;
				}
				if ($line =~ m/< output > # "(.*)"\(\.List\{K\}\) <\/ output >/) {
					my $currentOutput = $1;
					$goodFinal{$currentStateNumber} = "";
					$states{$currentStateNumber} = $currentOutput;
				}
				if ($line =~ m/< errorCell > (.*) <\/ errorCell >/) {
					my $currentOutput = $1;
					#print STDERR "setting bad state\n";
					$errorStates{$currentStateNumber} = "";
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
			} elsif ($line =~ m/^arc (\d+) ===> state (\d+) \((c?rl) /) {
				my $arcNumber = $1;
				$currentStateDestination = $2;
				$currentRule = $3;
				if ($seenMain) {
					$arcs{$currentStateNumber}{$currentStateDestination} = "";
				}
				$state = "arc";
				$currentRuleName = "";
			} else {
				$currentRule .= $line;
				if ($line =~ m/label ([\w-]+).*\] \.\)$/) {
					$currentRuleName = $1;
					if ($currentRuleName eq "call-main") {
						%states = ();
						$seenMain = 1; 
					}
					if ($seenMain) {
						$arcs{$currentStateNumber}{$currentStateDestination} = $currentRuleName;
					}
				}
				if ($line =~ m/metadata .*heating/) {
					if ($line =~ m/freezer\("\(([^\)]+)\)\./) {
						$currentRuleName = $1;
					}
					$currentRuleName .= ' heat';
					if ($seenMain) {
						$arcs{$currentStateNumber}{$currentStateDestination} = $currentRuleName;
					}
				}
			}
			next;
		}
	}

	for my $node (keys %states) {
		my $attribs = getAttribs($node);
		$attribs->{'label'} = "$node\n${states{$node}}";
		$g->add_node($node, %$attribs);
	}

	for my $from (keys %arcs) {
		for my $to (keys %{$arcs{$from}}) {
			# print "$from, $to\n";
			$g->add_edge($from => $to, label => $arcs{$from}{$to});
		}
	}

	open(DOTOUTPUT, ">$outFilename");
	print DOTOUTPUT $g->as_text;
	close(DOTOUTPUT);
	#@solutions = reverse(@solutions);
	$retval .= "========================================================================\n";
	$retval .= scalar(@solutions) . " solutions found\n"; 
	for my $solution (@solutions) {

		$retval .= "------------------------------------------------------------------------\n";
		$retval .= "Solution $solution->{'num'}\n";
		if (defined($solution->{'retval'})) {
			$retval .= "Program completed successfully\n"; 
			$retval .= "Return value: " . getString($solution->{'retval'}) . "\n";
		} else {
			$retval .= "Program got stuck\n";
			$retval .= "File: " . getString($solution->{'file'}) . "\n";
			$retval .= "Line: " . getString($solution->{'line'}) . "\n";
		}
		if (defined ($solution->{'error'})) {
			$retval .= getString($solution->{'error'}) . "\n";
		}
		$retval .= "Output:\n" . getString($solution->{'output'}) . "\n";
		
	}
	$retval .= "========================================================================\n";
	$retval .= scalar(@solutions) . " solutions found\n"; 
	
	return $retval;
}

sub getAttribs {
	my ($nodeId) = (@_);
	my $attribs = {};
	if (exists($errorStates{$nodeId})) {
		$attribs->{"fillcolor"} = "red";
		$attribs->{"style"} = "filled";
	}
	if (exists($goodFinal{$nodeId})) {
		$attribs->{"fillcolor"} = "green";
		$attribs->{"style"} = "filled";
	}
	return $attribs;
}

sub getString {
	my ($s) = (@_);
	
	$s =~ s/\%/\%\%/g;
	$s =~ s/\\\\/\\\\\\\\/g;
	return substr(`printf "x$s"`, 1);
}
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
1;
