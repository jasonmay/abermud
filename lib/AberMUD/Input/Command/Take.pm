#!/usr/bin/env perl
package AberMUD::Input::Command::Take;
use Moose;
use namespace::autoclean;
extends 'AberMUD::Input::Command';

sub run {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args;

    if (!@args) {
        return "Take what?";
    }
    elsif (@args == 1) {
        if ($args[0] eq 'all') {
            my @objects_you_can_take = grep {
            $_->location == $you->location
                and $_->can('held_by')
                and !$_->held_by
            }  $you->universe->objects;

            $_->held_by($you) for @objects_you_can_take;

            $you->say(
                sprintf(
                    "%s takes everything he can.\n",
                    $you->name
                ),
                except => $you,
            ) if @objects_you_can_take;


            return @objects_you_can_take
                ? "You take everything you can."
                : "There is nothing here for you to take.";
        }
        my @matching_objects = grep {
            $_->location == $you->location
            and lc($_->name) eq lc($args[0])
        } $you->universe->objects;

        if (@matching_objects) {
            if ($matching_objects[0]->can('held_by')) {
                if ($matching_objects[0]->held_by) {
                    return "You are already carrying that!"
                        if $matching_objects[0]->held_by == $you;

                    return "The " . $matching_objects[0]->name
                        . " is not on the ground for you to take.";
                }
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
