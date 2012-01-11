package AberMUD::Universe::Role::WithSystemData;
use Moose::Role;

has corpse_location => (
    is        => 'ro',
    isa       => 'AberMUD::Location',
    builder   => '_build_corpse_location',
    lazy      => 1,
    #weak_ref => 1,
);

sub _build_corpse_location {
    my $self = shift;

    return AberMUD::Location->new(
        universe    => $self,
        title       => 'Dead Zone',
        description => q[This is the zone for corpses. ] .
                       q[Mortals do not belong here.],
    );
}

has eaten_location => (
    is        => 'ro',
    isa       => 'AberMUD::Location',
    builder   => '_build_eaten_location',
    lazy      => 1,
    #weak_ref => 1,
);

sub _build_eaten_location {
    my $self = shift;

    return AberMUD::Location->new(
        title       => 'Eaten Zone',
        description => q[This is the zone for eaten food. ] .
                       q[Mortals do not belong here.],
    );
}

has pit_location => (
    is        => 'ro',
    isa       => 'AberMUD::Location',
    builder   => '_build_pit_location',
    lazy      => 1,
    #weak_ref => 1,
);

sub _build_pit_location {
    my $self = shift;

    return AberMUD::Location->new(
        title       => 'The Sacrificial Pit',
        description => q[This is the sacrificial pit. ] .
                       q[Mortals do not belong here.],
    );
}

has pit_objects => (
    is      => 'ro',
    isa     => 'ArrayRef[AberMUD::Object]',
    builder => '_build_pit_objects',
    lazy    => 1,
);

sub _build_pit_objects {
    my $self = shift;

    my @objs = $self->get_objects;

    my @pit_objects = ();

    # FIXME objects should have a 'pit' flag
    for my $obj (@objs) {
        next unless $obj->zone->name eq 'start';
        next unless lc($obj->name) =~ /pit/;
        push @pit_objects, $obj;
    }

    return \@pit_objects;
}

no Moose::Role;

1;
