#!/usr/bin/env perl
package AberMUD::Input::Command::Goto;
use AberMUD::OO::Commands;

command goto => sub {
    my ($self, $e) = @_;
    my ($name, $zone) = split '@', $e->arguments, 2;
    return "Please specify something." unless $name;

    my @things = ();
    push @things, $e->universe->get_objects, $e->universe->get_mobiles;
    push @things, $e->universe->player_list unless $zone;
    for my $thing (@things) {
        if ($thing->can('zone') and defined $thing->zone) {
            next unless $thing->zone->name eq $zone;
        }
        next unless $thing->name eq $name;
        warn $thing->name . '?';
        warn $thing->location;
        warn $thing->contained_by if $thing->getable;
        next unless $thing->location;
        warn $thing->name;
        if ($thing == $e->player) {
            return "That's you!";
        }

        $e->universe->change_location($e->player, $thing->location);
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

