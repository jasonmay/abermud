package AberMUD::Special;
use Moose;
use Module::Pluggable search_path => ['AberMUD::Special::Plugin'];

use AberMUD::Special::Hook;
use AberMUD::Special::Hook::Command;
use AberMUD::Special::Hook::Death;
use AberMUD::Special::Hook::Sacrifice;

use Scalar::Util 'weaken';

has hooks => (
    is  => 'ro',
    isa => 'HashRef[ArrayRef[AberMUD::Special::Hook]]',
    default => sub { {} },
);

sub call_hooks {
    my $self = shift;
    my %args = @_;

    my $type = $args{type};
    my $when = $args{when};

    my $hook_args = $args{arguments};
    my @hooks = @{ $self->hooks->{$type} || [] };

    my $final_interrupt = 0;
    my @results = ();
    foreach my $hook (@hooks) {
        my ($interrupt, $result) = $hook->call($when, @$hook_args);
        if ($interrupt) {
            $final_interrupt = 1;
        }
        push @results, $result if defined $result;
    }

    return ($final_interrupt, @results);
}

sub load_plugins {
    my $self = shift;
    my %args = @_;

    my $wself = $self; weaken $wself;
    my $command_block = sub {
        my $when = shift;
        return sub {
            my ($name, $block) = @_;
            my $hook = AberMUD::Special::Hook::Command->new(
                command_name    => $name,
                "${when}_block" => $block,
            );
            $self->hooks->{command} ||= [];
            push @{$self->hooks->{command}}, $hook;
        };
    };

    my $death_block = sub {
        my $when = shift;
        return sub {
            my ($victim, $block) = @_;
            my $hook = AberMUD::Special::Hook::Death->new(
                victim          => $victim,
                "${when}_block" => $block,
            );
            $self->hooks->{death} ||= [];
            push @{$self->hooks->{death}}, $hook;
        };
    };

    my $sacrifice_block = sub {
        my $when = shift;
        return sub {
            my ($object, $block) = @_;
            my $hook = AberMUD::Special::Hook::Sacrifice->new(
                object          => $object,
                "${when}_block" => $block,
            );
            $self->hooks->{sacrifice} ||= [];
            push @{$self->hooks->{sacrifice}}, $hook;
        };
    };

    foreach my $special_class (__PACKAGE__->plugins) {
        Class::MOP::load_class($special_class);
        no strict 'refs';
        local ${"${special_class}::UNIVERSE"} = $args{universe};
        local *{"${special_class}::before_command"}
            = $command_block->('before');
        local *{"${special_class}::after_command"}
            = $command_block->('after');
        local *{"${special_class}::before_death"}
            = $death_block->('before');
        local *{"${special_class}::after_death"}
            = $death_block->('after');
        local *{"${special_class}::before_sacrifice"}
            = $sacrifice_block->('before');
        local *{"${special_class}::after_sacrifice"}
            = $sacrifice_block->('after');

        $special_class->setup(%args);
    }
}

no Moose;

1;
