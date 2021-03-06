---
aliases: ["/archives/418"]
title: "Ghetto: Your Solution for Workarounds™"
date: "2009-03-07T09:58:53-06:00"
tags: [perl, perl-6, rakudo]
guid: "http://blog.afoolishmanifesto.com/?p=418"
---
I like to make playlists. But I also reorganize my music something like once or twice a year. Because of that my playlists get broken as they are really just lists of filenames. This past summer I wrote some code in ruby that would find files with the same basename but ignore the directory structure, and reconstruct playlists from that. It worked perfectly **except** every now and then I would get a live version or two. This works because I have an sqlite database of all of my music thanks to amaroK.

Well, I decided that I would update the script so that I wouldn't have those issues with live versions. I decided that I would have an intermediate filetype, which I would basically keep around forever. Announcing the FRU media playlist filetype! Actually not that exciting. Anyway, here are a couple scripts:

m3u2fru.pl6:

```
#!/home/frew/personal/rakudo/perl6

use Ghetto;

for =$*IN -> $line {
   unless $line ~~ /^\#/ {
      my $file = $line.split('/').pop;

      my $cmd = qq{dcop amarok collection query "SELECT title,artist.name,album.name FROM tags JOIN artist ON artist.id = artist  JOIN album ON album.id = album WHERE url LIKE \\"%/$file\\""};
      my ( $track,$artist,$album ) = Ghetto::run($cmd).split("\n");
      say $track;
      say $artist;
      say $album;
      say '--';
   }
}
```

fru2m3u.pl6:

```
#!/home/frew/personal/rakudo/perl6

use Ghetto;

for =$*IN -> $track,$artist,$album,$sep {
   my $cmd = qq{dcop amarok collection query "SELECT url FROM tags JOIN artist ON artist.id = artist  JOIN album ON album.id = album WHERE artist.name = \\"$artist\\" and album.name = \\"$album\\" and title = \\"$track\\""};
   # this insanity is to take the first character off because amaroK adds a
   # . to the front of all the file names.  There's probably a better way
   # to do this.
   say Ghetto::run($cmd).split("\n")[0].reverse.chop.reverse;
}
```

But the more important part, is the Ghetto module. Currently rakudo does not have any way to get the output of a command, but it can read from files, so we can fake it:

```
module Ghetto;

sub run($cmd) {
   # create a random filename to store output in
   my $tmp = ".tmp-{(1..100).pick}-ghetto";

   # use the real run command, :: means root namespace
   ::run("$cmd > '$tmp'");

   # open the file
   my $data_file = open($tmp, :r);
   
   # put the data from the file into a variable
   my $val;
   for =$data_file { $val ~= "$_\n"; }

   # delete the file
   unlink($tmp);

   #gimme my data!
   return $val;
}
```

Obviously this is slow, bad in that it could possibly overwrite files, etc. It's ghetto. But the idea is that later when we actually **can** do something like this without a ghetto solution it won't be hard to fix your code.

I also thought it was fun to do a pipe-based solution. The way I had it set up before was something like this:

    ./plup.rb old.m3u new.m3u

That's alright, but I would usually look at the output to make sure it was right. Now I do this:

    cat old.m3u | ./m3u2fru.pl6 | ./fru2m3u.pl6 > new.m3u

Sure it's longer, but I can easily see the output at any point in the process. Furthermore, since I am using zsh (maybe bash can do this too, not sure) I can do this:

    cat old.m3u | ./m3u2fru.pl6 >new.fru | ./fru2m3u.pl6 > new.m3u

So I can keep the intermediate results for next time!
