#!/usr/bin/env perl
package AberMUD::Input::Command::Inventory;
use AberMUD::OO::Commands;

command inventory => sub {
    my $you  = shift;
    my $output = q{};

    my @objects_you_carry = grep {
        $_->can('held_by') and $_->held_by
            and $_->held_by == $you
    } $you->universe->objects;

    if (@objects_you_carry) {
        $output = "Your backpack contains:\n";
        $output .= join(' ', map { $_->name } @objects_you_carry);

        my @containers = grep { $_->container } @objects_you_carry;

        $output .= "\n" . $you->universe->display_container_contents($_)
            for @containers;
    }
    else {
        $output = "Your backpack contains nothing.";
    }

    $you->say(
        $you->name . " rummages through his backpack.\n",
        except => $you,
    );


    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
