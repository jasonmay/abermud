#!/usr/bin/env perl
package AberMUD::Player;
use KiokuDB::Class;
use namespace::autoclean;

extends 'AberMUD::Killable';

use AberMUD::Location;

use List::Util      qw(first);
use List::MoreUtils qw(first_value);

=head1 NAME

AberMUD::Player - AberMUD Player class for playing

=head1 SYNOPSIS

    my $player = AberMUD::Player->new;

=head1 DESCRIPTION

XXX

=cut

with qw(
    AberMUD::Player::Role::InGame
    AberMUD::Role::Humanoid
);

has '+location' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

has prompt => (
    is      => 'rw',
    isa     => 'Str',
    default => '>',
);

has password => (
    is  => 'rw',
    isa => 'Str',
);

has markings => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
    traits  => ['Hash', 'KiokuDB::DoNotSerialize'],
    handles => {
        'mark' => 'set',
    }
);

has output_buffer => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'clear_output_buffer',
    traits  => ['String', 'KiokuDB::DoNotSerialize'],
    lazy    => 1,
    default => '',
    handles => {
        append_output_buffer => 'append',
    },
);

has money => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has '+_carrying' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

# game stuff
sub setup {
    my $self = shift;

    if ($self->dead) {

        my $restore = int($self->max_strength * 2 / 3);
        $restore = 40 if $restore < 40;

        # restore strength
        $self->current_strength($restore);
        $self->dead(0);
    }
}

sub final_prompt {
    my $self = shift;
    my $prompt = $self->prompt;

    $prompt =~ s/%h/$self->current_strength/e if $self->can('current_strength');
    $prompt =~ s/%H/$self->max_strength/e     if $self->can('max_strength');

    #$prompt =~ s/%m/$self->current_mana/e;
    #$prompt =~ s/%M/$self->max_mana/e;

    return $prompt;
}

after death => sub {
    my $self = shift;
    my %args = @_;
    my $universe = $args{universe};

    # TODO Save, dematerialize

    delete $universe->players->{$self->name};

    # no_prompt => 1 omitted
    $self->append_output_buffer(<<DEATH);

&+r***********************************&N
      I guess you died! LOL!
&+r***********************************&N
DEATH

    $self->mark(disconnect => 1);
};

__PACKAGE__->meta->make_immutable;

1;
