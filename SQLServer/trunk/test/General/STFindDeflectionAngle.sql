SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO


PRINT 'Testing [$(cogoowner)].[STFindDeflectionAngle] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 5 0)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 4.33 2.5)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 2.5 4.33)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 0 5)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, -2.5 4.33)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, -4.33 2.5)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, -5 0)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, -4.33 -2.5)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, -2.5 -4.33)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 0 -5)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 2.5 -4.33)',0) as rotate_line union all
select geometry::STGeomFromText('LINESTRING (-5 0, 0 0)',0) as base_line,geometry::STGeomFromText('LINESTRING (0 0, 4.33 -2.5)',0) as rotate_line 
)
select Round([$(cogoowner)].[STFindDeflectionAngle] (base_line,rotate_Line),1)  as deflectionAngle
  from data as f;
GO

with data as (
select geometry::STGeomFromText('CIRCULARSTRING(0 0,1 1,2 0)',0) as cString union all
select geometry::STGeomFromText('CIRCULARSTRING(0 0,1 -1,2 0)',0) as cString union all
select geometry::STGeomFromText('CIRCULARSTRING(0 0,1 1,0 2)',0) as cString union all
select geometry::STGeomFromText('CIRCULARSTRING(0 2,1 1,0 0)',0) as cString union all
select geometry::STGeomFromText('CIRCULARSTRING(0 0,1 -1,0 -2)',0) as cString union all
select geometry::STGeomFromText('CIRCULARSTRING(0 0,-1 -1,0 -2)',0) as cString
)
select Round([$(cogoowner)].[STFindDeflectionAngle] (cString,NULL),1)  as deflectionAngle,
       cString
  from data as f;
GO
