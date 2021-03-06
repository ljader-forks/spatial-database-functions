SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STBearingAlongLine]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STBearingAlongLine];
  Print 'Dropped [$(owner)].[STBearingAlongLine] ...';
END;
GO

Print 'Creating [$(owner)].[STBearingAlongLine] ...';
GO

CREATE FUNCTION [$(cogoowner)].[STBearingAlongLine] 
(
  @p_linestring geometry
)
Returns Float
AS
/****m* COGO/STBearingAlongLine (2008)
 *  NAME
 *    STBearingAlongLine -- Returns a (Normalized) bearing in Degrees along a non-geodetic linestring geometry's first and last point
 *  SYNOPSIS
 *    Function STBearingAlongLine (
 *               @p_linestring geometry
 *             )
 *     Returns float 
 *  DESCRIPTION
 *    Function that computes the bearing from the supplied linestring's start and end points.
 *    The result is expressed as a whole circle bearing in decimal degrees.
 *  INPUTS
 *    @p_linestring (geometry) - LineString.
 *  RESULT
 *    decimal degrees (float) - Bearing between point 1 and 2 from 0-360.
 *  EXAMPLE
 *    SELECT [$(cogoowner)].[STBearingAlongLine] (
 *             geometry::STGeomFromText('LINESTRING(0 0,45 45)',0) 
 *           ) as Bearing;
 *    Bearing
 *    45
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2019 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  If (@p_linestring IS NULL)
    Return NULL;
  Return [$(cogoowner)].[STBearing] (
            @p_linestring.STStartPoint().STX,
            @p_linestring.STStartPoint().STY,
            @p_linestring.STEndPoint().STX,
            @p_linestring.STEndPoint().STY
         );
End;
GO

