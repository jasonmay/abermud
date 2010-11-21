package AberMUD::Special;
use Moose;
use AberMUD::Input::Command::Composite;

with 'MooseX::Object::Pluggable';

sub _build_plugin_app_ns { ['AberMUD::Special'] }

foreach my $command (AberMUD::Input::Command::Composite->get_command_names) {
    __PACKAGE__->meta->add_method(
        "command_$command$_" => sub { 0 },
    ) for '', '_BEFORE', '_AFTER';
}

sub BUILD {
    my $self = shift;
    $self->load_plugins('Quest::Excalibur');
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
