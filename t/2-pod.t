#!/usr/bin/perl

# Test POD correctness and coverage for SMS::AQL
#
# $Id: SMS-AQL.t 81 2007-01-04 22:25:47Z davidp $

use strict;
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

