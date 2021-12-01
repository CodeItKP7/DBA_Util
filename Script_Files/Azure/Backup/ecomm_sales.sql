select		et.[ReferenceId], wcb.utcdatecreated, et.[FirstName], et.[LastName], et.[PhoneNumber], et.[EmailAddress], et.[EmailOptIn], et.[BillingStreetNumber], et.[BillingStreetName], 
		et.[BillingCity], et.[BillingState], et.[BillingZipCode], et.[BillingFullAddress], et.[ServiceStreetNumber], et.[ServiceStreetName], et.[ServiceCity], et.[ServiceState], 
		et.[ServiceZipCode], et.[ServiceFullAddress], et.[Acreage], et.[AcreageDescription], et.[CallToSchedule], et.[BillingSameAsService], et.[BillingFirstName], et.[BillingLastName], 
		et.[LastStep], et.[AppointmentDate], et.[AppointmentTime], et.[TransactionResponse], et.[TransactionToken], et.[ServiceName], et.[ServiceType], et.[BasePrice], et.[SalesTax], 
		et.[Subtotal], et.[TotalDueToday], et.[IsPropertyOwner], et.[CampaignCode], et.[UserAgent], et.[AcceptTermsAndConditions], et.[Querystring], et.[SessionStart], et.[SessionComplete], 
		et.[ServiceFrequency], et.[SecondaryServiceName], et.[SecondaryServiceType], et.[SecondaryServiceFrequency], et.[PestName], et.[PromoCode], et.[OriginalPrice], et.[Bathrooms], et.[BasketId],
		isnull(wcb.accountid, 0) as [accountid], isnull(wcb.basketstatus, 'NULL') as [basketstatus], isnull(wcb.processingsummary, 'NULL') as [processingsummary]
from		[dbo].[Staging_EcommerceTransaction] et
left join	[dbo].[Staging_tWebCommerceBasket] wcb
on		et.basketid = wcb.basketid
order by    	wcb.utcdatecreated desc
