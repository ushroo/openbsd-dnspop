#!/usr/bin/perl -w
####################################################################################################
##
## dnspop.pl
##
##  REPLACE em0 ON LINE 24 WITH YOUR INTERFACE
##
####################################################################################################

use v5.10;
use strict;
use warnings;

####################################################################################################

my $SEEN_COOLDOWN = 6000;  # milliseconds cooldown for seen domains
my $NOTIFY_TIME   = 7000;  # milliseconds display of X notification

main:
    {
    my $fh;
    my %seen;

    open $fh => '-|', '/usr/bin/doas /usr/sbin/tcpdump -lttti em0 -n port 53 2>&1';
    die $! unless $fh;

    while (my $s = <$fh>)
        {
        chomp $s;

        my $t = time;

        if ($s =~ /^(\w+ \d+ \d\d:\d\d:\d\d\.\d+) (\d+\.\d+\.\d+\.\d+\.\d+) > (\d+\.\d+\.\d+\.\d+\.\d+): (\d+)\+ (\w+)\? (.+)\. \(\d+\)$/)
            {
            my $time    = $1;
            my $send_ip = $2;
            my $recv_ip = $3;
            my $sid     = $4;
            my $query   = $5;
            my $domain  = $6;

            # skip if seen recently

            if (exists $seen{$domain} and $t - $seen{$domain} < ($SEEN_COOLDOWN / 1000))
                {
                say "$time $query\t$domain (SKIP)";
                next;
                }

            # update seen time

            $seen{$domain} = $t;

            # console out

            say "$time $query\t$domain";

            # notify bubble

            `/usr/local/bin/notify-send -u low -t $NOTIFY_TIME "$domain"`;
            }
        }

    close $fh;
    }

####################################################################################################
