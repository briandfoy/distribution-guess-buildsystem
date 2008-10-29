# $Id$
package Distribution::Guess::BuildSystem;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

use Carp qw(carp);
use Config qw(%Config);
use Cwd;
use File::Spec::Functions qw(catfile);

use Module::Extract::VERSION;

$VERSION = '0.11';

=head1 NAME

Distribution::Guess::BuildSystem - This is the description

=head1 SYNOPSIS

	use Distribution::Guess::BuildSystem;

	chdir $dist_dir;
	
	my $guesser = Distribution::Guess::BuildSystem->new(
		dist_dir => $dir
		);
	
	my $build_files   = $guesser->build_files; # Hash ref
	
	my $build_pl      = $guesser->has_build_pl;
	my $makefile_pl   = $guesser->has_makefile_pl;
	
	my $both          = $guesser->has_build_and_makefile;
	
	my $build_command = $guesser->build_commands; # Hash ref
	
	if( $guesser->uses_module_install ) 
		{
		my $version = $guesser->module_install_version;
		my $pita    = $guesser->uses_auto_install;
		}
		
	if( $guesser->uses_makemaker )   
		{
		my $version = $guesser->makemaker_version;
		my $make    = $guesser->make_command;
		}

=head1 DESCRIPTION

There are three major build system for Perl distributions:

=over 4

=item * ExtUtils::MakeMaker

Uses F<Makefile.PL> and C<make>.

=item * Module::Build

Uses F<Build.PL> and C<perl>, although it might have a F<Makefile.PL> that is
a wrapper.

=item * Module::Install

Uses F<Makefile.PL> and calls to an embedded C<Module::Install>. It might
use C<auto_install> to call C<CPAN.pm> at build time.

=back

The trick is to figure out which one you are supposed to use.

=head2 Methods

=over 4

=item new

	dist_dir
	
=cut

sub new
	{
	my %defaults = { dist_dir => cwd() };
	
	my( $class, %args ) = @_;
	
	@defaults{ keys %args } = values %args;
	
	bless { dist_dir => $args{dist_dir} }, $_[0];
	}

=item dist_dir

=cut

sub dist_dir
	{
	$_[0]->{dist_dir}
	}

=back

=head2 Questions about the distribution

=over 4

=item build_files

Returns an hash reference of build files found in the distribution. The
keys are the filenames of the build files. The values 

=cut

{
my @files = (
	[ qw( has_makefile_pl makefile_pl ) ],
	[ qw( has_build_pl build_pl ) ],

	);
	
sub build_files
	{
	my %found;
	
	foreach my $pairs ( @files )
		{
		my( $check, $file ) = @$pairs;
		$found{ $_[0]->$file() } = $_[0]->$file() if $_[0]->$check()
		}
		
	return \%found;
	}

}

=item preferred_build_file

Returns the build file that you should use, even if there is more than
one. Right now this is simple. If C<Build.PL> is there, use it before
C<Makefile.PL>.

=cut

sub preferred_build_file
	{
	return $_[0]->build_pl    if $_[0]->has_build_pl;
	return $_[0]->makefile_pl if $_[0]->has_makefile_pl;
	}

=item preferred_build_command

Returns the build command that you should use, even if there is more than
one. Right now this is simple. If C<Build.PL> is there, return C<perl>.
If not and C<Makefile.PL> is there, return C<make>.

=cut

sub preferred_build_command
	{
	return $_[0]->perl_command if $_[0]->has_build_pl;
	return $_[0]->make_command if $_[0]->has_makefile_pl;
	}
	
=item build_file_paths

Returns an anonymous hash to the paths to the build files, based on
the dist_dir argument to C<new> and the return value of
C<build_files>. The keys are the file names and the values are 
the paths.

=cut

sub build_file_paths
	{
	my %paths;
	
	foreach my $file ( keys %{ $_[0]->build_files } )
		{
		$paths{$file} = File::Spec->catfile( $_[0]->dist_dir, $file );	
		}
		
	return \%paths;
	}

=item makefile_pl_path

=cut

