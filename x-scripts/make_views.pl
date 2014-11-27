#!/usr/bin/perl

# this script will create views
# for vedabase 2013
# it is initial setting of views
# it reads record id (for display) which is identical to historical_record_id
# only in initial state
#
# therefore this script can be used only for first initialization
# of views in vedabase

open(my $foutput, ">", "./views.txt") or die "error 3";

open(my $fh, "<", "./complete2013/dump/levels.txt") 
	or die "cannot open < input.txt: $!";

my $levels = {};
my $levelsop = {};

# this is maximum level record
# for current scope of canPrint()
my $maxLevelIndex = 700;

# this is flag if also normal paragraphs should
# be printed out
my $gPrintStyles = 1;

while(<$fh>)
{
	chomp($_);
	$line = $_;
	@parts = split /\t/, $line;
	
	$levels->{$parts[2]} = $parts[0];
	$levelsop->{$parts[0]} = $parts[2];
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
$maxRec = 300;
$maxLevel = 300;
my $globLastLevel = 0;
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
			#print $line, "\n";
			@levelRecs[$level] = $parts[1];
			@levelRecIds[$level] = $gid;
			$gid++;
			$globLastLevel = printLevels();
			#print @levelRecs, "\n";
			#print "----\n";
		}
		else
		{
		    if (canPrint() && $gPrintStyles)
		    {
				for($j = 0; $j < $globLastLevel; $j++)
				{
					printf("    ");
				}
				printf("STYLE[%s]: %s\n", $parts[3], substr($parts[1], 0, 80));
				$c++;
			}
		}
        processRecord(@parts);
	}
    if ($maxRec > 0 && $c > $maxRec)
    {
    	last;
    }
}

close($fh);


sub getBookKey {

    if ($levelRecs[1] =~ /^ 01\. /)
    {
        return "IGNORE";
    }
 
    if ($levelRecs[1] =~ /^ Contents/)
    {
        return "IGNORE";
    }   
    if ($levelRecs[1] =~ /^\s02\. Bhag.*/)
    {
    	return "BG";
    }
    
    if ($levelRecs[1] =~ /^ 03\. /)
    {
        return "SB";
    }

    if ($levelRecs[1] =~ /^ 04\. /)
    {
        return "CC";
    }
    if ($levelRecs[1] =~ /^ 05\. /)
    {
        $key = "SPB";
        if ($levelRecs[3] =~ /The Nectar of Instruction/) { $key .= '.NOI'; }
        if ($levelRecs[3] =~ /r.*\s.*opani.*ad/) { $key .= '.ISO'; }
        if ($levelRecs[3] =~ /rada-bhakti-s/) { $key .= '.NBS'; }
        if ($levelRecs[3] =~ /Mukunda-.*-stotra/) { $key .= '.MMS'; }
        return $key;
    }
    if ($levelRecs[1] =~ /^ 16\. /)
    {
        $key = "WPA";
        if ($levelRecs[3] =~ /.*r.*Brahma-sa.*hit.*/) { $key .= '.SBS'; }        
        return $key;
    }
    
    return "OTHER";

}

#
# this function controls only printing
# it has no impact on creating views
#
# use this for investigation of processed file
#

sub canPrint {

    my $key = getBookKey();
    
    return 0 if ($key eq 'IGNORE');
    
    #return 1 if ($key =~ /SPB\.MMS/);
    #return 1 if ($key eq 'WPA.SBS');
    
    return 0;
}

sub processRecord {
    
    my $maxLevel = 10000;
    my @parts = @_;
    my $book = getBookKey();
    
    if ($book eq 'BG' || $book eq 'SB' || $book eq 'SPB.NOI' || $book eq 'SPB.ISO' || $book eq 'SPB.NBS' 
        || $book eq 'SPB.MMS' || $book eq 'WPA.SBS')
    {
        $maxLevel = 6;
		insertLevelToView($maxLevel, @parts);
        if ($parts[3] eq 'PA_Textnum')
        {
            insertRecord('Translations', $maxLevel, @parts);
            insertRecord('Sanskrit', $maxLevel, @parts);
            insertRecord('Sanskrit & Translations', $maxLevel, @parts);
        }
        if ($parts[3] eq 'PA_Translation')
        {
            insertRecord('Translations', $maxLevel, @parts);
            insertRecord('Sanskrit & Translations', $maxLevel, @parts);
        }
        if ($parts[2] eq 'LE_Verse_Text')
        {
            insertRecord('Sanskrit', $maxLevel, @parts);
            insertRecord('Sanskrit & Translations', $maxLevel, @parts);
        }
    }
    elsif ($book eq 'CC')
    {
        $maxLevel = 6;
		insertLevelToView($maxLevel, @parts);
        if ($parts[3] eq 'PA_Textnum')
        {
            insertRecord('Translations', $maxLevel, @parts);
            insertRecord('Bengali', $maxLevel, @parts);
            insertRecord('Bengali & Translations', $maxLevel, @parts);
        }
        if ($parts[3] eq 'PA_Translation')
        {
            insertRecord('Translations', $maxLevel, @parts);
            insertRecord('Bengali & Translations', $maxLevel, @parts);
        }
        if ($parts[2] eq 'LE_Verse_Text')
        {
            insertRecord('Bengali', $maxLevel, @parts);
            insertRecord('Bengali & Translations', $maxLevel, @parts);
        }
    }
    else
    {
        $maxLevel = 6;
		insertLevelToView($maxLevel, @parts);
    }
}

my %views;


sub insertLevelToView {
    my ($maxLevel, @parts) = @_;
    
	my $level = $levels->{$parts[2]};
	if (defined $level && $level <= $maxLevel)
	{
	    printf $foutput ("LEV\t%d\t%s\n", $level, $parts[1]);
	}
   
}

#  creates lines for inserting into tables VIEWS
#  DIR  <dirID> <parentID> <text>
#  REC  <dirID> <recordID>

sub insertRecord {
    my ($view, $maxLevel, @parts) = @_;
    my $data = {};
    my $printed = {};
    my $levelRecText = [];
    my $levelRecId = [];
    
    printf $foutput ("REC\t%s\t%d\t%s\n", $view, $parts[0], $parts[1]);
}

sub printLevels {

	my $lastId;
	my $lastLevel = 0;
	for($i = 0; (($i < scalar(@levelRecs)) && ($i <= $maxLevelIndex)); $i++)
	{
		if (exists $levelRecs[$i])
		{
		    $lastId = $levelRecIds[$i];
		    if (canPrint())
		    {
			    printf("    ");
			}
		    if (!$printedRecs{$lastId} && (canPrint() || $i <= 1))
		    {
				printf("LEVEL[%d]: %s (%s)\n", $i, $levelRecs[$i], $levelsop->{$i});
				$printedRecs{$lastId} = 1;
			}
			$lastLevel = $i;
		}
	}
	
	return $lastLevel;
}


close($foutput);