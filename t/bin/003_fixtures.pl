#!/usr/bin/env perl
use File::Copy;

use lib 'lib';
use AberMUD::Directory;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Zone;

my $zone = AberMUD::Zone->new(name => 'test');

my %locations = (
    test1 => AberMUD::Location->new(
        world_id           => 'test1',
        id                 => 'road',
        title              => 'A road',
        description        => "There is a road here heading north. "
                              . "You hear noises in the distance. ",
        zone               => $zone,
        _objects_on_ground => $set1,
        active             => 1,
    ),
    test2 => AberMUD::Location->new(
        world_id           => 'test2',
        id                 => 'path',
        title              => 'Path',
        description        => "This path goes north and south.",
        zone               => $zone,
        _objects_on_ground => $set2,
        active             => 1,
    ),
);

my $o1 = AberMUD::Object->new_with_traits(
    name        => 'rock',
    description => 'A rock is laying on the ground here.',
    location    => $locations{test1},
);

my $o2 = AberMUD::Object->new_with_traits(
    name        => 'sword',
    description => 'Here lies a sword run into the ground.',
    location    => $locations{test1},
    traits      => ['AberMUD::Object::Role::Weapon'],
);

$o1->location($locations{test1});
$o2->location($locations{test2});

my $file = 't/etc/kdb/003';

unlink $file;
my $kdb = AberMUD::Directory->new(
    kdb => KiokuDB->connect(
        "dbi:SQLite:dbname=$file",
        create => 1,
    )
);

$kdb->store("location-$_" => $locations{$_}) foreach keys %locations;


$locations{test1}->north($locations{test2});
$locations{test2}->south($locations{test1});

$kdb->update($_) foreach values %locations;

my @ids = $kdb->store($o1, $o2);

warn $kdb->lookup($ids[0])->location->title;

