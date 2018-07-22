use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Asciidoc::Parser',
	AUTHOR        => q{Gabor Szabo <szabgab@cpan.org>},
	VERSION_FROM  => 'lib/Asciidoc/Parser.pm',
	ABSTRACT_FROM => 'lib/Asciidoc/Parser.pm',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {
		'Test::More'          => 0,
	},
);
