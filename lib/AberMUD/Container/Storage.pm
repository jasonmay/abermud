package AberMUD::Container::Storage;
use Moose;
extends 'Bread::Board::Container';

use Bread::Board;

has dsn => (
    is      => 'ro',
    isa     => 'Str',
    default => AberMUD::Util::dsn,
);

has serializer => (
    is      => 'ro',
    isa     => 'Str',
    default => 'yaml',
);

has create => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

sub BUILD {
    my $self = shift;

    my $c = container $self => as {
        service dsn        => $self->dsn;
        service serializer => $self->serializer;
        service create     => $self->create;

        service object => (
            class => 'AberMUD::Storage',
            lifecycle => 'Singleton',
            block => sub {
                my $service = shift;

                return AberMUD::Storage->new(
                    dsn        => $service->param('dsn'),
                    extra_args => {
                        serializer => $service->param('serializer'),
                        create     => $service->param('create'),
                    },
                );
            },
            dependencies => [ qw(dsn serializer create) ],
        );
    };

    return $c;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
