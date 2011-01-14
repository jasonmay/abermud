package AberMUD::Role::Humanoid;
use Moose::Role;

use AberMUD::Object::Util qw(bodyparts);

has bodyparts => (
    is      => 'rw',
    isa     => 'ArrayRef[AberMUD::Object]',
    lazy    => 1,
    builder => '_build_bodyparts',
);

sub _build_bodyparts {
    my $self = shift;

    return [
        map {
            AberMUD::Object->with_traits(qw/Getable BodyPart/)->new(
                name => $_,
                owner => $self,
            )
        } bodyparts()
    ];
}

no Moose::Role;

1;
