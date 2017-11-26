# flolilos-PoShScripts
**All my often used PowerShell-scripts:**

## _fortryingoutloud
Just a few (old) tests I like to keep around.

## automount:smb.ps1
Automount SMB-shares (to circumvent the inability to browse after disabling SMBv1).

## catalog_backup
For backing up picture catalogs.

## compare_via_ffmpeg
Easy-to-use tool to create difference videos via FFmpeg.

## cpuwatch
Document the computer's CPU- and RAM-stats (into a CSV-file).

## exif_tool
Remove EXIF-entries in pictures (and re-add copyright information) via [exiftool](https://sno.phy.queensu.ca/~phil/exiftool/).

## find_extensions
Look for files with other extensions than the specified (helps at cleaning up)

## foobar_datamover
Move MP3s after converting them with foobar, so they make sense again.

## ipconfig_replacement
**Not complete!** A playground for replacing `ipconfig`. Or not.

## kamera_gui
Old version of `security-cam_gui` - will get delted after `security-cam_gui` is validated.

## mysqldump_bash.sh
_**Not** a PowerShell-script, but a Bash-script._ Make backups of a complete MySQL database via `mysqldump`, then `gzip` it. Delete old files if `>128MB` are used.

## mysqldump_powershell
**Not yet working!** A PowerShell-implementation of `mysqldump_bash.sh`.

## oldcodec_searchanddestroy
Search for old codecs with FFprobe. If wanted, delete them.

## oldcodec_transcode
Now almost completely implemented in `oldcodec_searchanddestroy`. Transcode files in batch with FFmpeg.

## outlook_+_google
Start Outlook and OutlookGoogleCalendarSync.

## pictures_cleanup
Clean up (sub)folders with unneeded files.

## powershell_doubleclick-behavior
Change behavior of a double-click on `.ps1`-files in Windows Explorer

## preventsleep
Prevent the computer from going to standby - options for forever, certain CPU threshold, running processes.

## processperformance
Cannot remember - that's why it's important to document everything!

## profile
My profile-file.

## remove_registry_entries
Remove some unnecessary context menu entries. **Could quite possibly damage your system, so be careful!**

## remove_win10_apps
Ask user which unnecessary apps to uninstall. **Could quite possibly damage your system, so be careful!**

## robocopy-gui
**Not complete!** Attempt to create a GUI for robocopy.

## screencapture
Capture your desktop, then render the video web-compliantly.

## security-cam_gui
Re-encode file from the SD-card of the main station of security cams (with FFmpeg.)

## split-quadscreen
Split a (quadscreen-)video into parts with FFmpeg.

## tiftojpeg
Use [imagemagick](https://www.imagemagick.org/) to convert TIFs to JPEGs - and save all metadata.

## transcodetomp3
Transcode files that are not MP3 to MP3 with FFmpeg.

## treecmd
Powershell-implementation of "tree".

## wakeonlan
Wakes server(s) up if they are not yet running.