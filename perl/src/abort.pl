#------------------------------------------------------------------------------
# Print error message (and function name) to stderr - then abort.
#
# @param string error messsage
# @param string function name (optional)
#------------------------------------------------------------------------------
sub abort {
	my ($msg, $func) = @_;

	if ($func) {
		print STDERR "\nABORT in $func:\n\t$msg\n";
	}
	else {  
		print STDERR "\nABORT:\n\t$msg\n";
	}

	exit 1;
}

1;
