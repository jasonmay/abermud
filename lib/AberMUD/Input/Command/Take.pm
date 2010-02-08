#!/usr/bin/env perl
package AberMUD::Input::Command::Take;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

my $command_name = lc __PACKAGE__;
$command_name =~ s/.+:://; $command_name =~ s/\.pm//;
override _build_name => sub { $command_name };

sub run {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args;

    if (!@args) {
        return "Take what?";
    }
    elsif (@args == 1) {
        my @matching_objects = grep {
            $_->location == $you->location
            and lc($_->name) eq lc($args[0])
        } @{ $you->universe->objects };

        if (@matching_objects) {
            if ($matching_objects[0]->can('held_by')) {
                $matching_objects[0]->held_by($you);
                $you->say(
                    sprintf(
                        "%s picks up a %s.\n",
                        $you->name, $matching_objects[0]->name
                    ),
                    except => $you,
                );
                return sprintf("You take the %s.", $matching_objects[0]->name);
            }
        }

        return "No object of that name is here.";
    }
    elsif (@args == 3 and lc($args[1]) eq 'from') {
        return "Not supported yet.";
    }
    else {
        return "That command syntax is not recognized.";
    }
}

__PACKAGE__->meta->make_immutable;

1;
