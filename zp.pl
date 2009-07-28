#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use AberMUD::Util;
use AberMUD::Location;
use File::Basename;

my @locations = (AberMUD::Location->new);
my %locations;
my %loc_map;

sub parse_zone {
    my $file = shift;
    my $zone = basename $file;
    $zone =~ s/\.zone$//;
    return unless -f $file;
    open my $fh, '<', $file;
    my $title;
    my $prev_line;
    my $n = 0;
    while (<$fh>) {
        $n++;
        next if m{/\*} .. m{\*/};
        if (/^%locations/ .. /^%(?!locations)/) {
            next if /^%locations/;
            if (/^lflags.*{(.*)}/) {
                # something
            }
            elsif($prev_line && $prev_line =~ /^lflags/ && (/.+\^/ .. /^\^/)) {
                next if ($prev_line && $prev_line !~ /^lflags/);
                if (/^\^/) {
                    if (!defined $locations[-1]->id) {
                        die "zone parsing failed to grab location ID";
                    }
                    push @locations, AberMUD::Location->new(zone => $zone);
                }
                else { 
                    if (/(.+)\^/) {
                        warn "title: $_";
                        $locations[-1]->title($1);
                    }
                    else {
                        warn "desciprion: " . substr($_, 0, 40);
                        my $loc = $locations[-1];
                        $locations[-1]->description(($loc->description||'') . $_);
                    }
                    next; # don't mark previous line
                }
            }
            else {
                next if /^\s*$/;
                if ($prev_line =~ /^\^/) {
                    my ($location, $exit_data) = /\s*(\S+)\s*(.+)/;
                    $locations[-1]->id($location);
                    warn "ID being set: $_";
                    my %exits = map { (lc substr($_, 0, 1)) => lc($_) }
                    @{AberMUD::Location->directions};

                    my @dir_nodes = split ' ', $exit_data;
                    for my $dir_node (@dir_nodes) {
                        next unless $dir_node =~ /:/;
                        my ($exit_letter, $id) = $dir_node =~ /(\w+):\^?(\w+)/;
                        die "$dir_node" unless exists $exits{$exit_letter};
                        my $exit = $exits{$exit_letter};
                        $loc_map{$location}->{$exit} = $id;
                    }
                    $locations{$location} = $locations[-1];
                }
                else {
                    # probably stuff like altitude etc
                }
            }
        }
        $prev_line = $_;
    }
    close $fh;
    for my $loc (@locations) {
        if (!defined $loc->id) {
#            warn "oh shit!";
            next;
        }
        for (@{AberMUD::Location->directions}) {
            next unless exists $loc_map{$loc->id};
            next unless exists $loc_map{$loc->id}->{$_};

            my $loc_id = $loc_map{$loc->id}->{$_};
            next unless exists $locations{$loc_id};
            #warn sprintf("$_ of %s is %s", $loc->id, $loc_id);
            $loc->$_($locations{$loc_id});
        }
    }
}

my $zones_dir = 'cdirt/data/ZONES';
opendir(my $dh, $zones_dir);

for (readdir($dh)) {
    parse_zone "$zones_dir/$_";
}

closedir $dh;

die;
