SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STRound] ...';
GO

-- Point
select [$(owner)].[STRound](geometry::STPointFromText('POINT(0.345 0.282)',0),1,1,1,1).STAsText() as RoundGeom;
GO

-- MultiPoint
SELECT [$(owner)].[STRound](geometry::STGeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),3,3,1,1).STAsText() as RoundGeom; 
GO

-- Linestring
select [$(owner)].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),2,2,1,1).STAsText() as RoundGeom;
GO

-- LinestringZ
select [$(owner)].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2 0.312,1.4 45.2 1.5738)',0),2,2,1,1).AsTextZM() as RoundGeom;
GO

-- Polygon
select [$(owner)].[STRound](geometry::STGeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),2,2,1,1).STAsText() as RoundGeom;
GO

-- MultiPolygon
select [$(owner)].[STRound](
         geometry::STGeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          2,2,1,1).STAsText() as RoundGeom;
GO

-- Geography
-- Can't overload existing STRound so have to use conversion functions.
SELECT [$(owner)].STToGeography(
         [$(owner)].[STRound](
           [$(owner)].STToGeometry(
                 geography::STGeomFromText('LINESTRING(141.29384764892390 -43.93834736282 234.82756,
                                                       141.93488793487934 -44.02323872332 235.26384)',
                                           4326),
                 4326
           ),
           6,7,
           3,1
         ),
         4326
       ).AsTextZM() as rGeom;
GO

PRINT 'Testing [STGeogRound] ...';
GO

SELECT [$(owner)].[STGeogRound](
          geography::STGeomFromText('LINESTRING(141.29384764892390 -43.93834736282 234.82756,
                                                141.93488793487934 -44.02323872332 235.26384)',
                                    4326),
          7,7,
          1,1
         ).AsTextZM() as rGeog;
GO

