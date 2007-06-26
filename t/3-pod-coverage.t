#!/usr/bin/perl

# Test POD correctness and coverage for SMS::AQL
#
# $Id: SMS-AQL.t 81 2007-01-04 22:25:47Z davidp $


use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" 
    if $@;
all_pod_coverage_ok();