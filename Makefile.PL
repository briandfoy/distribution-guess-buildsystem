use ExtUtils::MakeMaker 6.64;

require 5.010;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Distribution::Guess::BuildSystem',
	'ABSTRACT'     => 'This is what the module does',
	'VERSION_FROM' => 'lib/BuildSystem.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '6.64',
		},
		
	'TEST_REQUIRES' => {
		'Test::More'               => '0',
		'Test::Output'             => '0',
		},
		
	'PREREQ_PM'    => { 
		'Test::More'               => '0',
		'Module::Extract::Use'     => "0",
		'Module::Extract::VERSION' => "0",
		},

	'PM'           => {
		'lib/BuildSystem.pm'         => '$(INST_LIBDIR)/BuildSystem.pm',
		},

	'MAN3PODS'     => {
		'lib/BuildSystem.pm' => '$(INST_MAN3DIR)/Distribution::Guess::BuildSystem.$(MAN3EXT)',
		},

	clean  => { FILES    => q|Distribution-Guess-BuildSystem-*| },

	);
