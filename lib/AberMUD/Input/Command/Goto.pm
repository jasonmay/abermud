#!/usr/bin/env perl
package AberMUD::Input::Command::Goto;
use AberMUD::OO::Commands;

command goto => sub {
    my ($self, $e) = @_;
    (my $loc_id = lc $e->arguments) =~ s/\W//g;

    my $loc = $e->universe->storage->lookup("location-$loc_id");

    if (!$loc) {
        return "Could not find that location.";
    }

    $e->player->change_location($loc);
    return $e->universe->look;
};

__PACKAGE__->meta->make_immutable;

1;

