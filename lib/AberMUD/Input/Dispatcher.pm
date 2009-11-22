#!/usr/bin/env perl
package AberMUD::Input::Dispatcher;
use Moose;
use namespace::autoclean;
extends 'Path::Dispatcher';

__PACKAGE__->meta->make_immutable;

require AberMUD::Input::Dispatcher::Rule;

1;

