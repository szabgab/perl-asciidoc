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
    my %dom;

    open my $fh, '<:encoding(UTF-8)', $filename or die;
    my $in_header;
    my @para;
    while (my $line = <$fh>) {
        if ($line =~ /^---$/) {
            if (not $dom{header}) {
                $dom{header} = {};
                $in_header = 1;
                next;
            } else {
                $in_header = 0;
                $dom{content} = [];
                next;
            }
        }
        if ($in_header and $line =~ /^([^:]*):\s+(.*)$/) {
            $dom{header}{$1} = $2;
            next;
        }
        if ($line =~ /^(=+)\s+(.*)$/) {
            push @{$dom{content}}, {
                tag => 'h' . length($1),
                text => $2,
            };
            next;
        }

        # for now desregard any extra instructions
        if ($line =~ /^'''$/) {
            last;
        }

        if ($line =~ /^\s*$/) {
            next if not @para; # before first para?
            if (@para) {
                push @{$dom{content}}, {
                    tag => 'p',
                    cont => [ @para ],
                };
                @para = ();
                next;
            }
        }

        push @para, $self->parse_line($line);
    }

    if (@para) {
        push @{$dom{content}}, {
            tag => 'p',
            cont => [ @para ],
        };
        @para = ();
    }

    return \%dom;
}

sub parse_line {
    my ($self, $line) = @_;
    return $line;
}

1;

=head1 NAME

Asciidoc::Parser - parsing Asciidoc files

=head1 SYNOPSIS

=head1 AUTHOR

Gabor Szabo

=cut

