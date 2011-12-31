#!/usr/bin/env perl
package AberMUD::Input::Command::Drop;
use AberMUD::OO::Commands;

command drop => sub {
    my ($universe, $you, $args) = @_;
    my @args = split ' ', $args;

    if (!@args) {
        return "Drop what?";
    }
    elsif ($args[0] eq 'all') {
        for ($you->carrying_loosely) {
            $universe->change_location($_, $you->location);
            $you->drop($_);
            $_->dropped(1) if $_->flags->{getflips};
        }

        $universe->send_to_location(
            $you,
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
        } $universe->get_objects;

        if (@matching_objects) {
            $you->drop($matching_objects[0]);
            $matching_objects[0]->dropped(1) if $matching_objects[0]->dropped_description;
            $universe->change_location($matching_objects[0], $you->location);
            $universe->send_to_location(
                $you,
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
