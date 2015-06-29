This is an script to download all images from a WordPress blog;

Dependencies:
	WWW::Mechanize;
	HTTP::Request;
	LWP::Simple;
	Cwd;	
	Parallel::ForkManager;

Usage:
	perl script.pl example.com/path/to/images folder

url: the url of the blog you want to dump
folder: the folder you want to store the images

TODO:
	In case of repeated images (difered by resolution) stand with maximum (or minumum) resolution	
	
CHANGES:
	Added Parallel::ForkManager to parallelize image download