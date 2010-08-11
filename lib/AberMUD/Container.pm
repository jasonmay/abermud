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

sub new_universe {
    my $self = shift;
    my $container = shift;
    my $b = shift;
    weaken(my $w = $b);

    my $config = $w->param('storage')->lookup('config')
        or die "No config found in kdb!";

    my $u = AberMUD::Universe->new(
        storage   => $w->param('storage'),
        _controller => $w->param('controller'),
        spawn_player_code => sub {
            my $self     = shift;
            my $id       = shift;
            #weaken(my $c = $container);
            my $player   = $container->fetch('player')->get(
                id          => $id,
                prompt      => '&*[ &+C%h/%H&* ] &+Y$&* ',
                location    => $config->location,
                input_state => [
                map {
                    my $class = "AberMUD::Input::State::$_";
                    Class::MOP::load_class($class);
                    $class->new(
                        universe => $self,
                    )
                } $config->input_states
                ],
            );

            return $player;
        }
    );

    return $u;
}

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
                weaken(my $w = $container);
                $container->new_universe($w, @_)
            },
            dependencies => [
                depends_on('storage'),
                depends_on('controller'),
            ],
        );

        #service input_states => {
        #    block => sub {
        #        my $s = shift;
        #        +{
        #            map {
        #                my $class = "AberMUD::Input::State::$_";
        #                Class::MOP::load_class($class);
        #                $class->new(
        #                    universe => $self,
        #                )
        #            } $config->input_states
        #        };
        #    },
        #    dependencies => 
        #};

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

