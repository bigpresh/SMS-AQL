#!/usr/bin/perl

# Test script for Net::AQSMS::Send
# $Id$

use strict;
use warnings;

my $test_user = 'davidp';
my $test_pass = 'mE821805dP';
my $test_to = '07884005261';
my $test_to_2 = '07884005261';
use Test::More qw(no_plan);


use lib '../lib/';
use_ok('Net::AQSMS::Send');



ok(my $sender = new Net::AQSMS::Send($test_user, $test_pass), 
    'Create instance of Net::AQSMS::Send');
    
ok(ref $sender eq 'Net::AQSMS::Send', 
    '$sender is an instance of Net::AQSMS::Send');
    

#ok($sender->send_sms($test_to, 'Test message sent with Net::AQSMS::Send'),
#    'Sent a test SMS to single recipient');
    
ok($sender->send_sms([$test_to, $test_to_2], 'Test message sent with Net::AQSMS::Send'),
    'Sent a test SMS to single recipient');