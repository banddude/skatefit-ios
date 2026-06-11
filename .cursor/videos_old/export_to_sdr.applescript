-- Export all MOV files to 1080p H.264 using QuickTime Player
set sourceFolder to POSIX file "/Users/mikeshaffer/swift_projects/skatefit_ios/skatefit/skatefit/videos/newvids/"
set outputFolder to "/Users/mikeshaffer/swift_projects/skatefit_ios/skatefit/skatefit/videos/sdr/"

tell application "Finder"
    set movFiles to every file of folder sourceFolder whose name extension is "mov"
end tell

repeat with movFile in movFiles
    set fileName to name of movFile
    set baseName to text 1 thru -5 of fileName -- Remove .mov extension
    
    tell application "QuickTime Player"
        activate
        open movFile
        
        delay 2 -- Wait for file to load
        
        -- Export as 1080p H.264
        export document 1 in POSIX file (outputFolder & baseName & ".mp4") using settings preset "1080p"
        
        delay 1
        close document 1 saving no
    end tell
end repeat

display notification "All videos exported to SDR folder" with title "Export Complete"