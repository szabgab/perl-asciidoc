use strict;
use warnings;
use Test::More;
use JSON;
use Asciidoc::Parser;

my @cases = glob "t/input/*.adoc";
#diag explain \@cases;

plan tests => 1 + @cases;

my $p = Asciidoc::Parser->new;
isa_ok $p, 'Asciidoc::Parser';

foreach my $infile (@cases) {
    (my $outfile = $infile) =~ s{/input/([^/]*)\.adoc$}{/output/$1.json};
    my $parsed = $p->parse_file($infile);
    my $expected = decode_json slurp($outfile);
    is_deeply $parsed, $expected, $infile;
}

sub slurp {
    my ($filename) = @_;
    local $/ = undef;
    open my $fh, '<:encoding(UTF-8)', $filename or die;
    return scalar <$fh>;
}
