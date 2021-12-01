#PingTest.PS1
cls;

$servers = "123", “OWSQLDDMO201", "OWSQL14O201", "abc"
Foreach($s in $servers)
{
    if((Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0 -quiet))
    {
        Write-Output "Problem connecting to $s";
        #Write-Output “Flushing DNS”;
        #ipconfig /flushdns | out-null;
        ipconfig | out-null;
        #Write-Output “Registering DNS”;
        #ipconfig /registerdns | out-null;
        #write-output “doing a NSLookup for $s”;
        #nslookup $s ;

        write-output “Re-pinging $s”;
        if(!(Test-Connection -Cn $s -BufferSize 16 -Count 1 -ea 0 -quiet))
            {“Problem still exists in connecting to $s"}
        ELSE 
            {“Resolved problem connecting to $s"};

    } # end if
} # end foreach
