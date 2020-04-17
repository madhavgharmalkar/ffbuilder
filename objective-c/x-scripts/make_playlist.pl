#!/usr/bin/perl

# this script will create playlists with audio
# for vedabase
#
# input files:
#      - levels.txt
#      - texts.txt


open(my $fh, "<", "./complete2013/dump/levels.txt") 
	or die "cannot open < input.txt: $!";

my $levels = {};

while(<$fh>)
{
	chomp($_);
	$line = $_;
	@parts = split /\t/, $line;
	
	$levels->{$parts[2]} = $parts[0];
	#printf("LEVEL %s => %d\n", $parts[2], $parts[0]);	
}

close($fh);


#
# tree structure
# it is array of hash values
# for each hash there are keys:
#     name      : this is name of node
#     subnodes  : this is reference to array of children nodes
#     objects   : this is reference to array of objects

my $rootObjs = [];
my $rootNodes = [];
my $root = {
  name => 'root',
  objects => $rootObjs,
  subnodes => $rootNodes,
  };

#
#reading texts file
#

open($fh, "<", "./complete2013/dump/texts.txt") or die "cannot open texts.txt : $!";

my $gid = 1;
my @levelRecIds = ();
my @levelRecs = ();
my %printedRecs;
$c = 0;
$maxLevel = 7;
while(<$fh>)
{
     $line = $_;
     $line =~ s/^\s+|\s+$//g;
     @parts = split /\t/, $line;
     if (scalar(@parts) >= 4)
     {
		$level = $levels->{$parts[2]};
		if (defined $level && $level <= $maxLevel)
		{
			splice (@levelRecs, $level, (scalar(@levelRecs) - $level));
			splice (@levelRecIds, $level, (scalar(@levelRecIds) - $level));
		}

        if ($parts[3] eq 'PA_Audio_Bg')
        {
            $object = undef;
            if ($parts[1] =~ /\<AUDIO:\"([\w\d\-\s]*)\"/)
            {
            	$object = $1;
            }
            else
            {
            	if ($parts[1] =~ /\<DL\:Data,\"([\w\s\d\-]*)\"/)
            	{
            		$object = $1;
            	}
            }
            
            if (defined $object)
            {
                my @locIds;
                my @locLevs;
                my $lastId;
				for($i = 0; $i < scalar(@levelRecs); $i++)
				{
					if (exists $levelRecs[$i])
					{
					    push @locIds, $levelRecIds[$i];
					    push @locLevs, $levelRecs[$i];
					    $lastId = $levelRecIds[$i];
						#printf("LEVEL[%d]: %s (%d)\n", $i, $levelRecs[$i], $levelRecIds[$i]);
					}
				}
				
				for($i = 0; $i < scalar(@locIds); $i++)
				{
				    if (!$printedRecs{$locIds[$i]})
				    {
				        $title = $locLevs[$i];
				        $title =~ s/\<[^\>\<]*\>//g;
				        printf("PLAYLT\t%d\t%d\t%s\n", $locIds[$i], (($i == 0) ? -1 : $locIds[$i-1]), $title);
				        $printedRecs{$locIds[$i]} = 1;
				    }
				}
				#$node = getNode($root);
				printf ("OBJECT\t%d\t%d\t%s\n", $gid, $lastId, $object);
				$gid++;
				#push (@{$node->{objects}}, $object);
				$object = undef;
            }
     	}
        else
     	{
			if (defined $level && $level <= $maxLevel)
			{
			    #print @levelRecs, "\n";
				@levelRecs[$level] = $parts[1];
				@levelRecIds[$level] = $gid;
				$gid++;
				#print @levelRecs, "\n";
				#print "----\n";
			}
		}
     }
     $c++;
}

close($fh);



sub getNode {
  my ($root) = @_;
  my $tmp = $root;
  my $tmp2;
  my $i = 0;
  for($i = 0; $i < scalar(@levelRecs); $i++)
  {
    my $entry = $levelRecs[$i];
    if (exists $levelRecs[$i])
    {
        printf ("     - testing %s\n", $entry);
		$tmp = findNode($tmp, $entry);
#		if (!defined $tmp2) {
#		  printf("    we must create %s\n", $entry);
#		  $tmp2 = createNode($tmp, $entry);
		  printNode($tmp, " in getNode");
		  printNode($root, " in getNode root");
#		}
#		$tmp = $tmp2;
	}
	printf("    ----- %d\n", $i);
  }
  
  return $tmp;
}

sub findNode {
  my ($dict, $entry) = @_;
  
  my $arr1 = $dict->{subnodes};
  my @arr = @{$arr1};
  printf(" * in find %s\n", $entry);
  for($i = 0; $i < scalar(@{arr1}); $i++)
  {
    if (!defined $arr[$i]) {
  printf(" * in find - next\n");
      next;
    }
    printf(" * in find - entry is %s\n", $arr[$i]);
    if (defined $arr[$i] && (exists $arr[$i]->{name}) && ($arr[$i]->{name} eq $entry))
    {
  printf(" * in find - returned\n");
      return $arr[$i];
    }
  }

  my $subnodes = [];
  my $object= [];
  printf(" * find: in createNode name is entry: %s\n", $entry);
  my $item = {
    name     => $entry,
    subnodes => $subnodes,
    objects  => $objects,
  };
  push @{$dict->{subnodes}}, $item;

  return $item;
}

sub createNode {
  my ($dict, $entry) = @_;

  my $arr1 = $dict->{subnodes};
  my @arr = @{$arr1};
  my $subnodes = [];
  my $object= [];
  printf("in createNode name is entry: %s\n", $entry);
  my $item = {
    name     => $entry,
    subnodes => $subnodes,
    objects  => $objects,
  };
  push @{$dict->{subnodes}}, $item;

  printNode($dict, "in createNode");  
  
  return $item;
}

sub printNode {
  my ($dict,$name) = @_;

  printf(" === object %s ===\n", $name);
  printf ("    = dict name    %s\n", $dict->{name});
  printf ("    = dict objects %d\n", scalar(@{$dict->{objects}}));
  printf ("    = dict nodes   %d\n", scalar(@{$dict->{subnodes}}));

}