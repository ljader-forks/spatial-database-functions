SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STRemoveDuplicatePoints] ...';
GO

-- ********************************************************************
select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0) as line;
GO

select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0).STNumPoints() as line;
GO

select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0).STIsValid() as line;
GO

select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0).MakeValid().STNumPoints() as line;
GO


select 'Text XY Ordinates' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0),3,null,null).AsTextZM() as fixedLine
union all select 'Test XY ordinates of XYZ' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,null,null).AsTextZM() as fixedLine
union all select 'Test XYZ ordinates of XYZ with Z digits that maintains Z' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,2,null).AsTextZM() as fixedLine
union all select 'Test XYZ ordinates of XYZ with Z digits that does not maintain Z' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,0,null).AsTextZM() as fixedLine
union all select 'Test XY ordinates of XYZM with precision that ignores Z and M differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,null,null).AsTextZM() as fixedLine
union all select 'Test XYZ ordinates of XYZM with Z digits that maintains Z but ignores M differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,2,null).AsTextZM() as fixedLine
union all select 'Test XYM ordinates of XYZM with M digits that maintains M but ignores Z differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,null,1).AsTextZM() as fixedLine
union all select 'Test XYMZ ordinates of XYZM with Z/M digits that maintains Z/M' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,1,1).AsTextZM() as fixedLine;
GO

