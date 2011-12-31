package AberMUD::Universe::Role::Mobile;
use Moose::Role;
use KiokuDB::Set;
use KiokuDB::Util qw(set);
use Time::HiRes ();
use namespace::autoclean;
use AberMUD::Location::Util 'directions';

has mobiles => (
    is  => 'rw',
    isa => 'KiokuDB::Set',
    handles => {
        get_mobiles => 'members',
    },
    default => sub { set() },
);

has traversable_mobiles => (
    is  => 'rw',
    isa => 'KiokuDB::Set',
    builder => '_build_traversable_mobiles',
    lazy    => 1,
    handles => {
        get_traversable_mobiles => 'members',
    },
);

sub _build_traversable_mobiles {
    my $self = shift;

    return set( grep { $_->speed and $_->speed > 0 } $self->get_mobiles );
}

around advance => sub {
    my $orig = shift;
    my $self = shift;

    my @moving_mobiles = grep {
        $self->roll_to_move($_)
    } $self->get_traversable_mobiles;

    $self->move_mobile($_) for @moving_mobiles;

    return $self->$orig(@_);
};

sub roll_to_move {
    my $self = shift;
    my $mobile = shift;
    return 0 unless $mobile->speed; # don't move if speed is zero

    my $go = !!( rand(30) < $mobile->speed );
    return $go;
}

sub move_mobile {
    my $self = shift;
    my ($mobile) = @_;

    my @dirs = grep { $self->can_move($mobile, $_) } directions();

    return $self unless @dirs;

    my $way = $dirs[rand @dirs];

    $self->move($mobile, $way);
}

1;
