#!/usr/bin/env perl
package AberMUD::Container;
use Moose;
use Bread::Board;
use Scalar::Util qw(weaken isweak);

use AberMUD::Directory;
use AberMUD::Controller;
use AberMUD::Universe;
use AberMUD::Player;
use AberMUD::Location;
use AberMUD::Object;
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
    my(@objs, @mobs);
    my $self = shift;
    my $container = shift;
    my $b = shift;
    weaken(my $w = $b);

    my $config = $w->param('directory')->lookup('config')
        or die "No config found in kdb!";

    my $u = AberMUD::Universe->new(
        directory   => $w->param('directory'),
        _controller => $w->param('controller'),
        spawn_player_code => sub {
            my $self     = shift;
            my $id       = shift;
            #weaken(my $c = $container);
            my $player   = $container->fetch('player')->get(
                id          => $id,
                prompt      => "&+Y\$&* ",
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


    my $start_loc
    = $config->location;

    return $u;
}

sub _build_container {
    my $container = shift;

    my $c = container 'AberMUD' => as {
        service directory => (
            class     => 'AberMUD::Directory',
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
                depends_on('directory'),
                depends_on('controller'),
            ],
        );

        service player => (
            class => 'AberMUD::Player',
            dependencies => [
                depends_on('directory'),
                depends_on('universe'),
            ],
            parameters => {
                id          => { isa => 'Str' },
                prompt      => { isa => 'Str' },
                input_state => { isa => 'ArrayRef' },
            },
        );

        service controller => (
            class     => 'AberMUD::Controller',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('directory'),
                depends_on('universe'),
            ]
        );

        service app => (
            class => 'AberMUD',
            lifecycle => 'Singleton',
            dependencies => [
                depends_on('directory'),
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

