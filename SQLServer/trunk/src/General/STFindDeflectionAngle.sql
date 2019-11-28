SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) Cogo($(cogoowner))';
GO

:On Error Ignore

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindDeflectionAngle]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindDeflectionAngle];
  PRINT 'Dropped [$(cogoowner)].[STFindDeflectionAngle] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STFindDeflectionAngle]...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindDeflectionAngle]
(
  @p_from_line geometry,
  @p_to_line   geometry
)
Returns Float
AS
/****f* COGO/STFindDeflectionAngle (2012)
 *  NAME
 *   STFindDeflectionAngle - Computes deflection angle between from line and to line.
 *  SYNOPSIS
 *    Function STFindDeflectionAngle
 *               @p_from_line geometry 
 *               @p_to_line   geometry
 *             )
 *      Return Float
 *  DESCRIPTION
 *    Supplied with a second linestring (@p_next_line) whose first point is the same as 
 *    the last point of @p_line, this function computes the deflection angle from the first line to the second
 *    in the direction of the first line.
 *  NOTES
 *    Only supports CircularStrings from SQL Server Spatial 2012 onwards, otherwise supports LineStrings from 2008 onwards.
 *    @p_line must be first segment whose STEndPoint() is the same as @p_next_line STStartPoint(). No other combinations are supported.
 *  INPUTS
 *    @p_from_line (geometry) - A linestring segment
 *    @p_to_line   (geometry) - A second linestring segment whose direction is computed from the start linestring direction + deflection angle.
 *  RESULT
 *    angle           (float) - Deflection angle in degrees.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - April 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_from_bearing     Float,
    @v_to_bearing       Float,
    @v_deflection_angle Float,
    @v_prev_point       geometry,
    @v_mid_point        geometry,
    @v_next_point       geometry;
  BEGIN
    IF ( @p_from_line is null or @p_to_line is null ) 
      Return NULL;

    IF ( @p_from_line.STGeometryType() NOT IN ('LineString','CircularString') 
      OR   @p_to_line.STGeometryType() NOT IN ('LineString','CircularString') 
       )
      Return NULL;

    -- Because we support circularStrings, we support only single segments ....
    IF ( ( @p_from_line.STGeometryType() = 'LineString'     and @p_from_line.STNumPoints() > 2 ) 
      OR (   @p_to_line.STGeometryType() = 'LineString'     and   @p_to_line.STNumPoints() > 2 ) 
      OR ( @p_from_line.STGeometryType() = 'CircularString' and @p_from_line.STNumPoints() > 3 )
      OR (   @p_to_line.STGeometryType() = 'CircularString' and   @p_to_line.STNumPoints() > 3 ) )
      Return null;

    -- Get intersection(mid) point
    SET @v_mid_point = @p_from_line.STEndPoint();

    -- Intersection point must be shared.
    IF ( @v_mid_point.STEquals(@p_to_line.STStartPoint())=0 )
      return NULL;

    -- Get previous and next points of 3 point angle.
    IF ( @p_from_line.STGeometryType()='CircularString' ) 
    BEGIN
      SET @v_prev_point = [$(cogoowner)].[STComputeTangentPoint](@p_from_line,'END',8);
      SET @v_next_point = [$(cogoowner)].[STComputeTangentPoint](@p_to_line,'START',8);
    END
    ELSE
    BEGIN
      SET @v_prev_point = @p_from_line.STStartPoint(); 
      SET @v_next_point = @p_to_line.STEndPoint();
    END;

    SET @v_from_bearing = [$(cogoowner)].[STBearingBetweenPoints] ( 
                               /* @p_start  */ @v_prev_point,
                               /* @p_centre */ @v_mid_point
                           );

    SET @v_to_bearing   = [$(cogoowner)].[STBearingBetweenPoints] ( 
                               /* @p_centre */ @v_mid_point,
                               /* @p_start  */ @v_next_point
                           );

    IF ( @v_from_bearing = @v_to_bearing ) 
      Return 0.0;

    SET @v_deflection_angle = @v_to_bearing - @v_from_bearing;
    SET @v_deflection_angle = case when @v_deflection_angle > 180.0 
                                   then @v_deflection_angle - 360.0
                                   when @v_deflection_angle < -180.0
                                   then @v_deflection_angle + 360.0
                                   else @v_deflection_angle
                               end;
    Return @v_deflection_angle;
  END;
END;
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


