SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT *
             FROM $(owner).sysobjects 
            WHERE id = object_id (N'[$(owner)].[STInsertN]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STInsertN];
  PRINT 'Dropped [$(owner)].[STInsertN] ...';
END;
GO

PRINT 'Creating [$(owner)].[STInsertN] ...';
GO

CREATE FUNCTION [$(owner)].[STInsertN]
(
  @p_geometry geometry,
  @p_point    geometry,
  @p_position integer,
  @p_round_xy int   = 3,
  @p_round_zm int   = 2
)
Returns geometry
As
/****f* EDITOR/STInsertN (2012)
 *  NAME
 *    STInsertN -- Function which inserts new coordinate (p_point) at position @p_position in the supplied geometry.
 *  SYNOPSIS
 *    Function STInsertN (
 *               @p_geometry geometry,
 *               @p_point    geometry,
 *               @p_position int,
 *               @p_round_xy int,
 *               @p_round_zm int 
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    Function that inserts the coordinate @p_point into position @p_position in the supplied geometry.
 *    @p_position Values:
 *      1. null -> defaults to 1;
 *      2. -1   -> maximum number of points ie STNumPoints(p_geometry) 
 *      3. Greater than STNumPoints(p_geometry) -> maximum number of points ie STNumPoints(p_geometry)
 *    The inserted coordinate's ordinates are rounded to @p_round_xy number of decimal digits of precision.
 *  NOTES
 *    This version is for SQL Server versions from 2012 onwards.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied geometry of any type.
 *    @p_point    (geometry) - Insert coordinate
 *    @p_position (int)      - Coordinate position in @p_geometry: between 1 and STNumPoints.
 *    @p_round_xy (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm (int)      - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    geometry -- Input geometry with coordinate inserted.
 *  EXAMPLE
 *    SELECT STInsertN(
 *             STGeomFromText ('LINESTRING(0 0,2 2)',0),
 *             STPointFromText('POINT(1 1)',0),
 *             2,
 *             1,1 ).AsTextZM() as newGeom;
 *    # updatedGeom
 *    'LINESTRING(0 0,1 1,2 2)'
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
     @v_wkt         varchar(max) = '',
     @v_dimensions  varchar(4), 
     @v_token       varchar(max),
     @v_delim       varchar(max),
     @v_insert_posn int,
     @v_ipoint      varchar(max) = '',
     @v_gType       varchar(max) = '',
     @v_round_xy    int          = ISNULL(@p_round_xy,3), 
     @v_round_zm    int          = ISNULL(@p_round_zm,2), 
     @v_coord       int          = 0,
     @v_position    int          = 0,
     @v_rows        int          = 0,
     @v_cValue      Float        = 0.0,
     @v_x           Float        = 0.0,
     @v_y           Float        = 0.0,
     @v_z           Float        = NULL,
     @v_m           Float        = NULL,
     @v_geometry    geometry;
  Begin
    IF ( @p_geometry is NULL ) 
    BEGIN
      RETURN CASE WHEN ( @p_point is not null ) THEN @p_point ELSE NULL END;
    END;

    IF ( @p_point is null) 
    BEGIN
       RETURN @p_geometry;
    END;

    If ( @p_geometry.STGeometryType() = 'GeometryCollection') 
    BEGIN
       RETURN @p_geometry; -- N'GeometryCollection p_geometry not supported.';
    END;

    If ( @p_point.STGeometryType() <> 'Point') 
    BEGIN
       RETURN @p_geometry; -- N'p_point must be a single point geometry.';
    END;

    IF ( ISNULL(@p_geometry.STSrid,-1) != ISNULL(@p_point.STSrid,-1) )
    BEGIN
      RETURN @p_geometry;
    END;

    -- Set flag for STPointFromText
    -- @p_dimensions => XY, XYZ, XYM, XYZM or NULL (XY)
    SET @v_dimensions = 'XY' 
                       + case when @p_geometry.HasZ=1 then 'Z' else '' end 
                       + case when @p_geometry.HasM=1 then 'M' else '' end;

    Set @v_insert_posn = case when @p_position = 0
                              then 1
                              when @p_position < 0 
                                   OR
                                   @p_position > @p_geometry.STNumPoints() + 1 
                              then @p_geometry.STNumPoints() + 1 
                              else @p_position
                          end;

    Set @v_ipoint = [$(owner)].[STPointAsText] (
                          /* @p_dimensions */ @v_dimensions,
                          /* @p_X          */ @p_point.STX,
                          /* @p_Y          */ @p_point.STY,
                          /* @p_Z          */ @p_point.Z,
                          /* @p_M          */ @p_point.M,
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_zm,
                          /* @p_round_m    */ @v_round_zm
                    ) ;

    -- Short circuit for two points.
    IF ( @p_geometry.STGeometryType() = 'Point' ) 
    BEGIN
      Set @v_token = [$(owner)].[STPointAsText] (
                          /* @p_dimensions */ @v_dimensions,
                          /* @p_X          */ @p_geometry.STX,
                          /* @p_Y          */ @p_geometry.STY,
                          /* @p_Z          */ @p_geometry.Z,
                          /* @p_M          */ @p_geometry.M,
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_zm,
                          /* @p_round_m    */ @v_round_zm
                    );
      Set @v_wkt = 'MULTIPOINT((' 
                   +
                   case when @v_insert_posn = 1 then @v_ipoint else @v_token end
                   +
                   '),('
                   +
                   case when @v_insert_posn = 1 then @v_token else @v_ipoint end
                   +
                   '))';
      Return geometry::STGeomFromText ( @v_wkt, @p_geometry.STSrid );
    END;

    Set @v_position = 0;
    Set @v_coord    = 0;
    Set @v_rows     = 0;
    DECLARE Tokens CURSOR FAST_FORWARD FOR
      SELECT t.token, t.separator
        FROM [$(owner)].[TOKENIZER](@p_geometry.AsTextZM(),' ,()') as t;
    OPEN Tokens;
    FETCH NEXT FROM Tokens 
          INTO @v_token, 
               @v_delim;
    WHILE @@FETCH_STATUS = 0
    BEGIN
       IF ( @v_token is null )  -- double delimiter
       BEGIN
          SET @v_wkt = @v_wkt + @v_delim
       END
       ELSE
       BEGIN
          IF ( @v_token not like '[-0-9]%' and @v_token <> 'NULL' ) 
          BEGIN
             IF ( @v_token = 'POINT' )
             BEGIN
                SET @v_token = REPLACE(@v_token,'POINT','MULTIPOINT(');
             END;
             SET @v_gType = @v_token;
             SET @v_wkt   = @v_wkt + @v_token + LTRIM(@v_delim)
          END
          ELSE -- @v_token LIKE '[0-9]%' or @v_token = 'NULL'  
          BEGIN
             SET @v_coord  = @v_coord + 1;
             SET @v_cValue = CASE WHEN @v_token = 'NULL' then NULL else CONVERT(Float,@v_token) end;
             IF ( @v_coord = 1 ) SET @v_x = @v_cValue;
             IF ( @v_coord = 2 ) SET @v_y = @v_cValue; 
             IF ( @v_coord = 3 ) SET @v_z = @v_cValue;
             IF ( @v_coord = 4 ) SET @v_m = @v_cValue;
             IF ( @v_delim in (',',')') )
             BEGIN
                SET @v_position  = @v_position + 1;
                IF ( @v_position = @v_insert_posn )
                BEGIN
                   SET @v_wkt = @v_wkt    + 
                                @v_ipoint + 
                                case when @v_gType LIKE 'MULTIPOINT%' 
                                     then '),(' 
                                     else ', ' 
                                 end;
                END;
                SET @v_wkt = @v_wkt 
                             + 
                             [$(owner)].[STPointAsText] (
                                /* @p_dimensions */ @v_dimensions,
                                /* @p_X          */ @v_X,
                                /* @p_Y          */ @v_Y,
                                /* @p_Z          */ @v_Z,
                                /* @p_M          */ @v_M,
                                /* @p_round_x    */ @v_round_xy,
                                /* @p_round_y    */ @v_round_xy,
                                /* @p_round_z    */ @v_round_zm,
                                /* @p_round_m    */ @v_round_zm
                             );
                SET @v_coord = 0;
                IF (    @v_position    = @p_geometry.STNumPoints() 
                    AND @v_insert_posn = @v_position + 1)
                BEGIN
                   SET @v_wkt = @v_wkt + 
                                case when @v_gType LIKE 'MULTIPOINT%' 
                                     then '),(' 
                                     else ', '
                                  end + 
                                @v_ipoint;
                END;
                SET @v_wkt = @v_wkt + @v_delim;
             END;
           END;
       END;
       FETCH NEXT FROM Tokens 
             INTO @v_token, @v_delim;
    END;
    IF ( @p_geometry.STGeometryType() = 'Point' )
    BEGIN
      SET @v_wkt = @v_wkt + ')';
    END;
    CLOSE Tokens
    DEALLOCATE Tokens
    SET @v_geometry = geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
    RETURN @v_geometry;
  End
End;
Go




