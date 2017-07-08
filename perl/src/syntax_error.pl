#------------------------------------------------------------------------------
# Abort with error message (to stderr).
#
# @param string syntax description
# @param string purpose (optional)
#------------------------------------------------------------------------------
sub syntax_error {
	my ($msg, $purpose) = @_;

	print STDERR "\nSYNTAX:  ".$ENV{'SCRIPT_NAME'}." $msg\n\n";

	if ($purpose) {
		print STDERR "$purpose\n\n";
	}
 
	print STDERR "\n";
	exit 1;
}

1;
