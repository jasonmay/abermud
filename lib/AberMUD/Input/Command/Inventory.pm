#!/usr/bin/env perl
package AberMUD::Input::Command::Inventory;
use AberMUD::OO::Commands;

command inventory => sub {
    my ($self, $e) = @_;
    my $output = q{};

    if ($e->player->carrying) {
        $output = "Your backpack contains:\n";
        $output .= join(
            ' ',
            map { $_->name_in_inv }
            grep { !($_->wearable and $_->worn) and !($_->wieldable and $_->wielded) }
            $e->player->carrying
        );

        my @containers = grep { $_->container } $e->player->carrying;

        $output .= "\n" . $_->display_contents()
            for @containers;
    }
    else {
        $output = "Your backpack contains nothing.";
    }

    $e->universe->send_to_location(
        $e->player,
        $e->player->name . " rummages through his backpack.\n",
        except => $e->player,
    );

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
