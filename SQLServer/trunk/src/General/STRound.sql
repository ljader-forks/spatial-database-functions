SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STRound]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STRound];
  PRINT 'Dropped [$(owner)].[STRound] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STGeogRound]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STGeogRound];
  PRINT 'Dropped [$(owner)].[STGeogRound] ...';
END;
GO

PRINT '################################';
PRINT 'Creating [$(owner)].[STRound] ...';
GO

CREATE FUNCTION [$(owner)].[STRound]
(
  @p_geometry geometry,
  @p_round_x int = 3,
  @p_round_y int = 3,
  @p_round_z int = 2,
  @p_round_m int = 2
)
Returns geometry
/****f* EDITOR/STRound (2008)
 *  NAME
 *    STRound -- Function which rounds the ordinates of the supplied geometry.
 *  SYNOPSIS
 *    Function [dbo].[STRound] (
 *               @p_geometry geometry,
 *               @p_round_x int = 3,
 *               @p_round_y int = 3,
 *               @p_round_z int = 2,
 *               @p_round_m int = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    The result of many geoprocessing operations in any spatial type can be geometries 
 *    with ordinates (X, Y etc) that have far more decimal digits of precision than the initial geometry.
 *
 *    Additionally, some input GIS formats, such as shapefiles (which has no associated precision model), 
 *    when loaded, can show far more decimal digits of precision in the created ordinates misrepresenting 
 *    the actual accuracy of the data.
 *
 *    STRound takes a geometry object and some specifications of the precision of any X, Y, Z or M ordinates, 
 *    applies those specifications to the geometry and returns the corrected geometry.
 * 
 *    The @p_round_* values are expressed as decimal digits of precision, which are used in TSQL's ROUND function 
 *    to round each ordinate value.
 *  PARAMETERS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *    @p_round_x       (int) - Decimal degrees of precision to which X ordinate is rounded.
 *    @p_round_y       (int) - Decimal degrees of precision to which Y ordinate is rounded.
 *    @p_round_z       (int) - Decimal degrees of precision to which Z ordinate is rounded.
 *    @p_round_m       (int) - Decimal degrees of precision to which M ordinate is rounded.
 *  RESULT
 *    geometry -- Input geometry moved by supplied X and Y ordinate deltas.
 *  EXAMPLE
 *    -- Geometry
 *    -- Point
 *    SELECT [dbo].[STRound](geometry::STPointFromText('POINT(0.345 0.282)',0),1,1,0,0).STAsText() as RoundGeom
 *    UNION ALL 
 *    -- MultiPoint
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),3,3,1,1).STAsText() as RoundGeom 
 *    UNION ALL 
 *    -- Linestring
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),2,2,1,1).STAsText() as RoundGeom
 *    UNION ALL 
 *    -- LinestringZ
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2 0.312,1.4 45.2 1.5738)',0),2,2,1,1).AsTextZM() as RoundGeom
 *    UNION ALL 
 *    -- Polygon
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),2,2,1,1).STAsText() as RoundGeom
 *    UNION ALL 
 *    -- MultiPolygon
 *    SELECT [dbo].[STRound](
 *             geometry::STGeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
 *              2,2,1,1).STAsText() as RoundGeom
 *    
 *    RoundGeom
 *    POINT (0.3 0.3)
 *    MULTIPOINT ((100.122 100.345), (388.839 499.404))
 *    LINESTRING (0.1 0.2, 1.4 45.2)
 *    LINESTRING (0.1 0.2 0.3, 1.4 45.2 1.6)
 *    POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))
 *    MULTIPOLYGON (((160 400, 200 400, 200 480, 160 480, 160 400)), ((100 200, 180 300, 100 300, 100 200)))
 *
 *    -- Geography
 *    SELECT [dbo].STToGeography(
 *             [dbo].[STRound](
 *               [dbo].STToGeometry(
 *                     geography::STGeomFromText('LINESTRING(141.29384764892390 -43.93834736282 234.82756,
 *                                                           141.93488793487934 -44.02323872332 235.26384)',
 *                                               4326),
 *                     4326
 *               ),
 *               6,7,
 *               3,1
 *             ),
 *             4326
 *           ).AsTextZM() as rGeom;
 *    
 *    rGeom
 *    LINESTRING (141.293848 -43.9383474 234.828, 141.934888 -44.0232387 235.264)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for SQL Server.
 *    Simon Greener - November 2019 - Modified to allow for 4 ordinate precision parameters (support Geography)
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    @v_wkt           varchar(max) = '',
    @v_wkt_remainder varchar(max),
    @v_dimensions    varchar(4),
    @v_round_x       int = 3,
    @v_round_y       int = 3,
    @v_round_z       int = 2,
    @v_round_m       int = 2,
    @v_pos           int = 0,
    @v_x             Float = 0.0,
    @v_y             Float = 0.0,
    @v_z             Float = NULL,
    @v_m             Float = NULL,
    @v_point         geometry;

  If ( @p_geometry is NULL ) 
    Return @p_geometry;

  If ( @p_geometry.STIsValid() = 0 ) 
    Return @p_geometry;

  SET @v_dimensions = 'XY' 
                      + case when @p_geometry.HasZ=1 then 'Z' else '' end +
                      + case when @p_geometry.HasM=1 then 'M' else '' end;

  SET @v_round_x = ISNULL(@p_round_x,3);
  SET @v_round_y = ISNULL(@p_round_y,3);
  SET @v_round_z = ISNULL(@p_round_z,2);
  SET @v_round_m = ISNULL(@p_round_m,2);

  -- Shortcircuit for simplest case
  IF ( @p_geometry.STGeometryType() = 'Point' ) 
  BEGIN
    SET @v_wkt = 'POINT(' 
                 +
                 [$(owner)].[STPointAsText] (
                        /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                        /* @p_X          */ @p_geometry.STX,
                        /* @p_Y          */ @p_geometry.STY,
                        /* @p_Z          */ @p_geometry.Z,
                        /* @p_M          */ @p_geometry.M,
                        /* @p_round_x    */ @v_round_x,
                        /* @p_round_y    */ @v_round_y,
                        /* @p_round_z    */ @v_round_z,
                        /* @p_round_m    */ @v_round_m
                 )
                 + 
                 ')';
    Return geometry::STPointFromText(@v_wkt,@p_geometry.STSrid);
  END;

  SET @v_wkt_remainder = @p_geometry.AsTextZM();
  SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
  SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

  WHILE ( LEN(@v_wkt_remainder) > 0 )
  BEGIN
     -- Is the start of v_wkt_remainder a coordinate?
     IF ( @v_wkt_remainder like '[-0-9]%' ) 
      BEGIN
       -- We have a coord
       -- Now get position of end of coordinate string
       SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                         then CHARINDEX(')',@v_wkt_remainder)
                         when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                         then CHARINDEX(',',@v_wkt_remainder)
                         else CHARINDEX(')',@v_wkt_remainder)
                     end;
       -- Create a geometry point from WKT coordinate string
       SET @v_point = geometry::STPointFromText(
                        'POINT(' 
                        + 
                        SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                        + 
                        ')',
                        @p_geometry.STSrid);         
       -- Add to WKT
       SET @v_wkt   = @v_wkt 
                      + 
                      [$(owner)].[STPointAsText] (
                              /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                              /* @p_X          */ @v_point.STX,
                              /* @p_Y          */ @v_point.STY,
                              /* @p_Z          */ @v_point.Z,
                              /* @p_M          */ @v_point.M,
                              /* @p_round_x    */ @p_round_x,
                              /* @p_round_y    */ @p_round_y,
                              /* @p_round_z    */ @v_round_z,
                              /* @p_round_m    */ @v_round_m
                      );
       -- Now remove the old coord from v_wkt_remainder
       SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));
     END
     ELSE
     BEGIN
       -- Move to next character
       SET @v_wkt           = @v_wkt + SUBSTRING(@v_wkt_remainder,1,1);
       SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
     END;
  END; -- Loop
  Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
