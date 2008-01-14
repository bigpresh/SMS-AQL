package SMS::AQL;

# SMS::AQL - Sends text messages via AQL's gateway
#
# David Precious, davidp@preshweb.co.uk
#
# $Id$


use 5.005000;

use strict;

use LWP::UserAgent;
use HTTP::Request;
use vars qw($VERSION);

$VERSION = '0.07';

my $UNRECOGNISED_RESPONSE = "Unrecognised response from server";
my $NO_RESPONSES = "Could not get valid response from any server";

=head1 NAME

SMS::AQL - Perl extension to send SMS text messages via AQ's SMS service

=head1 SYNOPSIS

  # create an instance of SMS::AQL, passing it your AQL username
  # and password (if you do not have a username and password, 
  # register at www.aql.com first).
  
  $sms = new SMS::AQL({
    username => 'username',
    password => 'password'
  });

  # other parameters can be passed like so:
  $sms = new SMS::AQL({
    username => 'username',
    password => 'password',
    options => { sender => '+4471234567' }
  });
  
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



=head1 METHODS

=over

=item new (constructor)

You must create an instance of SMS::AQL, passing it the username and
password of your AQL account:

  $sms = new SMS::AQL({ username => 'fred', password => 'bloggs' });
  
You can pass extra parameters (such as the default sender number to use,
or a proxy server) like so:

  $sms = new SMS::AQL({
    username => 'fred', 
    password => 'bloggs',
    options  => {
        sender => '+44123456789012',
        proxy  => 'http://user:pass@host:port/',
    },
  });

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
    
    # configure user agent to use a proxy, if requested:
    # TODO: validate supplied proxy details
    if ($params->{options}->{proxy}) {
        $self->{ua}->proxy(['http','https'] => $params->{options}->{proxy});
    }
    
    # remember the username and password
    ($self->{user}, $self->{pass}) = 
        ($params->{username}, $params->{password});
        
        
    # remember extra params:
    $self->{options} = $params->{options};
    
    # the list of servers we can try:
    $self->{servers} = ['gw1.sms2email.com', 'gw11.sms2email.com',
                'gw2.sms2email.com', 'gw22.sms2email.com'];
                
    # remember the last server response we saw:
    $self->{last_response} = '';
    $self->{last_response_text} = '';
    $self->{last_error} = '';
    $self->{last_status} = 0;
        
    return $self;	
}



=item send_sms($to, $message [, \%params])

Sends the message $message to the number $to, optionally
using the parameters supplied as a hashref.

If called in scalar context, returns 1 if the message was
sent, 0 if it wasn't.

If called in list context, returns a two-element list, the
first element being 1 for success or 0 for fail, and the second
being a message indicating why the message send operation
failed.

You must set a sender, either at new or for each send_sms call.

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

    my ($self, $to, $text, $opts) = @_;
    
    $to =~ s/[^0-9+]//xms;

    # assemble the data we need to POST to the server:
    my %postdata = (
        'username' => $self->{user}, 
        'password' => $self->{pass},
        'orig'     => $opts->{sender} || $self->{options}->{sender}, 
        'to_num'   => $to,
        'message'  => $text,
    );
    
    if (!$postdata{orig}) {
	$self->{last_error} = "Cannot send message without sender specified";
	warn($self->{last_error});
        return 0;
    }
    
    # try the request to each sever in turn, stop as soon as one succeeds.
    for my $server (sort { (-1,1)[rand 2] } @{$self->{servers}} ) {
        
        my $response = $self->{ua}->post(
            "http://$server/sms/postmsg-concat.php", \%postdata);
    
        next unless ($response->is_success);  # try next server if we failed.
    
        my $resp = $response->content;
    
	$self->_check_aql_response_code($response);

	return wantarray ? ($self->last_status, $self->last_response_text) : $self->last_status;
    
    } # end of while loop through servers
        
    # if we reach this point without returning, then we tried all 4 SMS gateway
    # servers and couldn't connect to any of them - this is pretty unlikely, if
    # it does happen it's almost certainly our own connectivity that's gone!
    $self->_set_no_valid_response;
    return wantarray ? (0, $self->last_error) : 0;
	
} # end of sub send_sms


