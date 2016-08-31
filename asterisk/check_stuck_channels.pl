#!/usr/bin/perl

use warnings;

$num_args = $#ARGV + 1;

if ($num_args != 6) {

    print "
Usage: check_stuck_channels -w 1800 -c 3600 -h 0
--------------------------------------------------------
|Status                |   label  |  Unit              |
--------------------------------------------------------
|Warning               |  -w      | Seconds            |
|Critical              |  -c      | Seconds            |
|orcefully Hangup Call |  -h      | Binary i.e 0 or 1  |
--------------------------------------------------------
\n";
    exit(3);
}
else {

    # Executing System Command for Asterisk to get Latest Information of Channels
    @channels = `/usr/sbin/asterisk -rx "core show channels concise"`;

    if($? == -1) {
        print "UNKNOWN - Unknown Channel Information is recieved!!."; 
        exit(3); 
    }

    else {

        # Limits to be set for Alerts
        $duration_limit_for_warning = $ARGV[1];
        $duration_limit_for_critical = $ARGV[3];
        $hang_channel_if_limit_exceeded = $ARGV[5];
        
        # Initializing Counter for Channels which are exceeding the duration limit
        $channels_exceeding_limit = 0;
        $channels_exceeded_limit = 0;
        $channels_exceeded_limit_but_failed_to_hangup = 0;

        # Counting total active channels 
        $total_active_channels = @channels;

        # Parsing each Channels Information
        foreach $channel (@channels){
            chomp($channel);
            @channel_params = split('!',$channel);

            $channel_id = $channel_params[0];
            $duration = $channel_params[11];

            if($duration > $duration_limit_for_critical) {
                $channels_exceeded_limit++;
                
                if($hang_channel_if_limit_exceeded) {
                    my $action = `/usr/sbin/asterisk -rx "channel request hangup $channel_id"`;
                    if($? == -1) {
                        $channels_exceeded_limit_but_failed_to_hangup++;
                    }
                }
            }
            elsif($duration > $duration_limit_for_warning) {
                $channels_exceeding_limit++;
            }
        }

        # Alerts Management
        if($channels_exceeded_limit > 0) {
        	print "CRITICAL - $channels_exceeded_limit ".($channels_exceeded_limit > 1 ? "Channels are" : "Channel is")." exceeding limit of $duration_limit_for_critical s ".($channels_exceeding_limit > 0 ? "and $channels_exceeding_limit ".($channels_exceeding_limit > 1 ? "Channels are" : "Channel is")." exceeding limit of $duration_limit_for_warning s " : "" )."!!!|Active=$total_active_channels;;; Exceeding-limit=$channels_exceeding_limit;;; Exceeded-limit=$channels_exceeded_limit;;; Hangup-Failed=$channels_exceeded_limit_but_failed_to_hangup;;;"; 
            exit(2);
        }
        elsif($channels_exceeding_limit > 0) {
        	print "WARNING - $channels_exceeding_limit ".($channels_exceeding_limit > 1 ? "Channels are" : "Channel is")." exceeding $duration_limit_for_warning s limit!|Active=$total_active_channels;;; Exceeding-limit=$channels_exceeding_limit;;; Exceeding-limit=$channels_exceeded_limit;;; Hangup-Failed=$channels_exceeded_limit_but_failed_to_hangup;;;"; 
            exit(1); 
        }
        else {
        	print "OK - $total_active_channels ".($total_active_channels > 1 ? "Channels are" : "Channel is")." Active.|Active=$total_active_channels;;; Exceeding-limit=$channels_exceeding_limit;;; Exceeded-limit=$channels_exceeded_limit;;; Hangup-Failed=$channels_exceeded_limit_but_failed_to_hangup;;;"; 
            exit(0);
        }

    }

}
