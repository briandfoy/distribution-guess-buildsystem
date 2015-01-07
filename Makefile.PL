require 5.010;
use strict;
use warnings;

my $github    = 'https://github.com/briandfoy/';
my $main_file = 'lib/Distribution/Guess/BuildSystem';

my %WriteMakefile = (
	'NAME'	        => 'Distribution::Guess::BuildSystem',
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '6.64',
		},
		
	'TEST_REQUIRES' => {
		'Test::More'               => '0',
		'Test::Output'             => '0',
		},
		
	'PREREQ_PM'    => { 
		'Module::Extract::Use'     => "0",
		'Module::Extract::VERSION' => "0",
		},

	clean  => { FILES    => q|Distribution-Guess-BuildSystem-*| },
	);

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			//
		"$MM 6.64";
	eval "use $MM_version";
	eval "use Test::Manifest 1.21" 
		if -e File::Spec->catfile( qw(t test_manifest) );
	WriteMakefile( %WriteMakefile );
	}


no warnings;
__PACKAGE__;
