#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DPKG::ShlibDeps::Resolve' ) || print "Bail out!\n";
}

diag( "Testing DPKG::ShlibDeps::Resolve $DPKG::ShlibDeps::Resolve::VERSION, Perl $], $^X" );
