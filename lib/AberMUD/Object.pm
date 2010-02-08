#!/usr/bin/env perl
package AberMUD::Object;
use KiokuDB::Class;
use Moose::Util qw(apply_all_roles);;
use Data::Dumper;
use namespace::autoclean;

with qw(
    MooseX::Traits
    AberMUD::Role::InGame
);

has name => (
    is => 'rw',
    isa => 'Str',
);

has buy_value => (
    is => 'rw',
    isa => 'Int',
);

has description => (
    is => 'rw',
    isa => 'Str',
);

has examine_description => (
    is => 'rw',
    isa => 'Str',
);

has ungetable => (
    is => 'bare',
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    # pass in ungetable => 1 and it won't load the Getable role
    # otherwise it loads the role. Because I mean, who doesn't
    # like taking stuff!
    if (!$args->{ungetable}) {
        my $getable_role = 'AberMUD::Object::Role::Getable';
        apply_all_roles($self, $getable_role);
    }
}

__PACKAGE__->meta->make_immutable;

1;

