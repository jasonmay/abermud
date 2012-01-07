#!/usr/bin/env perl
package AberMUD::Universe::Role::Violent;
use Moose::Role;
use namespace::autoclean;

use AberMUD::Object::Util 'bodyparts';

use AberMUD::Messages;

around advance => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        unless $self->does('AberMUD::Universe::Role::Mobile');

    for my $mobile ($self->get_mobiles) {
        next unless $mobile->does('AberMUD::Mobile::Role::Hostile');

        if ($self->roll_to_start_fight($mobile)) {
            $self->start_fight($mobile);
        }
    }

    $self->fight_iteration();

    return $self->$orig(@_);
};

sub roll_to_start_fight {
    my $self = shift;
    my ($mob) = @_;

    my $roll = rand 100;
    my $go = !!($mob->aggression >= $roll);

    return $go;
}

sub generate_random_fight_data {
    my $self     = shift;
    my $attacker = shift;

    my $damage   = int rand($attacker->total_damage);
    my $bodypart = ( bodyparts() )[ rand scalar( bodyparts() ) ];

    my $spans = Array::IntSpan->new(
        [(0, 0) => 'futile'],
        [(1, 33) => 'weak'],
        [(34, 66) => 'med'],
        [(67, 100) => 'strong'],
    );
    my $hit_type = $attacker->wielding ? 'WeaponHit' : 'BareHit';
    my %hits = %{ AberMUD::Messages->$hit_type };

    my $perc = $damage * 100 / $attacker->total_damage;
    my $damage_level = $spans->lookup(int $perc);
    my @messages = @{ $hits{$damage_level} };
    my $message = $messages[rand @messages];

    my %data = (
        damage   => $damage,
        bodypart => $bodypart,
        message  => $message,
    );

    return %data;
}

sub fight_iteration {
    my $self = shift;
    my $type = shift || '';

    #foreach my $mobile ($self->get_mobiles) {
    #    if ($mobile->fighting) {
    #        $mobile->fighting->fighting($mobile)
    #            if $mobile->fighting->fighting != $mobile;
    #        $mobile->attack;
    #    }
    #}

    foreach my $player ($self->player_list) {
        if ($player->fighting) {
            if ($player->location != $player->fighting->location) {
                $player->append_output_buffer("I guess you're not fighting anymore..\n");
                $player->stop_fighting;
                next;
            }
            $player->fighting->fighting($player)
                if $player->fighting->fighting != $player;

            my %data;

            %data = $self->generate_random_fight_data($player);
            $self->attack(
                attacker => $player,
                victim   => $player->fighting,
                %data,
            );

            if ($player->fighting) { # could have killed
                %data = $self->generate_random_fight_data($player->fighting);
                $self->attack(
                    attacker => $player->fighting,
                    victim   => $player,
                    %data,
                );
            }
        }
    }
}

sub start_fight {
    my $self   = shift;
    my $mobile = shift;

    return unless $mobile->can('fighting');
    return unless $mobile->location;

    my @potential_victims = grep {
        $_ != $mobile and
        $_->location and
        $_->location == $mobile->location
    } $self->player_list;

    return unless @potential_victims;
    my $killable = $potential_victims[rand @potential_victims];
    $mobile->start_fighting($killable);
}

sub attack {
    my $self = shift;
    my %args = @_;

    my $attacker = $args{attacker};
    my $victim   = $args{victim};
    my $bodypart = $args{bodypart};
    my $damage   = $args{damage};
    my $message  = $args{message};

    my %final_messages = (
        map {
            $_ => AberMUD::Messages::format_fight_message(
                $message,
                attacker    => $attacker,
                victim      => $victim,
                bodypart    => $bodypart,
                perspective => $_,
            ) . "\n";
        } qw(attacker victim bystander)
    );

    my $prev_strength = $victim->reduce_strength($damage);

    if ($attacker->isa('AberMUD::Player')) {
        my $xp = $prev_strength - $victim->current_strength;
        $self->change_score($attacker, $xp);
    }

    my $interrupt = 0;
    my @hook_results = ();
    my $death = ($victim->current_strength <= 0);

    if ($victim->current_strength <= 0) {
        my $special = $self->special;

        ($interrupt, @hook_results) = $special->call_hooks(
            type => 'death',
            when => 'before',
            arguments => [
                victim  => $victim,
            ],
        );
    }

    my $show_hook_results = sub {
        if (@hook_results and $_[0]->isa('AberMUD::Player')) {
            $_[0]->append_output_buffer(
                join('', map { "$_\n" } @hook_results)
            );
        }
    };

    if (!$interrupt) {
        $attacker->append_output_buffer($final_messages{attacker})
            if $attacker->isa('AberMUD::Player');
        $victim->append_output_buffer($final_messages{victim})
            if $victim->isa('AberMUD::Player');

        $victim->death(universe => $self) if $death;

        $show_hook_results->($attacker);

        $self->send_to_location(
            $attacker, $final_messages{bystander},
            except => [$attacker, $victim],
        );

        # if this attack killed the victim
        if ($death) {
            $self->send_to_location(
                $attacker,
                sprintf(
                    qq[%s falls to the ground.\n],
                    $victim->formatted_name,
                ),
                except => [$victim],
            );

            # call the death hook after all the death messages
            (undef, @hook_results) = $self->special->call_hooks(
                type => 'death',
                when => 'after',
                arguments => [
                    attacker => $attacker,
                    victim   => $victim,
                ],
            );
            $show_hook_results->($attacker);
        }
    }
    else {
        if ($death) {
            $victim->dead(0);
            $victim->current_strength(1);
            $show_hook_results->($attacker);
        }
    }

    return;
}

1;

