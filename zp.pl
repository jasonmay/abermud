#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Util;
use AberMUD::Location;
use File::Basename;
use Carp;
use String::Util ':all';

my @locations = (AberMUD::Location->new);
my %locations;
my %loc_map;

sub parse_zone {
    my $file = shift;
    my $zone_file = lc(basename $file);
    my $zone = $zone_file;
    $zone =~ s/\.zone$//;
    return unless -f $file;
    open my $fh, '<', $file;
    my $title;
    my $prev_line;
    my $n = 0;
    $_ = <$fh> until $_ && /^%locations/ || !$_;

    while (<$fh>) {
        $n++;
        next if m{/\*} .. m{\*/};
        next if /^%locations/;
        if (/^%zone:(\S+)/) {
            $zone = $1;
            $_ = <$fh> while $_ && !/^%locations/;
            $_ = <$fh>; # skip
        }
        next if /^\s*$/;
        last if /^%(?!locations)/;
        my ($id, $exit_info) = /(\S+)\s*(.*);/;
        $id = trim $id;
        my $loc = AberMUD::Location->new(zone => $zone);
        croak "$file -> $_" unless $id;
        $loc->id($id);
        $locations{"$id\@$zone"} = $loc;

        my @exit_nodes = split ' ', $exit_info;

        foreach my $exit_node (@exit_nodes) {
            # TODO check for doors
            my ($dir_letter, $exit_loc) = $exit_node =~/\^?(.+):(.+)/;
            $exit_loc .= "\@$zone" if $exit_loc !~ /@/;
            $exit_loc =~ s/\@(.+)/'@' . lc $1/e;
            $loc_map{"$id\@$zone"}->{$dir_letter} = $exit_loc;
        }

        $_ = <$fh> while $_ && lc($_) !~ /^lflags/;
        last unless $_;

        #do something with lflags later

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
    warn "parsed $file";
}

my $zones_dir = 'cdirt/data/ZONES';
opendir(my $dh, $zones_dir);
for (readdir($dh)) {
    next unless lc($_) =~ /\.zone$/;
    parse_zone "$zones_dir/$_";
}
closedir $dh;

my %dir = map { substr($_, 0, 1) => $_ } (qw/north south east west up down/);
my $count = 0;
while (my ($loc_id, $loc) = each %locations) {
    next unless exists $loc_map{$loc_id};
    while (my ($dir_letter, $exit) = each %dir) {
        next unless exists $loc_map{$loc_id}->{$dir_letter};
        #this is false negative with locations that depend on doors
#        die "location ID not mapped correctly!: $loc_id $dir_letter"
        $count++, next
            unless exists $locations{$loc_map{$loc_id}->{$dir_letter}};
        $loc->$exit($locations{$loc_map{$loc_id}->{$dir_letter}});
    }
#    die "$loc_id";
}

die $count;
