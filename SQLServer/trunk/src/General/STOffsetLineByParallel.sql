USE [DEVDB]
GO
/****** Object:  UserDefinedFunction [dbo].[STOffsetLineByParallel]    Script Date: 21-Oct-19 1:07:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[STOffsetLineByParallel]
(
  @p_linestring  geometry,
  @p_offset      Float,
  @p_round_xy    int = 3,
  @p_round_zm    int = 2
)
Returns varchar(max) -- geometry 
AS
/****f* GEOPROCESSING/STOffsetLineByParallel (2012)
 *  NAME
 *    STOffsetLineByParallel -- Creates new linestring a line at a fixed offset from the input 2 point LineString or 3 point CircularString.
 *  SYNOPSIS
 *    Function STOffsetLineByParallel (
 *               @p_linestring geometry,
 *               @p_offset     float, 
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry
 *  EXAMPLE
 *    WITH data AS (
 *     SELECT geometry::STGeomFromText('CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3)',0) as segment
 *     UNION ALL
 *     SELECT geometry::STGeomFromText('LINESTRING (-3 6.3 1.1 9.3, 0 0 1.4 16.3)',0) as segment
 *  )
 *  SELECT 'Before' as text, d.segment.AsTextZM() as rGeom from data as d
 *  UNION ALL
 *  SELECT 'After' as text, [$(owner)].STOffsetLineByParallel(d.segment,1,3,2).AsTextZM() as rGeom from data as d;
 *  GO
 *  DESCRIPTION
 *    This function creates a parallel line at a fixed offset to the supplied LineString.
 *    To create a line on the LEFT of the segment (direction start to end) supply a negative p_distance; 
 *    a +ve value will create a line on the right side of the segment.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision, and its ZM ordinates rounded to @p_round_zm of precision.
 *  NOTES
 *    A Segment is defined as a simple two point LineString geometry or three point CircularString geometry. 
 *  INPUTS
 *    @p_linestring  (geometry) - Must be a LineString.
 *    @p_offset         (float) - if < 0 then linestring is created on left side of original; if > 0 then offset linestring it to right side of original.
 *    @p_round_xy         (int) - Rounding factor for XY ordinates.
 *    @p_round_zm         (int) - Rounding factor for ZM ordinates.
 *  RESULT
 *    offset line    (geometry) - On left or right side of supplied linestring at required distance.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding (Oracle).
 *    Simon Greener - Nov 2017 - Original coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_gtype            varchar(max),
    @v_wkt              varchar(max),
    @v_dimensions       varchar(4),
    @v_round_xy         int,
    @v_round_zm         int,
	@v_sign             int,
	@v_deflection_angle float,
    @v_offset           float,
	@v_iMPoint          geometry,
	@v_iDetails         varchar(100),
	@v_acute_angle      bit,
	@v_circular_arc     geometry,
    @v_circle           geometry,
    @v_start_point      geometry,
    @v_mid_point        geometry,
    @v_end_point        geometry,

	@v_geom_Array       xml,
	@v_return_geometry  geometry,

    /* Cursor */	
    @v_first_id            int,
    @v_first_element_id    int,
    @v_first_subelement_id int,
    @v_first_segment_id    int, 
	@v_first_length        float,
    @v_first_parallel      geometry,
	@v_first_segment       geometry,

    @v_next_id            int,
    @v_next_element_id    int,
    @v_next_subelement_id int,
    @v_next_segment_id    int, 
	@v_next_length        float,
	@v_next_parallel      geometry,
	@v_next_segment       geometry;

  If ( @p_linestring is null )
    Return @p_linestring.STAsText();

  If ( ABS(ISNULL(@p_offset,0.0)) = 0.0 )
      Return @p_linestring.STAsText();

  SET @v_gtype = @p_linestring.STGeometryType();
  IF ( @v_gtype NOT IN ('LineString','CircularString' ) )
    Return @p_linestring.STAsText();

  -- Let [STOffsetSegment] handle simple 2 point linestring
  IF ( @v_gtype = 'LineString' and @p_linestring.STNumPoints() = 2 )
    Return [dbo].[STOffsetSegment] ( @p_linestring, @p_offset, @p_round_xy, @p_round_zm).STAsText();

  -- Let [STOffsetSegment] handle simple 3 point CircularString
  IF ( @v_gtype = 'CircularString' and @p_linestring.STNumPoints() = 3 and @p_linestring.STNumCurves() = 1)
    Return [dbo].[STOffsetSegment] ( @p_linestring, @p_offset, @p_round_xy, @p_round_zm).STAsText();

  -- Set flag for STPointFromText
  SET @v_dimensions  = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;
  SET @v_round_xy    = ISNULL(@p_round_xy,3);
  SET @v_round_zm    = ISNULL(@p_round_zm,2);
  SET @v_sign        = SIGN(@p_offset);
  SET @v_offset      = ABS(@p_offset);
  SET @v_wkt         = '';

  -- Walk over all the segments of the linear geometry allowing access to previous records
  DECLARE cParallelSegments 
   CURSOR LOCAL 
          SCROLL
          STATIC
          READ_ONLY
      FOR SELECT v.id,
                 v.element_id,
                 v.subelement_id,
                 v.segment_id,
                 v.length,
                 [dbo].[STOffsetLineByParallel]( v.geom, @p_offset, @p_round_xy, @p_round_zm ) as parallel_segment,
                 v.geom
            FROM [dbo].[STSegmentLine](@p_linestring) as v
           ORDER BY v.element_id, 
                    v.subelement_id, 
                    v.segment_id;

  OPEN cParallelSegments;

  -- Get First Segment
  FETCH NEXT 
   FROM cParallelSegments 
   INTO @v_first_id,            
        @v_first_element_id,    
        @v_first_subelement_id, 
        @v_first_segment_id, 
		@v_first_length,
        @v_first_parallel,
        @v_first_segment;

  -- Get Second Segment
  FETCH NEXT 
        FROM cParallelSegments 
        INTO @v_next_id,            
             @v_next_element_id,    
             @v_next_subelement_id, 
             @v_next_segment_id, 
			 @v_next_length,
             @v_next_parallel,
             @v_next_segment;

  SET @v_return_geometry = NULL;
  WHILE @@FETCH_STATUS = 0
  BEGIN

	-- Compute intersection of current pair of offset segments
	SET @v_iMPoint = 
	      [dbo].[STRound](
		        [cogo].[STFindLineIntersectionBySegment] (
                   @v_first_parallel,
                   @v_next_parallel),
                   @v_round_xy,
				   @v_round_zm
          );

	SET @v_iDetails = 
          [cogo].[STFindLineIntersectionDetails] (
                   @v_first_parallel,
                   @v_next_parallel
          );

    -- Check for Parallel (Both are equivalent)
	IF ( @v_iDetails 
         IN ('Parallel',
             'Intersection at End Point 1 and Start Point 2') )
	BEGIN
      -- Add first
	  SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                            @v_Geom_Array,
                            -1,
                            'insert',
                            @v_first_parallel
                           );
      -- Save second
	  SET @v_first_id            = @v_next_id;
	  SET @v_first_element_id    = @v_next_element_id;
	  SET @v_first_subelement_id = @v_next_subelement_id;
	  SET @v_first_segment_id    = @v_next_segment_id;
	  SET @v_first_length        = @v_next_length;
	  SET @v_first_parallel      = @v_next_parallel;
	  SET @v_first_segment       = @v_next_segment;
      FETCH NEXT 
            FROM cParallelSegments 
            INTO @v_next_id,  
                 @v_next_element_id,    
                 @v_next_subelement_id, 
                 @v_next_segment_id, 
                 @v_next_length,
                 @v_next_parallel,
                 @v_next_segment;

       -- If no more segments we need to add to last...
       IF ( @@FETCH_STATUS <> 0 )
         SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                @v_Geom_Array,
                                -1,
                                'insert',
                                @v_first_parallel
                             );
       CONTINUE;
	END;

    IF ( @v_first_id = 1 )
	BEGIN
      -- Determine which start point to write
	  IF ( @v_iDetails IN ('Intersection Within 1 and Within 2',
	                       'Intersection at End Point 1 and Within 2',
	                       'Intersection Within 1 and Within 2',
                           'Intersection Within 1 and at Start Point 2',
						   'Intersection at Start Point 1 and Virtual Intersection Near Start Point 2' ) )
      BEGIN
        SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                @v_Geom_Array,
                                -1,
                                'insert',
                                @v_iMPoint.STGeometryN(1)
                             );
	  END;
	END;

	SET @v_deflection_angle = [cogo].[STFindAngleBetween] ( 
                                 @v_first_segment,
                                 @v_next_segment,
                                 @v_sign
                              );

    SET @v_acute_angle = case when  @v_deflection_angle > 90.0 
                              then 0 
                              else 1 
                          end;

    -- Test result
	IF (@v_acute_angle = 0 
	    and 		
		@v_iDetails = 'Virtual Intersection Near End 1 and Start 2' )
	BEGIN
	  /* Obtuse Angle, so generate Circular Arc */
	  SET @v_circular_arc = 
                 [dbo].[STMakeCircularLine] (
				   @v_first_parallel.STEndPoint(),
			       [cogo].[STFindPointBisector] (
                     /*@p_line      */ @v_first_segment,
                     /*@p_next_line */ @v_next_segment,
                     /*@p_offset    */ @v_offset,
                     /*@p_round_xy  */ @p_round_xy,
                     /*@p_round_z   */ @p_round_zm,
                     /*@p_round_m   */ @p_round_zm
                   ),
				   @v_next_parallel.STStartPoint(),
				   @p_round_xy,@p_round_zm,@p_round_zm
                  );
        SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                @v_Geom_Array,
                                -1,
                                'insert',
                                @v_circular_arc
                             );
	  END
	  ELSE
	  BEGIN 
	    /* Acute Angle */ 
