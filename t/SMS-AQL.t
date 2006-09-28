#!/usr/bin/perl

# Test script for Net::AQSMS::Send
# $Id$

use strict;
use warnings;

# NOTE - the test username and password is for testing SMS::AQL *only*,
# not to be used for any other purpose.  It is given a small amount of
# credit now and then, if you try to abuse it, it just won't get given
# any more credit.  So don't.
my $test_user = 'sms-aql-test';
my $test_pass = 'sms-aql-test';

my $test_to = '07884005261';

use Test::More qw(no_plan);


use lib '../lib/';
use_ok('SMS::AQL');



ok(my $sender = new SMS::AQL({username => $test_user, password => $test_pass}), 
    'Create instance of SMS::AQL');
    
ok(ref $sender eq 'SMS::AQL', 
    '$sender is an instance of SMS::AQL');
    

#ok($sender->send_sms($test_to, 'Test message sent with SMS::AQL'),
#    'Sent a test SMS to single recipient');
    
ok($sender->send_sms($test_to, 'Test message sent with SMS::AQL', 
    { sender => 'bob the builder' }),
    'Sent a test SMS to single recipient');