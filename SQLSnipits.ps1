

$ServerInstnace = "DC-APPSDSQL02.thadmin.com"
$database = "PlatypusII"


#Test SQL Server Connection
Function Test-SQLConnection ($Server) {
    $connectionString = "Data Source=$Server;Integrated Security=true;Initial Catalog=master;Connect Timeout=3;"
    $sqlConn = New-Object ("Data.SqlClient.SqlConnection") $connectionString
    trap
    {
        Write-Error "Cannot connect to $Server.";
        exit
    }

    $sqlConn.Open()
    if ($sqlConn.State -eq 'Open')
    {
        $sqlConn.Close();
    }
}

#Run-SQLQuery function which allows use to run queries against SQL and return them as a PSObject
Function Run-SQLQuery {
    #Params
    [CmdletBinding()]
    Param(
    [parameter(position=0)]
        $ServerInstance,
    [parameter(position=1)]
        $Database,
    [parameter(position=2)]
        $Query
    )

    #Open SQL Connection
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
    $SqlConnection.ConnectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True" 
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand 
    $SqlCmd.Connection = $SqlConnection 
    $SqlCmd.CommandText = $Query 
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter 
    $SqlAdapter.SelectCommand = $SqlCmd 
    $DataSet = New-Object System.Data.DataSet 
    $a=$SqlAdapter.Fill($DataSet) 
    $SqlConnection.Close() 
    $DataSet.Tables[0]
}