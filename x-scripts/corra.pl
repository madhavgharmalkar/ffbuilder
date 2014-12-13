#

my $fh;

open($fh, "<", "/Work/vb2014/tables/lect2.txt") 
	or die "cannot open < input.txt: $!";

my $levels = {};

while(<$fh>)
{
	chomp($_);
	$line = $_;
	@parts = split /\t/, $line;

    if (scalar(@parts) == 2)
    {
		$levels->{$parts[0]} = $parts[1];
    }	
}

close($fh);

my $oh;

open($oh, ">", "/Work/vb2014/bookmarks2014b.txt")
    or die "error";
open($fh, "<", "/Work/vb2014/bookmarks2014.txt") 
	or die "cannot open < input.txt: $!";

while(<$fh>)
{
	chomp($_);
	$line = $_;
	@parts = split /\t/, $line;

    if (scalar(@parts) == 4)
    {
          if (exists $levels->{$parts[2]})
          {
              printf $oh ("%s\t%s\t%s\t%s\n", $parts[0], $parts[1], $parts[2], $levels->{$parts[2]});
              printf ("Old: %s\nNew: %s\n\n", $parts[3], $levels->{$parts[2]});
          }
          else
          {
              printf $oh ("%s\n", $line);
          }
    }
}

close($fh);

close($oh);
