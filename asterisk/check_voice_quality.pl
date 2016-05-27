#!/usr/bin/perl

use DBI;
use warnings;

my $num_args = $#ARGV + 1;

if ($num_args ne 6) {
    print "
Usage: check_voice_quality.pl -w 2.5 -c 3.0 -t 5
----------------------------------------------
|Status                |   label  |  Unit    |
---------------------------------------------
|Warning               |  -w      | value    |
|Critical              |  -c      | value    |
|Time Interval         |  -t      | minutes  |
----------------------------------------------
\n";
    exit(3);
}
else {

	my $warning_value = $ARGV[1];
	my $critical_value = $ARGV[3];
	my $interval_minutes = $ARGV[5];
	
	#Database Settings
	my $db_driver = "mysql"; 
	my $db_name = "voipmonitor";
	my $db_host = "localhost";
	my $db_port = "3306";
	my $db_user = "<username>";
	my $db_pass = "<password>";
	my $db_dsn = "dbi:$db_driver:$db_name:$db_host:$db_port";
	my $dbh = DBI->connect($db_dsn, $db_user, $db_pass) or die "Connection Error: $DBI::errstr\n";
	my $sth = $dbh->prepare("SELECT SUM(IF(`a_mos_adapt` <= $critical_value AND `a_mos_adapt` >= $warning_value, 1, 0)) AS 'warning', SUM(IF(`a_mos_adapt` < $warning_value, 1, 0)) AS 'critical', COUNT(*) AS 'total' FROM `cdr` WHERE `a_mos_adapt` > 0 AND `calldate` >= NOW() - INTERVAL $interval_minutes MINUTE;");
	$sth->execute() or die $DBI::errstr;
	my @result = $sth->fetchrow_array();
	$sth->finish();
	#Closing Database Connection 
	$dbh->disconnect or warn $dbh->errstr;

	$warning_count = (defined $result[0] ? $result[0] : 0);
	$critical_count =  (defined $result[1] ? $result[1] : 0);
	$total = (defined $result[2] ? $result[2] : 0);
	$performance_parameters = "|critical=$critical_count;;; warning=$warning_count;;; total=$total;;;";
	
	if($total gt 0) {
		if( $warning_count eq 0 and $critical_count ne 0) {
			print "CRITICAL - MOS value of $critical_count call".($critical_count gt 1 ? "s have": " has")." dropped below the threshold value of $critical_value!!! $performance_parameters";
			exit(2);
		}
		elsif( $warning_count ne 0 and $critical_count ne 0 ) {
			print "CRITICAL - MOS value of $critical_count call".($critical_count gt 1 ? "s have": " has")." dropped below the threshold value of $critical_value and $warning_count call".($warning_count gt 1 ? "s have": " has")." dropped below the threshold value of $warning_value!!! $performance_parameters";
			exit(2);		
		}
		elsif($warning_count ne 0 and $critical_count eq 0){
			print "WARNING - MOS value of $warning_count call".($warning_count gt 1 ? "s have": " has")." dropped below the threshold value of $warning_value!!! $performance_parameters";
			exit(1);
		}
		else {
			print "OK - MOS value is OK for last $total ".($total gt 1 ? "calls" : "call").". $performance_parameters";
			exit(0);
		}
	}
	else {
		print "UNKNOWN - No call is available to calculate MOS value!! $performance_parameters"; 
	   	exit(1); 
	}
}
