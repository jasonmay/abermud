#!/usr/bin/env perl
package AberMUD::Role::InGame;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Location;
use AberMUD::Location::Util qw(directions);
use List::MoreUtils qw(any);

has name => (
    is  => 'rw',
    isa => 'Str',
);

has universe => (
    is       => 'rw',
    isa      => 'AberMUD::Universe',
    weak_ref => 1,
);

has location => (
    is  => 'rw',
    isa => 'AberMUD::Location',
);

has zone => (
    is  => 'rw',
    isa => 'AberMUD::Zone',
);

has description => (
    is  => 'rw',
    isa => 'Str',
);

has examine_description => (
    is  => 'rw',
    isa => 'Str',
);

foreach my $direction ( directions() ) {
    __PACKAGE__->meta->add_method(
        "can_go_$direction" => sub {
            my $self = shift;
            return 0 unless $self->location;

            return $self->universe->check_exit(
                $self->location,
                $direction,
            );
        }
    );
}

sub say {
    my $self    = shift;
    my $message = shift;
    my %args    = @_;

   my @except = ref($args{except}) eq 'ARRAY'
                    ? (@{$args{except} || []})
                    : ($args{except} || ());

    my @players = grep {
        my $p = $_;
        $p->location == $self->location && !any { $p == $_ } @except
    }
    $self->universe->game_list;

    $_->send("\n$message") for @players;

    return $self;
}

sub local_to {
    my $self    = shift;
    my $in_game = shift;

    return 0 unless $in_game->can('location');
    return 0 unless $in_game->location;

    return $self->in($in_game->location);
}

sub in {
    my $self     = shift;
    my $location = shift;

    return ($self->location && $self->location == $location);
}

sub name_matches {
    my $self = shift;
    my $word = shift or return 0;

    return 1 if $self->name and lc($self->name) eq lc($word);

    return 0;
};

# separate layer for cache updates, etc.
sub change_location {
    my $self     = shift;
    my $location = shift;

    $self->location($location);
}

1;
