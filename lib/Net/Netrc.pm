package Net::Netrc;

use Carp;
use strict;

my %netrc = ();

sub _readrc {
 my $host = shift;
 my $file = (getpwuid($>))[7] . "/.netrc";
 my($login,$pass,$acct) = (undef,undef,undef);
 local *NETRC;
 local $_;

 $netrc{default} = undef;

 my @stat = stat($file);

 if(@stat)
  {
   if($stat[2] & 077)
    {
     carp "Bad permissions: $file";
     return ();
    }
   if($stat[4] != $<)
    {
     carp "Not owner: $file";
     return ();
    }
  }

 if(open(NETRC,$file))
  {
   my($mach,$macdef,$tok,@tok) = (0,0);

   while(<NETRC>) 
    {
     undef $macdef if /\A\n\Z/;

     if($macdef)
      {
       push(@$macdef,$_);
       next;
      }

     push(@tok, split(/[\s\n]+/, $_));

TOKEN:
     while(@tok)
      {
       if($tok[0] eq "default")
	{
	 shift(@tok);
         $mach = $netrc{default} = {};

	 next TOKEN;
	}

       last TOKEN unless @tok > 1;
       $tok = shift(@tok);

       if($tok eq "machine")
	{
         my $host = shift @tok;
         $mach = $netrc{$host} = {};
	}
       elsif($tok =~ /^(login|password|account)$/)
	{
         next TOKEN unless $mach;
         my $value = shift @tok;
         $mach->{$1} = $value;
	}
       elsif($tok eq "macdef")
	{
         next TOKEN unless $mach;
         my $value = shift @tok;
         $mach->{macdef} = {} unless exists $mach->{macdef};
         $macdef = $mach->{machdef}{$value} = [];
	}
      }
    }
   close(NETRC);
  }
}

sub lookup {
 my $pkg = shift;
 my $mach = shift;

 _readrc() unless exists $netrc{default};

 return bless \$mach if exists $netrc{$mach};

 return bless \("default") if defined $netrc{default};

 return undef;
}

sub login {
 my $me = shift;
 $me = $netrc{$$me};
 exists $me->{login} ? $me->{login} : undef;
}

sub account {
 my $me = shift;
 $me = $netrc{$$me};
 exists $me->{account} ? $me->{account} : undef;
}

sub password {
 my $me = shift;
 $me = $netrc{$$me};
 exists $me->{password} ? $me->{password} : undef;
}

sub lpa {
 my $me = shift;
 ($me->login, $me->password, $me->account);
}

1;
