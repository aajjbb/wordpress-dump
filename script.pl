=pod
script.pl

script to dump all photos of an wordpress blog

usage:

perl script.pl url folder

url: url for the root folder to be dumped
folder: folder where images are going to be saved
=cut
package file;

use strict;
#use warnings;
use feature qw(say);

use WWW::Mechanize;
use HTTP::Request;
use LWP::Simple;
use Cwd;

my $memory_image = {};
my $root_url = $ARGV[0];
my $visited = 1;
my $folder = $ARGV[1];

my @image_extensions = ('.jpg', '.jpeg', '.bmp', '.png');

=doc
    returns the image extension
=cut

sub image_extension {
	my $url = shift;
	
	for my $extension (@image_extensions) {
		if ($extension eq substr $url, length($url) - length($extension), length($extension)) {
			return $extension;
		}
	}
	
	return '-1';
}

=doc
save image in $url in path $folder . $filename
=cut


sub save {
	my $url = shift;
	my $filename = shift;

	my $hifen_position = rindex($filename, '-');

	my $image_name = $filename;
	my $image_resolution_txt = (substr $filename, $hifen_position + 1);

	if ($hifen_position == -1) {
		$image_resolution_txt = '1000x1000';
	} else {
		my $len = length($image_resolution_txt);
		$image_resolution_txt = substr $image_resolution_txt, 0, $len - ($len - (rindex($image_resolution_txt, '.')));
		$image_name = (substr $filename, 0, $hifen_position) . image_extension($filename);
	}

	if (!$memory_image->{$image_name} || $image_resolution_txt > $memory_image->{$image_name}) {
		say $filename;

		getstore($url, $folder . '/' . $image_name);
		
		$memory_image->{$image_name} = $image_resolution_txt;
	}
}

=doc
	check whether $url represent an image
=cut

sub is_image {
	return 0;
}   

=doc
	Prepare next link to be sniffer
=cut

sub next_link {
	my $url = shift;
	my $ext = shift;

	my $next;
	
	if ((substr $url, -1) eq '/') {
		$next = $url . $ext;
	} else {
		$next = $url . '/' . $ext;
	}
	return $next;						
}

sub grab {
	my $url = shift;

	my $robot = WWW::Mechanize->new();
	
	$robot->get($url);
		
	for my $link ($robot->links) {
		if ($link->text !~ /Parent\ Directory/) {
			my $next = next_link($url, $link->url);
			
			if (image_extension($link->url) eq '-1') {
				grab($next);
			} else {
				save($next, $link->text);						
			}
		}
	}	
}

if (!$folder) {
	$folder = cwd();
}

mkdir($folder);

grab($root_url . '/wp-content/uploads');	
