#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Util;
use AberMUD::Location;
use File::Basename;
use Carp;
use String::Util ':all';
use KiokuDB;
use KiokuDB::Backend::DBI;
use AberMUD::Zone;
#use namespace::autoclean;

my @locations = (AberMUD::Location->new);
my %locations;
my %dir_locations;
my %loc_map;
my %loc_world_map;
my $total_locs = 0;

sub parse_zone {
    my $file = shift;
    my $zone_file = lc(basename $file);
    my $zone = $zone_file;
    $zone =~ s/\.zone$//;
    my $zone_obj = AberMUD::Zone->new(name => $zone);
    return unless -f $file;
    open my $fh, '<', $file;
    my $title;
    my $prev_line;
    my $n = 0;
    $_ = <$fh> until $_ && /^%locations/ || !$_;

    while (<$fh>) {
        next if /^%locations/;
        if (/^%zone:(\S+)/) {
            $zone = $1;
            $zone_obj = AberMUD::Zone->new(name => $zone);
            $_ = <$fh> while $_ && !/^%locations/;
            $_ = <$fh>; # skip
            $n = 1;
        }
        next if /^\s*$/;
        last if /^%(?!locations)/;
        $n++;
        my ($id, $exit_info) = /(\S+)\s*(.*);/;
        $id = trim $id;
        my $loc = AberMUD::Location->new(zone => $zone_obj);
        croak "$file -> $_" unless $id;
        $loc->id($id);
        $locations{"$id\@$zone"}  = $loc;
        $dir_locations{"$zone$n"} = $loc;
        $loc->world_id("$zone$n");

        my @exit_nodes = split ' ', $exit_info;

        foreach my $exit_node (@exit_nodes) {
            # TODO check for doors
            my ($dir_letter, $exit_loc) = $exit_node =~/\^?(.+):(.+)/;
            $exit_loc .= "\@$zone" if $exit_loc !~ /@/;
            $exit_loc =~ s/\@(.+)/'@' . lc $1/e;
            $loc_map{"$id\@$zone"}->{$dir_letter} = $exit_loc;
            $loc_world_map{"$zone$n"}->{$dir_letter} = $exit_loc;
        }

        $_ = <$fh> while $_ && lc($_) !~ /^lflags/;
        last unless $_;

        my ($flags) = /\{(.+)\}/;

        #do something with lflags later
        $loc->flags(+{map { $_ => 1 } split(' ', lc $flags)}) if $flags;

        $_ = <$fh>;
        die $_ unless /\^/;
        my ($title) = /(.+)\^/;
        $loc->title($title) if $title;

        $_ = <$fh>; last unless $_;

        while ($_ && $_ !~ /^\^/) {
            $loc->description(($loc->description||'') . $_);
            $_ = <$fh>;
        }
    }
    close $fh;
    print "parsed $file\n";
}

my $zones_dir = 'zones';
opendir(my $dh, $zones_dir);
for (readdir($dh)) {
    next unless lc($_) =~ /\.zone$/;
    parse_zone "$zones_dir/$_";
}
closedir $dh;

unlink qw/abermud abermud-journal/;
my $kdb = KiokuDB->connect('dbi:SQLite:dbname=abermud', create => 1);
my $scope = $kdb->new_scope;
my %dir = map { substr($_, 0, 1) => $_ } @{AberMUD::Location->directions};

while (my ($dir_key, $dir_value) = each %dir_locations) {
    $kdb->store("location-$dir_key" => $dir_value);
}

warn "$locations{'Bones@abyss'}";

while (my ($loc_id, $loc) = each %locations) {
    next unless exists $loc_map{$loc_id};
    while (my ($dir_letter, $exit) = each %dir) {
        next unless exists $loc_map{$loc_id}->{$dir_letter};
        next unless exists $locations{$loc_map{$loc_id}->{$dir_letter}};

        my $loc_dir = $locations{$loc_map{$loc_id}{$dir_letter}};
        $loc->$exit($loc_dir);
    }
#    die "$loc_id";
}

$kdb->update($_) foreach values %dir_locations;