sub _set_no_valid_response {
	my $self = shift;
	$self->{last_error} = $NO_RESPONSES;
	$self->{last_status} = 0;
}

=item credit()

Returns the current account credit. Returns undef if any errors occurred

=cut

sub credit {

    my $self = shift;

    # assemble the data we need to POST to the server:
    my %postdata = (
        'username' => $self->{user}, 
        'password' => $self->{pass},
        'cmd'      => 'credit',
    );
    
    # try the request to each sever in turn, stop as soon as one succeeds.
    for my $server (sort { (-1,1)[rand 2] } @{$self->{servers}} ) {
        
        my $response = $self->{ua}->post(
            "http://$server/sms/postmsg.php", \%postdata);
    
        next unless ($response->is_success);  # try next server if we failed.
    
	$self->_check_aql_response_code($response);
        
        my ($credit) = $response->content =~ /AQSMS-CREDIT=(\d+)/;
        
        return $credit;
        
   }
    
   $self->_set_no_valid_response;
   return undef;
} # end of sub credit



=item last_status()

Returns the status of the last command: 1 = OK, 0 = ERROR.

=cut

sub last_status { shift->{last_status} }

=item last_error()

Returns the error message of the last failed command.

=cut

sub last_error { shift->{last_error} }

=item last_response()

Returns the raw response from the AQL gateway.

=cut

sub last_response { shift->{last_response} }

=item last_response_text()

Returns the last result code received from the AQL
gateway in a readable format.

Possible codes are:

=over

=item AQSMS-AUTHERROR

The username and password supplied were incorrect

=item AQSMS-NOCREDIT

Out of credits (The account specified did not have sufficient credit)

=item AQSMS-OK

OK (The message was queued on our system successfully)

=item AQSMS-NOMSG

No message or no destination number were supplied

=back

=cut

my %lookup = (
	"AQSMS-AUTHERROR" => { 
		text => "The username and password supplied were incorrect", 
		status => 0,
		},
	"AQSMS-NOCREDIT" => { 
		#text => "The account specified did not have sufficient credit", 
		text => "Out of credits",
		status => 0,
		},
	"AQSMS-OK" => { 
		#text => "The message was queued on our system successfully",
		text => "OK",
		status => 1,
		},
	"AQSMS-CREDIT" => {
		#text is filled out in credit sub
		status => 1,
		},
	"AQSMS-NOMSG" => { 
		text => "No message or no destination number were supplied", 
		status => 0,
		},
	"AQSMS-INVALID_DESTINATION" => { 
		text => "Invalid destination", 
		status => 0,
		},

	# This one looks deprecated. A 401 error appears if username or password is missing from request
	# but this module should always add that, so not needed to check against
	#"AQSMS-NOAUTHDETAILS" => { text => "The username and password were not supplied", error => 1 },
	);

sub _check_aql_response_code {
	my ($self, $res) = @_;
	my $r = $self->{last_response} = $res->content;
	$r =~ s/^([\w\-]+).*/$1/;				# Strip everything after initial alphanumerics and hyphen
	if (exists $lookup{$r}) {
		$self->{last_response_text} = $lookup{$r}->{text};
		$self->{last_status} = $lookup{$r}->{status};
	} else {
		$self->{last_response_text} = "$UNRECOGNISED_RESPONSE: $r";
		$self->{last_status} = 0;
	}
	unless ($self->last_status) {
		$self->{last_error} = $self->{last_response_text};
	}
}

sub last_response_text { shift->{last_response_text} }


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

Copyright (C) 2006-2007 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=head1 THANKS

 - to Adam Beaumount and the AQL team for their assistance
 - to Ton Voon at Altinity (http://www.altinity.com/) for contributing
   several improvements

=cut
