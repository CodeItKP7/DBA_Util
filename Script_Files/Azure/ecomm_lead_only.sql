SELECT
	wcb.accountid,
	li.basketid,
	firstname,
	lastname,
	ph.phonenumber,
	c.emailaddress, 
	streetname,
	streetnumber,
	addr.city, --(would like to get this added)
	addr.[state],
	postalcode,
	firstservicedate,
	timeoptiondesc,
	est.programtypeid,-- I think they want this to be if the lead is sold pull that program information
	wcb.utcdatecreated,
	leadtypeid,
	ISNULL(br1.glprefix, br2.glprefix) branchnumber,
	ISNULL(bc11.categoryname, bc22.categoryname) region,
	ISNULL(bc1.categoryname, bc11.categoryname) division,
	li.createdsource
FROM
    tWebCommerceBasketLineItem li
    join twebcommercebasket wcb on li.basketid=wcb.basketid
    left join taccount acc on acc.accountid=wcb.accountid
    inner join tcontact c on c.contactid=wcb.primarycontactid
    left join taddress addr on addr.addressid=li.addressid
    left join ttimeoptionsetupname tosn on tosn.timeoptionid=li.timeoptionid and tosn.languageid=0
	left join tbranch br1 on br1.glprefix=li.branchnumber
	left join tbranchcategory bc1 ON bc1.branchcategoryid=br1.branchdistrictid
	left join tbranchcategory bc11 ON bc11.branchcategoryid=br1.branchregionid
	left join tbranch br2 on br2.branchid=li.servicecenterid
	left join tbranchcategory bc2 ON bc2.branchcategoryid=br2.branchdistrictid
	left join tbranchcategory bc22 ON bc22.branchcategoryid=br2.branchregionid
	outer apply ( 
		select top 1 p.programtypeid from testimate e join tprogram p on p.estimateid=e.estimateid
		where e.siteid=li.siteid
			and e.estimatetypeid=li.leadtypeid
		order by e.estimateid, p.programid
	) est
	inner join tcontactphonenumber ph on ph.phoneid = c.primaryphoneid
	
WHERE
    li.leadonly=1
	and li.createdsource<>5--eCommerce
ORDER BY
    li.basketid DESC 

--select top 100 --programtypeid,
--* from testimate e --join tprogram p on p.estimateid=e.estimateid --where accountid=34450456

--select * from tWebCommerceBasketLineItem li
--    join twebcommercebasket wcb on li.basketid=wcb.basketid
--where li.basketid=1971
