package AberMUD::Special::Plugin;
use strict;
use warnings;

our $UNIVERSE;

require Package::Stash;
sub import {
    my ($caller) = caller();
    my $stash = Package::Stash->new($caller);
    $stash->add_symbol('&identify_object', sub { $UNIVERSE->identify_object(@_) });

    my @functions = qw(
        before_command
        after_command
        before_change_location
        after_change_location
        before_death
        after_death
        before_sacrifice
        after_sacrifice
    );
    for (@functions) {
        $stash->add_symbol("&$_", sub {});
    }
}
#sub identify_object { $UNIVERSE->identify_object(@_) }
#sub identify_object { $UNIVERSE->identify_object(@_) }

1;
