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

    return \%content;
}

1;

=head1 NAME

Asciidoc::Parser - parsing Asciidoc files

=head1 SYNOPSIS

=head1 AUTHOR

Gabor Szabo

=cut

