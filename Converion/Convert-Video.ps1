
#Script Variables
$InputFolder = "C:\Users\brandonh\Downloads\Season 1"
$FFMPEGpath = "C:\Users\brandonh\Downloads\ffmpeg-20180330-cdd6a52-win64-static\ffmpeg-20180330-cdd6a52-win64-static\bin\"


#Get a list of all files from $inputfolder that have a last write time over than 5 minutes. THis to to prevent processing a file already being downloaded. 
$ToProcess = $InputFolder | Get-ChildItem -Recurse | Where-Object LastWriteTime -le ((Get-Date).AddMinutes(-5))



foreach ($Item in $ToProcess){
    

    $outputFolder = "C:\Users\brandonh\Downloads\convert"

    IF (!(Test-Path -Path $outputFolder)) {

        New-Item -Path $outputFolder -ItemType Directory

        }

    cmd /c $FFMPEGpath\ffmpeg.exe -ss 17 -i "$($Item.fullname)" -vcodec h264 -acodec copy "$($outputFolder)\$($Item.name)"

}


