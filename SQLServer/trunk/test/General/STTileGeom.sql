SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(owner)].[STTileGeom] ...';
GO

SELECT t.colN, t.rowN, t.tile.STBuffer(0.1) as geom
  FROM [$(owner)].[STTileGeom] (
         geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
         10,10,
         0,0,0,1) as t;
GO

SELECT t.colN, t.rowN, t.tile as geom
  FROM [$(owner)].[STTileGeom] (
         geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
         10,10,
         0,0,45,0) as t;
GO


