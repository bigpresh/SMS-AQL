use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::AQL',
    VERSION_FROM      => 'lib/SMS/AQL.pm', # finds $VERSION
    PREREQ_PM         => { LWP::UserAgent => 0 },
    ($] > 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/AQL.pm',
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),
);
