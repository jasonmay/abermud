package AberMUD::Object::Role::BodyPart;
use Moose::Role;

has detached => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
);

has health => (
    is      => 'rw',
    isa     => 'Int',
    default => 100,
    clearer => '_reset_health',
);

# right_leg, etc.
has part_name => (
    is      => 'rw',
    isa     => 'Int',
    default => 100,
);

# "right leg", etc.
has display_part_name => (
    is      => 'rw',
    isa     => 'Int',
    default => 100,
);

has owner => (
    is       => 'ro',
    does     => 'AberMUD::Role::Killable',
    required => 1,
);

sub first_person_severed_description {
    my $self = shift;
    my %args = @_;

    # TODO varying rot descriptions
    my $desc = sprintf(
        "Your severed %s lies on the ground here.",
        $self->name
    );

    return $desc;
}

around final_description => sub {
    my ($orig, $self) = (shift, shift);

    return undef unless $self->detached;

    # TODO varying rot descriptions
    my $desc = sprintf(
        "%s's severed %s lies on the ground here.",
        $self->owner->name, $self->name
    );

    return $desc;
};

sub take_damage {
    my $self   = shift;
    my ( $damage ) = @_;

    my $new_health = $self->health - $damage;

    $new_health = 0 if $new_health < 0;

    $self->health($new_health);

    if ($new_health == 0) {
        $self->detached(1);
        if ($self->owner->isa('AberMUD::Player')) {
            $self->owner->say(
                sprintf(
                    "%s's severed %s falls to the ground.",
                    $self->owner->display_name, $self->name,
                ),
                except => $self->owner,
            );

            $self->owner->say(
                sprintf(
                    "Your severed %s falls to the ground.",
                    $self->name,
                ),
            );
        }
    }
}

no Moose::Role;

1;
