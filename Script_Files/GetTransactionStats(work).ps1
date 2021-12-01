import-module dbatools

cls
#CONSTANTS FOR MANAGEMENT SERVER INFO
$srcsrvr = 'RWSQLMGMTH202'
$srcdb = 'DBA'
$srcTab = 'TransactionHistory'


#GET THE LIST OF SQL SERVERS
$Global:srvList = import-csv -path 'C:\PowerSh\Rollins\DBA_Admin\TxServers1.csv'

#RUN TO END FOR ALL SQL SERVERS IN LIST
FOREACH($instance in $Global:srvList.instance)
    {


#GET THE SQL SERVER START TIME FROM SOURCE SERVER
    $SQL = "select Convert(varchar,sqlserver_start_time,20) as [SrvStart] from SYS.dm_os_sys_info"

    $srvStartTime = Invoke-Sqlcmd -ServerInstance $instance -Query $SQL    


    
#GET THE LIST OF USER DATABASES ON EACH SQL SERVER IN THE LIST
    $DBSQL = "select distinct instance_name as 'name'
                        from SYS.sysperfinfo
                        where object_name like '%:Databases%'
                        and instance_name not in ('master','model', 'msdb','tempdb')"
            $global:DBList = Invoke-Sqlcmd -ServerInstance $instance -Query $DBSQL
        

#GET THE LAST RECORDED SQL STARTUP TIME FROM THE TRANSACTIONhISTORY TABLE            
    $SQL = "Select convert(varchar,MAX([SQL Server Startup Time]),20) as [CurrentStartup] from dbo.TransactionHistory where ServerName = '$instance'"
    $RecordedStartUp = invoke-sqlcmd -ServerInstance $srcsrv -Database $srcdb -query $SQL


#DETERMINE IF SQL INSTANCE HAS BEEN RE-STARTED
        IF($srvStartTime.SrvStart -eq $RecordedStartUp.CurrentStartup)
       {
        $timecomp = 1
        }
        ELSE
        {
        $timecomp = 0
        }

#IF SQL SERVER HAS NOT BEEN RE-STARTED, GET THE DATA TO UPDATE THE EXISTING ROWS IN THE TRANSACTIONHISTORY TABLE
        IF($timecomp -eq 1)
        {
        #CHECK FOR NAMED INSTANCE
            
            #PARSE THE INSTANCE NAME
            
            #RUN THIS SQL IF NAMED INSTANCE
            $SQL = "
            SELECT rtrim(@@SERVERName) AS [ServerName], rtrim(counter_name) as [CounterName], rtrim(instance_name) as [DatabaseName], cntr_value AS [Transactions(Cummulative)], 
            (cntr_value/(datediff(SS,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/Sec(Avg)],
            (cntr_value/(datediff(mi,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/min(Avg)],
            (cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/hr(Avg)],
            ((cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1)*24) as [Tranaction/day(Avg)],
            (CONVERT([decimal],datediff(ss,(select sqlserver_start_time from SYS.dm_os_sys_info),getdate())/(86400))) as[UpTime(Days)],                                                            
            '$srvStart' as [SQL Server Startup Time],
            GETDATE() AS [LastUpdate]
            FROM SYS.sysperfinfo
            WHERE cntr_type = 272696576        
            and instance_name not in ('master','model','msdb','tempdb')
            and object_name like '%:Databases%'  
            and counter_name in (
            'Transactions/sec',  
            'Write Transactions/sec')
            Order by Instance_Name" 
            
                    

            #GET THE UPDATE DATA SET
            $result = Invoke-Sqlcmd -ServerInstance $instance -Query $SQL 
            } 
                        
                foreach($dbname in $global:DBList.name)
                {
                $db1 = $dbname       
                 
                    $SQL1 = "
                        SELECT rtrim(@@SERVERName) AS [ServerName], rtrim(counter_name) as [CounterName], rtrim(instance_name) as [DatabaseName], cntr_value AS [Transactions(Cummulative)], 
                        (cntr_value/(datediff(SS,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/Sec(Avg)],
                        (cntr_value/(datediff(mi,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/min(Avg)],
                        (cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/hr(Avg)],
                        ((cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1)*24) as [Tranaction/day(Avg)],
                        '$srvStart' as [SQL Server Startup Time], GETDATE() AS [LastUpdate]
                        FROM SYS.sysperfinfo
                        WHERE cntr_type = 272696576 
                        and Instance_Name = '$db1'
                        and Counter_Name =  'Transactions/Sec'     
                        and instance_name not in ('master','model','msdb','tempdb')
                        and object_name like '%:Databases%'    
                        ORDER BY ServerName, DatabaseName DESC"                     

                 

                $result1 = Invoke-Sqlcmd -ServerInstance $instance -Query $SQL1                
           
               
                $sn = $result1.ServerName              
                $db = $result1.DatabaseName
                $counter = $result1.CounterName
                $tpsT = $result1.'Transactions(Cummulative)'               
                $tpsA = $result1.'Tranaction/Sec(Avg)'
                $tpaM = $result1.'Tranaction/min(Avg)'              
                $tpaH = $result1.'Tranaction/hr(Avg)'             
                $tpaD = $result1.'Tranaction/day(Avg)'               
                $LUpd = $result1.LastUpdate              
                
#write-host $sn,$db,$counter,$tpsT,$tpsA,$tpaM,$tpaH,$tpaD,$LUpd


                        $SQL2 = "                               
                        UPDATE [$srcTab]
                        SET 
                         [Transactions/sec(Cummulative)] = $tpsT,
                         [Transactions/sec(Avg)] = $tpsA,
                         [Transactions/Min(Avg)] = $tpaM,
                         [Transactions/Hr(Avg)] = $tpaH,
                         [Transactions/Day(Avg)] = $tpaD,
                         [LastUpdate] = '$LUpd'
                        WHERE [ServerName] = '$sn'
                        AND [DatabaseName] =  '$db'
                        AND [CounterName] = '$counter'
                        GO"

               Invoke-Sqlcmd -ServerInstance $srcsrv -Database $srcdb -Query $SQL2 -ErrorLevel 0
            }

           
                
                foreach($dbname in $global:DBList.name)
                {
                $db1 = $dbname                  
                       
                $SQL1 = "
                    SELECT rtrim(@@SERVERName) AS [ServerName], rtrim(counter_name) as [CounterName], rtrim(instance_name) as [DatabaseName], cntr_value AS [Transactions(Cummulative)], 
                    (cntr_value/(datediff(SS,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/Sec(Avg)],
                    (cntr_value/(datediff(mi,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/min(Avg)],
                    (cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/hr(Avg)],
                    ((cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1)*24) as [Tranaction/day(Avg)],
                    '$srvStart' as [SQL Server Startup Time], GETDATE() AS [LastUpdate]
                    FROM SYS.sysperfinfo
                    WHERE cntr_type = 272696576 
                    and Instance_Name = '$db1'
                    and Counter_Name =  'Write Transactions/Sec'     
                    and instance_name not in ('master','model','msdb','tempdb')
                    and object_name like '%:Databases%'    
                    ORDER BY ServerName, DatabaseName DESC" 
                

                
                
                
                $result1 = Invoke-Sqlcmd -ServerInstance $instance -Query $SQL1  
           
               
                $sn = $result1.ServerName              
                $db = $result1.DatabaseName
                $counter = $result1.CounterName
                $tpsT = $result1.'Transactions(Cummulative)'               
                $tpsA = $result1.'Tranaction/Sec(Avg)'
                $tpaM = $result1.'Tranaction/min(Avg)'              
                $tpaH = $result1.'Tranaction/hr(Avg)'             
                $tpaD = $result1.'Tranaction/day(Avg)'               
                $LUpd = $result1.LastUpdate   
                                       
#write-host $sn,$db,$counter,$tpsT,$tpsA,$tpaM,$tpaH,$tpaD,$LUpd    

                $SQL2 = "
                        USE $srcdb 
                                 
                        UPDATE [$srcTab]
                        SET 
                         [Transactions/sec(Cummulative)] = $tpsT,
                         [Transactions/sec(Avg)] = $tpsA,
                         [Transactions/Min(Avg)] = $tpaM,
                         [Transactions/Hr(Avg)] = $tpaH,
                         [Transactions/Day(Avg)] = $tpaD,
                         [LastUpdate] = '$LUpd'
                        WHERE [ServerName] = '$sn'
                        AND [DatabaseName] =  '$db'
                        AND [CounterName] = '$counter'
                        GO"

    
                Invoke-Sqlcmd -ServerInstance $srcsrv -Database $srcdb -Query $SQL2 -ErrorLevel 0
            }
        
             

#THIS SECTION INSERTS A NEW RECORD IF THE SQL SERVER INSTANCE HAS BEEN RE-STARTED
        IF($timecomp -eq 0)
        {                   
            
                $SQL = "
                SELECT rtrim(@@SERVERName) AS [ServerName], rtrim(counter_name) as [CounterName], rtrim(instance_name) as [DatabaseName], cntr_value AS [Transactions(Cummulative)], 
                (cntr_value/(datediff(SS,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/Sec(Avg)],
                (cntr_value/(datediff(mi,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/min(Avg)],
                (cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1) as [Tranaction/hr(Avg)],
                ((cntr_value/(datediff(hh,getdate(),(select sqlserver_start_time from SYS.dm_os_sys_info)))*-1)*24) as [Tranaction/day(Avg)],
                (CONVERT([decimal],datediff(ss,(select sqlserver_start_time from SYS.dm_os_sys_info),getdate())/(86400))) as[UpTime(Days)],                                                            
                '$srvStart' as [SQL Server Startup Time],
                GETDATE() AS [LastUpdate]
                FROM SYS.sysperfinfo
                WHERE cntr_type = 272696576        
                and instance_name not in ('master','model','msdb','tempdb')
                and object_name like '%:Databases%'   
                and counter_name in (
                'Transactions/sec',  
                'Write Transactions/sec')
                Order by Instance_Name"               
        
                  
            $result = Invoke-Sqlcmd -ServerInstance $instance -Query $SQL -ErrorLevel 0
 
            Write-SqlTableData -ServerInstance $srcsrvr -DatabaseName $srcdb -SchemaName dbo -TableName $srcTab -InputData $Result
            }
    }
    
        
    
