#!/usr/bin/env perl
package AberMUD::Input::Command::Look;
use AberMUD::OO::Commands;

command 'look', priority => -10, sub {
    my $you  = shift;
    my $args = shift;

    if (!$args) {
        return "You are somehow nowhere." unless defined $you->location;
        return $you->look;
    }

    my @args = split ' ', $args;

    if (lc($args[0]) eq 'in') {
        return "Look in what?" unless $args[1];

        my $object = $you->universe->identify_object(
            $you->location, $args[1]
        ) or return "I don't see anything like that.";

        $object->container or return "You can't look in that!";

        my $output = _show_container_contents($you->universe, $object, 0);
    }
    else {
        return "LOL"; # TODO should do same as "examine"
    }
};

sub _show_container_contents {
    my ($universe, $object, $tabs) = @_;

    my $output = '';
    my $first_object = 1;
    my @contained_containers;
    my @contained = $universe->objects_contained_by($object);

    #warn map { $_->name } @contained;
    foreach (@contained) {
        next unless $_->containable;
        next unless $_->contained_by($object);

        $first_object and $output .= ' ' x (4 * $tabs - 1);

        $output .= ' ' . $_->name;

        push @contained_containers, $_ if $_->container;
    }

    foreach (@contained_containers) {
        my @contained = $universe->objects_contained_by($_)
            or next;

        $output .= sprintf(
            "\n%sThe %s contains:\n%s",
            '    ' x $tabs, $_->name, _show_container_contents($universe, $_, $tabs + 1),
        );
    }

    return $output;
}

__PACKAGE__->meta->make_immutable;

1;
