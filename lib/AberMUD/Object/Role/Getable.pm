#!/usr/bin/env perl
package AberMUD::Object::Role::Getable;
use Moose::Role;

use AberMUD::Player;
use AberMUD::Mobile;

has weight => (
    is  => 'rw',
    isa => 'Int',
);

has size => (
    is  => 'rw',
    isa => 'Int',
);

has held_by => (
    is      => 'rw',
    isa     => 'AberMUD::Player|AberMUD::Mobile',
    clearer => '_stop_being_held',
);

no Moose::Role;

1;

