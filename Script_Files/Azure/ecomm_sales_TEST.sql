select		et.[BasketId], isnull(wcb.accountid, 0) as [accountid], et.[FirstName], et.[LastName], et.[PhoneNumber], et.[EmailAddress], et.[EmailOptIn], et.[BillingStreetNumber], et.[BillingStreetName], 
		et.[BillingCity], et.[BillingState], et.[BillingZipCode], et.[BillingFullAddress], et.[ServiceStreetNumber], et.[ServiceStreetName], et.[ServiceCity], et.[ServiceState], 
		et.[ServiceZipCode], et.[ServiceFullAddress], et.[Acreage], et.[AcreageDescription], et.[CallToSchedule], et.[BillingSameAsService], et.[BillingFirstName], et.[BillingLastName], 
		et.[LastStep], et.[AppointmentDate], et.[AppointmentTime], et.[TransactionResponse], et.[TransactionToken], et.[ServiceName], et.[ServiceType], et.[BasePrice], et.[SalesTax], 
		et.[Subtotal], et.[TotalDueToday], et.[IsPropertyOwner], et.[CampaignCode], et.[UserAgent], et.[AcceptTermsAndConditions], et.[SessionStart], et.[SessionComplete], 
		et.[ServiceFrequency], et.[PestName], et.[PromoCode], et.[OriginalPrice], et.[Bathrooms], 
		--isnull(wcb.basketstatus, 'NULL') as [basketstatus],
		--isnull(wcb.processingsummary, 'NULL') as [processingsummary], 
		wcb.utcdatecreated
from		[dbo].[Staging_EcommerceTransaction] et
left join	[dbo].[Staging_tWebCommerceBasket_TEST] wcb
on		et.basketid = wcb.basketid
order by   et.[SessionStart] desc
