#CSS codes
$header = @"
<style>

    h1 {

        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;

    }

    
    h2 {

        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;

    }

    
    
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
	}
	
    th {
        background: #20756e;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        padding: 10px 15px;
        vertical-align: middle;
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }
    


    #CreationDate {

        font-family: Arial, Helvetica, sans-serif;
        color: #ff3300;
        font-size: 12px;

    }



    .PresentStatus {

        background: #67f58d;
    }
    
  
    .NotPresentStatus {

        background: #f59667;
    }

    .NotSetStatus {

        background: #f567d9;
    }




</style>
"@


$CSV = Import-Csv C:\Data\Temp\HomeFoldersAuditOutput.csv |Sort-Object -Property HomeFolderStatus | ConvertTo-Html -Property HomeFolderStatus,SamAccountName,Description,ADAccountEnabled,HomeFolderPath,HomeFolderSize'(MB)',FolderCreationTime,FolderLastWriteTime,FolderLastAccessTime -PreContent "<h2>Services Information</h2>"
$CSV = $CSV -replace '<td>Present</td>','<td class="PresentStatus">Present</td>'
$CSV = $CSV -replace '<td>NotPresent</td>','<td class="NotPresentStatus">NotPresent</td>'
$CSV = $CSV -replace '<td>NotSet</td>','<td class="NotSetStatus">NotSet</td>'


$CSV = ConvertTo-Html -Body "$CSV" -Head $header
$CSV | Out-File .\HTMLTest_New.html