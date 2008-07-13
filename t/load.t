# $Id: load.t,v 1.2 2004/09/08 00:25:42 comdog Exp $
BEGIN {
	@classes = qw(Distribution::Guess::BuildSystem);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	$result = use_ok( $class );
	print "Bail out! $class did not compile [$@]\n" unless $result;
	}