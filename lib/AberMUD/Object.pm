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

has alt_name => (
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

has flags => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
);

has examine_description => (
    is => 'rw',
    isa => 'Str',
);

# methods wrapped by roles
sub in_direct_possession { 0 }
sub on_the_ground { 1 }

sub getable     { 0 }
sub wearable    { 0 }
sub wieldable   { 0 }
sub edible      { 0 }
sub containable { 0 }
sub container   { 0 }
sub openable    { 0 }
sub closeable   { 0 }
sub gateway     { 0 }
sub pushable    { 0 }

sub o_does {
    my $self = shift;
    my $base = shift;
    $self->does("AberMUD::Object::Role::$base");
}

around name_matches => sub {
    my ($orig, $self) = (shift, shift);
    return 1 if $self->$orig(@_) or (
        $self->alt_name
        and lc($self->alt_name) eq lc($_[0])
    );

    return 0;
};

sub formatted_name {
    my $self = shift;

    my $name = $self->name;

    if ($self->edible) {
        $name = "&+G$name&*";
    }

    return $name;
}

__PACKAGE__->meta->make_immutable;

1;

