#!/usr/bin/env perl
package AberMUD::Controller;
use Moose;
use AberMUD::Player;
use AberMUD::Connection;

use Module::Pluggable
    search_path => ['AberMUD::Input::State'],
    sub_name    => '_input_states',
;

has backend_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has backend_params => (
    is       => 'ro',
    isa      => 'Ref',
    required => 1,
);

has storage => (
    is  => 'ro',
    isa => 'AberMUD::Storage',
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => 6715,
);

has backend => (
    is      => 'ro',
    does    => 'AberMUD::Backend',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Class::MOP::load_class($self->backend_class);

        my $p = $self->backend_params;
        my %param_map =
            ref($self->backend_params) eq 'HASH' ? (%$p) :
            ref($self->backend_params) eq 'ARRAY'? (map { $_ => $_ } @$p) :
            ();

        my %params = ();
        while (my ($param_key, $param_value) = each %param_map) {
            $params{$param_key} = $self->$param_value;
        }
        return $self->backend_class->new(%params);
    },
    handles => ['run'],
);

has universe => (
    is       => 'ro',
    isa      => 'AberMUD::Universe',
    required => 1,
);

has connections => (
    is => 'ro',
    isa => 'HashRef[MUD::Connection]',
    traits  => ['Hash'],
    handles => {
        add_connection  => 'set',
        connection      => 'get',
        has_connections => 'count',
    },
);

has input_states => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_input_states',
);

sub _build_input_states {
    my $self = shift;
    my %input_states;
    foreach my $input_state_class ($self->_input_states) {
        next unless $input_state_class;
        Class::MOP::load_class($input_state_class);
        my $input_state_object = $input_state_class->new(
            universe          => $self->universe,
            command_composite => $self->command_composite,
            special_composite => $self->special_composite,
        );

        $input_states{ $input_state_class } = $input_state_object;
    }

    return \%input_states;
}

has special_composite => (
    is  => 'ro',
    isa => 'AberMUD::Special',
);

has command_composite => (
    is       => 'ro',
    isa      => 'AberMUD::Input::Command::Composite',
    required => 1,
);

has storage => (
    is       => 'ro',
    isa      => 'AberMUD::Storage',
    required => 1,
    handles => [
        'save_player',
    ],
);

sub new_connection {
    my $self = shift;
    my @states = $self->storage->lookup_default_input_states();
    return AberMUD::Connection->new(
        input_states => [ @{$self->input_states}{@states} ],
    );
}

before run => sub {
    my $self = shift;

    warn "Loaded " . scalar(my @o = $self->universe->objects->members) . " objects...\n";
    warn "Loaded " . scalar(my @m = $self->universe->mobiles->members) . " mobiles...\n";
    warn "Loaded " . scalar(my @l = $self->universe->locations->members) . " locations...\n";
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

AberMUD::Controller - Logic that coordinates gameplay and I/O

=head1 SYNOPSIS

  my $abermud = AberMUD::Controller->new(universe => $universe);

=head1 DESCRIPTION

This module is basically L<MUD::Controller> with some modifications
involving player actions and POE-related enhancements.

See L<MUD::Controller> documentation for more details on the functionality
of this module.

=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

You may use this code under the same terms of Perl itself.
