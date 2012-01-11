#!/usr/bin/env perl
package AberMUD::Object;
use KiokuDB::Class;
use Moose::Util qw(apply_all_roles);;
use namespace::autoclean;

extends 'AberMUD::InGame';

with qw(
    MooseX::Traits
);

has '+_trait_namespace' => (
    default => sub { 'AberMUD::Object::Role' },
);

has id => (
    is  => 'rw',
    isa => 'Str',
);

has alt_name => (
    is  => 'rw',
    isa => 'Str',
);

has buy_value => (
    is  => 'rw',
    isa => 'Int',
);

has description => (
    is  => 'rw',
    isa => 'Str',
);

has flags => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has examine_description => (
    is  => 'rw',
    isa => 'Str',
);

has moniker => (
    is  => 'rw',
    isa => 'Str',
);

has contained_by => (
    is       => 'rw',
    isa      => 'Maybe[AberMUD::Object]',
    clearer  => '_clear_contained_by',
    weak_ref => 1,
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
sub lockable    { 0 }
sub gateway     { 0 }
sub pushable    { 0 }
sub multistate  { 0 }
sub key         { 0 }

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

sub name_in_inv {
    my $self = shift;
    $self->getable or return '';

    my $name = $self->formatted_name;

    $self->edible    and $name  = "&+G$name&*";
    $self->wieldable and $name .= " &+M<weapon>&*";
    $self->wearable  and $name .= " &+C<armor>&*";
    $self->container and $name .= " &+y<cont>&*";

    return $name;
}

sub final_location {
    my $self = shift;

    my $o = $self;

    if ($o->getable) {
        $o = $o->contained_by
            while $o->getable and $o->contained_by;

        return $o->held_by->location
            if $o->getable and $o->held_by;
    }

    return $o->location;
}

sub in {
    my ($self, $location) = @_;

    return ($self->final_location && $self->final_location == $location);
};

around change_location => sub {
    my ($orig, $self) = (shift, shift);

    $self->location->objects_in_room->remove($self)
        if $self->location;

    $self->$orig(@_);
    $self->location->objects_in_room->insert($self);
};

sub final_description {
    my $self = shift;
    return $self->description;
}

__PACKAGE__->meta->make_immutable;

1;