sub makefile_pl_path
	{
	return unless $_[0]->has_makefile_pl;
	
	File::Spec->catfile( $_[0]->dist_dir, $_[0]->makefile_pl );
	}

=item build_pl_path

=cut

sub build_pl_path
	{
	return unless $_[0]->has_build_pl;
	
	File::Spec->catfile( $_[0]->dist_dir, $_[0]->build_pl );
	}
	
=item has_build_pl

Has the file name returned by C<build_pl>.

=cut

sub _has_file
	{
	my( $self, $file ) = @_;
	
	my $path = File::Spec->catfile(
		$self->dist_dir, $file
		);
	
	$self->{has}{$file} = $path if -e $path;
	$self->{has}{$file};
	}

sub has_build_pl { $_[0]->_has_file( $_[0]->build_pl )  }

=item has_makefile_pl

Has the file name returned by C<makefile_pl>.

=cut

sub has_makefile_pl { $_[0]->_has_file( $_[0]->makefile_pl )  }

=item has_build_and_makefile

Has both the files returned by C<makefile_pl> and C<build_pl>.

=cut

sub has_build_and_makefile
	{
	$_[0]->has_build_pl 
		&& 
	$_[0]->has_makefile_pl
	}

=item make_command

Looks in %Config to see what perl discovered when someone built it if you
can use a C<make> variant to build the distribution.

=item perl_command

Returns the perl currently running if you can use perl to build the
distribution.

=item build_commands

Returns a hash reference of the commands you can use to build the
distribution. The keys are the commands, such as C<make> or C<perl Build.PL>.

=cut

sub make_command { $_[0]->has_makefile_pl ? $Config{make} : () }
sub perl_command { $_[0]->has_build_pl    ? $^X           : () }

sub build_commands
	{
	my %commands;
	
	$commands{ $_[0]->make_command } = 1 
		if $_[0]->has_makefile_pl;

	$commands{ $_[0]->perl_command . " " . $_[0]->build_pl    } = 1 
		if $_[0]->has_build_pl;

	return \%commands;
	}

=item uses_makemaker

The distro uses ExtUtils::Makemaker.

=cut

sub _get_modules
	{
	my( $self, $path ) = @_;
	my $extractor = $self->module_extractor_class->new;
	$extractor->get_modules( $path );	
	}
	
sub uses_makemaker
	{
	return unless $_[0]->has_makefile_pl;
	
	scalar grep { $_ eq $_[0]->makemaker_name } 
		$_[0]->_get_modules( $_[0]->makefile_pl_path )
	}

=item makemaker_version

Returns the version of Makemaker installed for the perl running this code.

=cut

sub makemaker_version
	{
	return unless $_[0]->uses_makemaker;
	
	my $version = $_[0]->_get_version( $_[0]->makemaker_name );
	}

sub _get_version
	{
	require Module::Extract::VERSION;
	
	my( $self, $module, @dirs ) = @_;
	
	@dirs = @INC unless @dirs;
	
	my $file = catfile( split /::/, $module ) . ".pm";
	
	foreach my $dir ( @dirs )
		{
		my $module = catfile( $dir, $file );
		next unless -e $module;
		
		return Module::Extract::VERSION->parse_version_safely( $module );
		}
		
	}
	
=item uses_module_build

Returns true if this distribution uses C<Module::Build>.

=cut

sub uses_module_build
	{
	return unless $_[0]->has_build_pl;

	scalar grep { $_ eq $_[0]->module_build_name } 
		$_[0]->_get_modules( $_[0]->build_pl_path )
	}

=item module_build_version

Returns the version of C<Module::Build> install for perl running this code.

=cut

sub module_build_version
	{
	return unless $_[0]->uses_module_build;

	my $version = $_[0]->_get_version( $_[0]->module_build_name );
	}

=item uses_module_install

Returns true if this distribution uses C<Module::Install>.

=cut

sub uses_module_install
	{		
	return unless $_[0]->has_makefile_pl;

	scalar grep { $_ eq $_[0]->module_install_name } 
		$_[0]->_get_modules( $_[0]->makefile_pl_path )
	}

