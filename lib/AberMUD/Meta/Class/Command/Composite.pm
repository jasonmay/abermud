package AberMUD::Meta::Class::Command::Composite;
use Moose;
extends 'Moose::Meta::Class';

has command_entries => (
    is		    => 'ro',
    isa		    => 'HashRef[AberMUD::Input::Command]',
    default	    => sub { +{} },
    traits          => ['Hash'],
    handles         => {
	add_command_entry => 'set',
	get_command_entry => 'get',
    },
);

__PACKAGE__->meta->make_immutable();

1;
