package Asciidoc::Parser;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub parse_file {
    my ($self, $filename) = @_;
    my %content;

    open my $fh, '<:encoding(UTF-8)', $filename or die;
    while (my $line = <$fh>) {
        if ($line =~ /^---$/) {
            if (not $content{header}) {
                $content{header} = {};
                next;
            }
        }
    }

    return \%content;
}

1;

=head1 NAME

Asciidoc::Parser - parsing Asciidoc files

=head1 SYNOPSIS

=head1 AUTHOR

Gabor Szabo

=cut

