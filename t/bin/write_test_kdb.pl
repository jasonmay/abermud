#!/usr/bin/env perl
use lib 'lib';
use AberMUD::Directory;
use AberMUD::Location;
use AberMUD::Zone;
use File::Copy;

my $zone = AberMUD::Zone->new(name => 'test');

my %locations = (
    test1 => AberMUD::Location->new(
        world_id    => 'test1',
        id          => 'road',
        title       => 'A road',
        description => "There is a road here heading north. "
                       . "You hear noises in the distance. ",
        zone        => $zone,
        active      => 1,
    ),
    test2 => AberMUD::Location->new(
        world_id    => 'test2',
        id          => 'path',
        title       => 'Path',
        description => "This path goes north and south.",
        zone        => $zone,
        active      => 1,
    ),
);

my $file = 't/etc/kdb/001';

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

copy($file => 't/etc/kdb/002');
