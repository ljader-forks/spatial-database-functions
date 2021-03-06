SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STIsCollinear] ...';
GO

select [$(owner)].[STIsCollinear](geometry::STGeomFromText('LINESTRING(0 0,1 0)',0),0.0) as avgBearing;
GO

select [$(owner)].[STIsCollinear](geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0)',0),0.0) as avgBearing;
GO

select [$(owner)].[STIsCollinear](geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,3 0,4 0.1)',0),0.0) as avgBearing;
GO

select [$(owner)].[STIsCollinear](geometry::STGeomFromText('LINESTRING(0 0,1 1,2 0,3 1,4 0.1)',0),0.0) as avgBearing;
GO

