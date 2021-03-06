=pod
script.pl

script to dump all photos of an wordpress blog

usage:

perl script.pl url folder

url: url for the root folder to be dumped
folder: folder where images are going to be saved
=cut
package wordpress_dump;

use strict;
#use warnings;
use feature qw(say);

use WWW::Mechanize;
use HTTP::Request;
use LWP::Simple;
use Cwd;

use Parallel::ForkManager;

my $MAX_PROCESS = 5;

my $memory_image = {};
my $visited = {};
my $root_url = $ARGV[0];
my $folder = $ARGV[1];
my $pm = new Parallel::ForkManager($MAX_PROCESS);

=doc
set image parallel download info (messages and max number of process)
=cut
sub setup_parallel {
	$pm->set_max_procs($MAX_PROCESS);

	$pm->run_on_start(
		sub {
			my ($name) = @_;
			#say "Starting Photo: $name"
		});
	
	$pm->run_on_finish(
		sub {
			my ($name) = @_;
			say "Finishing NAME: $name"
		});	
}


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

	if (!$memory_image->{$image_name} && $hifen_position == -1) {
		$pm->start($image_name) and next;
	
		getstore($url, $folder . '/' . $image_name);
		$memory_image->{$image_name} = $image_resolution_txt;
		
		$pm->finish($image_name);

		say "Done ", $filename;
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

	if ($visited->{$url}) {
		return;
	}

	$visited->{$url} = 1;
		
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

#create folder to hold images
mkdir($folder);
#setup parallel image download
setup_parallel;

grab($root_url);
	


