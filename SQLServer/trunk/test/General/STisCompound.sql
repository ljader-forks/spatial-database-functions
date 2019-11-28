SET ANSI_NULLS ON;
SET ARITHABORT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Testing [$(owner)].[STIsCompound] ...';
GO

SELECT [$(owner)].[STIsCompound](GEOMETRY::STGeomFromText(' CURVEPOLYGON( COMPOUNDCURVE( CIRCULARSTRING(0 5,5 0,10 5,5 10,0 5))) ',0)) as isCompound;
GO


