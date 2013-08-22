package Loglib;

use strict;
use Digest::MD5  qw/ md5_hex /;
use POSIX qw(strftime);
use Time::Local;

my $LOG_LEVEL = 16;
my $SN = "Loglib";

sub NOTICE_LOG {
    my ($cont) = @_;
    PrintLog("NOTICE",$cont);
}

sub ERROR_LOG {
    my ($cont) = @_;
    PrintLog("ERROR",$cont);
}

sub DEBUG_LOG {

        my ($cont) = @_;
        PrintLog("DEBUG",$cont);
}

sub FATAL_LOG {
    my ($cont) = @_;
    PrintLog("FATAL",$cont);
}

sub WARN_LOG {
    my ($cont) = @_;
    PrintLog("WARN",$cont);
}

sub PrintLog {
    my ($flag,$cont) = @_;
    if($LOG_LEVEL<16) {
        return if($flag eq "DEBUG");
    }
    my $dt = GetLogDate();
    print "$dt $flag $cont\n";
}

sub FP_NOTICE_LOG {
    my ($fp, $cont) = @_;
    FP_PrintLog($fp, "NOTICE",$cont);
}

sub FP_ERROR_LOG {
    my ($fp, $cont) = @_;
    FP_PrintLog($fp,"ERROR",$cont);
}

sub FP_DEBUG_LOG {
    my ($fp, $cont) = @_;
    FP_PrintLog($fp, "DEBUG",$cont);
}

sub FP_FATAL_LOG {
    my ($fp, $cont) = @_;
    FP_PrintLog($fp, "FATAL",$cont);
}

sub FP_WARN_LOG {
    my ($fp, $cont) = @_;
    FP_PrintLog($fp, "WARN",$cont);
}

sub FP_PrintLog {
    my ($fp, $flag,$cont) = @_;
    if($LOG_LEVEL<16) {
        return if($flag eq "DEBUG");
    }
    my $dt = GetLogDate();
    print $fp "$dt $flag $cont\n";
}

sub GetLogDate {
    my $dt = strftime "%Y-%m-%d %H:%M:%S", localtime(time);
    return $dt;
}
