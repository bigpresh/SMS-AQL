use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::AQL',
    VERSION_FROM      => 'lib/SMS/AQL.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/AQL.pm', # retrieve abstract from module
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),
);
