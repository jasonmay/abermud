#!/usr/bin/env perl
package AberMUD::Container;
use Moose;

use Bread::Board;
use Scalar::Util qw(weaken);

use AberMUD::Storage;
use AberMUD::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Mobile;
use AberMUD::Object::Role::Getable;
use AberMUD::Object::Role::Weapon;
use AberMUD::Util ();

use namespace::autoclean;

has container => (
    is         => 'rw',
    isa        => 'Bread::Board::Container',
    lazy_build => 1,
    builder    => '_build_container',
    handles    => [qw(resolve param)],
);

has storage_block => (
    is      => 'ro',
    isa     => 'Maybe[CodeRef]',
    builder => '_build_storage_block',
    lazy    => 1,
);

sub _build_storage_block { undef }

has controller_block => (
    is      => 'ro',
    isa     => 'Maybe[CodeRef]',
    builder => '_build_controller_block',
    lazy    => 1,
);

sub setup_controller {
    my ($self, $service, $controller) = @_;

    foreach my $input_state_class ($controller->_input_states) {
        next unless $input_state_class;
        Class::MOP::load_class($input_state_class);
        my $input_state_object = $input_state_class->new(
            universe          => $service->param('universe'),
            command_composite => $service->param('command_composite'),
            special_composite => $service->param('special_composite'),
        );

        $controller->set_input_state(
            $input_state_class => $input_state_object,
        );
    }

}

sub _build_controller_block {
    return sub {
        my ($self, $service) = @_;

        my $controller = AberMUD::Controller->new(
            storage  => $service->param('storage'),
            universe => $service->param('universe'),
        );

        $self->setup_controller($service, $controller);

        return $controller;
    };
}

has universe_block => (
    is  => 'ro',
    isa => 'Maybe[CodeRef]',
    builder => '_build_universe_block',
    lazy    => 1,
);

sub _build_universe_block {
    return sub {
        my ($self, $service) = @_;

        my $config = $service->param('storage')->lookup('config')
            or die "No config found in kdb!";

        my $u = $config->universe;

        $u->storage($service->param('storage'));
        $u->_controller($service->param('controller'));
        $u->players(+{});
        $u->players_in_game(+{});

        weaken(my $weakservice = $service);
        weaken(my $weakcontainer = $self);

        my @input_states = map {
            $u->_controller->get_input_state("AberMUD::Input::State::$_")
        } @{ $config->input_states };

        my %player_params = (
            prompt            => '&*[ &+C%h/%H&* ] &+Y$&* ',
            location          => $config->location,
            special_composite => $weakservice->param('special_composite'),
        );

        $u->spawn_player_code(
            sub {
                my $self     = shift;
                my $player   = $weakcontainer->resolve(
                    service    => 'player',
                    parameters => \%player_params,
                );

                return $player;
            }
        );

        return $u;
    }
}

has player_block => (
    is  => 'ro',
    isa => 'Maybe[CodeRef]',
    builder => '_build_player_block',
);

sub _build_player_block { undef }

sub _build_container {
    my $self = shift;

    weaken(my $weakself = $self);
    my $c = container 'AberMUD' => as {

        my %player_args;
        if ($self->player_block) {
            $player_args{block} = sub {
                $weakself->player_block->($weakself, @_)
            };
        }
        else {
            $player_args{parameters} = {
                prompt            => { isa => 'Str' },
                location          => { isa => 'AberMUD::Location' },
                input_state       => { isa => 'ArrayRef' },
                special_composite => { isa => 'AberMUD::Special' },
            };
        }

        my %controller_args;
        $controller_args{block} = sub {
            $weakself->controller_block->($weakself, @_)
        } if $self->controller_block;

        my %storage_args;
        $storage_args{block} = sub {
            $weakself->storage_block->($weakself, @_)
        } if $self->storage_block;

        service storage => (
            class     => 'AberMUD::Storage',
            lifecycle => 'Singleton',
            %storage_args,
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifecycle => 'Singleton',
            block     => sub { $weakself->universe_block->($weakself, @_) },
            dependencies => {
                storage           => depends_on('storage'),
                controller        => depends_on('controller'),
                special_composite => depends_on('special_composite'),
            },
        );

        service player => (
            class => 'AberMUD::Player',
            dependencies => {
                storage  => depends_on('storage'),
                universe => depends_on('universe'),
                special_composite => depends_on('special_composite'),
            },
            %player_args,
        );

        service controller => (
            class     => 'AberMUD::Controller',
            lifecycle => 'Singleton',
            %controller_args,
            dependencies => {
                storage           => depends_on('storage'),
                universe          => depends_on('universe'),
                command_composite => depends_on('command_composite'),
                special_composite => depends_on('special_composite'),
            },
        );

        service special_composite => (
            class     => 'AberMUD::Special',
            lifecycle => 'Singleton',
            dependencies => {
                command_composite => depends_on('command_composite'),
            },
        );

        service command_composite => (
            class     => 'AberMUD::Input::Command::Composite',
            lifecycle => 'Singleton',
        );

        service app => (
            class => 'AberMUD',
            lifecycle => 'Singleton',
            dependencies => {
                storage    => depends_on('storage'),
                controller => depends_on('controller'),
                universe   => depends_on('universe'),
            }
        );
    };

    return $c;
}

sub storage_object {
    my $self = shift;

    return $self->resolve(service => 'storage');
}

1;

__END__

=head1 NAME

AberMUD::Container - wires all the AberMUD components together

=head1 SYNOPSIS

  use AberMUD::Container;
  
  my $c = AberMUD::Container->new->container;
  $c->resolve(service => 'app')->run;

=head1 DESCRIPTION

See L<Bread::Board> for more information.

