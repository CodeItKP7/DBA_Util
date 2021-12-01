
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
    $msg.From = "DBA "+"donotreply@rollins.com"

    $msg.To.Add("EDonoghue@rollins.com")
    $msg.To.Add("gmelerin@rollins.com") #added 04/15/2021
#    $msg.To.Add("rrollins3@rollins.com") #removed 04/15/2021
#    $msg.To.Add("sweaver@Rollins.com") #removed 04/01/2021

    $msg.CC.Add("khorlach@rollins.com")
    $msg.CC.Add("tbrady@rollins.com")
    $msg.CC.Add("CGlover@rollins.com")
    $msg.CC.Add("chris.adams@rollins.com")
    $msg.CC.Add("jbolith1@rollins.com")
    $msg.CC.Add("kjackson@rollins.com")
    $msg.CC.Add("Ijohnson@Rollins.com")
    $msg.CC.Add("gscott@rollins.com") #added 01/22/2021
    $msg.CC.Add("dbaalert@rollins.com")

#    $msg.To.Add("ssubrama@rollins.com")
#    $msg.CC.Add("kjackson@rollins.com")
#    $msg.CC.Add("jbolith1@rollins.com")
#    $msg.CC.Add("bsmith12@rollins.com")
#    $msg.To.Add("tzimmerman@rollins.com") #removed 01/22/2021

    $msg.Subject = $pSubj
    $msg.Body = "This is an automated message. Please see attached file." + "`r`n`n" + "Thank you."
    $msg.Attachments.Add($att)
    $smtp.Send($msg)
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