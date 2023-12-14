/*here we will analyze paid and unpaid channel and there perfomance */


/* With gsearch site performing better, Now management have lunched second paid search channel 'bsearch' 
   now they are looking for weekly trended session volume and compare to 'gsearch' nonbrand,
   date limit >2012-8-22 to <2012-11-29 */


select 
    -- yearweek(created_at) as yrwk,
     min(date(created_at)) as week_start_date,
    --  count(distinct website_session_id) as total_sessions,
     count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
     count(distinct case when utm_source = 'bsearch' then website_session_id else null end ) as bsearch_sessions
     
     from website_sessions
     where created_at > '2012-08-22' -- specified in request 
         and  created_at < '2012-11-29' -- dictated by the time of the request
         and utm_campaign ='nonbrand' -- limitin to nonbrand paid search
group by yearweek (created_at);
     
 -- device wise analysis of gsearch and bsearch traffic
 
 select utm_source,
        count(distinct website_session_id) as sessions,
        count(distinct case when device_type = 'mobile' then website_session_id else null end ) as mobile_sessions,
		count(distinct case when device_type = 'mobile' then website_session_id else null end )/ count(distinct website_session_id) as mobile_cvr_rate
        
        from website_sessions
       
     where created_at > '2012-08-22' -- specified in request 
         and  created_at < '2012-11-29' -- dictated by the time of the request
         and utm_campaign ='nonbrand' -- limitin to nonbrand paid search
		 -- and utm_source in ('/gsearch','/bsearch')
    group by utm_source;
    
    
 /*find out nonbrand conversion rates from session to order for gsearch and bsearch and slice the 
   data by device type , date limit >2012-08-22 to < 2012-09-18 */
    
 -- cross channel bid optimization 
 select website_sessions.device_type,
       website_sessions.utm_source,
       count(distinct website_sessions.website_session_id) as sessions,
       count(distinct orders.order_id) as orders,
       count(distinct orders.order_id) / count(distinct website_sessions.website_session_id) as cvr_rate
       from website_sessions
       left join orders
       on
	    website_sessions.website_session_id= orders.website_session_id
        where website_sessions.created_at > '2012-08-22'
        and website_sessions.created_at < '2012-09-18'
        and utm_campaign ='nonbrand'
        group by 1,2;
        
        
/* from the last analysis we get to know that 'bsearch' is non generating enougf traffic so management
   decided to bid down for gsearch, now they are looking for wwekly session volume for gsearch and bsearch nonbrand,
   broken down by device and compare to show bsearch as a percent of gsearch for each device date limit >2012-11-04 to <2012-12-22 */

  select 
        yearweek(created_at ) as year_week,
        min(date(created_at)) as week_start_date,
        count(distinct case when utm_source ='gsearch'  and device_type ='desktop' then website_session_id else null end )as gsearch_desktop_session,
        count(distinct case when utm_source ='bsearch' and device_type= 'desktop' then website_session_id else null end) as bsearch_desktop_session,
        count(distinct case when utm_source ='bsearch' and device_type= 'desktop' then website_session_id else null end)/
        count(distinct case when utm_source ='gsearch'  and device_type ='desktop' then website_session_id else null end ) as b_pct_of_g_desktop,
        count(distinct case when utm_source ='gsearch'  and device_type ='mobile' then website_session_id else null end )as gsearch_mobile_session,
        count(distinct case when utm_source ='bsearch' and device_type= 'mobile' then website_session_id else null end)as bsearch_mobile_session,
        count(distinct case when utm_source ='bsearch' and device_type= 'mobile' then website_session_id else null end)/
       count(distinct case when utm_source ='gsearch'  and device_type ='mobile' then website_session_id else null end ) as b_pct_of_g_mobile
    
   from website_sessions
   where created_at > '2012-11-04'
    and created_at< '2012-12-22'
    and utm_campaign = 'nonbrand'
group by 
      yearweek(created_at);
    

/*potential invester is asking if we're building any momentum with our brand or if we'll need to keep relying on paid traffic,
so now will have to find out organic search ,direct type in ,and paid brand search sessions by month, and show those sessions as % of paid nonbrand.alter
date limit<2012-12-23.*/


select 
     year(created_at) as yr,
     month(created_at) as mo,
     count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end ) as nonbrand,
     count(distinct case when channel_group = 'paid_brand' then website_session_id else null end ) as brand,
     count(distinct case when channel_group = 'paid_brand' then website_session_id else null end )/
     count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end ) as brand_pct_of_nonbrand,
     count(distinct case when channel_group = 'direct_type_in' then website_session_id else null end ) as direct,
     count(distinct case when channel_group = 'direct_type-in' then website_session_id else null end)/
     count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end ) as direct_pct_of_nonbrand,
     count(distinct case when channel_group ='organic_search' then website_session_id else null end) as organic,
     count(distinct case when channel_group = 'organic_search' then website_session_id else null end)/
     count(distinct case when channel_group = 'paid_nonbrand' then website_session_id else null end ) as organic_pct_of_nonbrand
   from (select
   website_session_id,
   created_at,
   case 
       when utm_source is null and http_referer in('https://www.gsearch.com','https://www.bsearch.com')then 'organic_search'
       when utm_campaign='nonbrand' then 'paid_nonbrand'
       when utm_campaign ='brand' then 'paid_brand'
       when utm_source is null and http_referer is null then 'direct_type_in'
       end as channel_group
  from website_sessions
  where created_at < '2012-12-23'
  )as sessions_w_channel_group
  group by 
  year(created_at),
  month(created_at)
  ; 
     
