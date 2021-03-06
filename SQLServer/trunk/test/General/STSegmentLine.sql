SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Testing [$(owner)].[STSegmentLine] ...';
GO

with data as (
select 0 as testid, geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10,11 11,12 12,100 100,200 200)',0) as linestring
union all
select 1 as testid, geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0) as linestring
union all
select 2 as testid, geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246,0 7,-3 6.3246),(-3 6.3246,0 0,3 6.3246))',0) as linestring
union all
select 3 as testid, geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 0,1 2.1082,3 6.3246,0 7,-3 6.3246,-1 2.1082,0 0))',0) as linestring 
union all
select 4 as testid, geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (0 0,1 2.1082,3 6.3246), CIRCULARSTRING(3 6.3246,0 7,-3 6.3246), CIRCULARSTRING(-3 6.3246,-1 2.1082,0 0))',0) as linestring
union all
select 5 as testid, geometry::STGeomFromText('COMPOUNDCURVE((0 -23.43778,0 23.43778),CIRCULARSTRING(0 23.43778,-45 23.43778,-90 23.43778),(-90 23.43778,-90 -23.43778),CIRCULARSTRING(-90 -23.43778,-45 -23.43778,0 -23.43778))',0) as linestring
)
select t.*
  from data as d
       cross apply [$(owner)].[STSegmentLine](d.linestring) as t
where d.testid = 1;
GO

