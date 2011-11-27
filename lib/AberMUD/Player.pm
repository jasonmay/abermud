#!/usr/bin/env perl
package AberMUD::Player;
use KiokuDB::Class;
use namespace::autoclean;

use AberMUD::Location;
use AberMUD::Location::Util qw(directions show_exits);

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
    AberMUD::Role::Killable
    AberMUD::Role::Humanoid
);

has '+location' => (
    traits => ['KiokuDB::DoNotSerialize'],
);

has markings => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => {
        mark => 'set',
    },
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
    is  => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
    traits => ['Hash'],
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

# game stuff
sub setup {
    my $self = shift;

    if ($self->dead) {

        my $restore = int($self->max_strength * 2 / 3);
        $restore = 40 if $restore < 40;

        # restore strength
        $self->current_strength($restore);
        $self->dead(0);
        $self->save_data();
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

sub death {
    my $self = shift;
    my %args = @_;
    my $universe = $args{universe};

    # TODO Save, dematerialize

    delete $universe->players->{$self->name};

    $self->append_output_buffer(<<DEATH, no_prompt => 1);

&+r***********************************&N
      I guess you died! LOL!
&+r***********************************&N
DEATH

    $self->mark(disconnect => 1);
};

__PACKAGE__->meta->make_immutable;

1;
