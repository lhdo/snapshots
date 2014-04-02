#!/usr/bin/perl
#
# A script to backup files using rsync.  This script is intended for cron usage
#
# usage: back_up.pl HOURLY dir2backup01 dir2backup02 dir2backup03 ....
#
#
#########################################################################################

use strict;
use File::Path;
use POSIX qw(strftime);

#######GLOBALS##########
my $root = '/snapshots/users';

my @monthly = ("$root\/monthly.0","$root\/monthly.1","$root\/monthly.2","$root\/monthly.3","$root\/monthly.4","$root\/monthly.5");
my @daily = ("$root\/daily.0","$root\/daily.1","$root\/daily.2","$root\/daily.3","$root\/daily.4","$root\/daily.5");
my @weekly =("$root\/weekly.0","$root\/weekly.1","$root\/weekly.2");
my @hourly = ("$root\/hourly.0","$root\/hourly.1","$root\/hourly.2","$root\/hourly.3","$root\/hourly.4","$root\/hourly.5",
                "$root\/hourly.6","$root\/hourly.7","$root\/hourly.8","$root\/hourly.9","$root\/hourly.10","$root\/hourly.11");

my $time = strftime "%Y-%m-%d %H:%M:%S", localtime;

########################
my ($type,@back_up) = @ARGV;

print STDOUT "Creating $type backup of \"@back_up\" on $time.\n";

if ($type eq "DAILY"){
  create_dir(\@daily);
  rm_mv(\@daily);
  system("mv $hourly[-1] $daily[0]");
}
elsif ($type eq "WEEKLY"){
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
  #default type is HOURLY
  create_dir(\@hourly);
  mk_tempdir("$root\/hourly.temp");
  for my $back_up (@back_up){
    exit unless (-d $back_up);
    my $cmd = "rsync -a --link-dest=$hourly[0] $back_up $root\/hourly.temp\/";
    system ($cmd);
  }
  rm_mv(\@hourly);
  system ("mv $root\/hourly.temp $hourly[0]");
}


$time = strftime "%Y-%m-%d %H:%M:%S", localtime;
print STDOUT "Completed $type backup of \"@back_up\" on $time.\n";

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
        system("rm -rf $dir->[$n-1]");
      }
      else{
        print STDOUT "Directory $dir->[$n-1] does not exist, cannot remove!  Exiting...\n";
        exit;
      }
    }
    else{
      unless (-d $dir->[$n]){
        system("mv $dir->[$n-1] $dir->[$n]");
      }
      else{
        print STDOUT "$dir->[$n] already exists!  Exiting backup...\n";
        exit;
      }
#      print "mv $dir->[$n-1] $dir->[$n]\n";
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

