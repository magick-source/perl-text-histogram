package Text::Histogram;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Exporter);

our @EXPORT_OK = qw(histogram);

sub histogram {
	my ($data, $opts) = @_;

	unless (ref $data) {
		$data = [@_];
		$opts = {};
	}
	$opts->{bins} ||= 8;
	$opts->{histogram_size} ||= 50;

	my $vcnt = scalar @$data;
	my @data = sort { $a <=> $b } @$data;

	my ($min, $max, $rmin, $rmax) = _check_outliers($vcnt, $opts, @data);

	my ($scale, $binsize, %bins)
			= _get_frequency($min,$max,$rmin,$rmax, $opts, \@data);

	my $hist = "";
	my $hsize = $opts->{histogram_size};
	if ($min != $rmin) {
		my $freq = _ceil(($bins{'min'}||0)/$scale);
		$hist.= sprintf "%8d %-${hsize}s - %6d\n",
				$min,
				"#" x $freq,
				($bins{'min'}||0);
	}
	for (my $i = _ceil(($rmin+1)/$binsize)-1;
				$i <= _ceil(($rmax+1)/$binsize)-1; $i++) {
		my $freq = _ceil(($bins{$i}||0)/$scale);
		my $val = $i*$binsize;
		$val = $rmin if $val < $rmin;
		$freq = "#" x $freq;
		$hist .= sprintf "%8d %-${hsize}s - %6d\n",
				$val,
				$freq,
				($bins{$i}||0)
	}
	if ($max != $rmax) {
		my $freq = _ceil(($bins{'max'}||0)/$scale);
		$hist.= sprintf "%8d %-${hsize}s - %6d\n",
				$rmax+1,
				"#" x $freq,
				($bins{'max'}||0);	
	}
	return $hist;
}

sub _get_frequency {
	my ($min, $max, $rmin, $rmax, $opts, $data) = @_;
	my %bins = ();
	my $bins = $opts->{bins};
	$bins-- if $rmin != $min;
	$bins-- if $rmax != $max;
	my $hsize = $opts->{histogram_size};

	my $binsize = _ceil( ($rmax - $rmin) / $bins );

	for my $v (@$data) {
		if ( $v < $rmin ) {
			$bins{'min'}++ ;
		} elsif ( $v > $rmax ) {
			$bins{'max'}++ ;
		} else {
			$bins{_ceil(($v+1)/$binsize) - 1}++ ;
		}
	}

	my ($minf, $maxf, $scale, $maxval) = (undef, undef, 1, 0);
	while ( my ($key, $value) = each (%bins) ) {
		next if $key eq 'min' or $key eq 'max';
		$minf = $key if !defined($minf) || $key < $minf;
		$maxf = $key if !defined($maxf) || $key > $maxf;

		$maxval = $value if $value > $maxval;
	}

	$scale = _ceil($maxval/$hsize) if $maxval>$hsize;

	return $scale, $binsize, %bins;
}

sub _ceil {
	my ($number) = shift;
	if ($number != int($number)) {
		$number = int($number) + 1;
	}
	return $number;
}

sub _check_outliers {
	my ($vcnt, $opts, @data) = @_;

	my ($min,$max) = my ($tmin, $tmax) = @data[0,-1];
	my $bins = $opts->{bins};

	my $cnt = int($vcnt/50); #max 2+2% of outlier points
	my $val = $data[0];

	my $c = 0;
	my $binsize = ($tmax - $tmin) / ($bins * 2);
	my ($rmin,$rmax) = (0, 0);
	while ( ($tmin != $rmin) or ($tmax != $rmax) ) {
		$rmin = $tmin;
		$rmax = $tmax;
		my $val = $data[0];
		for my $i (1..$cnt) {
			# point with more than half the size of a bin are grouped
			# in a big bin, in the beginning.
			$c = $data[$i] - $val;
			if ( $c > $binsize) {
				$tmin = $data[$i];
				$val = $data[$i];
				$binsize = ($tmax - $tmin) / ($bins * 2);
			}
			last if $i >= $cnt;
		}

		$val = $data[-1];
		for my $i (1..$cnt) {
			my $v1 = $data[-1-$i];
			$c = $val - $v1;
			if ($c > $binsize) {
				$tmax = $v1;
				$val = $v1;
				$binsize = ($tmax - $tmin) / ($bins * 2);
			}
			last if $i > $cnt;
		}
	}

	return ($min, $max, $rmin, $rmax);
}

1; # End of Text::Histogram

__END__

=head1 NAME

Text::Histogram - The great new Text::Histogram!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Text::Histogram;

    my $foo = Text::Histogram->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head1 AUTHOR

Marco Neves, C<< <neves at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-text-histogram at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Histogram>. 
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Histogram

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Histogram>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Histogram>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Histogram>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Histogram/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Marco Neves.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