End;
GO

PRINT 'Creating [$(owner)].[STGeogRound] ...';
GO

CREATE FUNCTION [$(owner)].[STGeogRound]
(
  @p_geography geography,
  @p_round_lat  int = 8,
  @p_round_long int = 8,
  @p_round_z    int = 2,
  @p_round_m    int = 2
)
Returns geography
/****f* EDITOR/STGeogRound (2008)
 *  NAME
 *    STGeogRound -- Function which rounds the Long/Lat ordinates of the supplied geography.
 *  SYNOPSIS
 *    Function [$(owner)].[STGeogRound] (
 *               @p_geometry geography,
 *               @p_round_lat  int = 8,
 *               @p_round_long int = 8,
 *               @p_round_z    int = 2,
 *               @p_round_m    int = 2
 *             )
 *     Returns geography
 *  DESCRIPTION
 *    The result of many geoprocessing operations in any spatial type can be geometries 
 *    with ordinates (X, Y etc) that have far more decimal digits of precision than the initial geometry.
 *
 *    Additionally, some input GIS formats, such as shapefiles (which has no associated precision model), 
 *    when loaded, can show far more decimal digits of precision in the created ordinates misrepresenting 
 *    the actual accuracy of the data.
 *
 *    STGeogRound takes a geography object and some specifications of the precision of any X, Y, Z or M ordinates, 
 *    applies those specifications to the geography and returns the corrected geometry.
 * 
 *    The @p_round_ll/@p_round_zm values are decimal digits of precision, which are used in TSQL's ROUND function 
 *    to round each ordinate value.
 *  NOTES
 *    Is wrapper over [STRound]
 *  PARAMETERS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *    @p_round_lat     (int) - Decimal degrees of precision to which Lat ordinate is rounded.
 *    @p_round_long    (int) - Decimal degrees of precision to which Long ordinate is rounded.
 *    @p_round_z       (int) - Decimal degrees of precision to which Z ordinate is rounded.
 *    @p_round_m       (int) - Decimal degrees of precision to which M ordinate is rounded.
 *  RESULT
 *    geometry -- Input geometry moved by supplied X and Y ordinate deltas.
 *  EXAMPLE
 *    -- Geography
 *    SELECT [$(owner)].[STGeogRound](
 *             geography::STGeomFromText('LINESTRING(141.29384764892390 -43.93834736282 234.82756,
 *                                                   141.93488793487934 -44.02323872332 235.26384)',
 *             4326),
 *               7,7
 *               1,1
 *             )
 *           ).AsTextZM() as rGeog
 *    
 *    rGeom
 *    LINESTRING (141.2938476 -43.9383474 234.8, 141.9348879 -44.0232387 235.3)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - November 2019 - Original Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Return [$(owner)].[STToGeography] (
            [$(owner)].[STRound](
               [$(owner)].[STToGeometry](
                     @p_geography,
                     @p_geography.STSrid
               ),
               @p_round_long, @p_round_lat, 
               @p_round_z,    @p_round_m
            ),
            4326
           );      
End;
GO

