#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;
use JSON;

for my $f (<*.json>) {
    next unless $f =~ /ghenna/;
    my $contents = read_file($f);
    my $data = JSON::decode_json($contents);
    while (my ($name, $obj) = each $data->{obj}) {
        $obj->{oflags} = [] unless ref($obj->{oflags}) eq 'ARRAY';
        if (
            (!grep { lc($_) eq 'wearable' } @{ $obj->{oflags}|| []})
            &&
            ($obj->{location} =~ /^worn_by/i)
        ) {
            warn "[$f] $name should be wearable\n";
        }
        if (
            (!grep { lc($_) eq 'container' } @{ $obj->{oflags}|| []})
            &&
            ($obj->{location} =~ /^worn_by/i)
        ) {
            warn "[$f] $name should be wearable\n";
        }
    }
}
