package AberMUD::Backend::Test::Connection;
use Moose;

with 'AberMUD::Connection';

has output_queue => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    traits  => ['Array'],
    handles => { push_output => 'push' },
);

sub get_output { shift @{ shift->output_queue } }

sub flush_output {
    my $self = shift;
    my $player = $self->associated_player or return;

    my $buffer = $player->output_buffer;
    $player->clear_output_buffer;
    return unless length($buffer);

    $self->push_output($buffer);
}

no Moose;

1;
