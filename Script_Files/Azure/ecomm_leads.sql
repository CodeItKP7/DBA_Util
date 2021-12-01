SELECT 
	ml.MarketingLeadId, ml.ExternalId, ml.CampaignId, ml.FirstName, ml.LastName, ml.IsOwner, ml.Address1,
	ml.City, ml.State, ml.PostalCode, ml.PrimaryPhone, ml.SecondaryPhone, ml.Email, ml.ServiceLinesCsv, ml.CreatedDate,
	ml.ServiceGroupId, ml.CaseId, ml.Comments, ml.BranchId, ml.EstimateId, ml.OriginalCaseId, ml.Source, ml.CreatedInBoss, prog.programid,
	CASE WHEN prog.programid IS NULL THEN NULL ELSE
		(	Select Sum (SaleValue) as salevalue 
			from eventvaluehistory 
			where programid = prog.programid 
			and HistoryType = 1 
			and IsEventInOriginalProgramSale = 1 
			group by programid) 
	END as salevalue
FROM	[contact360].[MarketingLead] ml
		LEFT JOIN [dbo].[tprogram] prog ON ml.CaseId = prog.CaseId
WHERE	source = 'ECOMM'
AND		ml.FirstName not like 'test%'
AND		ml.LastName not like 'test%'
AND		ml.Email not like '%capgemini%'
AND		ml.Email not like '%rollins%'
ORDER BY MarketingLeadId DESC