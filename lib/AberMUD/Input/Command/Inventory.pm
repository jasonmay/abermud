#!/usr/bin/env perl
package AberMUD::Input::Command::Inventory;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

my $command_name = lc __PACKAGE__;
$command_name =~ s/.+:://; $command_name =~ s/\.pm//;
override _build_name => sub { $command_name };

sub run {
    my $you  = shift;
    my $output = q{};

    my @objects_you_carry = grep {
        $_->can('held_by') and $_->held_by
            and $_->held_by == $you
    } @{ $you->universe->objects };

    if (@objects_you_carry) {
        $output = "Your backpack contains:\n";
        $output .= join(' ', map { $_->name } @objects_you_carry);
    }
    else {
        $output = "Your backpack contains nothing.";
    }

    $you->say(
        $you->name . " rummages through his backpack.\n",
        except => $you,
    );


    return $output;
}

__PACKAGE__->meta->make_immutable;

1;
