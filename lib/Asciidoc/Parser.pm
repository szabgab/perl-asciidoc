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
    $self->{dom} = {};

    open my $fh, '<:encoding(UTF-8)', $filename or die;
    my $in_header;
    $self->{para} = '';
    while (my $line = <$fh>) {
        chomp $line;

        $self->parse_comment($line) and next;

        if ($line =~ /^---$/) {
            if (not $self->{dom}{header}) {
                $self->{dom}{header} = {};
                $in_header = 1;
                next;
            } else {
                $in_header = 0;
                $self->{dom}{content} = [];
                next;
            }
        }
        if ($in_header and $line =~ /^([^:]*):\s+(.*)$/) {
            $self->{dom}{header}{$1} = $2;
            next;
        }

        # for now we totally skip any ifdef section
        if ($line =~ /^ifdef::/) {
            $self->{in_def} = 1;
            next;
        }
        if ($self->{in_def}) {
            if ($line =~ /^endif::/) {
                $self->{in_def} = 0;
            }
            next;
        }

        if ($line =~ /^(=+)\s+(.*)$/) {
            push @{$self->{dom}{content}}, {
                tag => 'h' . length($1),
                text => $2,
            };
            next;
        }

        $self->handle_source($line, 'code') and next;
        $self->handle_source($line, 'special') and next;

        if ($line =~ /^\*\s+(.*)/) {
            push @{$self->{dom}{content}}, {
                tag => 'li',
                cont => [ $self->parse_line($line) ],
            };
            next;
        }

        # for now desregard any extra instructions
        if ($line =~ /^'''$/) {
            last;
        }

        if ($line =~ /^\s*$/) {
            # before first para?
            if ($self->{para}) {
                $self->save_para and next;
            }
            next;
        }

        #push @{$self->{para}}, ' ' if @{ $self->{para} };
        $self->{para} .= ' ' if $self->{para};
        $self->{para} .= $line;
        #push @{$self->{para}}, $self->parse_line($line);
    }

    $self->save_para;

    return $self->{dom};
}

sub parse_comment {
    my ($self, $line) = @_;
    if ($self->{in_comment}) {
        if ($line =~ m{^////$}) {
            $self->{in_comment} = 0;
        }
        return 1;
    }
    if ($line =~ m{^////$}) {
        $self->{in_comment} = 1;
        return 1;
    }
    return;
}


sub save_para {
    my ($self) = @_;
    return if not $self->{para};

    push @{$self->{dom}{content}}, {
        tag => 'p',
        cont => [ $self->parse_line($self->{para}) ],
    };
    $self->{para} = '';
    return 1;
}


sub parse_line {
    my ($self, $line) = @_;
    if ($line =~ /^(.*)_(\w+)_(.*)$/) {
        my  ($pre, $cont, $post) = ($1, $2, $3);
        return (
            $self->parse_line($pre),
            {
                tag => 'b',
                cont => $cont,
            },
            $self->parse_line($post),
        );
    }

    # link:../install[Other Link]
    if ($line =~ /^(.*) link: ([^\[]+)  \[([^\]]+)\]   (.*)$/x) {
        my ($pre, $link, $anchor, $post) = ($1, $2, $3, $4);
        return (
            $self->parse_line($pre),
            {
                tag => 'a',
                link => $link,
                cont => $anchor,
            },
            $self->parse_line($post),
        );
    }

    # <<doc/developer#,Extend Asciidoc>>
    if ($line =~ /^(.*)<<([^,>]*),([^>]*)>>(.*)$/) {
        my  ($pre, $link, $anchor, $post) = ($1, $2, $3, $4);
        return (
            $self->parse_line($pre),
            {
                tag => 'a',
                link => $link,
                cont => $anchor,
            },
            $self->parse_line($post),
        );
    }
    return $line;
}

sub handle_source {
    my ($self, $line, $type) = @_;
    my $re = qr/^\[source(?:,\s*(\w+))?\]\s*$/;
    my $sep = '----';

    if ($type eq 'special') {
        $re = qr/^\[(CAUTION|NOTE)\]$/;
        $sep = '====';
    }

    if ($line =~ $re) {
        $self->{$type} = $1;
        return 1;
    }
    if ($line eq $sep) {
        if ($self->{"in_$type"}) {
            push @{$self->{dom}{content}}, {
                tag => $type,
                cont => $self->{"cont_$type"},
                lang => $self->{$type},
            };
            $self->{"in_$type"} = 0;
            delete $self->{$type};
            return 1;
        }
        if (exists $self->{$type}) {
            $self->{"in_$type"} = 1;
            $self->{"cont_$type"} = '';
            return 1;
        }
    }
    if ($self->{"in_$type"}) {
        $self->{"cont_$type"} .= "$line\n";
        return 1;
    }

    return;
}

sub parse_file2 {
    my ($self, $filename) = @_;

use Regexp::Grammars;
my $parser = qr {
    <nocontext:>
    <ASCIIDOC>

    <rule: ASCIIDOC> <Header> <Ifdef> <Body>

    <rule: Header> ^---$ <[Pair]>* ^---$
    <rule: Pair> ^<Key>: <Value>$
    <rule: Body> .*

    <rule: Ifdef> ^ifdef:: .*?  endif::\[\]$

    <token: Key> \w+
    <token: Value> .*?

}xsm;

    my $input;
    {
        open my $fh, '<:encoding(UTF-8)', $filename or die;
        local $/ = undef;
        $input = <$fh>;
    }

    if ($input =~ $parser) {
        return \%/;
    }
    return;
}

1;

=head1 NAME

Asciidoc::Parser - parsing Asciidoc files

=head1 SYNOPSIS

=head1 AUTHOR

Gabor Szabo

=cut

