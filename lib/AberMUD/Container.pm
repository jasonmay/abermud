#!/usr/bin/env perl
package AberMUD::Container;
use Moose;
use Bread::Board;
use Scalar::Util qw(weaken isweak);

use AberMUD::Storage;
use AberMUD::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Mobile;
use AberMUD::Object::Role::Getable;
use AberMUD::Object::Role::Weapon;

use namespace::autoclean;

with qw(
    MooseX::Traits
);

has container => (
    is         => 'rw',
    isa        => 'Bread::Board::Container',
    lazy_build => 1,
    builder    => '_build_container',
    handles    => [qw(fetch param)],
);

sub _build_container {
    my $container = shift;

    my $c = container 'AberMUD' => as {
        service storage => (
            class     => 'AberMUD::Storage',
            lifecycle => 'Singleton',
        );

        service universe => (
            class => 'AberMUD::Universe',
            lifecycle => 'Singleton',
            block     => sub {
                $container->new_universe(@_)
            },
            dependencies => [
                depends_on('storage'),
                depends_on('controller'),
            ],
        );

        service player => (
            class => 'AberMUD::Player',
            dependencies => [
                depends_on('storage'),
                depends_on('universe'),
            ],
            parameters => {
                id          => { isa => 'Str' },
                prompt      => { isa => 'Str' },
                location    => { isa => 'AberMUD::Location' },
                input_state => { isa => 'ArrayRef' },
            },
        );

        service controller => (
            class     => 'AberMUD::Controller',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('storage'),
                depends_on('universe'),
            ]
        );

        service app => (
            class => 'AberMUD',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('storage'),
                depends_on('controller'),
                depends_on('universe'),
            ]
        );
    };
}

sub new_universe {
    my $container = shift;
    my $b         = shift;

    weaken(my $weakcontainer = $container);

    weaken(my $w = $b);

    my $config = $w->param('storage')->lookup('config')
        or die "No config found in kdb!";

    my $u = $config->universe;

    $u->storage($b->param('storage'));
    $u->_controller($b->param('controller'));
    $u->players(+{});
    $u->players_in_game(+{});

    $u->spawn_player_code(
        sub {
            my $self     = shift;
            my $id       = shift;
            my $player   = $weakcontainer->fetch('player')->get(
                id          => $id,
                prompt      => '&*[ &+C%h/%H&* ] &+Y$&* ',
                location    => $config->location,
                input_state => [
                    map {
                        $w->param('controller')->get_input_state(
                            "AberMUD::Input::State::$_"
                        )
                    } @{ $config->input_states }
                ],
            );

            return $player;
        }
    );

    return $u;
}

1;

__END__

=head1 NAME

AberMUD::Container - wires all the AberMUD components together

=head1 SYNOPSIS

  use AberMUD::Container;
  
  my $c = AberMUD::Container->new->container;
  $c->fetch('app')->get->run;

=head1 DESCRIPTION

See L<Bread::Board> for more information.

