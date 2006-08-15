package Net::AQSMS::Send;

# Send text messages via AQL's gateway
#
# David Precious, davidp@preshweb.co.uk
#
# $Id$


use 5.008007;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;


our $VERSION = '0.01';

=head1 NAME

Net::AQSMS::Send - Perl extension to send SMS text messages via AQ's SMS service

=head1 SYNOPSIS

  $sender = new Net::AQSMS::Send;
  

=head1 DESCRIPTION

Provides a nice object-oriented interface to send SMS text messages
using the HTTP gateway provided by AQ Ltd (www.aql.com) in the UK.


=cut


sub new {

    my ($package, $user, $pass) = @_;

    if (!$user || !$pass) {
        warn 'Must supply username, password and password';
        return undef;
    }

    my $self = bless { contents => {} } => 
        ($package || 'Net::AQSMS::Send');

    ($self->{user}, $self->{pass}) = ($user, $pass);

    $self->{ua} = new LWP::UserAgent;

    return $self;	
}



=item send_sms($to, $message [, \%params])

Sends the message $message to the number $to, optionally
using the parameters supplied as a hashref.

$to can be an array passed by reference, in which case
the message will sent to each number in the array with one
call to AQ's multiple message gateway... this is much more
efficient than calling send_sms() once for every recipient,
but means that you do not know which of the messages sent
successfully and which didn't.

=cut

sub send_sms {
# send the greeting to the number specified.  Returns true on success, false
# if it fails (due to a HTTP request failing, or the SMS gateway saying no)

my ($self, $to, $text, $opts) = @_;
print "to:$to\n";
my $to_num;
if (ref $to eq 'ARRAY') {
    # multiple recipients:
    map { $_ = $self->_canonical_number($_) } @{$to};
    $to_num = join ',', @{$to};
} else {
    # normal, single-recipient mode
    $to_num = $self->_canonical_number($to);
}


my @servers = ('gw1.sms2email.com', 'gw11.sms2email.com',
               'gw2.sms2email.com', 'gw22.sms2email.com');

my %postdata = (
    'username' => $self->{user}, 
    'password' => $self->{pass},
    'orig'     => $self->{orig_num}, 
    'to_num'   => $to_num,
    'message'  => $text
);

	
# try the request to each sever in turn, stop as soon as one succeeds.
while (my $server = shift @servers)
	{
	
	my $script =  (ref $to eq 'ARRAY')? 
        'postmsg-multi.php' : 'postmsg.php';
    
    print "I'm going to post to $script, to is $to_num, to is a " . ref($to) . "\n";
    exit;
	my $response = $self->{ua}->post("http://$server/sms/$script",
		\%postdata);

	next unless ($response->is_success);  # try next server if we failed.

	my $resp = $response->content;

	for ($resp)
		{
		if (/AQSMS-OK/ig)
			{
			# the aqsms gateway, he say YES
			return "OK|OK";
			} elsif (/AQSMS-NOCREDIT/) {
			# uh-oh, we're out of credit!
			return "FAIL|NOCREDIT";
			} else {
			# didn't recognise the response
			return "FAIL|Unrecognised AQSMS response ($resp)";
			}
		}

	} # end of while loop through servers
	
# if we reach this point without returning, then we tried all 4 SMS gateway
# servers and couldn't connect to any of them - this is pretty unlikely, if
# it does happen it's almost certainly our own connectivity that's gone!
return 'FAIL|NOSERVERS';
	
} # end of sub send_sms




# fix up the number
sub _canonical_number {

    my ($self, $num) = @_;
    
    $num =~ s/[^0-9+]//;
    if (!$num) { return undef; }
    $num =~ s/^0/+44/;
    
    return $num;
    
}






1;
__END__



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

David Precious, E<lt>davidp@slackware.lanE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
