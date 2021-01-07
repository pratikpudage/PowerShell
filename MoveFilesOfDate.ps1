<#
.SYNOPSIS
This script facilitates moving of Exchange transaction files (*.log) from specified source and to the desired destination folders. It can be modified to handle different type of file extensions.


.DESCRIPTION
This script facilitates moving of Exchange transaction files (*.log) from specified source and to the desired destination folders.
The operator will have to provide the date for which the log files should be moved.


.NOTES
Author: Pratik Pudage (PratikPudage80@Gmail.com)


.USAGE
.\MoveFilesOfDate.ps1 -Source "SourcePath" -Destination "DestinationPath" -MoveFilesofDate MM/DD/YYYY


.EXAMPLES
.\MoveFilesOfDate.ps1 -Source D:\Source -Destination D:\Dest -MoveFilesofDate 03/31/2017

#>

Param(
    [DateTime]$MoveFilesofDate,
    [string]$Source,
    [string]$Destination
    )
$MoveDate = $MoveFilesOfDate
Get-ChildItem $Source -Filter *.log | Where {($_.CreationTime.Day -eq $MoveDate.Day) -and ($_.CreationTime.Month -eq $MoveDate.Month) -and ($_.CreationTime.Year -eq $MoveDate.Year)} | Move-Item -Destination $Destination