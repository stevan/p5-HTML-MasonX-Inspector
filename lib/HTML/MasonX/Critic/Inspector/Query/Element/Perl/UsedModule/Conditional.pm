package HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule::Conditional;
# ABSTRACT: Query result objects representing conditionally used Perl modules

use strict;
use warnings;

use Carp            ();
use List::Util      ();
use Module::Runtime ();

our $VERSION = '0.01';

use parent 'HTML::MasonX::Critic::Inspector::Query::Element::Perl::UsedModule';
use slots (
    # ... cache some data ...
    _module         => sub {},
    _module_version => sub {},
    _arguments      => sub {},
);

our @ALLOWED_ROOT_NAMESPACE_MODULES = qw[
	PadWalker Carp DEBUG Encode
	JSON YAML URI DateTime
	Cwd Fcntl Socket POSIX
	strict warnings
	parent base
	feature experimental utf8
];

sub BUILD {
    my ($self, $params) = @_;

	my @args = $self->ppi->arguments;

	#use Data::Dumper;

	#warn __PACKAGE__," ARGS: ", Dumper \@args;

	# NOTE:
	# Drop everything until we find something that
	# actually looks like a module name. This is
	# NOT perfect, and will mess up occasionaly.
	shift @args
		until # we have nothing left ...
			scalar @args == 0
			|| # but if we do have something left
		   	(  # determine if it is a module name ...
		   		# first is has to be some kind of quoted token ...
			   	$args[0]->isa('PPI::Token::Quote')
			   	&&
			   	# then we do some guessing ....
			   	(
			   		# has module seperator, most of them will ...
			   		$args[0]->string =~ /\:\:/
			   			||
			   		# or it is one of the allowed ones ...
			   		List::Util::any { $args[0]->string eq $_ } @ALLOWED_ROOT_NAMESPACE_MODULES
			   	)
			   	# and then if our guesses were okay, make sure
			   	# it actully looks like a module to Perl
			   	&& Module::Runtime::is_module_name( $args[0]->string )
			);

	#warn __PACKAGE__," PRE MODULE: ", Dumper \@args;

	Carp::confess('Unable to find a module name') unless @args;

	my $module = shift @args;

	my $module_version;
	if ( @args && $args[0]->isa('PPI::Token::Number') ) {
		# we likely have a version here now ...
		$module_version = shift @args;
	}

	#warn __PACKAGE__," CONDITIONAL ARGS: ", Dumper \@args;

	$self->{_module}         = $module->string;
	$self->{_module_version} = $module_version ? $module_version->content : undef;
	$self->{_arguments}      = \@args;
}

sub is_conditional { 1 }

sub module         { $_[0]->{_module}         }
sub module_version { $_[0]->{_module_version} }
sub arguments      { @{ $_[0]->{_arguments} } }

# HACK: ... yeah this is kind of a hack, but should work
sub is_pragma { $_[0]->{_module} eq lc $_[0]->{_module} }

1;

__END__

=pod

=head1 DESCRIPTION

=cut
