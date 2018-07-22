use strict;
use warnings;
use Test::More;
use Asciidoc::Parser;

plan tests => 1;

my $p = Asciidoc::Parser->new;
isa_ok $p, 'Asciidoc::Parser';