--RETURN CAST(@v_acute_angle as varchar(10)) + ' -> Acute';
        IF ( @v_iDetails 
		     IN ('Intersection at Start 1 Start 2',
                 'Intersection at Start 1 End 2',
				 'Intersection at End 1 Start 2',
                 'Intersection at End 1 End 2',
				 'Unknown' ) )
		BEGIN
          -- All combinations should be impossible for Parallel lines that started connected
	      FETCH NEXT 
	       FROM cParallelSegments 
	       INTO @v_next_id,
                @v_next_element_id,    
                @v_next_subelement_id, 
                @v_next_segment_id, 
                @v_next_length,
                @v_next_parallel,
			    @v_next_segment;
          CONTINUE;
		END;

        IF ( @v_iDetails 
		     IN ('Intersection within both segments', 
		         'Virtual Intersection Within 2 and Near Start 1') )
		BEGIN
          -- All three points in @v_iMPoint are equal then we have an intersection within both lines
		  -- Intersection point can be:
		  -- * Actually Within first @v_first_parallel and second @v_next_parallel
		  -- * Or same as start of @v_first_parallel
		  -- * Or same as end of @v_next_parallel
          IF ( @v_iDetails = 'Virtual Intersection Within 2 and Near Start 1' )
		  BEGIN
		    IF ( @v_iMPoint.STGeometryN(1).STEquals(@v_first_parallel.STStartPoint()) = 1 
			     OR
				 @v_iMPoint.STGeometryN(1).STEquals(@v_next_parallel.STEndPoint()) = 1 
				)
            BEGIN
              -- We don't add the first segment's start point only the intersection point
              SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                     @v_Geom_Array,
                                     -1,
                                     'insert',
                                     @v_iMPoint.STGeometryN(1)
                                  );
		    END
		    ELSE
		    BEGIN
              -- Add start and intersection
			  SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                     @v_Geom_Array,
                                     -1,
                                     'insert',
                                     @v_first_parallel.STStartPoint()
                                  );
			  SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                     @v_Geom_Array,
                                     -1,
                                     'insert',
                                     @v_iMPoint.STGeometryN(1)
                                  );
		    END;
		  END;
	    END;

        -- All Virtual intersections mean lines no longer physically touch.
		-- Those resulting from Obtuse angle are over-ridden by code above
        -- Some are valid, some are not
		IF ( @v_iDetails  = 'Virtual Intersection Near End 1 and Start 2' )
		BEGIN
          -- Valid Intersection
		  SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                 @v_Geom_Array,
                                 -1,
                                 'insert',
                                 @v_first_parallel.STStartPoint()
                              );
          SET @v_Geom_Array = [dbo].[STGeomArray] ( 
                                 @v_Geom_Array,
                                 -1,
                                 'insert',
                                 @v_iMPoint.STGeometryN(1)
                              );
		END;

		IF ( @v_iDetails = 'Virtual Intersection Near Start 1 and End 2' )
		BEGIN
          -- Throw away Start and process second against next
		  SET @v_first_parallel = @v_next_parallel;
		END;

        IF ( @v_iDetails 
             IN ('Virtual Intersection Within 1 and Near Start 2',
                 'Virtual Intersection Within 1 and Near End 2',
                 'Virtual Intersection Within 2 and Near Start 1',
                 'Virtual Intersection Within 2 and Near End 1',
                 'Virtual Intersection Near Start 1 and Start 2',
                 'Virtual Intersection Near End 1 and End 2' ) )
        BEGIN
	      -- No intersection so check relationship with next_segment.
	      FETCH NEXT 
	       FROM cParallelSegments 
	       INTO @v_next_id,            
                @v_next_element_id,    
                @v_next_subelement_id, 
                @v_next_segment_id, 
                @v_next_length,
                @v_next_parallel,
			    @v_next_segment;
          CONTINUE;
		END;
     END;
  END;
  CLOSE      cParallelSegments;
  DEALLOCATE cParallelSegments;
  RETURN @v_wkt; -- @v_return_geometry;
END 

select dbo.STOffsetLineByParallel(geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0),
-0.5,3,1) as rGeom;

UNION ALL
SELECT [dbo].[STOffsetLine](
         geometry::STGeomFromText('LINESTRING (666925 830700, 667187 830726, 667188 830727)',28355),
         -20.0,
         3,
		 1
       ) as oGeom
go

SELECT [dbo].[STOffsetLine] (
         geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0),
         -2.0,
         3,
		 1
       ).STAsText() as oGeom
where 1=1

SELECT [dbo].[STOffsetLine](
         geometry::STGeomFromText('LINESTRING (0.0 0.0, 20.0 0.0)',0),
         20.0,
         3,
		 1
       ).STBuffer(0.1) as oGeom -- .STAsText() as oGeom
