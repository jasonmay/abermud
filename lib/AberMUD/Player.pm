#!/usr/bin/env perl
package AberMUD::Player;
use KiokuDB::Class;
use namespace::autoclean;
extends 'MUD::Player';

use AberMUD::Location;
use AberMUD::Location::Util qw(directions show_exits);

use Carp            qw(cluck);
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
    MooseX::Traits
    AberMUD::Player::Role::InGame
    AberMUD::Role::Killable
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
    is  => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
    traits => ['Hash'],
    handles => {
        'mark' => 'set',
    }
);

sub id {
    my $self = shift;

    my $p = $self->universe->players;
    return first_value { $p->{$_} == $self } keys %$p;
}

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

sub send {
    my $self    = shift;
    my $message = shift;
    my %args    = @_;

    return unless $self->id;

    $message .= AberMUD::Util::colorify($self->final_prompt) unless $args{no_prompt};

    $self->universe->_controller->send($self->id => AberMUD::Util::colorify($message));
}

sub sendf {
    my $self    = shift;
    my $message = shift;

    $self->send(sprintf($message, @_));
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

    $self->save_data();
    $self->dematerialize();

    $self->send(<<DEATH, no_prompt => 1);

&+r***********************************&N
      I guess you died! LOL!
&+r***********************************&N
DEATH

    $self->disconnect;
};

sub change_score {
    my $self = shift;
    my $delta = shift;

    my $prev_level = $self->level;

    $self->score($self->score + $delta);

    if ($self->level > $prev_level) {

        if ($self->level > $self->max_level) {
            for ($prev_level + 1 .. $self->level) {
                $self->universe->broadcast(
                    sprintf(
                        "Congratulations to %s for making it to level &+C$_&*.\n",
                        $self->name
                    ),
                    except => $self,
                );

                $self->send("Congratulations! You made it to level &+C$_&*.\n"),
            }
            $self->max_level($self->level);
        }
    }
    elsif ($self->level < $prev_level) {
            $self->sendf(
                "You are back to level &+C%s&*.\n",
                $self->level,
            );
    }

    $self->save_data();
}

__PACKAGE__->meta->make_immutable;

1;
