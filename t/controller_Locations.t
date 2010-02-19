use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'AberMUD::Web' }
BEGIN { use_ok 'AberMUD::Web::Controller::Locations' }

ok( request('/locations')->is_success, 'Request should succeed' );
done_testing();
