#!/usr/bin/env perl
package AberMUD::Input::Command::Drop;
use AberMUD::OO::Commands;

command drop => sub {
    my $you  = shift;
    my $args = shift;
    my @args = split ' ', $args;

    if (!@args) {
        return "Drop what?";
    }
    elsif ($args[0] eq 'all') {
        for ($you->carrying_loosely) {
            $_->change_location($you->location);
            $_->_stop_being_held;
            $_->dropped(1) if $_->flags->{getflips};
        }

        $you->say(
            sprintf(
                "%s drops everything he can.\n",
                $you->name,
            ),
            except => $you,
        );
        return "You drop everything you can.";
    }
    else {
        my @matching_objects = grep {
            $_->can('held_by') and $_->held_by
            and $_->held_by == $you
            and lc($_->name) eq lc($args[0])
        } $you->universe->get_objects;

        if (@matching_objects) {
            $matching_objects[0]->_stop_being_held;
            $matching_objects[0]->dropped(1) if $matching_objects[0]->dropped_description;
            $matching_objects[0]->change_location($you->location);
            $you->say(
                sprintf(
                    "%s drops a %s.\n",
                    $you->name, $matching_objects[0]->name
                ),
                except => $you,
            );
            return sprintf("You drop the %s.", $matching_objects[0]->name);
        }

        return "No object of that name is here.";
    }
};

__PACKAGE__->meta->make_immutable;

1;
