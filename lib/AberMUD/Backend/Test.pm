package AberMUD::Backend::Test;
use Moose;

with 'AberMUD::Backend';

__PACKAGE__->meta->make_immutable;
no Moose;

1;
