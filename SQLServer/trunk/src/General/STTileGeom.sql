USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STTileGeom]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STTileGeom];
  PRINT 'Dropped [$(owner)].[STTileGeom] ...';
END;
GO

PRINT 'Creating [$(owner)].[STTileGeom] ...';
GO

CREATE FUNCTION [$(owner)].[STTileGeom]
(
  @p_geometry geometry,
  @p_TileX    float,
  @p_TileY    float,
  @p_rx       float,
  @p_ry       float,
  @p_rangle   float
)
returns @table table
(
  col  Int,
  row  Int,
  geom geometry
)
AS
/****f* TILING/STTileGeom (2008)
 *  NAME
 *    STTileGeom -- Covers envelope of supplied goemetry with a mesh of tiles of size TileX and TileY.
 *  SYNOPSIS
 *    Function [$(owner)].[STTileGeom] (
 *               @p_geometry geometry,
 *               @p_TileX  float,
 *               @p_TileY  float,
 *               @p_rx     float,
 *               @p_ry     float,
 *               @p_rangle float,
 *             )
 *     Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  DESCRIPTION
 *    Function that takes a non-ppoint geometry type, determines its spatial extent (LL/UR),
 *    computes the number of tiles given the tile size @p_TileX/@p_TileY (real world units),
 *    creates each tile as a polygon, and outputs it in the table array with its col/row reference.
 *    The lower left and upper right coordinates are calculated as follows:
 *      LL.X = @p_geometry.STEnvelope().STPointN(1).STX;
 *      LL.Y = @p_geometry.STEnvelope().STPointN(1).STY;
 *      UR.X = @p_geometry.STEnvelope().STPointN(3).STX;
 *      UR.Y = @p_geometry.STEnvelope().STPointN(3).STY;
 *    The number of columns and rows that cover this area is calculated.
 *    All rows and columns are visited, with polygons being created that represent each tile.
 *    If @p_rx/@p_ry/@p_rangle are supplied, the resultant grid is rotated around @p_rx and @p_ry angle @p_rangle.
 *  INPUTS
 *    @p_geometry (geometry) -- Column reference 
 *    @p_TileX       (float) -- Size of a Tile's X dimension in real world units.
 *    @p_TileY       (float) -- Size of a Tile's Y dimension in real world units.
 *    @p_rX          (float) - X ordinate of rotation point.
 *    @p_rY          (float) - Y ordinate of rotation point.
 *    @p_rangle       (float) - Rotation angle expressed in decimal degrees between 0 and 360.
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    SELECT t.col, t.row, t.geom.STAsText() as geom
 *      FROM [$(owner)].[STTileGeom] (
 *             geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
 *             400,200,0,0,0
 *          ) as t;
 *    GO
 *
 *    col row geom
 *    --- --- ------------------------------------------------------------
 *    0   0   POLYGON ((0 0, 400 0, 400 200, 0 200, 0 0))
 *    0   1   POLYGON ((0 200, 400 200, 400 400, 0 400, 0 200))
 *    0   2   POLYGON ((0 400, 400 400, 400 600, 0 600, 0 400))
 *    0   3   POLYGON ((0 600, 400 600, 400 800, 0 800, 0 600))
 *    0   4   POLYGON ((0 800, 400 800, 400 1000, 0 1000, 0 800))
 *    1   0   POLYGON ((400 0, 800 0, 800 200, 400 200, 400 0))
 *    1   1   POLYGON ((400 200, 800 200, 800 400, 400 400, 400 200))
 *    1   2   POLYGON ((400 400, 800 400, 800 600, 400 600, 400 400))
 *    1   3   POLYGON ((400 600, 800 600, 800 800, 400 800, 400 600))
 *    1   4   POLYGON ((400 800, 800 800, 800 1000, 400 1000, 400 800))
 *    2   0   POLYGON ((800 0, 1200 0, 1200 200, 800 200, 800 0))
 *    2   1   POLYGON ((800 200, 1200 200, 1200 400, 800 400, 800 200))
 *    2   2   POLYGON ((800 400, 1200 400, 1200 600, 800 600, 800 400))
 *    2   3   POLYGON ((800 600, 1200 600, 1200 800, 800 800, 800 600))
 *    2   4   POLYGON ((800 800, 1200 800, 1200 1000, 800 1000, 800 800))
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *    Simon Greener - October  2019 - Added rotation capability
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
   DECLARE
     @v_srid  Int,
     @v_ll_x  float,
     @v_ll_y  float,
     @v_ur_x  float,
     @v_ur_y  float,
     @v_loCol int,
     @v_hiCol int,
     @v_loRow int,
     @v_hiRow int,
     @v_col   int,
     @v_row   int,
     @v_wkt   nvarchar(max),
     @v_tile  geometry;
   BEGIN
     IF ( @p_geometry is null )
       Return;
     IF ( @p_geometry.STGeometryType() = 'Point' )
       Return;
     SET @v_srid = @p_geometry.STSrid;
     SET @v_ll_x = @p_geometry.STEnvelope().STPointN(1).STX;
     SET @v_ll_y = @p_geometry.STEnvelope().STPointN(1).STY;
     SET @v_ur_x = @p_geometry.STEnvelope().STPointN(3).STX;
     SET @v_ur_y = @p_geometry.STEnvelope().STPointN(3).STY;

     SET @v_loCol = FLOOR(   @v_LL_X / @p_TileX );
     SET @v_hiCol = CEILING( @v_UR_X / @p_TileX ) - 1;
     SET @v_loRow = FLOOR(   @v_LL_Y / @p_TileY );
     SET @v_hiRow = CEILING( @v_UR_Y / @p_TileY ) - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + '))';
         SET @v_tile = geometry::STGeomFromText(@v_WKT,@v_srid);
         IF ( @p_rx is not null and @p_ry is not null and COALESCE(@p_rangle,0) <> 0 ) 
            SET @v_tile = [$(owner)].[STRotate]( @v_tile, @p_rx, @p_ry, @p_rangle, 15, 15 );
         INSERT INTO @table VALUES(@v_col,@v_row,@v_tile);
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
END;
GO

Print 'Testing [$(owner)].[STTileGeom] ...';
GO

SELECT t.col, t.row, t.geom.STAsText() as geom
  FROM [$(owner)].[STTileGeom] (
         geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
         400,200,
         0,0,0) as t;
GO

SELECT t.col, t.row, t.geom.STAsText() as geom
  FROM [$(owner)].[STTileGeom] (
         geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
         400,200,
         0,0,45) as t;
GO

QUIT;
GO

