#!/usr/bin/perl
#
# A script to backup files using rsync.  This script is intended for cron usage
#
# usage: back_up.pl [DAILY/WEEKLY/MONTHLY]
#
##############################################################

use strict;
use File::Path;
use POSIX qw(strftime);

#######GLOBALS##########
my $root = '/snapshots/system';

my @hourly =
my @daily = ("$root\/daily.0","$root\/daily.1","$root\/daily.2","$root\/daily.3","$root\/daily.4","$root\/daily.5");
my @weekly =("$root\/weekly.0","$root\/weekly.1","$root\/weekly.2");
my @monthly = ("$root\/monthly.0","$root\/monthly.1","$root\/monthly.2");

########################
my $time = strftime "%Y-%m-%d %H:%M:%S", localtime;

my ($type) = @ARGV;

print STDOUT "Creating $type backup of system on $time.\n";

if ($type eq "WEEKLY"){
  create_dir(\@weekly);
  rm_mv(\@weekly);
  system("mv $daily[-1] $weekly[0]");
}
elsif ($type eq "MONTHLY"){
  create_dir(\@monthly);
  rm_mv(\@monthly);
  system("mv $weekly[-1] $monthly[0]");
}
else{
  #default type is DAILY
  create_dir(\@daily);
  mk_tempdir("$root\/daily.temp");
  my $cmd = "/usr/bin/rsync -a --exclude \"sys\" --exclude \"/mnt\" --exclude \"/proc\" --exclude \"/media\" --exclude \"/home\" --exclude \"/snapshots\" --link-dest=$daily[0] /. $root\/daily.temp\/";
  system ($cmd);
  rm_mv(\@daily);
  my $done = "echo \"Done\" > $root\/daily.temp\/.done\; rm $root\/daily.temp\/.done" unless (-e "$root\/daily.temp\/.done");
  system ($done);
  system ("mv $root\/daily.temp $daily[0]");
}

$time = strftime "%Y-%m-%d %H:%M:%S", localtime;
print STDOUT "Completed $type backup of system on $time.\n";

sub mk_tempdir{
  my $dir = shift;
  if (-d $dir){
    system("rm -rf $dir");
    mkdir("$dir",0755);
  }
  else{
    mkdir("$dir",0755);
  }
}

sub rm_mv{
  my $dir = shift;
  my $count = @$dir;
  my $n = $count;
  for ($n; $n > 0; $n--){
    if ($n == $count){
      if (-d $dir->[$n-1]){
        `rm -rf $dir->[$n-1]`;
#        rmtree($dir->[$n-1],0,0);
      }
      else{
        print STDOUT "Directory $dir->[$n-1] does not exist, cannot remove!  Exiting...\n";
        exit;
      }
    }
    else{
      unless (-d $dir->[$n]){
        `mv $dir->[$n-1] $dir->[$n]`;
      }
      else{
        print STDOUT "$dir->[$n] already exists!  Exiting backup...\n";
        exit;
      }
    }
  }
}

sub create_dir{
  my $dirs = shift;
  for my $dir(@{$dirs}){
    unless (-d $dir){
      mkdir($dir,0755);
    }
  }
}

