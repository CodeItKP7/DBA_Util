
param   ( [parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)] [string]$pSubj
        );

$ErrorActionPreference = "Stop";
$smtpServer = "smtprelay.rollins.local";


try
{
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = "dbaalert@rollins.com"
    $msg.To.Add("dbaalert@rollins.com")
    $msg.Subject = $pSubj
    $msg.Body = "This is an automated message." + "`r`n`n" + "Please verify job history for error details." + "`r`n`n" + "Thank you."
    $smtp.Send($msg)
    #$att.Dispose()
    #$smtp.Dispose()
}
catch
{
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = "dbaalert@rollins.com"
    $msg.To.Add("ssubrama@rollins.com")
    $msg.Subject = "Script Error Email Step failed - " + $pSubj
    $msg.Body = "This is an automated message. " + "`r`n`n" + "Thank you." + "`r`n`n" + "Exception Type: $($_.Exception.GetType().FullName)" + "`r`n`n" + "Exception Message: $($_.Exception.Message)"
    $smtp.Send($msg)
 }
finally
{
    #$att.Dispose();
    #$smtp.Dispose();
 }