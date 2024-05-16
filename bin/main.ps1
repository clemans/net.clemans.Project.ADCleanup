Function Get-FullNameFromCsv() {
    Param([Parameter(Mandatory = $true)]$User)
    return "$($User."First Name") $($User."Last Name")"
}

Function Get-TerminatedFullNameFromCsv() {
    Param([Parameter(Mandatory = $true)]$User)
    return "$(($User.Employee.split(',')[-1]).Trim()) $(($User.Employee.split(',')[0]).Trim())"
}

function Convert-ToSamAccountName {
    param (
        [string]$FullName
    )

    # Split the full name into parts
    $NameParts = $FullName -split ', '

    # Extract last name and first name
    $LastName = $NameParts[0]
    $FirstName = $NameParts[1]

    # Check if the first name contains a middle initial
    if ($FirstName -match '\s[A-Z]\.$') {
        # Extract first initial and middle initial
        $FirstInitial = $FirstName.Substring(0,1).ToLower()
        $MiddleInitial = $FirstName -replace '.*\s([A-Z])\.$', '$1'

        # Construct the sAMAccountName
        $SamAccountName = $FirstInitial + $LastName.ToLower()
    }
    else {
        # Extract first name without middle initial
        $FirstInitial = $FirstName.Substring(0,1).ToLower()

        # Construct the sAMAccountName
        $SamAccountName = $FirstInitial + $LastName.ToLower()
    }

    return $SamAccountName
}

Function Get-SamAccountNameFromCsv() {
    Param([Parameter(Mandatory = $false)][System.Object]$UserRow)
    return "$(($UserRow.'First Name')[0])$($UserRow.'Last Name')"
}

Function Get-ADAccountFromAttributes() {
    Param(
        [Parameter(Mandatory = $true)]$User
    )
    $fullyQualifiedDomainName = "moorecenter.org"
    $givenName = $User.'First Name'
    $givenNameFirst3Letters = $givenName[0..2] -join ""
    $surName = $User.'Last Name'
    $sAMAccountName = Get-SamAccountNameFromCsv -User $User
    $email = "${givenName}.${surName}@${fullyQualifiedDomainName}"
    # $fullName = Get-FullNameFromCsv -User $User
    $fullName = Get-TerminatedFullNameFromCsv -User $User

    $filter = {
        (
            ((GivenName -like "${givenNameFirst3Letters}*") -and (Surname -eq $surName)) -or
            ((GivenName -eq $givenName) -and (sAMAccountName -eq $sAMAccountName)) -or
            (GivenName -eq $givenName -and Surname -eq $surName) -or
            (Name -eq $fullName) -or
            (DisplayName -eq $fullName) -or
            (mail -eq $email) -or
            (EmailAddress -eq $email) -or
            ((proxyAddresses -like "*SMTP:$email*") -or (proxyAddresses -like "*smtp:$email*")) -or
            ((msExchShadowProxyAddresses -like "*SMTP:$email*") -or (msExchShadowProxyAddresses -like "*smtp:$email*"))
        )
    }
    $properties = "GivenName", "Surname", "Name", "DisplayName", "mail", "EmailAddress", "proxyAddresses", "msExchShadowProxyAddresses", "Enabled"
    $parameters = @{
        Filter     = $filter
        Properties = $properties
    }
        if (Get-ADUser @parameters) {
            return Get-ADUser @parameters
        }
        return @{
            SamAccountName = $sAMAccountName
            Name = $fullName
            Exists = $false
            Enabled = $false
        }
}

Function ConvertTo-DataTable {
    Param(
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$ArrayList
    )

    $table = New-Object System.Data.DataTable

    # Create columns based on the properties of the first object in the ArrayList
    $ArrayList[0].PSObject.Properties | ForEach-Object {
        $column = New-Object System.Data.DataColumn($_.Name)
        $table.Columns.Add($column)
    }

    # Add rows to the DataTable
    foreach ($item in $ArrayList) {
        $row = $table.NewRow()
        foreach ($prop in $item.PSObject.Properties) {
            $row[$prop.Name] = $prop.Value
        }
        $table.Rows.Add($row)
    }
    return $table | Sort-Object -Property sAMAccountName
}

