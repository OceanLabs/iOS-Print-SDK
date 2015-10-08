#!/usr/bin/perl
$folderLocations = `xcrun simctl list`; # running "xcrun simctl list" on terminal returns iOS device locations
$currentUserID = `id -un`;              # get current user
chomp($currentUserID);                  # remove extra white space from user string
print "currentUserID: $currentUserID\n";  # debug logs

while($folderLocations =~ /iPhone 4s \((.{9}-.*?)\)/g) { # Use regex to loop through each iPhone 4s device found in $folderLocations. Insert the permissions in the database of each.
    print "folderLocations <1>: $1\n";  # debug logs
    `sqlite3 /Users/$currentUserID/Library/Developer/CoreSimulator/Devices/$1/data/Library/TCC/TCC.db "insert into access values('kTCCServicePhotos','ly.kite.sdk', 0, 1, 0, 0, 0)"`;
    print "\n";  # neat logs
}
