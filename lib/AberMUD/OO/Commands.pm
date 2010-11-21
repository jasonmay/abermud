package AberMUD::OO::Commands;

use Moose ();
use Moose::Exporter;

use Scalar::Util qw(reftype);

Moose::Exporter->setup_import_methods(
    with_caller => ['command'],
);

sub init_meta { shift; Moose->init_meta(@_) }

sub command {
    my ($caller, $name, $code) = (shift, shift, pop);
    my %options = @_;

    # extend method-metaclass with a new trait
    my $method_metaclass = Moose::Meta::Class->create_anon_class(
        superclasses => [ $caller->meta->method_metaclass ],
        roles        => [
            'AberMUD::Role::Command',
            'AberMUD::OO::Command::Method::Meta::Role::Specials',
        ],
    );

    # create a bare metamethod
    my $metamethod = $method_metaclass->name->wrap(
        $code,
        name         => $name,
        package_name => $caller,
    );

    # begin handling metamethod attributes
    my %command_args;

    for (qw/priority aliases/) {
        $command_args{$_} = $options{$_} if $options{$_};
    }

    # consolidate all (heh) alias aliases
    $command_args{aliases} ||= [];
    if ($command_args{alias}) {
        my @aliases = (reftype($command_args{alias}) eq 'ARRAY')
            ? @{$command_args{alias}} : ($command_args{alias});

        push @{$command_args{aliases}}, @aliases;
    }

    $metamethod->$_($command_args{$_}) for keys %command_args;

    # finally add to the caller
    $caller->meta->add_method($name => $metamethod);

}

1;
