#!/usr/bin/env perl
package AberMUD::Input::Command::Inventory;
use AberMUD::OO::Commands;

command inventory => sub {
    my $you  = shift;
    my $output = q{};

    my @objects_you_carry = grep {
        $_->can('held_by') and $_->held_by
            and $_->held_by == $you
    } $you->universe->get_objects;

    if (@objects_you_carry) {
        $output = "Your backpack contains:\n";
        $output .= join(
            ' ',
            map { $_->name_in_inv }
            grep { !($_->wearable and $_->worn) and !($_->wieldable and $_->wielded) }
            @objects_you_carry
        );

        my @containers = grep { $_->container } @objects_you_carry;

        $output .= "\n" . $_->display_contents()
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
