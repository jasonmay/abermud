#!/usr/bin/env perl
package AberMUD::Input::Command::Goto;
use AberMUD::OO::Commands;

command goto => sub {
    my ($self, $e) = @_;
    my ($name, $zone) = split '@', $e->arguments, 2;
    return "Please specify a mobile." unless $name;
    return "Please specify a zone." unless $zone;

    my @mobs = $e->universe->get_mobiles;
    for my $mob (@mobs) {
        next unless $mob->zone->name eq $zone;
        next unless $mob->name eq $name;
        $e->universe->change_location($e->player, $mob->location);
        my $look_event = AberMUD::Event::Command->new(
            universe  => $e->universe,
            player    => $e->player,
            arguments => '',
        );
        return $self->trigger_command('look', $look_event);
    }
    return "I could not find $name in $zone.";
};

__PACKAGE__->meta->make_immutable;

1;

