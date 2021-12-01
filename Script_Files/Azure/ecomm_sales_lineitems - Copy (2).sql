SELECT TOP 100
    li.basketid,
    li.lineitemid,
    li.addressid,
    li.siteid,
    c.firstname,
    c.lastname,
    c.businessname,
    addr.streetname,
    addr.streetnumber,
    addr.[state],
    addr.postalcode,
    tosn.timeoptiondesc,
    li.[programtypeid]
      ,li.[customerdisplayedinitialprice]
      ,li.[customerdisplayedrecurringprice]
      ,li.[utclastchanged]
      ,li.[utcdatecreated]
      ,li.[lastchangedby]
      ,li.[servicecenterid]
      ,li.[leadtypeid]
      ,li.[primarytargetid]
      ,li.[bathroomsnumber]
      ,li.[firstservicedate]
      ,li.[timeoptionid]
      ,li.[customerdisplayedinitialtax]
      ,li.[customerdisplayedrecurringtax]
      ,li.[applyeasypay]
      ,li.[numberofmonthstoservice]
      ,li.[specificmonthstoservice]
      ,li.[couponcode]
      ,li.[discountvaluetype]
      ,li.[discountvalue]
      ,li.[priceoverride]
      ,li.[leadonly]
      ,li.[branchnumber]
      ,li.[createdsource]
      ,li.[sourceid]
FROM
    tWebCommerceBasketLineItem li
    join twebcommercebasket wcb on li.basketid=wcb.basketid
    left join taccount acc on acc.accountid=wcb.accountid
    left join tcontact c on c.contactid=acc.primarycontactid
    left join taddress addr on addr.addressid=li.addressid
    left join ttimeoptionsetupname tosn on tosn.timeoptionid=li.timeoptionid and tosn.languageid=0
ORDER BY
    li.basketid DESC
