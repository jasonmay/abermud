package AberMUD::Object::Role::Multistate;
use Moose::Role;
use AberMUD::Location::Util qw(directions);

has state => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has descriptions => (
    is => 'rw',
    isa => 'ArrayRef[Maybe[Str]]',
    default => sub { [] },
);

sub multistate { 1 }

around final_description => sub {
    my ($orig, $self) = @_;

    my $desc = $self->descriptions->[$self->state] // '';
    return $desc if length($desc) > 0;

    return $self->$orig(@_);
};

no Moose::Role;

1;
