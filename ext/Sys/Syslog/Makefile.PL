use ExtUtils::MakeMaker;
use ExtUtils::Constant 0.07 'WriteConstants';

WriteMakefile(
    NAME		=> 'Sys::Syslog',
    VERSION_FROM	=> 'Syslog.pm', 
    MAN3PODS		=> {}, 	# Pods will be built by installman.
    XSPROTOARG          => '-noprototypes',
    realclean => {FILES=> 'constants.c constants.xs'},
);
WriteConstants(
    NAME => 'GDBM_File',
    NAMES => [qw(LOG_ALERT LOG_AUTH LOG_AUTHPRIV LOG_CONS LOG_CRIT LOG_CRON
                 LOG_DAEMON LOG_DEBUG LOG_EMERG LOG_ERR LOG_FACMASK LOG_FTP
                 LOG_INFO LOG_KERN LOG_LFMT LOG_LOCAL0 LOG_LOCAL1 LOG_LOCAL2
                 LOG_LOCAL3 LOG_LOCAL4 LOG_LOCAL5 LOG_LOCAL6 LOG_LOCAL7 LOG_LPR
                 LOG_MAIL LOG_NDELAY LOG_NEWS LOG_NFACILITIES LOG_NOTICE
                 LOG_NOWAIT LOG_ODELAY LOG_PERROR LOG_PID LOG_PRIMASK LOG_SYSLOG
                 LOG_USER LOG_UUCP LOG_WARNING),
              {name=>"_PATH_LOG", type=>"PV", default=>["PV", '""']},
             ],
);
