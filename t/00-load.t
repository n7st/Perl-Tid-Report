#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Tid' ) || print "Bail out!\n";
    use_ok( 'Tid::Report' ) || print "Bail out!\n";
}

diag( "Testing Tid $Tid::VERSION, Perl $], $^X" );
