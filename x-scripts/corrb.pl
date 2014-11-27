#

my $fh;
my $oh;

open($oh, ">", "/Work/keywords3.txt")
    or die "error";
open($fh, "<", "/Work/keywords2.txt") 
	or die "cannot open < input.txt: $!";

while(<$fh>)
{
	chomp($_);
	$line = $_;

     if ($line =~ m/(\d+)\tBG \d+\.\d+$/)
     {
     	printf $oh ("%s\n", $line);
     }
     elsif ($line =~ m/(\d+)\tBG (\d+)\.(\d+)\-(\d+)$/)
     {
         for ($i = $3; $i <= $4; $i++)
         {
              printf $oh ("%s\tBG %s.%s\n", $1, $2, $i);
         }
     }
     elsif ($line =~ m/\d+\tSB \d+\.\d+\.\d+$/)
     {
     	printf $oh ("%s\n", $line);
     }
     elsif ($line =~ m/(\d+\tSB \d+\.\d+)\.(\d+)\-(\d+)$/)
     {
         for ($i = $2; $i <= $3; $i++)
         {
             printf $oh ("%s.%s\n", $1, $i);
         }
     }
     elsif ($line =~ m/\d+\tCC \w+ \d+\.\d+$/)
     {
     	printf $oh ("%s\n", $line);
     }
     elsif ($line =~ m/(\d+\tCC \w+ \d+)\.(\d+)\-(\d+)$/)
     {
         for ($i = $2; $i <= $3; $i++)
         {
             printf $oh ("%s.%s\n", $1, $i);
         }
     }
     else
     {
     }
}

close($fh);

close($oh);
