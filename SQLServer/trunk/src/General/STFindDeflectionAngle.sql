SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) Cogo($(cogoowner))';
GO

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
 *    Two modes:
 *    If @p_from_line and @p_to_line are supplied the function generates the deflection angle between them.
 *    If only @p_from_line is supplied it must be a CIRCULARSTRING whereby deflection angle is computed from 
 *    points 1,2 and 2,3. *Useful for computing rotation of circular arc to left or to right.
 *    If @p_to_line is supplied its first point must be the same as the last point of @p_from_line.
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
    @v_bearing1         Float,
    @v_bearing2         Float,
    @v_deflection_angle Float;
  IF ( @p_from_line is null OR 
     ( @p_to_line is null AND @p_from_line.STGeometryType() <> 'CIRCULARSTRING')  )
    Return NULL;

  IF ( @p_from_line.STGeometryType() NOT IN ('LineString','CircularString') 
    OR @p_to_line is not null AND @p_to_line.STGeometryType() NOT IN ('LineString','CircularString') 
     )
    Return NULL;

  -- Because we support circularStrings, we support only single segments ....
  IF ( ( @p_from_line.STGeometryType() = 'LineString'     and @p_from_line.STNumPoints() > 2 ) 
    OR ( @p_from_line.STGeometryType() = 'CircularString' and @p_from_line.STNumPoints() > 3 ) )
    Return NULL;

  IF ( @p_to_line is not null 
      AND (   @p_to_line.STGeometryType() = 'LineString'     and   @p_to_line.STNumPoints() > 2 ) 
       OR (   @p_to_line.STGeometryType() = 'CircularString' and   @p_to_line.STNumPoints() > 3 ) )
    Return null;

  IF ( @p_to_line is null ) 
  BEGIN
    SET @v_bearing1 = [$(cogoowner)].[STNormalizeBearing] (
                          [$(cogoowner)].[STBearingBetweenPoints] (
                            @p_from_line.STPointN(1),
                            @p_from_line.STPointN(2)
                          )
                        );

    SET @v_bearing2 = [$(cogoowner)].[STNormalizeBearing] (
                          [$(cogoowner)].[STBearingBetweenPoints] (
                            @p_from_line.STPointN(2),
                            @p_from_line.STPointN(3)
                          )
                        );
  END
  ELSE
  BEGIN
    SET @v_bearing1 = [$(cogoowner)].[STNormalizeBearing] (
                           [$(cogoowner)].[STBearingBetweenPoints] (
                              @p_from_line.STPointN(1),
                               @p_from_line.STPointN(2)
                           )
                     );
    SET @v_bearing2 = [$(cogoowner)].[STNormalizeBearing] (
                           [$(cogoowner)].[STBearingBetweenPoints] (
                             @p_to_line.STStartPoint(),
                             @p_to_line.STEndPoint()
                           )
                        );
  End;

  SET @v_deflection_angle = @v_bearing2 - @v_bearing1;
  SET @v_deflection_angle = case when @v_deflection_angle > 180.0 
                                 then @v_deflection_angle - 360.0
                                 when @v_deflection_angle < -180.0
                                 then @v_deflection_angle + 360.0
                                 else @v_deflection_angle
                               end;
  RETURN @v_deflection_angle;

END;
GO
