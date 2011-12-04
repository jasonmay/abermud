#!/usr/bin/env perl
package AberMUD::Input::Command::Inventory;
use AberMUD::OO::Commands;

command inventory => sub {
    my ($universe, $you) = @_;
    my $output = q{};

    if ($you->carrying) {
        $output = "Your backpack contains:\n";
        $output .= join(
            ' ',
            map { $_->name_in_inv }
            grep { !($_->wearable and $_->worn) and !($_->wieldable and $_->wielded) }
            $you->carrying
        );

        my @containers = grep { $_->container } $you->carrying;

        $output .= "\n" . $_->display_contents()
            for @containers;
    }
    else {
        $output = "Your backpack contains nothing.";
    }

    $universe->send_to_location(
        $you,
        $you->name . " rummages through his backpack.\n",
        except => $you,
    );

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