=item uses_auto_install

Returns true if this distribution uses C<Module::Install> and will
use the auto_install feature.

This is a very simple test right now. If it finds the string
C<auto_install> in the build file, it returns true.

=cut

sub uses_auto_install
	{
	return unless $_[0]->has_makefile_pl && $_[0]->uses_module_install;
	
	$_[0]->_file_has_string( $_[0]->makefile_pl_path, 'auto_install' );
 	}

=item module_install_version

Returns the version of C<Module::Install>.

=cut

sub module_install_version
	{
	return unless $_[0]->uses_module_install;

	my $version = $_[0]->_get_version( 
		 $_[0]->module_install_name,  $_[0]->module_install_dir
		);
	}

=item uses_module_build_compat

Returns true if this distribution uses C<Module::Install::Compat> and will
use the C<create_makefile_pl> feature.

This is a very simple test right now. If it finds the string
C<create_makefile_pl> in the build file, it returns true.

=cut

sub uses_module_build_compat
	{
	return unless $_[0]->has_build_pl && $_[0]->uses_module_build;
	
	$_[0]->_file_has_string( $_[0]->build_pl_path, 'create_makefile_pl' );
	}

=item build_pl_wraps_makefile_pl

Returns true if C<Build.PL> is a wrapper around C<Makefile.PL>.

=cut

sub build_pl_wraps_makefile_pl
	{
	return unless $_[0]->has_build_pl && $_[0]->has_makefile_pl;
	
	$_[0]->_file_has_string( $_[0]->build_pl_path, 
		"Makefile.PL" );	
	}
	
sub _file_has_string
	{
	my $fh;
	unless( open $fh, "<", $_[1] )
		{
		carp "Could not open $_[1]: $!";
		return;
		}
		
	while( <$fh> ) { return 1 if /\Q$_[2]/ }
		
	return;
	}

=item just_give_me_a_hash

=cut

{
my @methods = qw(
	dist_dir
	build_files
	build_file_paths
	makefile_pl_path
	build_pl_path
	has_build_pl
	has_makefile_pl
	has_build_and_makefile
	make_command
	perl_command
	build_commands
	uses_makemaker
	makemaker_version
	uses_module_build
	module_build_version
	uses_module_install
	uses_auto_install
	module_install_version
	uses_module_build_compat
	build_pl_wraps_makefile_pl
	);

sub just_give_me_a_hash
	{
	my %hash = ();
		
	foreach my $method ( @methods )
		{
		$hash{ $method } = $_[0]->$method();
		}
	
	return \%hash;
	}
}

=back

=head2 Methods for strings

You may want to override or extend these, so they are methods.

=over 4

=item makefile_pl

Returns the string used for the Makefile.PL filename. Seems stupid 
until you want to change it in a subclass, which you can do now
that it's a method. :)

=cut

sub makefile_pl { 'Makefile.PL' }

=item build_pl

Returns the string used for the Build.PL filename. Seems stupid 
until you want to change it in a subclass, which you can do now
that it's a method. :)

=cut

sub build_pl  { 'Build.PL' }

=item makemaker_name

Returns the module name of Makemaker, which is C<ExtUtils::MakeMaker>.

=cut

sub makemaker_name { 'ExtUtils::MakeMaker' }

=item module_build_name

Return the string representing the name for Module::Build.

=cut

sub module_build_name { 'Module::Build' }

=item module_install_name

Return the string representing the name for Module::Install. By default
this is C<inc::Module::Install>.

=cut

sub module_install_name { 'inc::Module::Install' }

=item module_install_dir

Returns the directory that contains Module::Install. This is the distribution
directory because the module name is actually C<inc::Module::Install>.

=cut

sub module_install_dir  { $_[0]->dist_dir }

=item module_extractor_class

The name of the module that can get a list of used modules from a Perl file.
By default this is Module::Extract::Use.

=cut

sub module_extractor_class { 'Module::Extract::Use' }
BEGIN { require Module::Extract::Use }

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	git://github.com/briandfoy/distribution-guess-buildsystem.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
