package AberMUD::Web::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt2',
    render_die => 1,
);

=head1 NAME

AberMUD::Web::View::TT - TT View for AberMUD::Web

=head1 DESCRIPTION

TT View for AberMUD::Web.

=head1 SEE ALSO

L<AberMUD::Web>

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
