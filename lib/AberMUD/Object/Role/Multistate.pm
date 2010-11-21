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

sub set_state {
    my $self      = shift;
    my $state     = shift;
    my $last_call = shift || 0; # base case to prevent loops

    if ($state == 0) {
        $self->universe->revealing_gateway_cache->delete($self);
    }
    else {
        $self->universe->revealing_gateway_cache->insert($self);
    }

    $self->state($state);

    if ($self->gateway and !$last_call) {
        foreach my $direction (directions()) {
            my $link_method = $direction . '_link';
            next unless $self->$link_method;
            next unless $self->$link_method->multistate;
            $self->$link_method->set_state($state, 1);
        }
    }
}

around final_description => sub {
    my ($orig, $self) = @_;

    my $desc = $self->descriptions->[$self->state] // '';
    return $desc if length($desc) > 0;

    return $self->$orig(@_);
};

no Moose::Role;

1;
