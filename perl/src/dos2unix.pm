#------------------------------------------------------------------------------
# Convert \r\n in file to \n. 
#
# @param string file
# @require abort
#------------------------------------------------------------------------------
sub dos2unix {
	my ($file) = @_;

	if (! -f $file) {
		abort("No such file [$file]");
	}

	open (FH, "<$file") || abort("Couldn't read [$file]");

	my ($data, $line);
	while (<FH>) {
		$line = $_;
		$line =~ s/[\r\n^M]+$//s;
		$data .= $line."\n";
	}

	close(FH);

	open (FH, ">$file") || abort("Couldn't write [$file]");
	print FH $data;
	close(FH);
}

1;
