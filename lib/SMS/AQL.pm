package SMS::AQL;

# SMS::AQL - Sends text messages via AQL's gateway
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
  
  # send an SMS:
  
  $sms->send_sms($to, $msg) || die;
  
  # called in list context, we can see what went wrong:
  my ($ok, $why) = $sms->send_sms($to, $msg);
  if (!$ok) {
      print "Failed, error was: $why\n";
  }
  
  # params for this send operation only can be supplied:
  $sms->send_sms($to, $msg, { sender => 'bob the builder' });

  

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
password of your AQL account:


  $sms = new SMS::AQL( username => 'fred', password => 'bloggs' );


=cut


sub new {

    my ($package, $params) = @_;

     if (!$params->{username} || !$params->{password}) {
         warn 'Must supply username and password';
         return undef;
     }

    my $self = bless { contents => {} } => 
        ($package || 'SMS::AQL');

    # get an LWP user agent ready
    $self->{ua} = new LWP::UserAgent;
    $self->{ua}->agent("SMS::AQL/$VERSION");
    
    # remember the username and password
    ($self->{user}, $self->{pass}) = 
        ($params->{'username'}, $params->{'password'});
    
    # the list of servers we can try:
    $self->{servers} = ['gw1.sms2email.com', 'gw11.sms2email.com',
                'gw2.sms2email.com', 'gw22.sms2email.com'];
                
    # remember the last server response we saw:
    $self->{last_response} = '';
        
    return $self;	
}


=head1 METHODS

=over

=item send_sms($to, $message [, \%params])

Sends the message $message to the number $to, optionally
using the parameters supplied as a hashref.

If called in scalar context, returns 1 if the message was
sent, 0 if it wasn't.

If called in list context, returns a two-element list, the
first element being 1 for success or 0 for fail, and the second
being a message indicating why the message send operation
failed.


Examples:
    
  if ($sms->send_sms('+44123456789012', $message)) {
      print "Sent message successfully";
  }
  
  my ($ok, $msg) = $sms->send_sms($to, $msg);
  if (!$ok) {
      print "Failed to send the message, error: $msg\n";
  }
  
=cut

sub send_sms {
# send the greeting to the number specified.  Returns true on success, false
# if it fails (due to a HTTP request failing, or the SMS gateway saying no)

    my ($self, $to, $text, $opts) = @_;
    
    $to =~ s/[^0-9+]//xms;

    # assemble the data we need to POST to the server:
    my %postdata = (
        'username' => $self->{user}, 
        'password' => $self->{pass},
        'orig'     => $opts->{sender} || $self->{sender}, 
        'to_num'   => $to,
        'message'  => $text,
    );
    
        
    # try the request to each sever in turn, stop as soon as one succeeds.
    while (my $server = shift @{$self->{servers}})
        {
        
        my $response = $self->{ua}->post("http://$server/sms/postmsg.php",
            \%postdata);
    
        next unless ($response->is_success);  # try next server if we failed.
    
        my $resp = $response->content;
    
        # this code wasn't too bad to start with but has now bloated into
        # cruftitude... will refactor this into a half decent lookup table
        # in the next version, but it works for now, to get the initial
        # version out the door.
        $self->{last_response} = $resp;
        
        print wantarray? 'list context' : 'scalar context';
        
        for ($resp)
            {
            if (/AQSMS-OK/)
                {
                # the aqsms gateway, he say YES
                return wantarray?
                    (1, 'OK') : 1;
                } elsif (/AQSMS-NOCREDIT/) {
                # uh-oh, we're out of credit!
                return wantarray?
                    (0, 'Out of credits') : 0;
                } elsif (/AQSMS-INVALID_DESTINATION/) {
                return wantarray?
                    (0, 'Invalid destination') : 0;
                } else {
                # didn't recognise the response
                return wantarray?
                    (0, 'Unrecognised response from server') : 0;
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

All bug reports, feature requests, patches etc welcome.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
