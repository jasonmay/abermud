package AberMUD::Web::View::HTML;

use strict;
use warnings;
use parent 'Catalyst::View::TD';

# Unless auto_alias is false, Catalyst::View::TD will automatically load all
# modules below the AberMUD::Web::Templates::HTML namespace and alias their
# templates into AberMUD::Web::Templates::HTML. It's simplest to create your
# template classes there. See the Template::Declare documentation for a
# complete description of its init() parameters, all of which are supported
# here.

__PACKAGE__->config(
    dispatch_to     => [qw(AberMUD::Web::Templates::HTML)],
    # auto_alias      => 1,
    # strict          => 1,
    # postprocessor   => sub { ... },
    # around_template => sub { ... },
);

=head1 NAME

AberMUD::Web::View::HTML - HTML View for AberMUD::Web

=head1 DESCRIPTION

TD View for AberMUD::Web. Templates are written in the
AberMUD::Web::Templates::HTML namespace.

=head1 SEE ALSO

L<AberMUD::Web>

=head1 AUTHOR

jasonmay

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
