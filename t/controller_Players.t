use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'AberMUD::Web' }
BEGIN { use_ok 'AberMUD::Web::Controller::Players' }

ok( request('/players')->is_success, '/players equest should succeed' );
ok( request('/players/id')->is_success, '/players/id Request should succeed' );
ok( request('/players/id/foo/reset_password')->is_success, '/players/id/foo/reset_password request should succeed' );
done_testing();
