#!/usr/bin/env perl
package AberMUD::Input::Command::Empty;
use AberMUD::OO::Commands;

command empty => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (!@args) {
        return "Empty what?";
    }
    elsif (@args == 1) {
        my $container = $universe->identify_object(
            $you->location,
            $args[0],
        ) or return "I don't see anything like that.";

        $container->container or return "That's not a container";

        if (
            $container->getable
                and $container->held_by
                and $container->held_by != $you
        ) {
            return "That belongs to " .
                $container->held_by->formatted_name .
                ". I don't think they'd appreciated that.";
        }

        my @contents = $container->containing
            or return "Nothing comes out.";


        my $inside = $contents[0];

        my $where = ($container->getable and $container->held_by) ? 'in your backpack' : 'on the ground';

        my $output = q[];
        foreach my $o (@contents) {
            $output .= sprintf(
                "You take the %s from the %s, and put it %s.\n",
                $o->formatted_name, $container->formatted_name, $where,
            );

            $o->take_from($container);

            if ($container->getable and $container->held_by) {
                $o->held_by($container->held_by);
            }
            else {
                $o->change_location($you->location);
            }
        }
        return $output;
    }

};

__PACKAGE__->meta->make_immutable;

1;
