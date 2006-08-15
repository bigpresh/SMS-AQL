package SMS::AQL;

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
use Data::Dumper; # TODO: take out when done with diagnostics

our $VERSION = '0.01';

=head1 NAME

SMS::AQL - Perl extension to send SMS text messages via AQ's SMS service

=head1 SYNOPSIS

  # create an instance of SMS::AQL, passing it your AQL username
  # and password (if you do not have a username and password, 
  # register at www.aql.com first).
  
  $sms = new SMS::AQL(
    username => 'username',
    password => 'password'
  );

  # extra parameters can be passed like so:
  $sms = new SMS::AQL(
    username => 'username',
    password => 'password',
    options => { sender => '+4471234567' }
  );
  

  

=head1 DESCRIPTION

SMS::AQL provides a nice object-oriented interface to send SMS text
messages using the HTTP gateway provided by AQ Ltd (www.aql.com) in 
the UK.

It supports concatenated text messages (over the 160-character limit
of normal text messages, achieved by sending multiple messages with
a header to indicate that they are part of one message (this is
handset-dependent, but supported by all reasonably new mobiles).



=head1 INITIALISATION

You must create an instance of SMS::AQL, passing it the username and
password of your AQL account.


=cut


sub new {

    my $package = shift;
    my %params = @_;

    print "params:\n";
    print Dumper(\%params);
    print "\n";
    exit;
    
     if (!$params{username} || !$params{password}) {
         warn 'Must supply username and password';
         return undef;
     }

    my $self = bless { contents => {} } => 
        ($package || 'SMS::AQL');

    # get an LWP user agent ready
    $self->{ua} = new LWP::UserAgent;
    $self->{ua}->agent("SMS::AQL/$VERSION");
    
    ($self->{user}, $self->{pass}) = 
        ($params{'username'}, $params{'password'});

    return $self;	
}


=head1 METHODS

=over

=item send_sms($to, $message [, \%params])

Sends the message $message to the number $to, optionally
using the parameters supplied as a hashref.

$to can be an array passed by reference, in which case
the message will sent to each number in the array with one
call to AQ's multiple message gateway... this is much more
efficient than calling send_sms() once for every recipient,
however the drawback is that you will not know which
messages suceeded and which failed, only the count of how
many were sucessful.

However, if you use the delivery_notification_url option
(see below) you can receive notification when each message
is either sucessfully delivered or rejected.

Examples:
    
  # sending a single message:
  if ($sms->send_sms('+44123456789012', $message)) {
    print "Sent message successfully";
  }


  # sending a message to multiple recipients:
  my @recipients = qw(+44123456789012 +44123456789013);
  my $num_sent = $sms->send_sms(\@recipients, 'My Message');
  
  # $num_sent is the number of messages which were sucessfully
  sent



=cut

sub send_sms {
# send the greeting to the number specified.  Returns true on success, false
# if it fails (due to a HTTP request failing, or the SMS gateway saying no)

my ($self, $to, $text, $opts) = @_;
print "to:$to\n";
my $to_num;
if (ref $to eq 'ARRAY') {
    # multiple recipients
    my @recipients = @$to;
} else {
    # single recipient, to simplify the
    # code we'll whack it in an array as
    # a single item.
    my @recipients = ($to);
}


#
map { $_ = $self->_canonical_number($_) } @{$to};
    $to_num = join ',', @{$to};



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



=item last_result()

Returns the last result code received from the AQL
gateway.

Possible codes are:

=over

=item AQSMS-NOAUTHDETAILS

The username and password were not supplied

=item AQSMS-AUTHERROR

The username and password supplied were incorrect

=item AQSMS-NOCREDIT

The account specified did not have sufficient credit

=item AQSMS-OK

The message was queued on our system successfully

=item AQSMS-NOMSG

No message or no destination number were supplied

=back

=cut

sub last_error {

    shift->{last_error}


} 


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


=back


=head1 SEE ALSO

http://www.aql.com/


=head1 AUTHOR

David Precious, E<lt>davidp@preshweb.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
