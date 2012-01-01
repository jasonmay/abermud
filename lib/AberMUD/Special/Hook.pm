package AberMUD::Special::Hook;
use Moose;

has ['before_block', 'after_block'] => (
    is  => 'rw',
    isa => 'CodeRef',
);

sub call {
    my $self = shift;
    my ($when, @args) = @_;

    my $block_method = "${when}_block";
    my $block = $self->$block_method;

    return 0 unless defined $block;

    return $block->(@args);
}

no Moose;

1;
