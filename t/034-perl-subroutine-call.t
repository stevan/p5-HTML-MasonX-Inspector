#!/usr/bin/env perl

use strict;
use warnings;

use Path::Tiny ();

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTML::MasonX::Inspector');
    use_ok('HTML::MasonX::Inspector::Query::PerlCode');
}

my $MASON_FILE_NAME = '050-mason-critic-policy.html';
my $COMP_ROOT       = Path::Tiny->tempdir;

$COMP_ROOT->child( $MASON_FILE_NAME )->spew(q[
<%once>
use Scalar::Util 'blessed';
use List::Util   qw[ max uniq ];
</%once>
<%init>
my $x;
if ( Scalar::Util::looks_like_number( $x ) ) {
    $x = max( 100, $x )
        if blessed( $x ) && $x->isa('FooBar');
}
</%init>
]);

subtest '... testing querying for subroutine calls' => sub {

    my $i = HTML::MasonX::Inspector->new( comp_root => $COMP_ROOT );
    isa_ok($i, 'HTML::MasonX::Inspector');

    my $state = $i->get_compiler_inspector_for_path( $MASON_FILE_NAME );
    isa_ok($state, 'HTML::MasonX::Inspector::Compiler');

    my $comp = $state->get_main_component;
    isa_ok($comp, 'HTML::MasonX::Inspector::Compiler::Component');

    is($comp->name, $MASON_FILE_NAME, '... got the expected name');

    my $blocks = $comp->blocks;
    isa_ok($blocks, 'HTML::MasonX::Inspector::Compiler::Component::Blocks');

    ok($blocks->has_once_blocks, '... we have once blocks');
    ok($blocks->has_init_blocks, '... we have init blocks');
    ok(!$blocks->has_filter_blocks, '... we do not have filter blocks');
    ok(!$blocks->has_shared_blocks, '... we do not have shared blocks');
    ok(!$blocks->has_cleanup_blocks, '... we do not have cleanup blocks');

    subtest '... testing the init block' => sub {

        my ($init) = @{ $blocks->init_blocks };
        isa_ok($init, 'HTML::MasonX::Inspector::Compiler::Component::PerlCode');

        subtest '... testing the subroutine calls' => sub {

            my @subcalls = HTML::MasonX::Inspector::Query::PerlCode->find_subroutine_calls( $init );
            is(scalar(@subcalls), 3, '... got the two calls');

            is($subcalls[0]->name, 'Scalar::Util::looks_like_number', '... got the name we expected');
            is($subcalls[0]->line_number, 8, '... got the line_number we expected');
            is($subcalls[0]->column_number, 6, '... got the column_number we expected');

            is($subcalls[1]->name, 'max', '... got the name we expected');
            is($subcalls[1]->line_number, 9, '... got the line_number we expected');
            is($subcalls[1]->column_number, 10, '... got the column_number we expected');

            is($subcalls[2]->name, 'blessed', '... got the name we expected');
            is($subcalls[2]->line_number, 10, '... got the line_number we expected');
            is($subcalls[2]->column_number, 12, '... got the column_number we expected');

        };

    };

};

done_testing;

