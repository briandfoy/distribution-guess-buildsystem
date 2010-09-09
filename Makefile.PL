# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'Distribution::Guess::BuildSystem',
	'ABSTRACT'     => 'This is what the module does',
	'VERSION_FROM' => 'lib/BuildSystem.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'               => '0',
		'Module::Extract::Use'     => "0",
		'Module::Extract::VERSION' => "0",
		},

	'PM'           => {
		'lib/BuildSystem.pm'         => '$(INST_LIBDIR)/BuildSystem.pm',
		},

	'MAN3PODS'     => {
		'lib/BuildSystem.pm' => '$(INST_MAN3DIR)/Distribution::Guess::BuildSystem.3',
		},

	clean  => { FILES    => q|Distribution-Guess-BuildSystem-*| },

	);
