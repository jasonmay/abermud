#!/usr/bin/env perl
package AberMUD::Role::InGame;
use Moose::Role;

use AberMUD::Location;

has 'location' => (
    is => 'rw',
    isa => 'AberMUD::Location',
    traits => ['KiokuDB::DoNotSerialize'],
    handles => {
        map {
            ("can_go_$_" => "has_$_")
        } @{AberMUD::Location->directions}
    },
);

no Moose::Role;

1;
