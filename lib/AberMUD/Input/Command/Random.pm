#!/usr/bin/env perl
package AberMUD::Input::Command::Random;
use AberMUD::OO::Commands;

# this is just for testing so I can play around on my MUD :D

command 'random' , priority => -10, sub {
    my ($you, $args) = @_;

    my @o = $you->universe->get_objects;


    my $location;

    my $output = "Scanning...\n";
    my $n = 0;
    until ($location or $n > 100) {
        my $o = $o[rand @o];
        $output .= "Trying " . $o->name . "...\n";
        next unless $o->getable;

        next unless $o->container or $o->wieldable or $o->wearable or $o->edible;

        if (rand(1) > .5) {
            next unless $o->on_the_ground;
        }

        if (!$o->location) {
            $o->getable or next;
            while ($o->getable and ($o->contained_by or $o->held_by)) {
                if ($o->contained_by) {
                    $output .= $o->name . " contained by " .
                        $o->contained_by->name . "...\n";
                    $o = $o->contained_by;
                }
                elsif ($o->held_by) {
                    $output .= $o->name . " carried by " .
                        $o->held_by->name . "...\n";
                    $location = $o->held_by->location;
                    last;
                }
                else { return "wtf" }
            }
        }
        else {
            $location = $o->location;
        }
        $n++;
    }

    return "I give up.\n" unless $location;

    $you->location($location);
    $output .= $you->look();
    return $output;
};

__PACKAGE__->meta->make_immutable;

1;

