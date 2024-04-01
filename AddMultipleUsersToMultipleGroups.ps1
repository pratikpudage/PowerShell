$Groups = Get-content C:\Temp\Groups.txt
$Members = Get-Content C:\Temp\Members.txt

ForEach ($Group in $Groups) {
Add-ADGroupMember -Identity $Group -Member $Members
}