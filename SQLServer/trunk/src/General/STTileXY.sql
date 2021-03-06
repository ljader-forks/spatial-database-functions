SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STTileXY]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STTileXY];
  PRINT 'Dropped [$(owner)].[STTileXY] ...';
END;
GO

PRINT 'Creating [$(owner)].[STTileXY] ...';
GO

CREATE FUNCTION [$(owner)].[STTileXY]
(
  @p_ll_x   float,
  @p_ll_y   float,
  @p_ur_x   float,
  @p_ur_y   float,
  @p_TileX  float,
  @p_TileY  float,
  @p_rx     float,
  @p_ry     float,
  @p_rangle float,
  @p_srid   int = 0
)
returns @table table
(
  col  Int,
  row  Int,
  geom geometry 
)
as
/****f* TILING/STTileXY (2008)
 *  NAME
 *    STTileXY -- Covers supplied envelope (LL/UR) with a mesh of tiles of size TileX and TileY.
 *  SYNOPSIS
 *    Function STTileXY (
 *               @p_ll_x   float,
 *               @p_ll_y   float,
 *               @p_ur_x   float,
 *               @p_ur_y    float,
 *               @p_TileX  float,
 *               @p_TileY  float,
 *               @p_rx     float,
 *               @p_ry     float,
 *               @p_rangle float,
 *               @p_srid   int = 0
 *             )
 *     Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
*  DESCRIPTION
 *    Function that takes a spatial extent (LL/UR), computes the number of tiles that cover it and
 *    the table array with its col/row reference.
 *    The number of columns and rows that cover this area is calculated using @p_TileX/@p_TileY which
 *    are in @p_SRID units.
 *    All rows and columns are visited, with polygons being created that represent each tile.
 *    If @p_rx/@p_ry/@p_rangle are supplied, the resultant grid is rotated around @p_rx and @p_ry angle @p_rangle.
 *  INPUTS
 *    @p_ll_x  (float) - Spatial Extent's lower left X ordinate.
 *    @p_ll_y  (float) - Spatial Extent's lower left Y ordinate.
 *    @p_ur_x  (float) - Spatial Extent's uppre righ X ordinate.
 *    @p_ur_y  (float) - Spatial Extent's uppre righ Y ordinate.
 *    @p_TileX (float) - Size of a Tile's X dimension in real world units.
 *    @p_TileY (float) - Size of a Tile's Y dimension in real world units.
 *    @p_rX    (float) - X ordinate of rotation point.
 *    @p_rY    (float) - Y ordinate of rotation point.
 *    @p_rangle (float) - Rotation angle expressed in decimal degrees between 0 and 360.
 *    @p_srid    (int) - Geometric SRID.
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  EXAMPLE
 *    SELECT row_number() over (order by t.col, t.row) as rid, 
 *           t.col, t.row, t.geom.STAsText() as geom
 *      FROM [$(owner)].[STTileXY](0,0,1000,1000,250,250,NULL,NULL,NULL,0) as t;
 *    GO
 *
 *    rid col row geom
 *    --- --- --- -----------------------------------------------------------
 *     1  0   0   POLYGON ((0 0, 250 0, 250 250, 0 250, 0 0))
 *     2  0   1   POLYGON ((0 250, 250 250, 250 500, 0 500, 0 250))
 *     3  0   2   POLYGON ((0 500, 250 500, 250 750, 0 750, 0 500))
 *     4  0   3   POLYGON ((0 750, 250 750, 250 1000, 0 1000, 0 750))
 *     5  1   0   POLYGON ((250 0, 500 0, 500 250, 250 250, 250 0))
 *     6  1   1   POLYGON ((250 250, 500 250, 500 500, 250 500, 250 250))
 *     7  1   2   POLYGON ((250 500, 500 500, 500 750, 250 750, 250 500))
 *     8  1   3   POLYGON ((250 750, 500 750, 500 1000, 250 1000, 250 750))
 *     9  2   0   POLYGON ((500 0, 750 0, 750 250, 500 250, 500 0))
 *    10  2   1   POLYGON ((500 250, 750 250, 750 500, 500 500, 500 250))
 *    11  2   2   POLYGON ((500 500, 750 500, 750 750, 500 750, 500 500))
 *    12  2   3   POLYGON ((500 750, 750 750, 750 1000, 500 1000, 500 750))
 *    13  3   0   POLYGON ((750 0, 1000 0, 1000 250, 750 250, 750 0))
 *    14  3   1   POLYGON ((750 250, 1000 250, 1000 500, 750 500, 750 250))
 *    15  3   2   POLYGON ((750 500, 1000 500, 1000 750, 750 750, 750 500))
 *    16  3   3   POLYGON ((750 750, 1000 750, 1000 1000, 750 1000, 750 750))
 * 
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
     @v_loCol int,
     @v_hiCol int,
     @v_loRow int,
     @v_hiRow int,
     @v_col   int,
     @v_row   int,
     @v_srid  int = ISNULL(@p_srid,0),
     @v_wkt   nvarchar(max),
     @v_tile  geometry;
   BEGIN
     SET @v_loCol = FLOOR(   @p_LL_X / @p_TileX );
     SET @v_hiCol = CEILING( @p_UR_X / @p_TileX ) - 1;
     SET @v_loRow = FLOOR(   @p_LL_Y / @p_TileY );
     SET @v_hiRow = CEILING( @p_UR_Y / @p_TileY ) - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(100), ROUND(@v_col * @p_TileX,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @p_TileY,6))                + ',' +
                 CONVERT(varchar(100), ROUND(((@v_col * @p_TileX) + @p_TileX),6)) + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @p_TileY,6))                + ',' +
                 CONVERT(varchar(100), ROUND(((@v_col * @p_TileX) + @p_TileX),6)) + ' ' + 
                 CONVERT(varchar(100), ROUND(((@v_row * @p_TileY) + @p_TileY),6)) + ',' +
                 CONVERT(varchar(100), ROUND(@v_col * @p_TileX,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(((@v_row * @p_TileY) + @p_TileY),6)) + ',' +
                 CONVERT(varchar(100), ROUND(@v_col * @p_TileX,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @p_TileY,6))                + '))';
         SET @v_tile = geometry::STGeomFromText(@v_WKT,@p_srid);
         IF ( @p_rx is not null and @p_ry is not null and COALESCE(@p_rangle,0) <> 0 ) 
            SET @v_tile = [$(owner)].[STRotate]( @v_tile, @p_rx, @p_ry, @p_rangle, 15, 15);
         INSERT INTO @table (   col,   row,geom)
                     VALUES (@v_col,@v_row,@v_tile);
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
END;
go



