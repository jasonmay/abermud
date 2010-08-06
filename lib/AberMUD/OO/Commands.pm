package AberMUD::OO::Commands;
use Moose ();
use Moose::Exporter;

sub init_meta {
    my $self    = shift;
    my %options = @_;

    $options{metaclass} = 'AberMUD::Meta::Class::Command::Composite';

    return Moose->init_meta(%options);
}

sub command {
    my $self = shift;
    my $name = shift;
    my $code = pop;
    my %options = @_;

    my %command_args = (code => $code);

    $comamnd_args{priority} = $options{priority} if $options{priority};

    my $command = AberMUD::Input::Command->new(%command_args);
    $self->meta->add_command_entry($name => $command);

}


1;
