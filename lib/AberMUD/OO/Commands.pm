package AberMUD::OO::Commands;
use Moose ();
use Moose::Exporter;

sub init_meta {
    my $self    = shift;
    my %options = @_;

    $options{metaclass} = 'AberMUD::Meta::Class::Command::Composite';

    return Moose->init_meta(%options);
}

sub command {
    my $self = shift;
    my ($name, $code) = @_;

    if ($self->meta->get_command_entry($name)) {
	$self->meta->get_command_entry($name)->code($code);
    }
    else {
	my $command = AberMUD::Input::Command->new(
	    code => $code,
	);
	$self->meta->add_command_entry($name => $command);
    }
}

sub command {
    my $self = shift;
    my ($name, $code) = @_;

    if ($self->meta->get_command_entry($name)) {
	$self->meta->get_command_entry($name)->code($code);
    }
    else {
	my $command = AberMUD::Input::Command->new(
	    code => $code,
	);
	$self->meta->add_command_entry($name => $command);
    }
}

