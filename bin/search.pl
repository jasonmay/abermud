#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use DBD::SQLite;
use YAML;
use JSON;

my $dbh = DBI->connect('dbi:SQLite:dbname=abermud');

my $sth = $dbh->prepare(qq[select data from entries where data like '%' || ? || '%']);

while (<>) {chomp;
    $sth->execute($_) or do { warn $dbh->errstr; next };
    my $row = $sth->fetchrow_hashref;
    next unless $row;
    my $obj = from_json($row->{data});
    warn YAML::Dump($obj);
}
