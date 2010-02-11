#!/usr/bin/env perl
use File::Copy;

use lib 'lib';
use AberMUD::Directory;
use AberMUD::Location;
use AberMUD::Object;
use AberMUD::Zone;
use AberMUD::Universe::Sets;

my $zone = AberMUD::Zone->new(name => 'test');

my %locations = (
    test1 => AberMUD::Location->new(
        world_id           => 'test1',
        id                 => 'road',
        title              => 'A road',
        description        => "There is a road here heading north. "
                              . "You hear noises in the distance. ",
        zone               => $zone,
        #_objects_on_ground => $set1,
        active             => 1,
    ),
    test2 => AberMUD::Location->new(
        world_id           => 'test2',
        id                 => 'path',
        title              => 'Path',
        description        => "This path goes north and south.",
        zone               => $zone,
        #_objects_on_ground => $set2,
        active             => 1,
    ),
);

my @objects = (
    AberMUD::Object->new_with_traits(
        name        => 'rock',
        description => 'A rock is laying on the ground here.',
        location    => $locations{test1},
    ),

    AberMUD::Object->new_with_traits(
        name        => 'sword',
        description => 'Here lies a sword run into the ground.',
        location    => $locations{test2},
        traits      => ['AberMUD::Object::Role::Weapon'],
    ),

    AberMUD::Object->new_with_traits(
        name                => 'sign',
        description         => 'There is a sign here.',
        examine_description => "Why do you care what it says? " .
                            "You're just a perl script!",
        location            => $locations{test1},
        ungetable           => 1,
        traits              => ['AberMUD::Object::Role::Weapon'],
    ),
);

my $sets = AberMUD::Universe::Sets->new;

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

for (@objects) {
    my $id = $kdb->store($_);
    $sets->all_objects->{$id} = $_;
}

$kdb->store("universe-sets" => $sets);
