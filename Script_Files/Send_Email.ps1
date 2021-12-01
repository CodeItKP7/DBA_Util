
param   ( [parameter(Position=0, Mandatory=$true,ValueFromPipeline=$true)] [string]$pFilePath,
          [parameter(Position=1, Mandatory=$true,ValueFromPipeline=$true)] [string]$pSubj
        );

$ErrorActionPreference = "Stop";
$smtpServer = "smtprelay.rollins.local";


try
{
    $msg = new-object Net.Mail.MailMessage
    $att = new-object Net.Mail.Attachment($pFilePath)
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = "dbaalert@rollins.com"
    $msg.To.Add("dbaalert@rollins.com")
    $msg.CC.Add("jbmoore@Rollins.com")
    $msg.Subject = $pSubj
    $msg.Body = "This is an automated message. Please see attached file." + "`r`n`n" + "Thank you."
    $msg.Attachments.Add($att)
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
    $msg.Subject = "Email Step failed - " + $pSubj
    $msg.Body = "This is an automated message. " + "`r`n`n" + "Thank you." + "`r`n`n" + "Exception Type: $($_.Exception.GetType().FullName)" + "`r`n`n" + "Exception Message: $($_.Exception.Message)"
    $smtp.Send($msg)
 }
finally
{
    #$att.Dispose();
    #$smtp.Dispose();
 }