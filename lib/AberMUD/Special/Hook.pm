package AberMUD::Special::Hook;
use Moose;

has ['before_block', 'after_block'] => (
    is  => 'rw',
    isa => 'CodeRef',
);

has plugin_class => (
    is  => 'ro',
    isa => 'Str',
);

sub call {
    my $self = shift;
    my ($when, $universe, @args) = @_;

    my $block_method = "${when}_block";
    my $block = $self->$block_method;

    return 0 unless defined $block;

    if ($self->plugin_class) {
        Class::MOP::load_class($self->plugin_class);
        no strict 'refs';
        local ${$self->plugin_class . '::UNIVERSE'} = $universe if defined $self->plugin_class;
    }
    else {
        return $block->(@args);
    }
}

no Moose;

1;
