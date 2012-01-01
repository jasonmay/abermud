#!/usr/bin/env perl
package AberMUD::Input::Command::Equipment;
use AberMUD::OO::Commands;
use List::Util qw(first);
use AberMUD::Object::Util qw(bodyparts);

command equipment => sub {
    my ($self, $e) = @_;

    my $weapon = first {
        $_->wieldable and $_->getable
            and $_->wielded
            and $_->held_by == $e->player
    } $e->universe->get_objects;

    my $output = sprintf('%-20s', '&+CWielding:&*');

    my $weapon_name = $weapon ? $weapon->name : 'Unarmed';
    $output .= sprintf('[%3s] %s', $e->player->total_damage, $weapon_name);

    $output .= "\n&+C=============================\n";

    my $bare = 1;

    my %coverage = $e->player->coverage;

    foreach my $part (bodyparts()) {
        next unless $coverage{$part};
        $output .= sprintf('%-20s', '&+C'.ucfirst($part).':&*');

        if ($coverage{$part}) {
            $output .= $coverage{$part}->name;
        }
        $output .= "\n";
    }

    $output .= "&+C=============================\n";

    return $output;
};

__PACKAGE__->meta->make_immutable;

1;