Function Export-DataTableFile() {
    Param(
        [Parameter(Mandatory=$true)]
        [System.String]$FileName,
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$ArrayList
    )
    $timestamp = Get-Date -Format "yyyyMMdd.HHmm"
    $csvFilePath = "./data/output/${timestamp}_${FileName}.csv"
    $dataTable = ConvertTo-DataTable -ArrayList $ArrayList
    $dataTable | Export-Csv -Path $csvFilePath -NoTypeInformation
}

Function Confirm-UserDeleteStatus() {
    Param(
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$Source,
        [Parameter(Mandatory=$true)]
        [System.Array]$SamAccountNames
    )
<<<<<<< Updated upstream
    foreach ($samAccountName in $SamAccountNames) {
       $User =  $Source | Where-Object { $_.sAMAccountName -eq $samAccountName }
       ($User.Exists && !$User.Enabled) ? $user.SamAccountName : $samAccountName
=======
    foreach ($samAccountName in $MSPData) {
      "`$HRData is $HRData\n"
        $UsersOKToDelete += $HRData | Where-Object {
            ($sAMAccountName -eq $_.sAMAccountName) -and
            (-not $_.Enabled -and $_.Exists)
        }
>>>>>>> Stashed changes
    }
    return $UsersOKToDelete
}

Function Main() {
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]$HRFilePath,
        [Parameter(Mandatory = $true)]
        [System.String]$MSPFilePath,
        [Parameter(Mandatory = $false)]
        [System.Boolean]$ExportToFile = $false
    )

    $samAccountNames = @{}
    $fullNames = @{}
    $MSPDataList = Get-Content $MSPFilePath
    $HRDataCsv= Import-Csv $HRFilePath
    $ADObjects = New-Object System.Collections.ArrayList

<<<<<<< Updated upstream
    $HRData  = Import-Csv $HRFile
    foreach ($hrAccount in $HRFile) {
=======
    foreach ($hrAccount in $HRDataCsv) {
>>>>>>> Stashed changes
        $samAccountNames[$hrAccount] = (Get-SamAccountNameFromCsv -User $hrAccount)
        # $fullNames[$hrAccount] = (Get-FullNameFromCsv -User $hrAccount)
        $fullNames[$hrAccount] = (Get-TerminatedFullNameFromCsv -User $hrAccount)
        Get-ADAccountFromAttributes -User $hrAccount | ForEach-Object {
            $sAMAccountName = $_ ? $_.SamAccountName : $samAccountNames[$hrAccount]
            $fullName = $_ ? $_.Name : $fullNames[$hrAccount]
            $exists = $_.ObjectClass -eq "user"
            $enabled = $_.Enabled
            $ADObjects.Add([PSCustomObject]@{
                sAMAccountName = $sAMAccountName
                FullName       = $fullName
                Exists         = $exists
                Enabled        = $enabled
            })
            Write-Debug "`nsAMAccountName: ${sAMAccountName}`nFullName: ${fullName}`nExists: ${exists}`nEnabled: ${enabled}`n"
        }
    }
<<<<<<< Updated upstream
    $MSPData = Get-Content $MSPFile
    Confirm-UserDeleteStatus -
=======
    $OKToDelete = Confirm-DeleteStatus -MSPData $MSPDataList -HRData $ADObjects
    "OK to Delete is: $OKToDelete"

>>>>>>> Stashed changes
    if ($ExportToFile) {
        Export-DataTableFile -FileName "HR_All" -ArrayList $ADObjects
        Export-DataTableFile -FileName "MSP_OKToDelete" -ArrayList $OKToDelete
    }
<<<<<<< Updated upstream
=======
    
    
>>>>>>> Stashed changes
}

# Inputs
$_args = @{
<<<<<<< Updated upstream
    HRFile       = ".\data\input\Employee Roster 3.26.24.csv"
    MSPFile      = ".\data\input\userprofiles.txt"
    ExportToFile = $true
=======
    HRFilePath   = ".\data\input\Employee Roster 3.26.24.csv"
    MSPFilePath  = ".\data\input\userprofiles.txt"
    ExportToFile = $false
>>>>>>> Stashed changes
    Debug        = $true
}

# Entrypoint
Main @_args
