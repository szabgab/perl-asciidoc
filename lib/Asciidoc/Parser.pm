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

        if ($line =~ /^\[source(,\s*(\w+))?\]\s*$/) {
            $self->{verbatim} = $2;
            next;
        }
        if ($line eq '----') {
            if ($self->{in_verbatim}) {
                push @{$self->{dom}{content}}, {
                    tag => 'code',
                    cont => $self->{verbatim_cont},
                    lang => $self->{verbatim},
                };
                $self->{in_verbatim} = 0;
                delete $self->{verbatim};
                next;
            }
            if (exists $self->{verbatim}) {
                $self->{in_verbatim} = 1;
                $self->{verbatim_cont} = '';
                next;
            }
        }
        if ($self->{in_verbatim}) {
            $self->{verbatim_cont} .= "$line\n";
            next;
        }

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

1;

=head1 NAME

Asciidoc::Parser - parsing Asciidoc files

=head1 SYNOPSIS

=head1 AUTHOR

Gabor Szabo

=cut

