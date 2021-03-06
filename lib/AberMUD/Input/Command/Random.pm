#!/usr/bin/env perl
package AberMUD::Input::Command::Random;
use AberMUD::OO::Commands;

# this is just for testing so I can play around on my MUD :D

command 'random' , priority => -10, sub {
    my ($self, $e) = @_;
    my $args = $e->arguments;

    return goto_mobile($e->universe, $e->player) if $args =~ /mob/i;

    my @o = $e->universe->get_objects;

    my $location;

    my $output = "Scanning...\n";
    my $n = 0;
    until ($location or $n > 100) {
        $n++;
        my $o = $o[rand @o];
        $output .= "Trying " . $o->name . "...\n";

        if ($args =~ /door/) {
            next unless $o->gateway;
        }
        elsif ($args =~ /key/) {
            next unless $o->key;
        }
        elsif ($args =~ /locked/) {
            next unless $o->lockable;
            next unless $o->locked;
        }
        elsif ($args =~ /multistate/) {
            next unless $o->multistate;
        }
        else {
            next unless $o->getable;
            next unless $o->container or $o->wieldable or $o->wearable or $o->edible;
        }

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
    }

    return "I give up.\n" unless $location;

    $e->universe->change_location($e->player, $location);
    $output .= $e->universe->look($e->player->location);
    return $output;
};

sub goto_mobile {
    my ($universe, $you)  = @_;

    my @moving_mobiles = grep {
    $_->location and
    $_->speed and
    $_->speed > 0
    } $universe->get_mobiles;

    my $m = $moving_mobiles[rand @moving_mobiles];

    $universe->change_location($you, $m->location);
    return $you->look;
}

command heal => sub {
    my ($self, $e) = @_;

    $e->player->current_strength($e->player->max_strength);
    return sprintf('Aww yeah. Back to %s!', $e->player->current_strength);
};

__PACKAGE__->meta->make_immutable;

1;

